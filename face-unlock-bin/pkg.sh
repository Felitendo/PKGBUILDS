# face-unlock-bin - the Arch build of face-unlock
# (https://git.felo.gg/LoonixTools/face-unlock), made by upstream's release
# workflow: the same program as the face-unlock package, with OpenCV linked in
# statically, so an OpenCV update on Arch does not break it.
#
# Not every release has the tarball (2.0.0 and older do not), so the newest
# release that has it is tracked, not /releases/latest. Gitea keeps no digest
# for release assets, so the checksum comes from downloading the tarball.

UPSTREAM_REPO="LoonixTools/face-unlock"

# newest published release with an Arch tarball, as its tag
latest_tag() {
  curl -sf "https://git.felo.gg/api/v1/repos/$UPSTREAM_REPO/releases?limit=30" \
    | jq -r '[.[] | select((.draft or .prerelease) | not)
                  | select(any(.assets[]; .name | endswith("-arch-x86_64.tar.zst")))]
             | first | .tag_name // empty'
}

# Kept off the AUR until a release has the tarball: until then the PKGBUILD
# has nothing to point at. The run that finds the first one updates the
# PKGBUILD and test-builds it before anything is pushed.
AUR_PUBLISH=false
if [[ -n "$(latest_tag)" ]]; then
  AUR_PUBLISH=true
fi

latest_version() {
  local tag
  tag="$(latest_tag)"
  [[ -n "$tag" ]] || return 75
  echo "${tag#v}"
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local name="face-unlock-$ver-arch-x86_64.tar.zst" sha

  sha="$(curl -sfL "https://git.felo.gg/$UPSTREAM_REPO/releases/download/v$ver/$name" \
    | sha256sum | cut -d' ' -f1)"

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
