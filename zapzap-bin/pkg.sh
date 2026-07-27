# zapzap-bin - ZapZap (https://github.com/rafatosta/zapzap), WhatsApp desktop
# client written in PyQt6 + PyQt6-WebEngine.
#
# Upstream publishes a pure-Python wheel per release, which the PKGBUILD
# installs against the system PyQt6 packages - unlike upstream's deb/AppImage
# bundles, which vendor all of Qt. Icon, desktop file and metainfo are not
# part of the wheel and come from the matching source tag.
#
# Upstream tags carry no "v" prefix.

UPSTREAM_REPO="rafatosta/zapzap"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_whl sha_src

  sha_whl="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$ver/zapzap-$ver-py3-none-any.whl" \
    | sha256sum | cut -d' ' -f1)"
  sha_src="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_whl' '$sha_src')|" "$pkgbuild"
}
