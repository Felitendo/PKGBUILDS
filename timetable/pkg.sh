# timetable - "Timetable" (https://codeberg.org/ostfriese4/untis), a GTK4 +
# LibAdwaita WebUntis client written in Python.
#
# Upstream publishes no binary release assets, so this is a source package:
# the PKGBUILD builds the meson project from the release tarball.

UPSTREAM_REPO="ostfriese4/untis"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(meson ninja glib2 glib2-devel gtk4 libadwaita python
            python-gobject gettext)

latest_version() {
  curl -sf "https://codeberg.org/api/v1/repos/$UPSTREAM_REPO/releases/latest" \
    | jq -r '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha
  sha="$(curl -sfL "https://codeberg.org/$UPSTREAM_REPO/archive/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
