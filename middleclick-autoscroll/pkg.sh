# middleclick-autoscroll - middle-click autoscroll for Chromium-based
# applications (https://git.felo.gg/LoonixTools/middleclick-autoscroll).
#
# Pure shell plus a gettext catalog and a scdoc man page, so the PKGBUILD just
# runs the upstream Makefile against the release tarball. Nothing is prebuilt
# and nothing is republished - the AUR package builds exactly what the tag
# contains.

UPSTREAM_REPO="LoonixTools/middleclick-autoscroll"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(gettext scdoc)

latest_version() {
  # the highest vX.Y.Z tag; not every release has a release page
  curl -sf "https://git.felo.gg/api/v1/repos/$UPSTREAM_REPO/tags?limit=50" \
    | jq -r '.[].name | select(test("^v[0-9]+(\\.[0-9]+)*$"))' \
    | sed 's/^v//' | sort -V | tail -n 1
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha

  sha="$(curl -sfL "https://git.felo.gg/$UPSTREAM_REPO/archive/v$ver.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
