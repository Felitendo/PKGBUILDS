# sharpemu-bin - SharpEmu (https://github.com/sharpemu/sharpemu), an
# experimental PlayStation 5 emulator written in C#.
#
# Upstream publishes prebuilt linux-x64 release assets itself, so there is no
# build_artifact() here: on a new version only pkgver and the checksums are
# refreshed and the result is pushed to the AUR.
#
# Upstream versions contain hyphens (v0.0.2-beta.4), which an Arch pkgver
# must not; latest_version therefore reports the underscored form
# (0.0.2_beta.4) and the PKGBUILD derives the upstream form back via _upver.

UPSTREAM_REPO="sharpemu/sharpemu"

latest_version() {
  # gh instead of plain curl: authenticated API calls, so shared-IP rate
  # limits on the CI runners can't bite.
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' \
    | sed -e 's/^v//' -e 's/-/_/g'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local upver="${ver//_/-}" sha
  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$upver/sharpemu-$upver-linux-x64.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sed -i "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha')|" "$pkgbuild"
}
