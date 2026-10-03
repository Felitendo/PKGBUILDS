# schist - Schist (https://github.com/Infrawrench/schist), a layered image
# editor in Rust (gpui) with PSD and Affinity support.
#
# Source package: the PKGBUILD builds the release tag, following upstream's own
# PKGBUILD in packaging/linux/aur/schist. That file names the dependencies of
# each tag, so refresh_checksums() fails when they no longer match ours.
#
# Releases are tagged v<version>, and /releases/latest skips prereleases.

UPSTREAM_REPO="Infrawrench/schist"

# Installed in CI (pacman) before the makepkg test build: the makedepends plus
# the libraries the build links against.
BUILD_DEPS=(rust clang mold fontconfig freetype2 libxcb libxkbcommon
            libxkbcommon-x11 vulkan-icd-loader wayland)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# pkgbuild_array <name>: the words of one array in a PKGBUILD on stdin, sorted
pkgbuild_array() {
  awk -v n="$1" '$0 ~ "^" n "=\\(" { f = 1 } f { sub(/#.*/, ""); print } f && /\)/ { exit }' \
    | sed "s/^$1=(//; s/).*//" | tr -s " '\"" '\n' | sed '/^$/d' | sort
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local upstream name sha

  upstream="$(gh api "repos/$UPSTREAM_REPO/contents/packaging/linux/aur/schist/PKGBUILD?ref=v$ver" \
    -H 'Accept: application/vnd.github.raw')" || return 1
  for name in depends makedepends; do
    if [[ "$(pkgbuild_array "$name" <<< "$upstream")" != "$(pkgbuild_array "$name" < "$pkgbuild")" ]]; then
      echo "upstream's $name changed in v$ver, update the PKGBUILD (and BUILD_DEPS):" >&2
      pkgbuild_array "$name" <<< "$upstream" >&2
      return 1
    fi
  done

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  if [[ "$sha" == "$(printf '' | sha256sum | cut -d' ' -f1)" ]]; then
    echo "could not download the v$ver source tarball" >&2
    return 1
  fi

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
