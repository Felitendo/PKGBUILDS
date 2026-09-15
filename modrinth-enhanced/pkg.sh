# modrinth-enhanced - Modrinth Enhanced (https://github.com/Felitendo/Modrinth-Enhanced),
# the Modrinth App (Tauri) with a series of patches applied: no ads, no
# telemetry, offline and Ely.by accounts, Linux fixes.
#
# Source package: upstream is not a fork but a patch series on top of a
# modrinth/code release tag. The PKGBUILD takes the patches from the Modrinth
# Enhanced release tag, applies them to the modrinth/code tarballs the same way
# upstream's scripts/prepare.sh does and builds the result like
# scripts/build.sh - the binary upstream wraps into the .deb that
# modrinth-enhanced-bin repackages.
#
# Two modrinth/code releases are pinned per version, both read from the
# release tag: upstream.txt is the release it was built on, patches/base.txt
# the one the patches were last exported against. They differ until the
# patches are exported again after Modrinth ships a release; the PKGBUILD then
# downloads both and rebases the patches from one onto the other.
#
# Release/version handling is identical to modrinth-enhanced-bin: a revision
# of the patches is tagged v0.21.2-2 and becomes pkgver 0.21.2.r2. See
# modrinth-enhanced-bin/pkg.sh.

UPSTREAM_REPO="Felitendo/Modrinth-Enhanced"

# Installed in CI (pacman) before the makepkg test build. makepkg runs with
# -d there, so the libraries the binary links against are listed too.
BUILD_DEPS=(rust git jdk17-openjdk node-gyp nodejs npm pnpm webkit2gtk-4.1 gtk3 libsoup3)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//; s/-/.r/'
}

# read_tag_file <tag> <path> - a file of the release tag, whitespace stripped
read_tag_file() {
  gh api "repos/$UPSTREAM_REPO/contents/$2?ref=$1" -H 'Accept: application/vnd.github.raw' \
    | tr -d '[:space:]'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag="v${ver/.r/-}" upstream base sha_patches sha_upstream sums

  upstream="$(read_tag_file "$tag" upstream.txt)"
  # like upstream's patch_base(): without base.txt the patches fit upstream.txt
  base="$(read_tag_file "$tag" patches/base.txt)" || base="$upstream"
  if [[ ! "$upstream" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ || ! "$base" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "could not resolve the Modrinth App releases of $tag (upstream: $upstream, base: $base)" >&2
    return 1
  fi

  sha_patches="$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$tag.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sha_upstream="$(curl -sfL "https://github.com/modrinth/code/archive/refs/tags/$upstream.tar.gz" \
    | sha256sum | cut -d' ' -f1)"
  sums="'$sha_patches' '$sha_upstream'"
  if [[ "$base" != "$upstream" ]]; then
    sums+=" '$(curl -sfL "https://github.com/modrinth/code/archive/refs/tags/$base.tar.gz" \
      | sha256sum | cut -d' ' -f1)'"
  fi

  sed -i \
    -e "s|^_tag=.*|_tag=\"$tag\"|" \
    -e "s|^_upstream=.*|_upstream=\"$upstream\"|" \
    -e "s|^_base=.*|_base=\"$base\"|" \
    -e "s|^sha256sums=.*|sha256sums=($sums)|" \
    "$pkgbuild"
}
