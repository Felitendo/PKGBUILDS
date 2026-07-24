# linux-wallpaperengine-bin - prebuilt package of
# https://github.com/Almamu/linux-wallpaperengine (Wallpaper Engine backgrounds
# on Linux, C++/CMake, bundles CEF for web wallpapers).
#
# Upstream has no releases or tags, so versions are commit snapshots of main
# in the same "r<commit count>.<short sha>" format the AUR -git package uses.
# Every new upstream commit therefore produces a new build.

UPSTREAM_REPO="Almamu/linux-wallpaperengine"

# Installed in CI (pacman) before build_artifact runs.
BUILD_DEPS=(cmake git sdl2 glm wayland-protocols xorg-xrandr lz4 ffmpeg mpv
            glfw glew freeglut libpulse libcups at-spi2-core nss libxcomposite
            libxdamage nspr dbus freetype2)

latest_version() {
  local sha count
  sha="$(gh api "repos/$UPSTREAM_REPO/commits/main" --jq '.sha')" || return 1
  # total commit count on main, from the Link pagination header
  count="$(gh api -i "repos/$UPSTREAM_REPO/commits?sha=main&per_page=1" \
    | grep -oiP 'page=\K[0-9]+(?=>; rel="last")')" || return 1
  [[ -n "$sha" && -n "$count" ]] || return 1
  echo "r${count}.${sha:0:7}"
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local sha="${ver##*.}"
  local workdir destdir srctree actual
  workdir="$(mktemp -d)"
  destdir="$(mktemp -d)"
  srctree="$workdir/src"

  git clone "https://github.com/$UPSTREAM_REPO.git" "$srctree"
  git -C "$srctree" checkout "$sha"
  git -C "$srctree" submodule update --init --recursive

  # make sure the checkout is really the snapshot the version claims to be
  actual="r$(git -C "$srctree" rev-list --count HEAD).$(git -C "$srctree" rev-parse --short=7 HEAD)"
  if [[ "$actual" != "$ver" ]]; then
    echo "snapshot mismatch: checked out $actual, expected $ver" >&2
    return 1
  fi

  # flags as in the AUR -git package; CEF is fetched by CMake during setup
  cmake -B "$workdir/build" -S "$srctree" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/linux-wallpaperengine \
    -Wno-dev \
    -DCMAKE_CXX_FLAGS='-ffat-lto-objects -Wno-builtin-macro-redefined' \
    -DCMAKE_C_FLAGS='-Wno-builtin-macro-redefined'
  cmake --build "$workdir/build" -j"$(nproc)"
  DESTDIR="$destdir" cmake --install "$workdir/build"
  chmod 755 "$destdir/opt/linux-wallpaperengine/linux-wallpaperengine"

  # forwarding script, as in the AUR -git package
  mkdir -p "$destdir/usr/bin"
  cat > "$destdir/usr/bin/linux-wallpaperengine" << 'EOF'
#!/bin/bash
export LD_LIBRARY_PATH="/opt/linux-wallpaperengine/lib:$LD_LIBRARY_PATH"
cd /opt/linux-wallpaperengine
exec ./linux-wallpaperengine "$@"
EOF
  chmod 755 "$destdir/usr/bin/linux-wallpaperengine"

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr opt

  rm -rf "$workdir" "$destdir"
}
