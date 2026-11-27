# skykeep-bin - Skykeep (https://github.com/YashwanthKamireddi/Skykeep), native
# iCloud apps for Linux (Rust, Tauri). Upstream publishes a .deb per release,
# which the PKGBUILD repackages. Installed from a .deb, the app leaves updates
# to the package manager, so nothing needs patching.
#
# GitHub lists each asset's sha256, so the .deb needs no download here.
# refresh_checksums() fails when the depends of upstream's own Arch package
# change, so a new run-time need is not missed.

UPSTREAM_REPO="YashwanthKamireddi/Skykeep"

# depends of upstream's packaging/arch/PKGBUILD, sorted
UPSTREAM_DEPENDS="gst-libav gst-plugins-base gst-plugins-base-libs gst-plugins-good gstreamer gtk3 libheif libsecret webkit2gtk-4.1"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local deps sha

  deps="$(gh api "repos/$UPSTREAM_REPO/contents/packaging/arch/PKGBUILD?ref=v$ver" \
      -H 'Accept: application/vnd.github.raw' \
    | awk '/^depends=\(/ { f = 1 } f { sub(/#.*/, ""); print } f && /\)/ { exit }' \
    | sed 's/^depends=(//; s/).*//' | tr -s " '\"" '\n' | sed '/^$/d' | sort | xargs)"
  if [[ "$deps" != "$UPSTREAM_DEPENDS" ]]; then
    echo "upstream's depends changed in v$ver, check the PKGBUILD: $deps" >&2
    return 1
  fi

  sha="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq ".assets[] | select(.name == \"Skykeep_${ver}_amd64.deb\") | .digest // empty" \
    | sed 's/^sha256://')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no Skykeep_${ver}_amd64.deb with a sha256 digest" >&2
    return 1
  fi
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
