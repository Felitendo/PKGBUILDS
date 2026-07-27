# snapx-bin - SnapX (https://github.com/SnapXL/SnapX), screenshot/sharing
# tool forked from ShareX, C#/.NET Avalonia UI.
#
# Upstream ships a self-contained Linux bundle per (pre)release which the
# PKGBUILD installs unchanged. The asset names embed build metadata
# (e.g. ...-0.4.0-alpha.0+g7eafb0f-X64...) that cannot be derived from the
# version alone, so refresh_checksums() resolves the asset via the GitHub API
# and syncs the _asset variable in the PKGBUILD along with the checksums.
# All upstream releases are marked prerelease, so latest_version() reads the
# release list instead of /latest.

UPSTREAM_REPO="SnapXL/SnapX"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases" --jq '.[0].tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local asset sha_bin sha_src

  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" --jq '.assets[].name' \
    | grep '^SnapX-UI-Release-Linux-' | grep -v musl | grep -- '-X64\.tar\.zst$')"
  [[ "$(wc -l <<< "$asset")" -eq 1 ]] || { echo "expected exactly one UI asset, got: $asset" >&2; return 1; }

  sha_bin="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/$asset" \
    | sha256sum | cut -d' ' -f1)"
  sha_src="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_asset=.*|_asset=\"$asset\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_bin' '$sha_src')|" \
    "$pkgbuild"
}
