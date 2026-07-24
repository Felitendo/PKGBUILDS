# snapx-bin - SnapX (https://github.com/SnapXL/SnapX), screenshot/sharing
# tool forked from ShareX, C#/.NET Avalonia UI.
#
# Upstream ships a self-contained Linux bundle per (pre)release, but the
# asset names embed build metadata (e.g. ...-0.4.0-alpha.0+g7eafb0f-X64...)
# that cannot be derived from the version alone. build_artifact() therefore
# resolves the asset by pattern via the GitHub API and repackages it under
# our own predictable name. All upstream releases are marked prerelease, so
# latest_version() reads the release list instead of /latest.

UPSTREAM_REPO="SnapXL/SnapX"

BUILD_DEPS=()

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases" --jq '.[0].tag_name' | sed 's/^v//'
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local workdir destdir asset
  workdir="$(mktemp -d)"
  destdir="$(mktemp -d)"

  asset="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" --jq '.assets[].name' \
    | grep '^SnapX-UI-Release-Linux-' | grep -v musl | grep -- '-X64\.tar\.zst$')"
  [[ "$(wc -l <<< "$asset")" -eq 1 ]] || { echo "expected exactly one UI asset, got: $asset" >&2; return 1; }

  gh release download "v$ver" -R "$UPSTREAM_REPO" --pattern "$asset" --dir "$workdir"
  mkdir -p "$destdir/opt/snapx"
  tar -xf "$workdir/$asset" -C "$destdir/opt/snapx"
  chmod 755 "$destdir/opt/snapx/snapx-ui"

  # upstream's launcher resolves its own directory, so a symlink from
  # /usr/bin would break it - use a wrapper instead
  mkdir -p "$destdir/usr/bin"
  cat > "$destdir/usr/bin/snapx-ui" << 'EOF'
#!/bin/sh
exec /opt/snapx/snapx-ui "$@"
EOF
  chmod 755 "$destdir/usr/bin/snapx-ui"

  # desktop file, icons and metainfo from the source tree
  curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/v$ver.tar.gz" | tar -xz -C "$workdir"
  cp -a "$workdir/SnapX-$ver/packaging/usr/share" "$destdir/usr/"

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr opt

  rm -rf "$workdir" "$destdir"
}
