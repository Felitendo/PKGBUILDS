# concat-bin - Concat (https://github.com/jub0t/Concat), a free and
# open-source CapCut replacement.
#
# Upstream publishes a self-contained Linux tarball per release, so there is
# no build step here: on a new version only pkgver, the asset name and the
# checksum are refreshed and the PKGBUILD repackages the tarball.
#
# 0.2.1 is the first release of the rewrite: the Tauri shell and its .deb are
# gone, and the app is now one Rust binary (Slint over the engine crates)
# shipped as Concat-<version>-linux-<arch>.tar.gz. The tag is what changed
# least - see below.
#
# The release list is not ordered by version: GitHub sorts it by creation
# time, and upstream's alpha numbering has run out of step with it before
# (v0.2.0-alpha.10 sat between alpha.2 and alpha.1). The newest release is
# therefore picked by publication date rather than by list position. Only
# tags that start with a version are considered, which is also what keeps the
# rolling "nightly" prerelease out.
#
# The asset name carries the workspace's version, not the tag - a prerelease
# of 0.2.2 ships Concat-0.2.2-linux-x86_64.tar.gz whatever its tag says - so
# it cannot be derived from pkgver and is resolved through the API into the
# _asset variable.
#
# pkgver drops the hyphens from the tag (v0.2.2-alpha.1 -> 0.2.2alpha.1).
# pacman sorts that older than a later plain 0.2.2 (`vercmp 0.2.2alpha.1
# 0.2.2` is -1), so prereleases upgrade to the eventual release on their own
# and no epoch is needed.

# Not on the AUR yet. concat-git goes up first; these two follow once the
# release cadence has been lived with for a while - upstream published
# several alphas a day before 0.2.1, and each one is an AUR push (and, for
# concat, a full Rust build in CI). Flip this to true to publish; until then
# the PKGBUILD is still kept current and test-built here.
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
  local tag asset sha

  tag="$(latest_tag)"
  if [[ "$(tag_to_pkgver <<< "$tag")" != "$ver" ]]; then
    echo "newest versioned release is $tag, not the requested $ver - try again" >&2
    return 1
  fi

  # e.g. Concat-0.2.1-linux-x86_64.tar.gz - the version is the workspace's,
  # not the tag's
  # `|| true`, so that a release that stops carrying the asset says so here
  # instead of ending the run on grep's exit status with nothing printed.
  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" --jq '.assets[].name' \
    | grep -E '^Concat-.*-linux-x86_64\.tar\.gz$' || true)"
  if [[ -z "$asset" || "$(wc -l <<< "$asset")" -ne 1 ]]; then
    echo "expected exactly one linux-x86_64 tarball in $tag, got: ${asset:-none}" >&2
    return 1
  fi

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$tag/$asset" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_asset=.*|_asset=\"$asset\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
