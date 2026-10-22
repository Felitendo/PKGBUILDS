# liner-bin - Liner (https://github.com/tryliner/desktop), an Electron music
# player. Upstream publishes a .deb per release, which the PKGBUILD repackages.
#
# The licence only allows personal, non-commercial use and no redistribution.
# The PKGBUILD downloads upstream's own .deb, so nothing is redistributed here.
#
# The release API lists a sha256 digest per asset, so the .deb needs no
# download here; the CI test build checks the sum against the real file.

UPSTREAM_REPO="tryliner/desktop"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_deb sha_license

  sha_deb="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq ".assets[] | select(.name == \"liner_${ver}_amd64.deb\") | .digest // empty" \
    | sed 's/^sha256://')"
  if [[ ! "$sha_deb" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no liner_${ver}_amd64.deb with a sha256 digest" >&2
    return 1
  fi
  sha_license="$(set -o pipefail; curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/LICENSE" \
    | sha256sum | cut -d' ' -f1)" || return 1

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_deb' '$sha_license')|" "$pkgbuild"
}
