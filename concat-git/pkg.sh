# concat-git - Concat (https://github.com/jub0t/Concat) built from the main
# branch. Same build as concat, see that package for why the editor needs
# cargo, cmake and clang and nothing else, and why the FemtoVG-over-wgpu
# renderer is the one a distribution package can build.
#
# The one difference: concat pins the prebuilt sherpa-onnx static-lib archive
# as a checksummed source, which it can because the version comes from a
# tagged Cargo.lock. Here it moves with main, so sherpa-onnx-sys' build
# script downloads it and build() needs the network.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. Following main here would mean AUR pushes
# that change nothing for anyone. latest_version() therefore reports the
# pkgver that is already in the PKGBUILD, which makes the update run a no-op:
# the package is rebuilt, re-checked and pushed only when the packaging
# itself changes.
#
# When that happens, makepkg refreshes the pkgver snapshot in the PKGBUILD as
# part of the test build, so the committed snapshot follows along by itself.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(rust cmake clang pkgconf git ffmpeg alsa-lib fontconfig freetype2)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
