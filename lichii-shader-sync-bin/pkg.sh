# lichii-shader-sync-bin - Lichii Shader Sync
# (https://github.com/oceanpacificpeace/lichii-shader-sync), downloads shared
# Vulkan shader caches into Lichii and Eden (Go).
#
# Upstream publishes a static Linux build of the command line tool with every
# release, which the PKGBUILD installs unchanged. The release API lists its
# sha256, so it needs no download here.
#
# Version handling is the same as in lichii-shader-sync: the shader packs are
# releases of the same repository, so only v<version> tags count.

UPSTREAM_REPO="oceanpacificpeace/lichii-shader-sync"

latest_version() {
  git ls-remote --tags --refs "https://github.com/$UPSTREAM_REPO.git" 'refs/tags/v*' \
    | sed -n 's|.*refs/tags/v\([0-9][0-9.]*[0-9]\)$|\1|p' | sort -V | tail -n 1
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha

  sha="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq '.assets[] | select(.name == "lichii-sync-linux-amd64") | .digest // empty' \
    | sed 's/^sha256://')"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no lichii-sync-linux-amd64 with a sha256 digest" >&2
    return 1
  fi
  sed -i "s|^sha256sums=.*|sha256sums=('$sha')|" "$pkgbuild"
}
