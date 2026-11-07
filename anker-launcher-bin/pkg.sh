# anker-launcher-bin - Anker Launcher (https://github.com/zororver/anker-launcher),
# the desktop client for AnkerGames.
#
# Upstream publishes a linuxdeploy AppImage per release, which the PKGBUILD
# unpacks and installs into /opt - so there is no build step here, only pkgver
# and the checksums are refreshed on a new version.

UPSTREAM_REPO="zororver/anker-launcher"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_img

  sha_img="$(set -o pipefail; curl -fsSL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/AnkerLauncher-$ver-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)" || return 1

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_img')|" "$pkgbuild"
}
