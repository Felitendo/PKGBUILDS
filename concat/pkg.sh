# concat - Concat (https://github.com/jub0t/Concat), a free and open-source
# CapCut replacement: a Tauri 2 shell around a Rust video engine.
#
# Source package: the PKGBUILD builds the Tauri binary from the release
# tarball - the same executable upstream wraps into the .deb that concat-bin
# repackages. Upstream's flake.nix is the reference for what that needs, and
# this follows it: JS toolchain plus cargo, and WOLFCUT_SYSTEM_TOOLS=1 to opt
# out of staging a private ffmpeg/whisper-cli into the bundle, because Arch
# packages both and the app falls back to PATH.
#
# sherpa-onnx-sys, the text-to-speech backend, ships no C++ build: its build
# script downloads a prebuilt static-lib archive from the sherpa-onnx release
# page. The PKGBUILD lists that archive as a source and points the build
# script at it (SHERPA_ONNX_ARCHIVE_DIR), so the binary is checksummed by
# makepkg rather than fetched unverified mid-build. Its version has to follow
# upstream's Cargo.lock, so refresh_checksums() reads it from the tarball and
# syncs the _sherpa variable in the PKGBUILD.
#
# Release/version handling is identical to concat-bin: every upstream release
# is a "v<version>-alpha.<n>" prerelease published on a push to main, the
# release list is ordered by creation rather than by version (v0.2.0-alpha.10
# sits between alpha.2 and alpha.1), so the newest is picked by publication
# date, and pkgver drops the hyphens - see concat-bin/pkg.sh.

# Not on the AUR yet. concat-git goes up first; these two follow once the
# alpha-per-push release cadence has been lived with for a while - upstream
# publishes several a day, and each one is an AUR push (and, for concat, a
# full Rust build in CI). Flip this to true to publish; until then the
# PKGBUILD is still kept current and test-built here.
AUR_PUBLISH=false

UPSTREAM_REPO="jub0t/Concat"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(rust npm webkit2gtk-4.1 gtk3 libsoup3 alsa-lib)

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
  local tag tarball sherpa sha_src sha_sherpa

  tag="$(latest_tag)"
  if [[ "$(tag_to_pkgver <<< "$tag")" != "$ver" ]]; then
    echo "newest versioned release is $tag, not the requested $ver - try again" >&2
    return 1
  fi

  # kept on disk rather than streamed: the tarball is needed twice, once for
  # its checksum and once for the Cargo.lock inside it
  tarball="$(mktemp)"
  if ! curl -sfL -o "$tarball" \
       "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$tag.tar.gz"; then
    rm -f "$tarball"
    echo "could not download the $tag source tarball" >&2
    return 1
  fi

  sha_src="$(sha256sum "$tarball" | cut -d' ' -f1)"
  sherpa="$(tar -xOzf "$tarball" --wildcards '*/desktop/src-tauri/Cargo.lock' \
    | grep -A2 '^name = "sherpa-onnx-sys"' | sed -n 's/^version = "\(.*\)"/\1/p')"
  rm -f "$tarball"

  if [[ -z "$sherpa" ]]; then
    echo "could not read the sherpa-onnx-sys version from $tag's Cargo.lock" >&2
    return 1
  fi

  sha_sherpa="$(curl -sfL "https://github.com/k2-fsa/sherpa-onnx/releases/download/v$sherpa/sherpa-onnx-v$sherpa-linux-x64-static-lib.tar.bz2" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_sherpa=.*|_sherpa=\"$sherpa\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_src' '$sha_sherpa')|" \
    "$pkgbuild"
}
