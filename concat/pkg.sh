# concat - Concat (https://github.com/jub0t/Concat), a free and open-source
# CapCut replacement.
#
# Source package: the PKGBUILD builds the editor from the release tarball -
# the same binary upstream ships in the Linux tarball that concat-bin
# repackages. Upstream's flake.nix is the reference for what that needs, and
# this follows it: cargo, cmake and clang, the system FFmpeg, and Slint's
# Skia renderer. (Until 0.2.4 the flake used FemtoVG over wgpu instead; main
# dropped that option.)
#
# Two build scripts download prebuilt static libraries: sherpa-onnx-sys (text
# to speech) and skia-bindings (Skia). The PKGBUILD lists both archives as
# sources and points the build scripts at them (SHERPA_ONNX_ARCHIVE_DIR,
# SKIA_BINARIES_URL), so makepkg checksums them rather than having them
# fetched unverified mid-build. Their names follow upstream's Cargo.lock, so
# refresh_checksums() reads them from the tarball and syncs _sherpa, _skia
# and _skia_key in the PKGBUILD.
#
# The Skia archive's key is <rust-skia commit>-<target>-<Skia features>. The
# commit comes from the skia-bindings crate (.cargo_vcs_info.json). The
# features depend on what Slint turns on, which only a cargo build resolves,
# so they are taken from upstream's flake.nix, which has to name the same
# archive (skiaKeyFeatures). If a flake has none, the PKGBUILD's are kept.
#
# Release/version handling is identical to concat-bin: the release list is
# ordered by creation rather than by version, so the newest is picked by
# publication date, only tags that start with a version count, and pkgver
# drops the hyphens - see concat-bin/pkg.sh.

UPSTREAM_REPO="jub0t/Concat"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(rust cmake clang pkgconf ffmpeg onnxruntime-cpu alsa-lib fontconfig freetype2)

latest_tag() {
  gh api "repos/$UPSTREAM_REPO/releases?per_page=100" \
    --jq '[.[] | select(.draft | not) | select(.tag_name | test("^v[0-9]"))]
          | sort_by(.published_at) | last | .tag_name'
}

tag_to_pkgver() {
  sed 's/^v//; s/-//g'
}

latest_version() {
  latest_tag | tag_to_pkgver
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag tarball lock flake sherpa skia skia_hash skia_features skia_key
  local sha_src sha_sherpa sha_skia archive

  tag="$(latest_tag)"
  if [[ "$(tag_to_pkgver <<< "$tag")" != "$ver" ]]; then
    echo "newest versioned release is $tag, not the requested $ver - try again" >&2
    return 1
  fi

  # kept on disk rather than streamed: the tarball is needed for its checksum
  # and for the Cargo.lock and flake.nix inside it
  tarball="$(mktemp)"
  if ! curl -sfL -o "$tarball" \
       "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$tag.tar.gz"; then
    rm -f "$tarball"
    echo "could not download the $tag source tarball" >&2
    return 1
  fi

  sha_src="$(sha256sum "$tarball" | cut -d' ' -f1)"
  # `|| true`, so that a tree that has moved a file or dropped a crate is
  # reported below instead of ending the run on a failed exit status with
  # nothing printed.
  lock="$(tar -xOzf "$tarball" --wildcards '*/src/Cargo.lock' || true)"
  flake="$(tar -xOzf "$tarball" --wildcards '*/flake.nix' 2>/dev/null || true)"
  rm -f "$tarball"

  sherpa="$(grep -A2 '^name = "sherpa-onnx-sys"' <<< "$lock" \
    | sed -n 's/^version = "\(.*\)"/\1/p' || true)"
  skia="$(grep -A2 '^name = "skia-bindings"' <<< "$lock" \
    | sed -n 's/^version = "\(.*\)"/\1/p' || true)"
  if [[ -z "$sherpa" || -z "$skia" ]]; then
    echo "could not read the sherpa-onnx-sys and skia-bindings versions from $tag's src/Cargo.lock" >&2
    return 1
  fi

  skia_hash="$(curl -sfL "https://static.crates.io/crates/skia-bindings/skia-bindings-$skia.crate" \
    | tar -xzO --wildcards '*/.cargo_vcs_info.json' | jq -r '.git.sha1' | cut -c1-20 || true)"
  if [[ ! "$skia_hash" =~ ^[0-9a-f]{20}$ ]]; then
    echo "could not read the rust-skia commit of skia-bindings $skia from crates.io" >&2
    return 1
  fi
  skia_features="$(sed -n 's/^ *skiaKeyFeatures = "\(.*\)";/\1/p' <<< "$flake")"
  if [[ -z "$skia_features" ]]; then
    skia_features="$(sed -n 's/^_skia_key=".*-x86_64-unknown-linux-gnu-\(.*\)"/\1/p' "$pkgbuild")"
  fi
  skia_key="$skia_hash-x86_64-unknown-linux-gnu-$skia_features"

  archive="$(mktemp)"
  if ! curl -sfL -o "$archive" \
       "https://github.com/k2-fsa/sherpa-onnx/releases/download/v$sherpa/sherpa-onnx-v$sherpa-linux-x64-static-lib.tar.bz2"; then
    rm -f "$archive"
    echo "could not download the sherpa-onnx $sherpa static-lib archive" >&2
    return 1
  fi
  sha_sherpa="$(sha256sum "$archive" | cut -d' ' -f1)"
  # a missing archive most likely means the features are wrong: check the
  # "TRYING TO DOWNLOAD AND INSTALL SKIA BINARIES" line of a build log
  if ! curl -sfL -o "$archive" \
       "https://github.com/rust-skia/skia-binaries/releases/download/$skia/skia-binaries-$skia_key.tar.gz"; then
    rm -f "$archive"
    echo "rust-skia has no Skia archive $skia/$skia_key" >&2
    return 1
  fi
  sha_skia="$(sha256sum "$archive" | cut -d' ' -f1)"
  rm -f "$archive"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_sherpa=.*|_sherpa=\"$sherpa\"|" \
    -e "s|^_skia=.*|_skia=\"$skia\"|" \
    -e "s|^_skia_key=.*|_skia_key=\"$skia_key\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_src' '$sha_sherpa' '$sha_skia')|" \
    "$pkgbuild"
}
