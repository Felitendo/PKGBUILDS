# voicenux-bin - Voicenux (https://github.com/voicenux/voicenux), a real-time
# voice changer and soundboard for PipeWire (Rust, GTK4 + libadwaita).
#
# Upstream builds an Arch tarball for every release (packaging/build-tarball.sh),
# made for this package: the `make install` tree under one folder. There is no
# build step here, only pkgver and the checksums are refreshed.
#
# Upstream's release workflow creates the release only after every package is
# built, so /releases/latest never points at a release without its assets.

UPSTREAM_REPO="voicenux/voicenux"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_tar sha_lic

  sha_tar="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/voicenux-$ver-arch-x86_64.tar.zst" \
    | sha256sum | cut -d' ' -f1)"
  sha_lic="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/data/icons/LICENSE" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_tar' '$sha_lic')|" "$pkgbuild"
}
