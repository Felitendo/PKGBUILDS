# lichii-shader-sync - Lichii Shader Sync
# (https://github.com/oceanpacificpeace/lichii-shader-sync), downloads shared
# Vulkan shader caches into Lichii and Eden (Go).
#
# Source package: the PKGBUILD builds the command line tool from the tag
# tarball. The GUI in ./gui is Windows only.
#
# The same repository publishes the shader packs as releases (tags such as
# 0400486024DEC000-20261108), and those often are "latest". So only v<version>
# tags count. They come from git ls-remote, which lists all of them at once.

UPSTREAM_REPO="oceanpacificpeace/lichii-shader-sync"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(go)

latest_version() {
  git ls-remote --tags --refs "https://github.com/$UPSTREAM_REPO.git" 'refs/tags/v*' \
    | sed -n 's|.*refs/tags/v\([0-9][0-9.]*[0-9]\)$|\1|p' | sort -V | tail -n 1
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha

  sha="$(set -o pipefail; curl -fsSL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)" || return 1
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
