# concat-bin - Concat (https://github.com/jub0t/Concat), a free and
# open-source CapCut replacement.
#
# Upstream builds the Linux release itself, so there is no build step here:
# on a new version the tag, the asset version and the checksums are refreshed
# and the PKGBUILD repackages upstream's .deb.
#
# 0.2.3 replaced the self-contained tarball this package used to take with a
# .deb, an .rpm and an AppImage, each for x86_64 and aarch64. Every release
# also carries a manifest.json listing each artifact with its sha256, so a
# new version costs two API calls and no download.
#
# The release list is not ordered by version: GitHub sorts it by creation
# time, and upstream's alpha numbering has run out of step with it before
# (v0.2.0-alpha.10 sat between alpha.2 and alpha.1). The newest release is
# therefore picked by publication date rather than by list position. Only
# tags that start with a version are considered, which is also what keeps the
# rolling "nightly" prerelease out.
#
# The asset name carries the workspace's version, not the tag - a prerelease
# of 0.2.4 ships Concat-0.2.4-linux-x86_64.deb whatever its tag says - so it
# cannot be derived from pkgver and is read from the manifest into _relver.
#
# pkgver drops the hyphens from the tag (v0.2.4-alpha.1 -> 0.2.4alpha.1).
# pacman sorts that older than a later plain 0.2.4 (`vercmp 0.2.4alpha.1
# 0.2.4` is -1), so prereleases upgrade to the eventual release on their own
# and no epoch is needed.

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
  local tag manifest relver sha_x86_64 sha_aarch64 arch sha file

  tag="$(latest_tag)"
  if [[ "$(tag_to_pkgver <<< "$tag")" != "$ver" ]]; then
    echo "newest versioned release is $tag, not the requested $ver - try again" >&2
    return 1
  fi

  manifest="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$tag/manifest.json")"
  relver="$(jq -r '.version // empty' <<< "$manifest" 2>/dev/null)"
  if [[ -z "$relver" ]]; then
    echo "$tag carries no usable manifest.json" >&2
    return 1
  fi

  # Both the name and the checksum come from the manifest, and the name is
  # checked against what the PKGBUILD builds from _relver: a release that
  # renames its artifacts says so here instead of 404ing in the test build.
  for arch in x86_64 aarch64; do
    sha="$(jq -r --arg a "$arch" '.binaries.linux[$a].deb.sha256 // empty' <<< "$manifest")"
    file="$(jq -r --arg a "$arch" '.binaries.linux[$a].deb.file // empty' <<< "$manifest")"
    if [[ ! "$sha" =~ ^[0-9a-f]{64}$ || "$file" != "Concat-$relver-linux-$arch.deb" ]]; then
      echo "$tag's manifest lists no Concat-$relver-linux-$arch.deb with a sha256" \
           "(file: ${file:-none})" >&2
      return 1
    fi
    printf -v "sha_$arch" '%s' "$sha"
  done

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_relver=.*|_relver=\"$relver\"|" \
    -e "s|^sha256sums_x86_64=.*|sha256sums_x86_64=('$sha_x86_64')|" \
    -e "s|^sha256sums_aarch64=.*|sha256sums_aarch64=('$sha_aarch64')|" \
    "$pkgbuild"
}
