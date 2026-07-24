# wiiudownloader-bin - prebuilt package of https://github.com/Xpl0itU/WiiUDownloader
# (Go + GTK3 downloader for Wii U titles from Nintendo's official servers).
#
# Upstream only ships AppImages, so build_artifact() builds the Go binary
# from the release tarball (grabTitles.py generates the title database that
# is compiled in).

UPSTREAM_REPO="Xpl0itU/WiiUDownloader"

# Installed in CI (pacman) before build_artifact runs.
BUILD_DEPS=(go gtk3 python)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local workdir destdir srctree
  workdir="$(mktemp -d)"
  destdir="$(mktemp -d)"

  curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" | tar -xz -C "$workdir"
  srctree="$workdir/WiiUDownloader-$ver"

  (cd "$srctree" && python3 grabTitles.py)

  (cd "$srctree/cmd/WiiUDownloader" && \
    GOPATH="$workdir/gopath" \
    GOFLAGS="-buildmode=pie -trimpath -mod=readonly -modcacherw" \
    go build -v -o "$destdir/wiiudownloader" .)

  install -Dm755 "$destdir/wiiudownloader" "$destdir/usr/bin/wiiudownloader"
  rm "$destdir/wiiudownloader"
  install -Dm644 "$srctree/data/WiiUDownloader.png" \
    "$destdir/usr/share/icons/hicolor/256x256/apps/wiiudownloader.png"

  mkdir -p "$destdir/usr/share/applications"
  cat > "$destdir/usr/share/applications/wiiudownloader.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=WiiUDownloader
Comment=Download Wii U titles from Nintendo's official servers
Exec=wiiudownloader
Icon=wiiudownloader
Terminal=false
Categories=Utility;
EOF

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr

  rm -rf "$workdir" "$destdir"
}
