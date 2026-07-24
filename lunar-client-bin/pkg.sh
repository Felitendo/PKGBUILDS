# lunar-client-bin - Lunar Client (https://lunarclient.com), Minecraft PvP
# modpack launcher, proprietary Electron AppImage.
#
# Upstream hosts versioned AppImages itself, so there is no build_artifact():
# on a new version pkgver, the artifact filename (_appimage) and the checksum
# are refreshed. Upstream currently publishes on the "ow" electron-updater
# channel (latest-ow-linux.yml) with an -ow filename suffix; the old plain
# channel (latest-linux.yml) went stale but is still checked in case they
# switch back - whichever carries the higher version wins.

DL_BASE="https://launcherupdates.lunarclientcdn.com"

_channel_version() {
  curl -sf "$DL_BASE/$1" | grep -Po '^version: \K\S+'
}

latest_version() {
  local a b
  a="$(_channel_version latest-ow-linux.yml | sed 's/-.*//')"
  b="$(_channel_version latest-linux.yml | sed 's/-.*//')"
  [[ -n "$a" || -n "$b" ]] || return 1
  if [[ -n "$a" && -n "$b" ]]; then
    if [[ "$(vercmp "$a" "$b")" -ge 0 ]]; then echo "$a"; else echo "$b"; fi
  else
    echo "${a:-$b}"
  fi
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local yml file sha
  for yml in latest-ow-linux.yml latest-linux.yml; do
    file="$(curl -sf "$DL_BASE/$yml" | grep -Po '^path: \K.*\.AppImage')"
    [[ "$file" == *"$ver"* ]] && break
    file=""
  done
  [[ -n "$file" ]] || { echo "no updater channel carries version $ver" >&2; return 1; }
  file="${file// /%20}"

  sha="$(curl -sfL "$DL_BASE/$file" | sha256sum | cut -d' ' -f1)"
  sed -i \
    -e "s|^_appimage=.*|_appimage=\"$file\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkgbuild"
}
