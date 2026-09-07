# kitty-tune-bin - KittyTune Desktop, a Kotlin/Compose music player.
# Repackage upstream's .debs for x86_64 and aarch64, including their JRE.

UPSTREAM_REPO="alan7383/KittyTuneDesktop"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local base sha_readme sha_x64 sha_arm64

  base="https://github.com/$UPSTREAM_REPO/releases/download/v$ver"
  sha_readme="$(set -o pipefail; curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/README.md" \
    | sha256sum | cut -d' ' -f1)" || return 1
  sha_x64="$(set -o pipefail; curl -fsSL "$base/kitty-tune_${ver}_amd64.deb" \
    | sha256sum | cut -d' ' -f1)" || return 1
  sha_arm64="$(set -o pipefail; curl -fsSL "$base/kitty-tune_${ver}_arm64.deb" \
    | sha256sum | cut -d' ' -f1)" || return 1

  sed -i \
    -e "s|^sha256sums=.*|sha256sums=('$sha_readme')|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
