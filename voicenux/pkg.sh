# voicenux - Voicenux (https://github.com/voicenux/voicenux), a real-time
# voice changer and soundboard for PipeWire (Rust, GTK4 + libadwaita).
#
# Source package: the PKGBUILD builds the release tag with cargo and installs
# it with upstream's Makefile. voicenux-bin repackages the Arch tarball that
# upstream builds from the same tree.
#
# Upstream's release workflow creates the release only after every package is
# built, so /releases/latest never points at a half-finished release.

UPSTREAM_REPO="voicenux/voicenux"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(rust clang gtk4 libadwaita pipewire)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
