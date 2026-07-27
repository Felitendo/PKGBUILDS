# waydroid-helper-bin - Waydroid Helper
# (https://github.com/ayasa520/waydroid-helper), a GTK4 + LibAdwaita GUI for
# Waydroid configuration and extension installation.
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt - so there is no build step here, only pkgver and the
# checksum are refreshed on a new version.

UPSTREAM_REPO="ayasa520/waydroid-helper"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/waydroid-helper-$ver-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
