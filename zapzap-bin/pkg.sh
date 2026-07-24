# zapzap-bin - prebuilt package of https://github.com/rafatosta/zapzap
# (WhatsApp desktop client written in PyQt6 + PyQt6-WebEngine).
#
# Upstream ships deb/AppImage bundles that vendor all of Qt; instead we build
# the (pure-Python) wheel and install it against the system PyQt6 packages,
# like the AUR source package does.

UPSTREAM_REPO="rafatosta/zapzap"

# Installed in CI (pacman) before build_artifact runs.
BUILD_DEPS=(python python-build python-installer python-setuptools python-wheel)

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local workdir destdir srctree staging sitedir entry
  workdir="$(mktemp -d)"
  destdir="$(mktemp -d)"
  staging="$(mktemp -d)"

  curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/tags/$ver.tar.gz" | tar -xz -C "$workdir"
  srctree="$workdir/zapzap-$ver"

  (cd "$srctree" && python -m build --wheel --no-isolation)
  python -m installer --destdir="$staging" "$srctree"/dist/*.whl

  # The wheel installs into site-packages, whose path changes with every
  # Python minor bump and would silently break a prebuilt package. Relocate
  # to a fixed dir and use our own launcher instead of the generated console
  # script (entry point parsed from pyproject.toml).
  sitedir="$(find "$staging/usr/lib" -maxdepth 2 -type d -name site-packages)"
  [[ -d "$sitedir/zapzap" ]] || { echo "zapzap module not found in $sitedir" >&2; return 1; }
  mkdir -p "$destdir/usr/lib/zapzap"
  mv "$sitedir/zapzap" "$sitedir"/zapzap-*.dist-info "$destdir/usr/lib/zapzap/"

  entry="$(python -c "import tomllib; print(tomllib.load(open('$srctree/pyproject.toml','rb'))['project']['scripts']['zapzap'])")"
  mkdir -p "$destdir/usr/bin"
  cat > "$destdir/usr/bin/zapzap" << EOF
#!/usr/bin/python3
import sys

sys.path.insert(0, "/usr/lib/zapzap")
from ${entry%%:*} import ${entry#*:}

sys.exit(${entry#*:}())
EOF
  chmod 755 "$destdir/usr/bin/zapzap"

  # Icon, desktop file and metainfo are not part of the wheel.
  install -Dm644 "$srctree/share/icons/com.rtosta.zapzap.svg" \
    "$destdir/usr/share/icons/hicolor/scalable/apps/com.rtosta.zapzap.svg"
  install -Dm644 "$srctree/share/applications/com.rtosta.zapzap.desktop" \
    "$destdir/usr/share/applications/com.rtosta.zapzap.desktop"
  install -Dm644 "$srctree/share/metainfo/com.rtosta.zapzap.appdata.xml" \
    "$destdir/usr/share/metainfo/com.rtosta.zapzap.appdata.xml"

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr

  rm -rf "$workdir" "$destdir" "$staging"
}
