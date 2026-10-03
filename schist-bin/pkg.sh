# schist-bin - Schist (https://github.com/Infrawrench/schist), a layered image
# editor in Rust (gpui) with PSD and Affinity support.
#
# Upstream builds the Linux release itself and publishes a .pkg.tar.zst per
# architecture, which the PKGBUILD repackages, as upstream's own
# packaging/linux/aur/schist-bin does. GitHub lists each asset's sha256, so a
# new version needs no download.
#
# The asset name carries upstream's package release
# (schist-<version>-<release>-<arch>.pkg.tar.zst), which is synced into
# _relver. The binary needs the same libraries as the source package, so the
# dependencies are checked against upstream's source PKGBUILD of the same tag:
# a missing one would not break the test build, only the app.

UPSTREAM_REPO="Infrawrench/schist"

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
  local upstream assets relver arch sha sha_x86_64 sha_aarch64

  upstream="$(gh api "repos/$UPSTREAM_REPO/contents/packaging/linux/aur/schist/PKGBUILD?ref=v$ver" \
    -H 'Accept: application/vnd.github.raw')" || return 1
  if [[ "$(pkgbuild_array depends <<< "$upstream")" != "$(pkgbuild_array depends < "$pkgbuild")" ]]; then
    echo "upstream's depends changed in v$ver, update the PKGBUILD:" >&2
    pkgbuild_array depends <<< "$upstream" >&2
    return 1
  fi

  # "<name> sha256:<hex>" per pacman package of the release
  assets="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq '.assets[] | select(.name | endswith(".pkg.tar.zst")) | "\(.name) \(.digest)"')"
  relver="$(sed -n "s/^schist-$ver-\([0-9]*\)-x86_64\.pkg\.tar\.zst .*/\1/p" <<< "$assets" \
    | sort -n | tail -n1)"

  for arch in x86_64 aarch64; do
    sha="$(awk -v f="schist-$ver-$relver-$arch.pkg.tar.zst" \
      '$1 == f { sub(/^sha256:/, "", $2); print $2 }' <<< "$assets")"
    if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
      echo "v$ver has no schist-$ver-$relver-$arch.pkg.tar.zst with a sha256" >&2
      return 1
    fi
    printf -v "sha_$arch" '%s' "$sha"
  done

  sed -i \
    -e "s|^_relver=.*|_relver=$relver|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x86_64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_aarch64')|" \
    "$pkgbuild"
}
