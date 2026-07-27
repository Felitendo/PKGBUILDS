# faugus-launcher-bin - Faugus Launcher
# (https://github.com/Faugus/faugus-launcher), a GTK4 front-end for running
# Windows games through UMU-Launcher.
#
# Upstream publishes an architecture-independent .deb per release, which the
# PKGBUILD repackages. The Debian revision in the asset name is not derived
# from the version, so refresh_checksums() resolves the asset via the GitHub
# API and syncs the _asset variable in the PKGBUILD along with the checksum.
#
# Upstream tags carry no "v" prefix.

UPSTREAM_REPO="Faugus/faugus-launcher"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local asset sha

  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$ver" --jq '.assets[].name' \
    | grep -E "^faugus-launcher_${ver}-[0-9]+_all\.deb$")"
  [[ "$(wc -l <<< "$asset")" -eq 1 ]] || { echo "expected exactly one deb, got: $asset" >&2; return 1; }

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$ver/$asset" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_asset=.*|_asset=\"$asset\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
