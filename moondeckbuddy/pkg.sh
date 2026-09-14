# moondeckbuddy - MoonDeck Buddy (https://github.com/FrogTheFrog/moondeck-buddy),
# the host-side companion of the MoonDeck Steam Deck plugin (C++23 + Qt6).
#
# Source package: the PKGBUILD builds the release tag against Arch's Qt6 - the
# same CMake project upstream hands to linuxdeploy for the AppImage that
# moondeckbuddy-bin repackages.
#
# The tag tarball lacks two inputs of the build, both pinned per release:
# - resources/ssl is a git submodule (FrogTheFrog/moondeck-keys) holding the
#   self-signed certificate compiled into Buddy; its commit is read from the
#   tag's tree.
# - glaze is pulled by src/lib/json/CMakeLists.txt with FetchContent at
#   configure time; its GIT_TAG is read from that file, and the PKGBUILD points
#   FETCHCONTENT_SOURCE_DIR_GLAZE at the matching tarball so build() needs no
#   network.
#
# Releases are created as drafts by upstream's CI and published by hand, so
# /releases/latest never points at a half-finished release.

UPSTREAM_REPO="FrogTheFrog/moondeck-buddy"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(cmake ninja procps-ng qt6-base qt6-httpserver qt6-websockets)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local keys glaze sha_src sha_keys sha_glaze

  keys="$(gh api "repos/$UPSTREAM_REPO/contents/resources/ssl?ref=v$ver" --jq '.sha')"
  glaze="$(gh api "repos/$UPSTREAM_REPO/contents/src/lib/json/CMakeLists.txt?ref=v$ver" \
    -H 'Accept: application/vnd.github.raw' | grep -Po 'GIT_TAG\s+v\K[0-9.]+$')"
  if [[ ! "$keys" =~ ^[0-9a-f]{40}$ || -z "$glaze" ]]; then
    echo "could not resolve the moondeck-keys commit ($keys) or glaze version ($glaze) of v$ver" >&2
    return 1
  fi

  sha_src="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sha_keys="$(curl -sfL "https://github.com/FrogTheFrog/moondeck-keys/archive/$keys.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sha_glaze="$(curl -sfL "https://github.com/stephenberry/glaze/archive/refs/tags/v$glaze.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_keys_commit=.*|_keys_commit=\"$keys\"|" \
    -e "s|^_glaze_ver=.*|_glaze_ver=\"$glaze\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_src' '$sha_keys' '$sha_glaze')|" \
    "$pkgbuild"
}
