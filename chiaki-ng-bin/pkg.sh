# chiaki-ng-bin - prebuilt package of https://github.com/streetpea/chiaki-ng
# (free PlayStation Remote Play client, C/C++ + Qt6).
#
# Upstream ships no plain Linux binaries (only AppImage/flatpak), so
# build_artifact() builds from a git checkout of the release tag (the source
# tarballs lack the required submodules). Mirrors the AUR source package:
# system curl instead of the vendored submodule, plus the Qt6GuiPrivate
# CMake fix carried in this directory.

UPSTREAM_REPO="streetpea/chiaki-ng"

# Installed in CI (pacman) before build_artifact runs.
BUILD_DEPS=(cmake git python-protobuf python-setuptools protobuf
            vulkan-headers qt6-base qt6-declarative qt6-svg qt6-webengine
            sdl2 ffmpeg fftw hidapi json-c libplacebo miniupnpc opus speexdsp
            openssl curl libssh2)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local pkgdir workdir destdir srctree
  pkgdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  workdir="$(mktemp -d)"
  destdir="$(mktemp -d)"
  srctree="$workdir/src"

  git clone --branch "v$ver" --depth 1 "https://github.com/$UPSTREAM_REPO.git" "$srctree"

  # use the system curl instead of the vendored submodule
  git -C "$srctree" rm -q third-party/curl
  sed -i 's:libcurl_shared:libcurl:' "$srctree/lib/CMakeLists.txt"
  patch -d "$srctree" -p1 < "$pkgdir/Qt6GuiPrivate-fix.patch"
  git -C "$srctree" submodule update --init

  CFLAGS="${CFLAGS:-} -std=gnu17" cmake -B "$workdir/build" -S "$srctree" -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCHIAKI_USE_SYSTEM_CURL=ON
  cmake --build "$workdir/build" -j"$(nproc)"
  DESTDIR="$destdir" cmake --install "$workdir/build"

  # AGPL-3.0-only-OpenSSL: not a common license, ship the texts
  mkdir -p "$destdir/usr/share/licenses/chiaki-ng-bin"
  install -m644 "$srctree/LICENSES/"* "$destdir/usr/share/licenses/chiaki-ng-bin/"

  rm -f "$destdir/usr/share/applications/mimeinfo.cache" \
        "$destdir/usr/share/icons/hicolor/icon-theme.cache"

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr

  rm -rf "$workdir" "$destdir"
}
