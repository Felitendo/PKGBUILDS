# fluxer-bin - Fluxer Desktop (https://fluxer.app), an Electron app.
#
# Upstream hosts versioned prebuilt binaries itself, so there is no
# build_artifact() here: on a new version only pkgver and the checksums
# are refreshed and the result is pushed to the AUR.

DL_BASE="https://api.fluxer.app/dl/desktop/stable/linux"

latest_version() {
  # the download API exposes the current version in the attachment filename,
  # e.g. content-disposition: attachment; filename="fluxer-stable-0.0.8-x64.tar.gz"
  curl -sfI "$DL_BASE/x64/latest/tar_gz" \
    | grep -oiP 'filename="fluxer-(stable-)?\K[0-9][^"]*(?=-x64\.tar\.gz)'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_desktop sha_x64 sha_arm64

  sha_desktop="$(sha256sum "$(dirname "$pkgbuild")/fluxer.desktop" | cut -d' ' -f1)"
  sha_x64="$(curl -sfL "$DL_BASE/x64/$ver/tar_gz" | sha256sum | cut -d' ' -f1)"
  sha_arm64="$(curl -sfL "$DL_BASE/arm64/$ver/tar_gz" | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^sha256sums=.*|sha256sums=('$sha_desktop')|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
