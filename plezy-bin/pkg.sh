# plezy-bin - Plezy (https://github.com/edde746/plezy), a Plex, Jellyfin and
# Emby client built with Flutter.
#
# Upstream builds the Linux release itself and publishes a .deb (plus .rpm,
# .pkg.tar.zst and a portable tarball) per release, so there is no build step
# here: on a new version only pkgver and the two checksums are refreshed and
# the PKGBUILD repackages the .deb directly.
#
# plezy itself is in [extra], built from source by an Arch packager, so only
# the -bin variant belongs in the AUR - a second source package would be a
# duplicate the AUR rejects outright. The two conflict, and plezy-bin provides
# plezy so either one satisfies a dependency on it. What it buys over the
# repository package is release-day updates without the Flutter build, which
# needs an fvm-pinned SDK and takes the better part of an hour.
#
# Release tags are plain versions with no v prefix (2.16.0), every release is a
# full release, and the asset names are fixed (plezy-linux-x64.deb /
# plezy-linux-arm64.deb), so /releases/latest is enough to track upstream.

UPSTREAM_REPO="edde746/plezy"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local base sha_x64 sha_arm64

  base="https://github.com/$UPSTREAM_REPO/releases/download/$ver"
  sha_x64="$(curl -sfL "$base/plezy-linux-x64.deb" | sha256sum | cut -d' ' -f1)"
  sha_arm64="$(curl -sfL "$base/plezy-linux-arm64.deb" | sha256sum | cut -d' ' -f1)"

  # curl -f keeps a 404 page out of the sums; a missing asset ends up empty here
  for sha in "$sha_x64" "$sha_arm64"; do
    if [[ "$sha" == "$(printf '' | sha256sum | cut -d' ' -f1)" ]]; then
      echo "one of the $ver .deb assets is missing or empty - try again" >&2
      return 1
    fi
  done

  sed -i \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
