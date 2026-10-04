# bt-volume-step - fixed volume steps for Bluetooth audio devices on PipeWire
# (https://git.felo.gg/LoonixTools/bt-volume-step).
#
# Nothing is compiled: the payload is a single Python script plus a systemd
# user unit, installed by the upstream Makefile. Sourced from the release
# tarball, so this is a source package without a -bin suffix.

UPSTREAM_REPO="LoonixTools/bt-volume-step"

# Installed in CI (pacman) before the makepkg test build. check() runs the
# upstream test suite, which needs nothing beyond python.
BUILD_DEPS=(python)

latest_version() {
  # the highest vX.Y.Z tag; not every release has a release page
  curl -sf "https://git.felo.gg/api/v1/repos/$UPSTREAM_REPO/tags?limit=50" \
    | jq -r '.[].name | select(test("^v[0-9]+(\\.[0-9]+)*$"))' \
    | sed 's/^v//' | sort -V | tail -n 1
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL \
    "https://git.felo.gg/$UPSTREAM_REPO/archive/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
