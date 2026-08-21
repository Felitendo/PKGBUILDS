# nextcloud-native - Nextcloud Native (https://github.com/Obiente/nc-native),
# an adaptive native Nextcloud client built with Kotlin/Compose Multiplatform.
#
# Source package: the PKGBUILD builds :ui:createDistributable from the release
# tarball, which is the same jpackage application image upstream wraps into the
# .deb that nextcloud-native-bin repackages.
#
# CONTRIBUTING.md lists an Android SDK, Rust and Node.js as prerequisites, but
# those cover the mobile target, the Windows Explorer helper and the website.
# The Linux desktop image builds with JDK 21 alone - verified against
# v0.1.0-alpha.2 with ANDROID_HOME and ANDROID_SDK_ROOT unset.
#
# Release/version handling is identical to nextcloud-native-bin: every upstream
# release is a prerelease and the list is dominated by per-build nightly-* and
# rolling channel-* releases, so only the versioned v* tags are packaged, and
# pkgver drops the hyphen (v0.1.0-alpha.2 -> 0.1.0alpha.2), which pacman sorts
# older than a later plain 0.1.0, so no epoch is needed. See
# nextcloud-native-bin/pkg.sh.

UPSTREAM_REPO="Obiente/nc-native"

# Installed in CI (pacman) before the makepkg test build.
BUILD_DEPS=(jdk21-openjdk python)

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
  local tag sha

  tag="$(latest_tag)"
  if [[ "$(tag_to_pkgver <<< "$tag")" != "$ver" ]]; then
    echo "newest versioned release is $tag, not the requested $ver - try again" >&2
    return 1
  fi

  sha="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$tag.tar.gz" \
    | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
