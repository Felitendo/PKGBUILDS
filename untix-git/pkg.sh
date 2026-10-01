# untix-git - "Timetable" (https://codeberg.org/ostfriese4/untis) built
# from the main branch. Same meson build as untix.
#
# There is no untix-bin: upstream publishes no binary release assets, and
# the app is pure Python anyway, so there would be nothing prebuilt to ship.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. latest_version() therefore reports the
# pkgver that is already in the PKGBUILD, which makes the update run a no-op:
# the package is rebuilt, re-checked and pushed only when the packaging itself
# changes. makepkg then refreshes the pkgver snapshot as part of the test build.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(meson ninja glib2 glib2-devel gtk4 libadwaita python
            python-gobject gettext git)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
