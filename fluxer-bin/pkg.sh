# fluxer-bin - Fluxer Desktop (https://fluxer.app), an Electron app.
#
# Upstream hosts versioned prebuilt binaries itself, so there is no
# build_artifact() here: on a new version only pkgver and the checksums
# are refreshed and the result is pushed to the AUR.
#
# The download API has one URL shape per channel, and this package follows
# "stable". Its /latest currently 302s into the canary channel - upstream has
# published nothing to stable since 0.0.8, and the pointer falls through to
# the channel that is moving. A canary build is a nightly, not what a package
# called fluxer-bin ships, so latest_version() recognises the fall-through
# and reports EX_TEMPFAIL instead of a version; see below.

DL_BASE="https://api.fluxer.app/dl/desktop/stable/linux"

latest_version() {
  local name ver

  # the download API exposes the current version in the attachment filename,
  # e.g. content-disposition: attachment; filename="fluxer-stable-0.0.8-x64.tar.gz"
  #
  # -L, and the last filename of the chain: when the stable channel has no
  # current build the request is redirected to another channel, and the
  # filename it answers with is how that becomes visible here.
  name="$(curl -sfIL "$DL_BASE/x64/latest/tar_gz" \
    | grep -oiP 'filename="\K[^"]+' | tail -n1)"

  ver="$(grep -oiP '^fluxer-(stable-)?\K[0-9][^"]*(?=-x64\.tar\.gz$)' <<< "$name" \
    || true)"
  if [[ -z "$ver" ]]; then
    # e.g. Fluxer-Canary-2026.904.135113-linux-x64.tar.gz - the canary channel
    echo "the stable channel's latest download is \"$name\", which is not a" \
         "stable build - nothing to update to" >&2
    return 75
  fi

  printf '%s\n' "$ver"
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
