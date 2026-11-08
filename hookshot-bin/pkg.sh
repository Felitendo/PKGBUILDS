# hookshot-bin - Hookshot (https://github.com/NotRexed/Hookshot), a static
# recompilation of Ocarina of Time (Switch 2). Its builder compiles the game
# on the user's PC from their own copy; nothing of the game is packaged.
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt - so there is no build step here, only pkgver and the
# checksum are refreshed on a new version.
#
# Upstream also has releases that are not versions (linux-parts, fast-updates,
# ...), so latest_version only takes v-tags that carry the AppImage.

UPSTREAM_REPO="NotRexed/Hookshot"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases" --jq '[.[]
    | select((.draft or .prerelease) | not)
    | select(.tag_name | test("^v[0-9]"))
    | select(any(.assets[]; .name | endswith("-x86_64.AppImage")))][0].tag_name' \
    | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/Hookshot-v$ver-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
