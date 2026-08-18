# nextcloud-native-bin - Nextcloud Native (https://github.com/Obiente/nc-native),
# an adaptive native Nextcloud client built with Kotlin/Compose Multiplatform.
#
# Upstream publishes a jpackage .deb (and .rpm) per release, so there is no
# build_artifact() here: on a new version only pkgver, the asset name and the
# checksum are refreshed and the PKGBUILD repackages the .deb directly.
#
# The project has no stable release yet. Every GitHub release is marked
# prerelease, so /latest is empty, and the release list is dominated by
# per-build "nightly-*" releases plus the rolling "channel-nightly" /
# "channel-prerelease" pointers, whose assets change under a fixed name. Only
# the versioned "v*" tags are packaged; nightlies would push several AUR
# updates a day and cannot be checksummed reliably.
#
# pkgver drops the hyphen from the tag (v0.1.0-alpha.2 -> 0.1.0alpha.2). That
# sorts newer than a later plain 0.1.0, so the first stable release of a
# version that was packaged as a prerelease needs an epoch bump.

UPSTREAM_REPO="Obiente/nc-native"

# newest release whose tag looks like a version (skips nightly-*/channel-*)
latest_tag() {
  gh api "repos/$UPSTREAM_REPO/releases?per_page=100" \
    --jq '[.[] | select(.tag_name | test("^v[0-9]"))] | .[0].tag_name'
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

  # e.g. nextcloudnative_1.0.3822_amd64.deb - the number is a build counter
  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/$tag" --jq '.assets[].name' \
    | grep -E '^nextcloudnative_.*_amd64\.deb$')"
  [[ "$(wc -l <<< "$asset")" -eq 1 ]] || { echo "expected exactly one amd64 .deb, got: $asset" >&2; return 1; }

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/$tag/$asset" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_asset=.*|_asset=\"$asset\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
