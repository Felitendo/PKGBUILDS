# euro-office-bin - Euro-Office Desktop Editors
# (https://github.com/Euro-Office/DesktopEditors), the European fork of the
# ONLYOFFICE Desktop Editors.
#
# Upstream builds the Linux release itself and publishes a .deb, an .rpm and a
# tarball per release, each for x86_64 and aarch64. The PKGBUILD repackages
# the .deb, so there is no build step here.
#
# There is no source package next to this one: upstream builds Linux only
# inside Docker (vcpkg, Qt from aqtinstall, CEF, a WASM toolchain for the
# editors), which neither makepkg nor the CI runner can do.
# euro-office-desktopeditors-git on the AUR runs that Docker build.
#
# Stable tags are v<version>-<build> (v9.3.5-2); betas and release candidates
# are prereleases, so /releases/latest only ever sees stable ones. pkgver
# turns the hyphen into an underscore (9.3.5_2). The release API lists a
# sha256 digest per asset, so a new version needs no download here; the CI
# test build checks the sums against the real files anyway.

UPSTREAM_REPO="Euro-Office/DesktopEditors"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' \
    | sed 's/^v//; s/-/_/'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag assets arch sha sha_amd64 sha_arm64

  tag="v${ver/_/-}"
  if ! assets="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" --jq '.assets')"; then
    echo "there is no release $tag" >&2
    return 1
  fi

  # the names are checked against what the PKGBUILD builds from pkgver, so a
  # release that renames its packages fails here and not in the test build
  for arch in amd64 arm64; do
    sha="$(jq -r --arg n "euro-office-euro-office_${ver/_/-}_$arch.deb" \
      '.[] | select(.name == $n) | .digest // empty' <<< "$assets" \
      | sed 's/^sha256://')"
    if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
      echo "$tag has no euro-office-euro-office_${ver/_/-}_$arch.deb with a sha256 digest" >&2
      return 1
    fi
    printf -v "sha_$arch" '%s' "$sha"
  done

  sed -i \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_amd64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_arm64')|" \
    "$pkgbuild"
}
