# moondeckbuddy - MoonDeck Buddy (https://github.com/FrogTheFrog/moondeck-buddy),
# the host-side companion of the MoonDeck Steam Deck plugin (C++23 + Qt6).
#
# Source package: the PKGBUILD builds the release tag against Arch's Qt6 - the
# same CMake project upstream hands to linuxdeploy for the AppImage that
# moondeckbuddy-bin repackages.
#
# The tag tarball leaves both of upstream's submodules empty, so each is pinned
# per release and passed to the build as its own source:
# - resources/ssl is FrogTheFrog/moondeck-keys, the self-signed certificate
#   compiled into Buddy.
# - src/lib/json/glaze is stephenberry/glaze, the JSON library. Up to 1.10.0
#   CMake pulled it with FetchContent and a GIT_TAG; since 1.11.0 it is a
#   submodule that src/lib/json/CMakeLists.txt adds with add_subdirectory.
# Both commits are read from the tag's tree.
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

  # A failed lookup is emptied rather than left to set -e: a submodule upstream
  # moved or renamed is then named by the message below. gh prints the error
  # body on stdout, so the empty assignment also keeps it out of the message.
  keys="$(gh api "repos/$UPSTREAM_REPO/contents/resources/ssl?ref=v$ver" --jq '.sha')" || keys=""
  glaze="$(gh api "repos/$UPSTREAM_REPO/contents/src/lib/json/glaze?ref=v$ver" --jq '.sha')" || glaze=""
  if [[ ! "$keys" =~ ^[0-9a-f]{40}$ || ! "$glaze" =~ ^[0-9a-f]{40}$ ]]; then
    echo "could not resolve the moondeck-keys ($keys) or glaze ($glaze) commit of v$ver" >&2
    return 1
  fi

  sha_src="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sha_keys="$(curl -sfL "https://github.com/FrogTheFrog/moondeck-keys/archive/$keys.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sha_glaze="$(curl -sfL "https://github.com/stephenberry/glaze/archive/$glaze.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_keys_commit=.*|_keys_commit=\"$keys\"|" \
    -e "s|^_glaze_commit=.*|_glaze_commit=\"$glaze\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_src' '$sha_keys' '$sha_glaze')|" \
    "$pkgbuild"
}
