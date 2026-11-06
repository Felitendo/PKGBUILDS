# capri-desktop-bin - Capri (https://github.com/lachydotmcg/capri-desktop), an
# unofficial desktop companion (C#/.NET, Avalonia on Linux).
#
# Upstream publishes a self-contained single-file Linux build per release,
# which the PKGBUILD installs unchanged. On Linux she only points to the
# release page when there is an update, so nothing needs patching.
#
# The release API lists a sha256 digest per asset, so the tarball needs no
# download here. The desktop entry, icon and licence come from the tag.

UPSTREAM_REPO="lachydotmcg/capri-desktop"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha file sums=()

  sha="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq '.assets[] | select(.name == "Capri-linux-x64.tar.gz") | .digest // empty' \
    | sed 's/^sha256://')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no Capri-linux-x64.tar.gz with a sha256 digest" >&2
    return 1
  fi
  sums+=("'$sha'")

  for file in cross/linux/capri-desktop.desktop cross/icon.png LICENSE.md; do
    sha="$(set -o pipefail; curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/$file" \
      | sha256sum | cut -d' ' -f1)" || return 1
    sums+=("'$sha'")
  done

  sed -i "s|^sha256sums=.*|sha256sums=(${sums[*]})|" "$pkgbuild"
}
