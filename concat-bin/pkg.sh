# concat-bin - Concat (https://github.com/jub0t/Concat), a free and
# open-source CapCut replacement: a Tauri 2 shell around a Rust video engine.
#
# Upstream publishes a Linux .deb per release, so there is no build step
# here: on a new version only pkgver, the asset name and the checksums are
# refreshed and the PKGBUILD repackages the .deb.
#
# The project has no stable release yet. Its build workflow publishes a
# "v<version>-alpha.<n>" prerelease for every green push to main, so /latest
# is empty and every tag is a prerelease - the alphas are what there is to
# package. They arrive several times a day, which is also how often this
# package can move.
#
# The release list is not ordered by version: GitHub sorts it by creation
# time, and upstream's alpha numbering has already run out of step with it
# (v0.2.0-alpha.10 sits between alpha.2 and alpha.1). The newest release is
# therefore picked by publication date rather than by list position.
#
# The asset name carries tauri.conf.json's version, not the tag - every alpha
# of 0.2.0 ships WolfCut_0.2.0_amd64.deb - so it cannot be derived from
# pkgver and is resolved through the API into the _asset variable.
#
# pkgver drops the hyphens from the tag (v0.2.0-alpha.15 -> 0.2.0alpha.15).
# pacman sorts that older than a later plain 0.2.0 (`vercmp 0.2.0alpha.15
# 0.2.0` is -1), so the prereleases upgrade to the eventual stable release on
# their own and no epoch is needed.

# Not on the AUR yet. concat-git goes up first; these two follow once the
# alpha-per-push release cadence has been lived with for a while - upstream
# publishes several a day, and each one is an AUR push (and, for concat, a
# full Rust build in CI). Flip this to true to publish; until then the
# PKGBUILD is still kept current and test-built here.
AUR_PUBLISH=false

UPSTREAM_REPO="jub0t/Concat"

# newest published release whose tag looks like a version
latest_tag() {
  gh api "repos/$UPSTREAM_REPO/releases?per_page=100" \
    --jq '[.[] | select(.draft | not) | select(.tag_name | test("^v[0-9]"))]
          | sort_by(.published_at) | last | .tag_name'
}

tag_to_pkgver() {
  sed 's/^v//; s/-//g'
}

latest_version() {
  latest_tag | tag_to_pkgver
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag asset sha_deb sha_license

  tag="$(latest_tag)"
  if [[ "$(tag_to_pkgver <<< "$tag")" != "$ver" ]]; then
    echo "newest versioned release is $tag, not the requested $ver - try again" >&2
    return 1
  fi

  # e.g. WolfCut_0.2.0_amd64.deb - the version is tauri.conf.json's, not the tag's
  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" --jq '.assets[].name' \
    | grep -E '_amd64\.deb$')"
  [[ "$(wc -l <<< "$asset")" -eq 1 ]] || { echo "expected exactly one amd64 .deb, got: $asset" >&2; return 1; }

  sha_deb="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$tag/$asset" \
    | sha256sum | cut -d' ' -f1)"
  # the .deb ships no copyright file, so the license comes from the tag
  sha_license="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/$tag/LICENSE" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_asset=.*|_asset=\"$asset\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_deb' '$sha_license')|" \
    "$pkgbuild"
}
