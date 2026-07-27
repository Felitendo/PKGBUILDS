# wiiudownloader-bin - WiiUDownloader
# (https://github.com/Xpl0itU/WiiUDownloader), a Go + GTK3 downloader for
# Wii U titles from Nintendo's official servers.
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt - so there is no build step here, only pkgver and the
# checksum are refreshed on a new version.

UPSTREAM_REPO="Xpl0itU/WiiUDownloader"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/WiiUDownloader-Linux-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
