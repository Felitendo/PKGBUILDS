# waypointer-bin - the Arch build of Waypointer
# (https://github.com/Felitendo/waypointer), made by upstream's release
# workflow: the same program as the waypointer package, without compiling Rune.
#
# Not every release has the tarball (0.1.0 does not), so the newest release
# that has it is tracked, not /releases/latest. The checksum is the digest
# GitHub keeps for every release asset.

UPSTREAM_REPO="Felitendo/waypointer"

# newest published release with an Arch tarball, as its tag
latest_tag() {
  gh api "repos/$UPSTREAM_REPO/releases?per_page=30" \
    --jq '[.[] | select((.draft or .prerelease) | not)
               | select(any(.assets[]; .name | endswith("-arch-x86_64.tar.zst")))]
          | first | .tag_name // empty'
}

latest_version() {
  local tag
  tag="$(latest_tag)"
  [[ -n "$tag" ]] || return 75
  echo "${tag#v}"
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local name="waypointer-$ver-arch-x86_64.tar.zst" sha

  sha="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq ".assets[] | select(.name == \"$name\") | .digest // empty" \
    | sed -n 's/^sha256://p')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/$name" \
      | sha256sum | cut -d' ' -f1)"
  fi

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
