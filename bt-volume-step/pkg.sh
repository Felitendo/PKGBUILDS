# bt-volume-step - fixed volume steps for Bluetooth audio devices on PipeWire
# (https://github.com/Felitendo/bt-volume-step).
#
# Nothing is compiled: the payload is a single Python script plus a systemd
# user unit, installed by the upstream Makefile. Sourced from the release
# tarball, so this is a source package without a -bin suffix.

UPSTREAM_REPO="Felitendo/bt-volume-step"

# Installed in CI (pacman) before the makepkg test build. check() runs the
# upstream test suite, which needs nothing beyond python.
BUILD_DEPS=(python)

latest_version() {
  curl -sf "https://api.github.com/repos/$UPSTREAM_REPO/releases/latest" \
    | jq -r '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL \
    "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
