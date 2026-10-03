# moonlight-vrr - Nonary's fork of Moonlight (https://github.com/Nonary/moonlight-qt),
# the GameStream client for PCs, with smooth VRR frame pacing (C++ + Qt6).
#
# Source package: the PKGBUILD builds the release tag against Arch's Qt6 and
# FFmpeg, as extra/moonlight-qt does for the original. moonlight-vrr-bin
# repackages the AppImage upstream builds from the same tag.
#
# The tag tarball lacks the git submodules. refresh_checksums() reads the
# commit of each from the tag's tree (enet and nanors from moonlight-common-c)
# and syncs it into the PKGBUILD. It fails when a submodule moves to another
# repository.
#
# Tags look like v6.1.0-vrr18, pkgver has an underscore for the hyphen.
# /releases/latest skips the betas, which upstream marks as prereleases.

UPSTREAM_REPO="Nonary/moonlight-qt"

# Installed in CI (pacman) before the makepkg test build: the makedepends plus
# the libraries the build links against. qmake turns off what it cannot find.
BUILD_DEPS=(vulkan-headers ffmpeg libdrm libglvnd libplacebo libva libx11 openssl opus
            qt6-base qt6-declarative qt6-svg sdl2-compat sdl2_ttf wayland)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' \
    | sed -e 's/^v//' -e 's/-/_/g'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local tag="v${ver//_/-}" var parent path repo sha url
  local -A commit=()
  local -a sed_args=() sums=()

  sums+=("$(curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$tag.tar.gz" \
    | sha256sum | cut -d' ' -f1)")

  # <PKGBUILD variable> <repository with the .gitmodules> <path> <repository>,
  # in the order of source=()
  while read -r var parent path repo; do
    read -r sha url < <(gh api "repos/$parent/contents/$path?ref=${commit[$parent]:-$tag}" \
      --jq 'select(.type == "submodule") | "\(.sha) \(.submodule_git_url)"') || true
    if [[ ! "$sha" =~ ^[0-9a-f]{40}$ || "${url%.git}" != "https://github.com/$repo" ]]; then
      echo "$tag: submodule $path is no longer $repo (${url:-not found}), update the PKGBUILD" >&2
      return 1
    fi
    commit[$repo]="$sha"
    sed_args+=(-e "s|^$var=.*|$var=\"$sha\"|")
    sums+=("$(curl -sfL "https://github.com/$repo/archive/$sha.tar.gz" | sha256sum | cut -d' ' -f1)")
  done <<'EOF'
_common_c Nonary/moonlight-qt moonlight-common-c/moonlight-common-c Nonary/moonlight-common-c
_enet Nonary/moonlight-common-c enet cgutman/enet
_nanors Nonary/moonlight-common-c nanors sleepybishop/nanors
_qmdnsengine Nonary/moonlight-qt qmdnsengine/qmdnsengine cgutman/qmdnsengine
_gamecontrollerdb Nonary/moonlight-qt app/SDL_GameControllerDB gabomdq/SDL_GameControllerDB
_h264bitstream Nonary/moonlight-qt h264bitstream/h264bitstream aizvorski/h264bitstream
EOF

  if [[ " ${sums[*]} " == *" $(printf '' | sha256sum | cut -d' ' -f1) "* ]]; then
    echo "$tag: could not download every source tarball" >&2
    return 1
  fi

  sed -i "${sed_args[@]}" \
    -e "s|^sha256sums=.*|sha256sums=($(printf "'%s' " "${sums[@]}" | sed 's/ $//'))|" \
    "$pkgbuild"
}
