# hookshot-bin - Hookshot (https://git.notrexed.dev/Hookshot/Hookshot), a
# static recompilation of Ocarina of Time (Switch 2). Its builder compiles the
# game on the user's PC from their own copy; nothing of the game is packaged.
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt - so there is no build step here, only pkgver and the
# checksum are refreshed on a new version.
#
# Upstream moved from GitHub to its own Forgejo. It also has releases that
# are not versions (rc, ...), so latest_version only takes v-tags that carry
# the AppImage.

FORGE="https://git.notrexed.dev"
UPSTREAM_REPO="Hookshot/Hookshot"

latest_version() {
  curl -sf "$FORGE/api/v1/repos/$UPSTREAM_REPO/releases?limit=50" | jq -r '[.[]
    | select((.draft or .prerelease) | not)
    | select(.tag_name | test("^v[0-9]"))
    | select(any(.assets[]; .name | endswith("-x86_64.AppImage")))][0].tag_name' \
    | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL "$FORGE/$UPSTREAM_REPO/releases/download/v$ver/Hookshot-v$ver-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
