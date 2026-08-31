# concat-git - Concat (https://github.com/jub0t/Concat) built from the main
# branch. Same build as concat, see that package for why the Tauri binary
# needs nothing but a JS toolchain and cargo, and why WOLFCUT_SYSTEM_TOOLS=1
# is the right switch for a distribution package.
#
# The one difference: concat pins the prebuilt sherpa-onnx static-lib archive
# as a checksummed source, which it can because the version comes from a
# tagged Cargo.lock. Here it moves with main, so sherpa-onnx-sys' build
# script downloads it and build() needs the network.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. Upstream publishes an alpha release for
# every green push to main, several times a day, so following main here would
# mean several AUR pushes a day that change nothing for anyone.
# latest_version() therefore reports the pkgver that is already in the
# PKGBUILD, which makes the update run a no-op: the package is rebuilt,
# re-checked and pushed only when the packaging itself changes.
#
# When that happens, makepkg refreshes the pkgver snapshot in the PKGBUILD as
# part of the test build, so the committed snapshot follows along by itself.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(rust npm git webkit2gtk-4.1 gtk3 libsoup3 alsa-lib)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
