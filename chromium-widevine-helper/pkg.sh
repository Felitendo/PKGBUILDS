# chromium-widevine-helper - Chromium extension + native messaging helper
# that installs Google's Widevine CDM into Chromium-based browser profiles
# (https://github.com/GloriousEggroll/chromium-widevine-helper).
#
# Upstream publishes neither releases nor tags; the canonical version lives in
# the Fedora RPM spec on the main branch. The package pins the main commit
# that carries that version, so it stays tied to a specific version (no -git
# suffix) - refresh_checksums() moves the pin along with the version.
#
# Nothing is compiled: the payload is a Python script, JSON manifests and the
# extension assets, so package() alone does the work.

UPSTREAM_REPO="GloriousEggroll/chromium-widevine-helper"
SPEC_PATH="Packaging/rpm/chromium-widevine-helper.spec"

BUILD_DEPS=()

spec_version() {
  grep -Po '^%global helper_version \K[0-9.]+'
}

latest_version() {
  curl -sf "https://raw.githubusercontent.com/$UPSTREAM_REPO/main/$SPEC_PATH" \
    | spec_version
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local commit specver sha

  commit="$(gh api "repos/$UPSTREAM_REPO/commits/main" --jq '.sha')"

  # main may have moved between the version check and this lookup
  specver="$(curl -sf "https://raw.githubusercontent.com/$UPSTREAM_REPO/$commit/$SPEC_PATH" \
    | spec_version)"
  if [[ "$specver" != "$ver" ]]; then
    echo "main is at $specver, not the requested $ver - try again" >&2
    return 1
  fi

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/$commit.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_commit=.*|_commit=\"$commit\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
