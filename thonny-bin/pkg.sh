# thonny-bin - Thonny (https://github.com/thonny/thonny), a Python IDE for
# beginners.
#
# Since 5.0 upstream ships no prebuilt Linux bundle anymore - the official
# installer script just creates a venv from the system Python and
# pip-installs thonny plus a pinned set of extras. A venv tied to the system
# Python would silently break on every Arch Python minor bump, so
# build_artifact() instead bundles a relocatable standalone CPython
# (astral-sh/python-build-standalone, tkinter included) into /opt/thonny-bin
# and pip-installs into that, mirroring the dependency pins of upstream's
# installer script. The install tree is published as a GitHub release asset
# of this repository, which the PKGBUILD then uses.

UPSTREAM_REPO="thonny/thonny"

# Series of the bundled CPython; bump deliberately (thonny 5.x supports
# Python 3.9-3.15).
PYTHON_SERIES="3.13"

BUILD_DEPS=()

latest_version() {
  # gh instead of plain curl: authenticated API calls, so shared-IP rate
  # limits on the CI runners can't bite.
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local workdir root prefix py
  workdir="$(mktemp -d)"
  root="$workdir/root"
  prefix="$root/opt/thonny-bin"
  mkdir -p "$prefix"

  gh release download -R astral-sh/python-build-standalone \
    --pattern "cpython-${PYTHON_SERIES}.*-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz" \
    --dir "$workdir"
  tar -xzf "$workdir"/cpython-*.tar.gz -C "$workdir"
  cp -a "$workdir/python/." "$prefix/"
  py="$prefix/bin/python3"

  # Upstream's installer script is the authority on which extra packages
  # (and pins) belong to a release - parse its pip install line instead of
  # hardcoding a list that would go stale.
  curl -sfL "https://github.com/$UPSTREAM_REPO/releases/download/v$ver/thonny-$ver.bash" \
    -o "$workdir/installer.bash"
  local extras=()
  mapfile -t extras < <(grep -m1 -- "-m pip install '" "$workdir/installer.bash" \
    | grep -oP "'[^']*'" | sed "s/^'//; s/'\$//")
  if [[ ${#extras[@]} -eq 0 ]]; then
    echo "thonny-bin: could not parse the extras list from the installer script" >&2
    return 1
  fi

  "$py" -m pip install --no-cache-dir --no-compile "${extras[@]}" "thonny==$ver"

  # pip wrote the staging path into the script shebangs; point them at the
  # final install location.
  local f
  for f in "$prefix/bin/"*; do
    [[ -f "$f" && ! -L "$f" && "$(head -c 2 "$f")" == '#!' ]] || continue
    sed -i "1s|$prefix|/opt/thonny-bin|" "$f"
  done

  # Precompile with the final paths recorded in the .pyc files - users can't
  # write __pycache__ under /opt at runtime. Some packages ship
  # intentionally uncompilable files, hence the || true.
  "$py" -m compileall -q -s "$root" "$prefix/lib" || true

  local sitepkg
  sitepkg="$("$py" -c 'import os, thonny; print(os.path.dirname(thonny.__file__))')"

  install -d "$root/usr/bin" "$root/usr/share/applications" \
    "$root/usr/share/pixmaps" "$root/usr/share/licenses/thonny-bin"
  ln -s /opt/thonny-bin/bin/thonny "$root/usr/bin/thonny"
  cp "$sitepkg/res/thonny.png" "$root/usr/share/pixmaps/thonny.png"
  curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/LICENSE.txt" \
    -o "$root/usr/share/licenses/thonny-bin/LICENSE.txt"

  # Mirrors the launcher that upstream's installer script generates.
  cat > "$root/usr/share/applications/thonny.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Thonny
GenericName=Python IDE
Comment=Python IDE for beginners
Exec=/opt/thonny-bin/bin/thonny %F
Icon=thonny
StartupWMClass=Thonny
Terminal=false
Categories=Development;IDE;
Keywords=programming;education;
MimeType=text/x-python;
EOF

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$root" opt usr

  rm -rf "$workdir"
}
