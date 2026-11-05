# lichii-bin - Lichii (https://github.com/zortos293/Lichii), an experimental
# Nintendo Switch and Switch 2 emulator, forked from Eglantine and Eden (C++ + Qt6).
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt, so there is no build step here. GitHub lists each
# asset's sha256, so a new version needs no download. The tar.gz next to the
# AppImage is no option: it links Ubuntu's FFmpeg 6, and Arch is on 9.
#
# Every release is a prerelease tagged build-N, N being upstream's CI run
# number, so /releases/latest finds nothing and pkgver is N. The oldest
# releases used other tags (nx2-build-34) and are skipped.

UPSTREAM_REPO="zortos293/Lichii"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases?per_page=100" \
    --jq '[.[] | select(.draft | not) | .tag_name | select(test("^build-[0-9]+$"))
           | ltrimstr("build-") | tonumber] | max'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local release arch sha sha_x86_64 sha_aarch64

  release="$(gh api "repos/$UPSTREAM_REPO/releases/tags/build-$ver")"
  for arch in x86_64 aarch64; do
    sha="$(jq -r --arg n "lichii-linux-$arch-pgo.AppImage" \
      '.assets[] | select(.name == $n) | .digest' <<< "$release" | sed 's/^sha256://')"
    if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
      echo "build-$ver has no lichii-linux-$arch-pgo.AppImage with a sha256" >&2
      return 1
    fi
    printf -v "sha_$arch" '%s' "$sha"
  done

  sed -i \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x86_64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_aarch64')|" \
    "$pkgbuild"
}
