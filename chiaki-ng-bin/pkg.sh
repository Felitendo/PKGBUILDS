# chiaki-ng-bin - chiaki-ng (https://github.com/streetpea/chiaki-ng), a free
# PlayStation Remote Play client (C/C++ + Qt6).
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt - so there is no build step here, only pkgver and the
# checksums are refreshed on a new version. The license texts are not part of
# the AppImage and come from the matching source tag.

UPSTREAM_REPO="streetpea/chiaki-ng"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_img sha_lic

  sha_img="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/chiaki-ng.AppImage_x86_64" \
    | sha256sum | cut -d' ' -f1)"
  sha_lic="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/COPYING" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_img' '$sha_lic')|" "$pkgbuild"
}
