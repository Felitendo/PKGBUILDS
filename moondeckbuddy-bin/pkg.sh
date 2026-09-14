# moondeckbuddy-bin - MoonDeck Buddy (https://github.com/FrogTheFrog/moondeck-buddy),
# the host-side companion of the MoonDeck Steam Deck plugin (C++23 + Qt6).
#
# Upstream publishes a linuxdeploy AppImage per release, which the PKGBUILD
# unpacks into /opt - so there is no build step here, only pkgver and the
# checksums are refreshed on a new version. The license text is not part of
# the AppImage and comes from the matching source tag.
#
# Releases are created as drafts by upstream's CI and published by hand, so
# /releases/latest never points at a release whose assets are still missing.

UPSTREAM_REPO="FrogTheFrog/moondeck-buddy"

# The AUR already carries moondeckbuddy-appimage, which ships the same upstream
# AppImage, so publishing this as well would be a second copy of one package.
# Flip this to true to publish; until then the PKGBUILD is still kept current
# and test-built here.
AUR_PUBLISH=false

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_img sha_lic

  sha_img="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/MoonDeckBuddy-$ver-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)"
  sha_lic="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/LICENSE" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_img' '$sha_lic')|" "$pkgbuild"
}
