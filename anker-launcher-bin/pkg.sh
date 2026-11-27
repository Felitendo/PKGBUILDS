# anker-launcher-bin - Anker Launcher (https://ankergames.net/launcher),
# the desktop client for AnkerGames.
#
# Upstream publishes a linuxdeploy AppImage per release, which the PKGBUILD
# unpacks and installs into /opt - so there is no build step here, only pkgver
# and the checksums are refreshed on a new version.

UPDATE_URL="https://ankergames.net/api/v1/client/update?version=0.0.0&platform=linux&arch=x86_64&channel=stable"
DOWNLOAD_BASE="https://ankergames.net/api/v1/launcher-files"

latest_version() {
  local json ver url
  json="$(curl -fsSL "$UPDATE_URL")" || return 1
  ver="$(jq -r '.version // empty' <<< "$json")"
  url="$(jq -r '.url // empty' <<< "$json")"

  if [[ -z "$ver" || ! "$ver" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "unexpected upstream version: '${ver:-<none>}'" >&2
    return 1
  fi
  if [[ "$url" != "$DOWNLOAD_BASE/v$ver/AnkerLauncher-$ver-x86_64.AppImage" ]]; then
    echo "unexpected upstream download URL: '${url:-<none>}'" >&2
    return 1
  fi

  printf '%s\n' "$ver"
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_img

  sha_img="$(set -o pipefail; curl -fsSL "$DOWNLOAD_BASE/v$ver/AnkerLauncher-$ver-x86_64.AppImage" \
    | sha256sum | cut -d' ' -f1)" || return 1

  sed -i "s|^sha256sums=.*|sha256sums=('$sha_img')|" "$pkgbuild"
}
