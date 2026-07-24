# trayscale-bin - prebuilt package of https://github.com/DeedleFake/trayscale
# (unofficial GTK4 + LibAdwaita GUI for the Tailscale CLI, written in Go).
#
# Upstream publishes no Linux binary assets, so build_artifact() builds the
# Go binary from the release tarball via upstream's dist.sh (slow: the gotk4
# bindings take a while to compile).

UPSTREAM_REPO="DeedleFake/trayscale"

# Installed in CI (pacman) before build_artifact runs.
BUILD_DEPS=(go gtk4 libadwaita gobject-introspection)

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
  srctree="$workdir/trayscale-$ver"

  (cd "$srctree" && \
    GOMODCACHE="$workdir/gomodcache" GOFLAGS="-modcacherw" \
    ./dist.sh build "v$ver" && \
    ./dist.sh install "$destdir/usr")

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr

  rm -rf "$workdir" "$destdir"
}
