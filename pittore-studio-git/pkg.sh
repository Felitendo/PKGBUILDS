# pittore-studio-git - Pittore Studio
# (https://github.com/Event-Horizon-desktop-environment/pittore-studio) built
# from the main branch. Same build as pittore-studio, see that package for the
# meson flags and why cuda is in makedepends.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. latest_version() therefore reports the
# pkgver that is already in the PKGBUILD, which makes the update run a no-op:
# the package is rebuilt, re-checked and pushed only when the packaging itself
# changes. That matters more here than elsewhere, because every test build
# installs the CUDA toolkit and the ROCm stack.
#
# When the packaging does change, makepkg refreshes the pkgver snapshot in the
# PKGBUILD as part of the test build, so the committed snapshot follows along
# by itself.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(cuda git hip-runtime-amd meson ninja pkgconf
            qt6-base qt6-svg zlib harfbuzz freetype2 fontconfig lcms2
            libwebp libtiff libjpeg-turbo zstd qrencode tomlplusplus)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
