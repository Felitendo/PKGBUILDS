# pittore-studio - Pittore Studio
# (https://github.com/Event-Horizon-desktop-environment/pittore-studio), a
# layer-based photo editor for Linux in C++20 on Qt 6.
#
# Source package: the PKGBUILD builds the release tag with meson, following
# upstream's own packaging/arch/PKGBUILD - the same file their CI feeds to
# makepkg to produce the .pkg.tar.zst that pittore-studio-bin repackages. That
# file names the dependencies and the GPU target lists of each tag, so
# refresh_checksums() fails when either no longer matches ours. A silently
# changed arch list would otherwise build for the wrong cards.
#
# makedepends differ from upstream's on purpose: cuda is added (upstream's own
# PKGBUILD passes -Dbackend-cuda=enabled but relies on its CI installing the
# toolkit separately) and git is dropped (nothing in the build uses it).
#
# Releases are tagged v<version>. The rolling prerelease upstream pushes on
# every main commit is not "latest", so /releases/latest skips it.

UPSTREAM_REPO="Event-Horizon-desktop-environment/pittore-studio"

# Installed in CI (pacman) before the makepkg test build: the makedepends plus
# the libraries the build links against. cuda is 5.6 GB installed, the ROCm
# stack behind hip-runtime-amd another couple - this is the heaviest test
# build here.
BUILD_DEPS=(cuda hip-runtime-amd meson ninja pkgconf
            qt6-base qt6-svg zlib harfbuzz freetype2 fontconfig lcms2
            libwebp libtiff libjpeg-turbo zstd qrencode tomlplusplus)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# pkgbuild_array <name>: the words of one array in a PKGBUILD on stdin, sorted
pkgbuild_array() {
  awk -v n="$1" '$0 ~ "^" n "=\\(" { f = 1 } f { sub(/#.*/, ""); print } f && /\)/ { exit }' \
    | sed "s/^$1=(//; s/).*//" | tr -s " '\"" '\n' | sed '/^$/d' | sort
}

# meson_opts: the --prefix and -D options of the meson setup call in a PKGBUILD
# on stdin, sorted. Line breaks and argument order do not matter.
meson_opts() {
  sed -n '/meson setup/,/[^\\]$/p' | grep -oE '(--prefix|-D[a-z-]+)=[^ ]+' | sort
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local upstream name sha

  upstream="$(gh api "repos/$UPSTREAM_REPO/contents/packaging/arch/PKGBUILD?ref=v$ver" \
    -H 'Accept: application/vnd.github.raw')" || return 1
  for name in depends optdepends; do
    if [[ "$(pkgbuild_array "$name" <<< "$upstream")" != "$(pkgbuild_array "$name" < "$pkgbuild")" ]]; then
      echo "upstream's $name changed in v$ver, update the PKGBUILD (and BUILD_DEPS):" >&2
      pkgbuild_array "$name" <<< "$upstream" >&2
      return 1
    fi
  done
  if [[ "$(meson_opts <<< "$upstream")" != "$(meson_opts < "$pkgbuild")" ]]; then
    echo "upstream's meson options changed in v$ver, update the PKGBUILD:" >&2
    meson_opts <<< "$upstream" >&2
    return 1
  fi

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  if [[ "$sha" == "$(printf '' | sha256sum | cut -d' ' -f1)" ]]; then
    echo "could not download the v$ver source tarball" >&2
    return 1
  fi

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
