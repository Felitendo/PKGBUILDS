# face-unlock - Face ID for Linux: Plasma, GNOME, Hyprland and Niri
# (https://git.felo.gg/LoonixTools/face-unlock). Called plasma-face-unlock
# before 2.0.0.
#
# Built from the release tarball with the upstream Makefile (CMake for the
# daemon, the agent and the PAM module). The two face networks are sources of
# their own from the OpenCV model zoo with fixed checksums, so a release only
# changes the tarball's.

UPSTREAM_REPO="LoonixTools/face-unlock"

# Installed in CI (pacman) before the makepkg test build, which skips the
# dependency check. check() runs the upstream tests and needs nothing more.
BUILD_DEPS=(cmake scdoc gettext opencv qt6-base qt6-declarative layer-shell-qt ki18n pam systemd-libs)

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
  # Only the first sum is the tarball's; the models' stay.
  sed -i -E "s|^sha256sums=\('[^']*'|sha256sums=('$sha'|" "$pkgbuild"
}
