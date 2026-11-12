# kdeglance - KDEGlance (https://github.com/AlexGraveler/KDEGlance), a Quick
# Look-style file preview for KDE Plasma and Dolphin (C++/Qt6, KF6).
#
# Source package: builds the tag archive like upstream's own
# packaging/arch/PKGBUILD, but without the tests. refresh_checksums() fails
# when that file's depends or makedepends no longer match ours. Upstream's
# source tarball asset is not used: it holds the same code, but 2.0.4 shipped
# without one (only Fedora RPMs).
#
# Upstream replaces releases in place (2.0.1 got a new tag twice). CI only
# refreshes the checksums for a new version, so latest_version() also compares
# the current version's tag archive with the PKGBUILD. When it changed, it
# refreshes, and CI bumps pkgrel.

UPSTREAM_REPO="AlexGraveler/KDEGlance"

# Installed in CI (pacman) before the makepkg test build: the makedepends plus
# the libraries the build links against.
BUILD_DEPS=(cmake ninja pkgconf qt6-base qt6-multimedia qt6-5compat qt6-svg
            kio kservice kcoreaddons kwindowsystem poppler-qt6 libraw)

# tarball_sha <version>: the sha256 of the tag archive
tarball_sha() {
  (set -o pipefail; curl -fsSL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$1.tar.gz" \
    | sha256sum | cut -d' ' -f1)
}

latest_version() {
  local ver pkgbuild sha
  ver="$(gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//')"
  pkgbuild="$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
  if [[ "$ver" == "$(grep -Po '^pkgver=\K.*' "$pkgbuild")" ]]; then
    sha="$(tarball_sha "$ver")" || return 1
    if ! grep -q "'$sha'" "$pkgbuild"; then
      refresh_checksums "$ver" "$pkgbuild" >&2 || return 1
    fi
  fi
  echo "$ver"
}

# pkgbuild_array <name>: the words of one array in a PKGBUILD on stdin, sorted
# and without version constraints
pkgbuild_array() {
  awk -v n="$1" '$0 ~ "^" n "=\\(" { f = 1 } f { sub(/#.*/, ""); print } f && /\)/ { exit }' \
    | sed "s/^$1=(//; s/).*//" | tr -s " '\"" '\n' | sed '/^$/d; s/[<>=].*//' | sort
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local upstream name sha

  # qt6-wayland and ffmpeg are left out on purpose, see the PKGBUILD
  upstream="$(gh api "repos/$UPSTREAM_REPO/contents/packaging/arch/PKGBUILD?ref=v$ver" \
    -H 'Accept: application/vnd.github.raw')" || return 1
  for name in depends makedepends; do
    if [[ "$(pkgbuild_array "$name" <<< "$upstream" | grep -vxE 'qt6-wayland|ffmpeg')" \
          != "$(pkgbuild_array "$name" < "$pkgbuild")" ]]; then
      echo "upstream's $name changed in v$ver, update the PKGBUILD (and BUILD_DEPS):" >&2
      pkgbuild_array "$name" <<< "$upstream" >&2
      return 1
    fi
  done

  sha="$(tarball_sha "$ver")" || return 1
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
