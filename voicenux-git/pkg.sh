# voicenux-git - Voicenux (https://github.com/voicenux/voicenux) built from
# the main branch. Same cargo build and `make install` as voicenux.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. latest_version() therefore reports the
# pkgver that is already in the PKGBUILD, which makes the update run a no-op:
# the package is rebuilt, re-checked and pushed only when the packaging itself
# changes. makepkg then refreshes the pkgver snapshot as part of the test build.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(rust clang git gtk4 libadwaita pipewire)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
