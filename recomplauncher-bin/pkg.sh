# recomplauncher-bin - RecompLauncher (https://github.com/elripalda/RecompLauncher),
# a launcher for recompiled and decompiled PC games (Rust, Tauri). Upstream
# publishes a .deb per release, which the PKGBUILD repackages. Installed from
# a .deb, the app's update button only opens the download page.
#
# Every release so far is a prerelease tagged vX.Y.Z-beta.N. pkgver is
# X.Y.Z.N, the form the AUR package had before it came here. A stable vX.Y.Z
# would sort below its own betas, so latest_version stops on one: the
# PKGBUILD then needs an epoch.
#
# GitHub lists each asset's sha256, so the .deb needs no download here.

UPSTREAM_REPO="elripalda/RecompLauncher"

tag_to_pkgver() { sed -E 's/^v//; s/-beta\./\./'; }

pkgver_to_tag() {
  sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.(.+)$/\1-beta.\2/; s/^/v/' <<< "$1"
}

latest_version() {
  local tags newest best
  tags="$(gh api "repos/$UPSTREAM_REPO/releases?per_page=50" --jq '.[]
    | select(.draft | not)
    | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+(-beta\\.[0-9.]+)?$"))
    | select(any(.assets[]; .name | endswith("_amd64.deb")))
    | .tag_name')"
  # releases are listed newest first, but betas were not always published in order
  best="$(tag_to_pkgver <<< "$tags" | sort -V | tail -n1)"
  newest="$(head -n1 <<< "$tags" | tag_to_pkgver)"
  if [[ "$newest" != *.*.*.* && "$(vercmp "$newest" "$best")" -lt 0 ]]; then
    echo "stable release $newest sorts below $best: the PKGBUILD needs an epoch" >&2
    return 1
  fi
  echo "$best"
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag sha
  tag="$(pkgver_to_tag "$ver")"
  sha="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" \
    --jq ".assets[] | select(.name == \"RecompLauncher_${tag#v}_amd64.deb\") | .digest // empty" \
    | sed 's/^sha256://')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "$tag has no RecompLauncher_${tag#v}_amd64.deb with a sha256 digest" >&2
    return 1
  fi
  sed -i -e "s|^sha256sums=.*|sha256sums=('$sha')|" -e "s|^_tag=.*|_tag=\"$tag\"|" "$pkgbuild"
}
