# nextcloud-native-git - Nextcloud Native (https://github.com/Obiente/nc-native)
# built from the main branch. Same build as nextcloud-native, see that package
# for why the Linux desktop image needs nothing but JDK 21.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. Upstream pushes several times a day, so
# following main here would mean several AUR pushes a day that change nothing
# for anyone. latest_version() therefore reports the pkgver that is already in
# the PKGBUILD, which makes the update run a no-op: the package is rebuilt,
# re-checked and pushed only when the packaging itself changes.
#
# When that happens, makepkg refreshes the pkgver snapshot in the PKGBUILD as
# part of the test build, so the committed snapshot follows along by itself.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(jdk21-openjdk python git)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
