# face-unlock - Face ID for Linux: Plasma, GNOME, Hyprland and Niri
# (https://github.com/LoonixTools/face-unlock). Called plasma-face-unlock
# before 2.0.0.
#
# Rust since 3.0.0. Built from the release tarball with the upstream Makefile.
# The two face networks are sources of their own from the OpenCV model zoo
# with fixed checksums, so a release only changes the tarball's.

UPSTREAM_REPO="LoonixTools/face-unlock"

# Installed in CI (pacman) before the makepkg test build, which skips the
# dependency check: the makedepends plus the libraries the build links
# against. check() runs the upstream tests and needs nothing more.
BUILD_DEPS=(rust scdoc pam libxkbcommon wayland)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL \
    "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  # Only the first sum is the tarball's; the models' stay.
  sed -i -E "s|^sha256sums=\('[^']*'|sha256sums=('$sha'|" "$pkgbuild"
}
