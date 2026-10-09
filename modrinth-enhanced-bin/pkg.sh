# modrinth-enhanced-bin - Modrinth Enhanced (https://github.com/Felitendo/Modrinth-Enhanced),
# the Modrinth App (Tauri) with a series of patches applied: no ads, no
# telemetry, offline and Ely.by accounts, Linux fixes.
#
# Upstream publishes a bundled .deb per release, so the app is not built here:
# on a new version only pkgver, the tag, the asset name and the checksums are
# refreshed and the PKGBUILD repackages the deb directly. The only thing built
# is vblank-shim.c, which ships with this package (see the PKGBUILD).
#
# Releases are tagged after the Modrinth App release they are built on
# (v0.21.2). When the patches change without a new Modrinth App release, the
# rebuild is tagged as a revision (v0.21.2-2) while the app and its .deb keep
# the plain version. pkgver turns the hyphen into ".r" (0.21.2.r2), which
# pacman sorts after 0.21.2 and before 0.21.3, so no epoch is needed.
#
# Upstream's release workflow creates the release together with its assets
# only after all three platforms built, so /releases/latest never points at a
# release whose .deb is still missing.

UPSTREAM_REPO="Felitendo/Modrinth-Enhanced"

# Installed in CI before the makepkg test build, for the shim's headers.
BUILD_DEPS=(glib2 libdrm)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//; s/-/.r/'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag="v${ver/.r/-}" dir asset sha sha_shim sha_script

  dir="$(dirname "$pkgbuild")"
  sha_shim="$(sha256sum "$dir/vblank-shim.c" | cut -d' ' -f1)"
  sha_script="$(sha256sum "$dir/modrinth-enhanced.sh" | cut -d' ' -f1)"

  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" \
    --jq '.assets[].name | select(endswith("_amd64.deb"))')"
  if [[ -z "$asset" || "$asset" == *$'\n'* ]]; then
    echo "could not find exactly one amd64 .deb in release $tag" >&2
    return 1
  fi

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$tag/$asset" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_asset=.*|_asset=\"$asset\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha' '$sha_shim' '$sha_script')|" \
    "$pkgbuild"
}
