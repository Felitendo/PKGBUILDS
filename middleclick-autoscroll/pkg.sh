# middleclick-autoscroll - middle-click autoscroll for Chromium-based
# applications (https://github.com/Felitendo/middleclick-autoscroll).
#
# Pure shell plus a gettext catalog and a scdoc man page, so the PKGBUILD just
# runs the upstream Makefile against the release tarball. Nothing is prebuilt
# and nothing is republished - the AUR package builds exactly what the tag
# contains.

UPSTREAM_REPO="Felitendo/middleclick-autoscroll"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(gettext scdoc)

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
