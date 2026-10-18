# gtaiv-eflc-fusionfix-bin - FusionFix
# (https://github.com/ThirteenAG/GTAIV.EFLC.FusionFix), a mod for Grand
# Theft Auto IV: The Complete Edition.
#
# There is no source package and no -git package: the mod only builds with
# MSVC (C++ modules), and its game data is made by Windows-only tools that
# ship as .exe files in the repository. So this repackages upstream's
# release zip, the one its install guide says to unpack next to GTAIV.exe.
#
# The zip has the same name in every release. Its sha256 comes from the
# release's asset digest, so a new version needs no 200 MB download. The
# DXVK version is read from upstream's workflow at the tag, because that is
# where the bundled vulkan.dll comes from.

UPSTREAM_REPO="ThirteenAG/GTAIV.EFLC.FusionFix"

latest_version() {
  gh api "repos/$UPSTREAM_REPO/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

# refresh_checksums <version> <pkgbuild-path>
refresh_checksums() {
  local ver="$1" pkgbuild="$2"
  local sha_zip sha_lic sha_dxvk sha_ual dxvk ual

  sha_zip="$(gh api "repos/$UPSTREAM_REPO/releases/tags/v$ver" \
    --jq '.assets[] | select(.name == "GTAIV.EFLC.FusionFix.zip") | .digest' \
    | sed 's/^sha256://')"
  if [[ ! "$sha_zip" =~ ^[0-9a-f]{64}$ ]]; then
    echo "v$ver has no GTAIV.EFLC.FusionFix.zip with a sha256 digest" >&2
    return 1
  fi

  # the tag in the step that downloads DXVK; the old one is kept if the
  # workflow no longer has that step
  dxvk="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/.github/workflows/msvc_x86.yml" \
    | sed -n '/repository: "doitsujin\/dxvk"/{n;s/^ *tag: *'\''\(v[^'\'']*\)'\''.*/\1/p}' || true)"
  if [[ -z "$dxvk" ]]; then
    dxvk="$(sed -n 's/^_dxvk="\(.*\)"/\1/p' "$pkgbuild")"
  fi
  ual="$(sed -n 's/^_ual="\(.*\)"/\1/p' "$pkgbuild")"

  sha_lic="$(curl -sfL "https://raw.githubusercontent.com/$UPSTREAM_REPO/v$ver/license" | sha256sum | cut -d' ' -f1)"
  sha_dxvk="$(curl -sfL "https://raw.githubusercontent.com/doitsujin/dxvk/$dxvk/LICENSE" | sha256sum | cut -d' ' -f1)"
  sha_ual="$(curl -sfL "https://raw.githubusercontent.com/ThirteenAG/Ultimate-ASI-Loader/$ual/license" | sha256sum | cut -d' ' -f1)"

  sed -i \
    -e "s|^_dxvk=.*|_dxvk=\"$dxvk\"|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha_zip' '$sha_lic' '$sha_dxvk' '$sha_ual')|" \
    "$pkgbuild"
}
