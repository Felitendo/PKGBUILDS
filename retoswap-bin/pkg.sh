# retoswap-bin - RetoSwap, the Reto network fork of Haveno (Java/JavaFX).
# Repackage upstream's .debs for x86_64 and aarch64, including their JRE.
# The AUR source package is called retoswap, so this one follows that name.
#
# Tags end in "-reto" and older ones lack the "v", so refresh_checksums()
# resolves the tag and syncs _tag in the PKGBUILD.

UPSTREAM_REPO="retoaccess1/haveno-reto"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed -E 's/^v//; s/-reto$//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag base sha_x64 sha_arm64

  for tag in "v$ver-reto" "$ver-reto"; do
    gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" --jq '.id' >/dev/null 2>&1 && break
    tag=""
  done
  [[ -n "$tag" ]] || { echo "no release tag found for $ver" >&2; return 1; }

  base="https://github.com/$UPSTREAM_REPO/releases/download/$tag"
  sha_x64="$(set -o pipefail; curl -fsSL "$base/haveno-v$ver-linux-x86_64-installer.deb" \
    | sha256sum | cut -d' ' -f1)" || return 1
  sha_arm64="$(set -o pipefail; curl -fsSL "$base/haveno-v$ver-linux-aarch64-installer.deb" \
    | sha256sum | cut -d' ' -f1)" || return 1

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
