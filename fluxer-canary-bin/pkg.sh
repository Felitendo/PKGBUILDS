# fluxer-canary-bin: the canary channel of Fluxer Desktop (https://fluxer.app).
#
# Same download API as fluxer-bin, which follows "stable" (see the notes
# there). Versions are date-based, and every build has a JSON manifest and a
# .sha256 next to its tarball, so nothing here downloads the tarballs.
# Upstream keeps only its last few builds, so CI has to keep pace.

DL_BASE="https://pkgs.fluxer.com/desktop/canary/linux"

latest_version() {
  local json ver url

  json="$(curl -sfL "$DL_BASE/x64/latest")" || return 1
  ver="$(jq -r '.version // empty' <<< "$json")"
  url="$(jq -r '.files.tar_gz.url // empty' <<< "$json")"

  # Only take a canary build with a plain dotted version (pkgver allows no
  # hyphens). Anything else is EX_TEMPFAIL, see scripts/update-package.sh.
  if [[ -z "$ver" || "$url" != */desktop/canary/linux/* || ! "$ver" =~ ^[0-9][0-9.]*$ ]]; then
    echo "the canary channel's current download is \"${url:-<none>}\" at" \
         "version \"${ver:-<none>}\", which is not a canary build" >&2
    return 75
  fi

  printf '%s\n' "$ver"
}

# _artifact_sha <arch> <version>: upstream's own checksum for that tarball
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

  sha_desktop="$(sha256sum "$(dirname "$pkgbuild")/fluxer-canary.desktop" | cut -d' ' -f1)"
  sha_x64="$(_artifact_sha x64 "$ver")" || return 1
  sha_arm64="$(_artifact_sha arm64 "$ver")" || return 1

  sed -i \
    -e "s|^sha256sums=.*|sha256sums=('$sha_desktop')|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
