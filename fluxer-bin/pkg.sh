# fluxer-bin - Fluxer Desktop (https://fluxer.app), an Electron app.
#
# Upstream hosts versioned prebuilt binaries itself, so there is no
# build_artifact() here: on a new version only pkgver and the checksums
# are refreshed and the result is pushed to the AUR.
#
# Versions are date-based: 2026.920.41303 is the build published at
# 2026-09-20 04:13:03 UTC, the last field being the time of day without
# leading zeros. vercmp orders those correctly both within a day and across
# days, and every one of them outranks the 0.0.x versions this package
# carried until upstream changed schemes.
#
# The download API has one URL shape per channel, and this package follows
# "stable". Every build publishes a JSON manifest and a .sha256 next to its
# artifacts, so neither the version check nor the checksum refresh has to
# pull the ~130 MB tarballs to look at them.
#
# Upstream keeps only its last few builds per channel - everything under the
# old scheme is already gone, which is how a pinned 0.0.8 turned into a 404
# for anyone installing from the AUR. The version named here stays fetchable
# only while this repository keeps pace with the channel.

DL_BASE="https://api.fluxer.app/dl/desktop/stable/linux"

latest_version() {
  local json ver url

  # the channel's manifest for whatever it currently considers current
  json="$(curl -sfL "$DL_BASE/x64/latest")" || return 1
  ver="$(jq -r '.version // empty' <<< "$json")"
  url="$(jq -r '.files.tar_gz.url // empty' <<< "$json")"

  # When stable has no current build the API falls through to another
  # channel, and the artifact URL is where that becomes visible. A canary
  # build is a nightly, not what a package called fluxer-bin ships, so that
  # is EX_TEMPFAIL rather than a version - see scripts/update-package.sh.
  # The version is shape-checked along with it: pkgver takes no hyphens, and
  # a channel name in there would be one.
  if [[ -z "$ver" || "$url" != */desktop/stable/linux/* || ! "$ver" =~ ^[0-9][0-9.]*$ ]]; then
    echo "the stable channel's current download is \"${url:-<none>}\" at" \
         "version \"${ver:-<none>}\", which is not a stable build -" \
         "nothing to update to" >&2
    return 75
  fi

  printf '%s\n' "$ver"
}

# _artifact_sha <arch> <version> - upstream's own checksum for that tarball,
# published as a sha256sum-format sidecar next to the download itself
_artifact_sha() {
  local sha
  sha="$(curl -sfL "$DL_BASE/$1/$2/tar_gz.sha256" | grep -ioEm1 '^[0-9a-f]{64}')"
  [[ -n "$sha" ]] || { echo "upstream publishes no checksum for $1 $2" >&2; return 1; }
  printf '%s\n' "$sha"
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_desktop sha_x64 sha_arm64

  sha_desktop="$(sha256sum "$(dirname "$pkgbuild")/fluxer.desktop" | cut -d' ' -f1)"
  sha_x64="$(_artifact_sha x64 "$ver")" || return 1
  sha_arm64="$(_artifact_sha arm64 "$ver")" || return 1

  sed -i \
    -e "s|^sha256sums=.*|sha256sums=('$sha_desktop')|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
