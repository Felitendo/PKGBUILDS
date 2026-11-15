# waypointer - Waypointer (https://github.com/Felitendo/waypointer), a tiny hand
# on a stick that points at things on your screen: the Linux version of TinyHand
# (Rust, drawn with Rune, for Wayland).
#
# Source package: the PKGBUILD builds the release tag and installs it with
# upstream's Makefile. Releases are tagged v<version>, and /releases/latest
# skips prereleases.

UPSTREAM_REPO="Felitendo/waypointer"

# Installed in CI (pacman) before the makepkg test build: the makedepends plus
# the libraries the build links against.
BUILD_DEPS=(rust alsa-lib libxkbcommon)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  if [[ "$sha" == "$(printf '' | sha256sum | cut -d' ' -f1)" ]]; then
    echo "could not download the v$ver source tarball" >&2
    return 1
  fi

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
