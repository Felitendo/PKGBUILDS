# tenzen-studio-bin - Tenzen Studio (https://tenzen.studio), a proprietary
# Electron app for recording and editing product demos.
#
# Upstream publishes no source, so there is only this -bin package. For Linux
# it ships nothing but a Flatpak bundle, versioned on its own download host:
# the PKGBUILD unpacks that with ostree (a Flatpak bundle is an OSTree static
# delta) and takes the icon out of app.asar, so the test build needs both.
#
# The release API names the current version and lists every artifact with its
# sha256, so nothing has to be downloaded to refresh the checksum - makepkg's
# test build verifies it against the real download anyway.

API="https://tenzen.studio/api/v1/desktop/releases/latest?channel=stable"

BUILD_DEPS=(ostree asar)

latest_version() {
  curl -sf "$API" | jq -r '.release.version'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2" sha

  sha="$(curl -sf "$API" | jq -r --arg f "Tenzen-$ver-linux-x64.flatpak" \
    '.release.artifacts[] | select(.file_name == $f) | .sha256')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "the release API lists no Tenzen-$ver-linux-x64.flatpak" >&2
    return 1
  fi

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
