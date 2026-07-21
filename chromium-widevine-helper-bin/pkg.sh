# chromium-widevine-helper-bin - prebuilt package of
# https://github.com/GloriousEggroll/chromium-widevine-helper
# (Chromium extension + native messaging helper that installs Google's
# Widevine CDM into Chromium-based browser profiles).
#
# Upstream publishes neither releases nor tags; the canonical version lives in
# the Fedora RPM spec on the main branch. build_artifact() snapshots main,
# verifies the snapshot still carries the requested version and assembles the
# install tree following upstream's spec - with Fedora's /usr/libexec
# relocated to /usr/lib, which Arch uses instead.

UPSTREAM_REPO="GloriousEggroll/chromium-widevine-helper"
SPEC_PATH="Packaging/rpm/chromium-widevine-helper.spec"

# Pure noarch install tree (Python script + JSON + extension assets).
BUILD_DEPS=()

spec_version() {
  grep -Po '^%global helper_version \K[0-9.]+'
}

latest_version() {
  curl -sf "https://raw.githubusercontent.com/$UPSTREAM_REPO/main/$SPEC_PATH" \
    | spec_version
}

# build_artifact <version> <output-file>
build_artifact() {
  local ver="$1" outfile="$2"
  local workdir destdir
  workdir="$(mktemp -d)"
  destdir="$(mktemp -d)"

  curl -sfL "https://github.com/$UPSTREAM_REPO/archive/refs/heads/main.tar.gz" \
    | tar -xz -C "$workdir" --strip-components=1

  # main may have moved between the version check and this download.
  local specver
  specver="$(spec_version < "$workdir/$SPEC_PATH")"
  if [[ "$specver" != "$ver" ]]; then
    echo "snapshot of main is $specver, not the requested $ver - try again" >&2
    return 1
  fi

  install -Dm755 "$workdir/helper/chromium-widevine" \
    "$destdir/usr/lib/chromium-widevine/chromium-widevine"
  install -d "$destdir/usr/bin"
  ln -s /usr/lib/chromium-widevine/chromium-widevine "$destdir/usr/bin/chromium-widevine"

  # The extension is shipped so it can be loaded unpacked from
  # chrome://extensions (chromium-widevine --install-native-hosts then
  # registers whatever ID the browser assigned it).
  mkdir -p "$destdir/usr/share/chromium-widevine"
  cp -a "$workdir/extension" "$destdir/usr/share/chromium-widevine/extension"
  find "$destdir/usr/share/chromium-widevine" -type d -exec chmod 755 {} +
  find "$destdir/usr/share/chromium-widevine" -type f -exec chmod 644 {} +

  install -Dm644 "$workdir/README.md" \
    "$destdir/usr/share/doc/chromium-widevine-helper-bin/README.md"

  # System-wide native messaging host manifests for the same browser lookup
  # roots upstream's RPM covers.
  local hostdir
  for hostdir in helium net.imput.helium chromium chromium-browser \
                 opt/chrome opt/edge brave vivaldi opera thorium iridium; do
    install -Dm644 "$workdir/helper/chromium-widevine-native-host.json" \
      "$destdir/etc/$hostdir/native-messaging-hosts/org.chromium.widevine.json"
  done
  # The upstream manifest hardcodes Fedora's /usr/libexec helper path.
  find "$destdir/etc" -name 'org.chromium.widevine.json' -exec \
    sed -i 's|/usr/libexec/chromium-widevine/|/usr/lib/chromium-widevine/|' {} +

  tar --zstd --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
      -cf "$outfile" -C "$destdir" usr etc

  rm -rf "$workdir" "$destdir"
}
