# skykeep - Skykeep (https://github.com/YashwanthKamireddi/Skykeep), native
# iCloud apps for Linux (Rust, Tauri).
#
# Source package: builds the release tag like upstream's own
# packaging/arch/PKGBUILD. A plain cargo build carries no bundle type, so the
# app leaves updates to the package manager. refresh_checksums() fails when
# the depends of that PKGBUILD change, so a new run-time need is not missed.
#
# Upstream publishes a release only after all of its builds are done, so
# /releases/latest never points at a half-finished one.

UPSTREAM_REPO="YashwanthKamireddi/Skykeep"

# Installed in CI (pacman) before the makepkg test build: the makedepends plus
# the libraries the build links against.
BUILD_DEPS=(rust nodejs npm pkgconf webkit2gtk-4.1 gtk3 libsoup3 libheif
            gstreamer gst-plugins-base-libs)

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

  sha="$(set -o pipefail; curl -fsSL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)" || return 1
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
