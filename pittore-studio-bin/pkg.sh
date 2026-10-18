# pittore-studio-bin - Pittore Studio
# (https://github.com/Event-Horizon-desktop-environment/pittore-studio), a
# layer-based photo editor for Linux in C++20 on Qt 6.
#
# Upstream's CI builds the Linux release itself and publishes a .pkg.tar.zst
# built in an Arch container from its own packaging/arch/PKGBUILD, which this
# PKGBUILD repackages. GitHub lists the asset's sha256, so a new version needs
# no download.
#
# The asset name carries upstream's package release
# (pittore-studio-<version>-<release>-x86_64.pkg.tar.zst), which is synced
# into _relver. The binary needs the same libraries as the source package, so
# the dependencies are checked against upstream's PKGBUILD of the same tag: a
# missing one would not break the test build, only the app.
#
# Upstream's meson install step ships no license text, so the MIT text comes
# from the matching tag as a second source.

UPSTREAM_REPO="Event-Horizon-desktop-environment/pittore-studio"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# pkgbuild_array <name>: the words of one array in a PKGBUILD on stdin, sorted
pkgbuild_array() {
  awk -v n="$1" '$0 ~ "^" n "=\\(" { f = 1 } f { sub(/#.*/, ""); print } f && /\)/ { exit }' \
    | sed "s/^$1=(//; s/).*//" | tr -s " '\"" '\n' | sed '/^$/d' | sort
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local upstream assets relver sha_pkg sha_lic

  upstream="$(gh api "repos/$UPSTREAM_REPO/contents/packaging/arch/PKGBUILD?ref=v$ver" \
    -H 'Accept: application/vnd.github.raw')" || return 1
  if [[ "$(pkgbuild_array depends <<< "$upstream")" != "$(pkgbuild_array depends < "$pkgbuild")" ]]; then
    echo "upstream's depends changed in v$ver, update the PKGBUILD:" >&2
    pkgbuild_array depends <<< "$upstream" >&2
    return 1
  fi

  # "<name> sha256:<hex>" per pacman package of the release, minus the
  # separate debug package
  assets="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq '.assets[] | select(.name | endswith(".pkg.tar.zst")) | "\(.name) \(.digest)"')"
  relver="$(sed -n "s/^pittore-studio-$ver-\([0-9]*\)-x86_64\.pkg\.tar\.zst .*/\1/p" <<< "$assets" \
    | sort -n | tail -n1)"
  sha_pkg="$(awk -v f="pittore-studio-$ver-$relver-x86_64.pkg.tar.zst" \
    '$1 == f { sub(/^sha256:/, "", $2); print $2 }' <<< "$assets")"
  if [[ ! "$sha_pkg" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no pittore-studio-$ver-$relver-x86_64.pkg.tar.zst with a sha256" >&2
    return 1
  fi

  sha_lic="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/LICENSE" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_relver=.*|_relver=$relver|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_pkg' '$sha_lic')|" \
    "$pkgbuild"
}
