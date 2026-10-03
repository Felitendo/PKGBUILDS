# moonlight-vrr-bin - Nonary's fork of Moonlight (https://github.com/Nonary/moonlight-qt),
# the GameStream client for PCs, with smooth VRR frame pacing (C++ + Qt6).
#
# Upstream publishes an AppImage per release, which the PKGBUILD unpacks and
# installs into /opt, so there is no build step here. GitHub lists each
# asset's sha256, so a new version needs no download. Upstream builds the
# AppImage without Wayland support, it runs through XWayland.
#
# Version handling is the same as in moonlight-vrr: tags look like
# v6.1.0-vrr18, pkgver has an underscore for the hyphen, and /releases/latest
# skips the betas.

UPSTREAM_REPO="Nonary/moonlight-qt"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' \
    | sed -e 's/^v//' -e 's/-/_/g'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local upver="${ver//_/-}" sha

  sha="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$upver" \
    --jq ".assets[] | select(.name == \"Moonlight-$upver-x86_64.AppImage\") | .digest" \
    | sed 's/^sha256://')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$upver has no Moonlight-$upver-x86_64.AppImage with a sha256" >&2
    return 1
  fi

  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
