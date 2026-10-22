# filee-bin - Filee (https://github.com/KnifeLemon/Filee), an offline file
# converter (C#/.NET, Avalonia).
#
# Upstream publishes a self-contained Linux tarball for x64 and arm64 with every
# release, which the PKGBUILD installs unchanged. Each tarball has a
# SHA256SUMS file next to it, so the checksums are read from there instead of
# downloading 120 MB per architecture.

UPSTREAM_REPO="KnifeLemon/Filee"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# upstream_sha <version> <x64|arm64>
upstream_sha() {
  local file="Filee-$1-linux-$2.tar.gz"
  curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$1/Filee-$1-linux-$2-SHA256SUMS.txt" \
    | awk -v f="$file" '$2 == f || $2 == "*" f { print $1 }'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_x64 sha_arm64

  sha_x64="$(upstream_sha "$ver" x64)"
  sha_arm64="$(upstream_sha "$ver" arm64)"
  if [[ ! "$sha_x64" =~ ^[0-9a-f]{64}$ || ! "$sha_arm64" =~ ^[0-9a-f]{64}$ ]]; then
    echo "no checksum for one of the $ver tarballs - try again" >&2
    return 1
  fi

  sed -i \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
