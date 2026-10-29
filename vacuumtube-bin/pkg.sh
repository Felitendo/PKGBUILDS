# vacuumtube-bin - VacuumTube (https://github.com/shy1132/VacuumTube),
# YouTube Leanback (TV UI) wrapper, Electron.
#
# Upstream publishes a bundled .deb per release, so there is no
# build_artifact() here: on a new version only pkgver and the checksum are
# refreshed and the PKGBUILD repackages the deb directly. The licence text
# is not in the deb and comes from the matching tag.

UPSTREAM_REPO="shy1132/VacuumTube"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha sha_lic
  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/VacuumTube-amd64.deb" \
    | sha256sum | cut -d' ' -f1)"
  sha_lic="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/LICENSE" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha' '$sha_lic')|" "$pkgbuild"
}
