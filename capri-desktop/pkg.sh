# capri-desktop - Capri (https://github.com/lachydotmcg/capri-desktop), an
# unofficial desktop companion (C#/.NET, Avalonia on Linux).
#
# Source package: builds the release tag's cross/ project like upstream's
# Linux build, but on Arch's .NET runtime. NuGet restores in prepare(), so
# that step needs network access. On Linux she only points to the release
# page when there is an update, so nothing needs patching.

UPSTREAM_REPO="lachydotmcg/capri-desktop"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(dotnet-sdk-10.0)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha

  sha="$(set -o pipefail; curl -fsSL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)" || return 1
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
