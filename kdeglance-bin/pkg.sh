# kdeglance-bin - KDEGlance (https://github.com/AlexGraveler/KDEGlance), a
# Quick Look-style file preview for KDE Plasma and Dolphin (C++/Qt6, KF6).
#
# Upstream attaches a pacman package to each release, built on CachyOS from
# its own packaging/arch/PKGBUILD. This PKGBUILD repackages it. The viewer is
# built for x86-64-v3 (its ELF note says so), which prepare() checks.
#
# The asset name carries upstream's pkgrel
# (kdeglance-<version>-<release>-x86_64.pkg.tar.zst), which is synced into
# _relver. refresh_checksums() reads the package's .PKGINFO: it syncs the Qt
# minimum and fails when the other depends no longer match ours.
#
# Upstream replaces the assets of a release in place (2.0.1 got a new package
# twice). CI only refreshes the checksums for a new version, so
# latest_version() also compares the current version's asset with the
# PKGBUILD. When it changed, it refreshes, and CI bumps pkgrel.

UPSTREAM_REPO="AlexGraveler/KDEGlance"

# pkg_asset <version>: "<name> <sha256>" of the release's newest pacman package
pkg_asset() {
  gh api "repos/$UPSTREAM_REPO/releases/tags/v$1" \
    --jq '.assets[] | "\(.name) \(.digest)"' \
    | sed -n "s/^\(kdeglance-$1-[0-9]*-x86_64\.pkg\.tar\.zst\) sha256:/\1 /p" \
    | sort -V | tail -n1
}

latest_version() {
  local ver pkgbuild
  ver="$(gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//')"
  pkgbuild="$(dirname "${BASH_SOURCE[0]}")/PKGBUILD"
  if [[ "$ver" == "$(grep -Po '^pkgver=\K.*' "$pkgbuild")" ]] &&
     ! grep -q "'$(pkg_asset "$ver" | cut -d' ' -f2)'" "$pkgbuild"; then
    refresh_checksums "$ver" "$pkgbuild" >&2 || return 1
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
  local asset name sha relver pkginfo qt

  asset="$(pkg_asset "$ver")"
  name="${asset% *}" sha="${asset#* }"
  relver="$(sed -n "s/^kdeglance-$ver-\([0-9]*\)-x86_64\.pkg\.tar\.zst$/\1/p" <<< "$name")"
  if [[ -z "$relver" || ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no kdeglance-$ver-<release>-x86_64.pkg.tar.zst with a sha256" >&2
    return 1
  fi

  # qt6-wayland and ffmpeg are left out on purpose, see the PKGBUILD
  pkginfo="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/$name" \
    | bsdtar -xOf - .PKGINFO)" || return 1
  qt="$(sed -n 's/^depend = qt6-base>=//p' <<< "$pkginfo")"
  if [[ -z "$qt" || "$(sed -n 's/^depend = //p' <<< "$pkginfo" | sed 's/[<>=].*//' \
          | grep -vxE 'qt6-wayland|ffmpeg' | sort)" != "$(pkgbuild_array depends < "$pkgbuild")" ]]; then
    echo "the depends of $name changed, update the PKGBUILD:" >&2
    sed -n 's/^depend = //p' <<< "$pkginfo" >&2
    return 1
  fi

  sed -i \
    -e "s|^_relver=.*|_relver=$relver|" \
    -e "s|'qt6-base>=[^']*'|'qt6-base>=$qt'|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
