# filee-git - Filee (https://github.com/KnifeLemon/Filee) built from the main
# branch. An offline file converter (C#/.NET, Avalonia).
#
# Upstream builds its Linux tarball with PowerShell scripts, and PowerShell is
# not in the Arch repos. The PKGBUILD does the same steps in bash: it reads the
# pinned font list from build/fetch-fonts.ps1, publishes the app and the CLI
# against Arch's .NET runtime, builds rhwp from the commit upstream pins and
# links Arch's 7-Zip in place of the bundled one.
#
# VCS packages are not version-tracked here on purpose. The AUR copy of a -git
# PKGBUILD carries only a snapshot of pkgver; the real version comes from
# pkgver() when the user builds it. latest_version() therefore reports the
# pkgver that is already in the PKGBUILD, which makes the update run a no-op:
# the package is rebuilt, re-checked and pushed only when the packaging itself
# changes.
#
# When that happens, makepkg refreshes the pkgver snapshot in the PKGBUILD as
# part of the test build, so the committed snapshot follows along by itself.

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(dotnet-sdk-10.0 rust git python)

latest_version() {
  grep -Po '^pkgver=\K.*' "$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
}

# refresh_checksums <version> <pkgbuild-path>
# Unreachable: latest_version() never reports a version other than the current
# one. The git source carries SKIP checksums, so there would be nothing to do.
refresh_checksums() {
  :
}
