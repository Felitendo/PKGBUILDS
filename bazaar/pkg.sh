# bazaar - GNOME app store focused on flatpaks/Flathub
# (https://github.com/bazaar-org/bazaar), C + GTK4/blueprint.
#
# Upstream tags releases but publishes no binaries, so this is a source
# package: the PKGBUILD builds the meson project from the release tarball.

UPSTREAM_REPO="bazaar-org/bazaar"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(meson ninja blueprint-compiler glib2-devel python-babel gettext
            gobject-introspection appstream flatpak gtk4 libadwaita
            gtksourceview5 libdex glycin glycin-gtk4 webkitgtk-6.0 json-glib
            libxmlb libyaml md4c libmalcontent libsecret libsoup3 libproxy
            libheif)

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
