#!/usr/bin/env bash
# Update one package directory:
#   1. determine the latest upstream version (pkg.sh: latest_version)
#   2. bring the PKGBUILD up to date:
#      - packages we build ourselves (pkg.sh defines build_artifact): make
#        sure the GitHub release asset for that version exists - building and
#        uploading it if necessary - and sync pkgver/sha256sums with it
#      - packages prebuilt by upstream (no build_artifact): on a new version,
#        set pkgver and let pkg.sh's refresh_checksums update the sums
#   3. if the PKGBUILD changed: set pkgrel and run a makepkg test build
#   4. regenerate .SRCINFO and commit changes back to this repository
#   5. push the package files to the AUR if it differs
#
# Requires: GH_TOKEN (GitHub release + repo push), AUR_SSH_PRIVATE_KEY.
# Optional: AUR_GIT_NAME / AUR_GIT_EMAIL for the AUR commit identity.
set -euo pipefail

pkg="${1:?usage: update-package.sh <package-dir>}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
pkg="${pkg%/}"

# In the CI container the checkout is owned by a different uid than root;
# git (also invoked internally by gh) refuses to touch it without this.
if [[ "${CI:-}" == "true" ]]; then
  git config --global --add safe.directory "$repo_root"
fi

BUILD_DEPS=()
source "$pkg/pkg.sh"

ver="$(latest_version || true)"
if [[ -z "$ver" || "$ver" == "null" ]]; then
  echo "::error::$pkg: could not determine the latest upstream version"
  exit 1
fi
echo "$pkg: latest upstream version is $ver"

oldver="$(grep -Po '^pkgver=\K.*' "$pkg/PKGBUILD")"
oldrel="$(grep -Po '^pkgrel=\K.*' "$pkg/PKGBUILD")"

### 2: bring the PKGBUILD up to date ########################################

if declare -f build_artifact >/dev/null; then
  # We build the binary artifact and host it as a GitHub release asset.
  tag="$pkg-$ver"
  asset="$pkg-$ver.tar.zst"

  if gh release view "$tag" --json assets -q '.assets[].name' 2>/dev/null | grep -qxF "$asset"; then
    echo "$pkg: release $tag already contains $asset - reusing it"
    gh release download "$tag" --pattern "$asset" --dir "$pkg" --clobber
  else
    echo "$pkg: building $asset"
    if [[ "${CI:-}" == "true" && "${#BUILD_DEPS[@]}" -gt 0 ]]; then
      pacman -S --noconfirm --needed "${BUILD_DEPS[@]}"
    fi
    build_artifact "$ver" "$repo_root/$pkg/$asset"
    gh release view "$tag" >/dev/null 2>&1 || \
      gh release create "$tag" --title "$tag" \
        --notes "Automated build of $pkg $ver (upstream: ${UPSTREAM_REPO:-unknown})."
    gh release upload "$tag" "$pkg/$asset" --clobber
  fi

  sha="$(sha256sum "$pkg/$asset" | cut -d' ' -f1)"
  sed -i \
    -e "s|^pkgver=.*|pkgver=$ver|" \
    -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
    "$pkg/PKGBUILD"
else
  # Upstream publishes the binaries itself; only refresh version + checksums.
  if [[ "$ver" != "$oldver" ]]; then
    sed -i "s|^pkgver=.*|pkgver=$ver|" "$pkg/PKGBUILD"
    refresh_checksums "$ver" "$pkg/PKGBUILD"
  else
    echo "$pkg: $ver is current"
  fi
fi

### 3: pkgrel + test build if the PKGBUILD changed ##########################

# makepkg refuses to run as root (the CI container), so hand it to an
# unprivileged user there.
run_makepkg() {
  if [[ "$EUID" -eq 0 ]]; then
    useradd -m builder 2>/dev/null || true
    chown -R builder "$pkg"
    (cd "$pkg" && runuser -u builder -- makepkg "$@")
  else
    (cd "$pkg" && makepkg "$@")
  fi
}

if git diff --quiet -- "$pkg/PKGBUILD"; then
  rel="$oldrel"
else
  if [[ "$ver" != "$oldver" ]]; then
    rel=1
  else
    rel=$((oldrel + 1))
  fi
  sed -i "s|^pkgrel=.*|pkgrel=$rel|" "$pkg/PKGBUILD"

  # -d: the runner only needs to package, not run the result
  run_makepkg -fdc
  echo "$pkg: makepkg test build succeeded"
fi

# .SRCINFO regeneration is cheap - do it every run so it can never go stale
run_makepkg --printsrcinfo > "$pkg/.SRCINFO.new"
mv "$pkg/.SRCINFO.new" "$pkg/.SRCINFO"
[[ "$EUID" -eq 0 ]] && chown -R 0:0 "$pkg"

# drop downloaded sources and build leftovers (all gitignored, never tracked)
rm -rf "$pkg/src" "$pkg/pkg"
rm -f "$pkg"/*.pkg.tar.* "$pkg"/*.tar.zst "$pkg"/*.tar.gz "$pkg"/*.deb "$pkg"/*.AppImage

### 4: commit back to this repository ########################################

if [[ "${CI:-}" == "true" ]]; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

  git add "$pkg/PKGBUILD" "$pkg/.SRCINFO"
  if git diff --cached --quiet; then
    echo "$pkg: no changes to commit"
  else
    git commit -m "$pkg: update to $ver-$rel [skip ci]"
    git pull --rebase origin "${GITHUB_REF_NAME:-main}"
    git push origin "HEAD:${GITHUB_REF_NAME:-main}"
  fi
fi

### 5: push to the AUR #######################################################

if [[ -z "${AUR_SSH_PRIVATE_KEY:-}" ]]; then
  echo "::error::$pkg: AUR_SSH_PRIVATE_KEY is not set - cannot push to the AUR." \
       "Add your AUR SSH private key as a repository secret named AUR_SSH_PRIVATE_KEY."
  exit 1
fi

# Pass the key and known_hosts explicitly instead of via ~/.ssh: in the CI
# container $HOME and the passwd home directory disagree, and ssh resolves
# "~" through the latter, silently ignoring anything written to $HOME/.ssh.
sshdir="$(mktemp -d)"
printf '%s\n' "$AUR_SSH_PRIVATE_KEY" > "$sshdir/key"
chmod 600 "$sshdir/key"
# Pinned host key, see https://aur.archlinux.org
echo 'aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN' \
  > "$sshdir/known_hosts"
export GIT_SSH_COMMAND="ssh -i $sshdir/key -o UserKnownHostsFile=$sshdir/known_hosts -o IdentitiesOnly=yes"

aurdir="$(mktemp -d)"
git clone "ssh://aur@aur.archlinux.org/$pkg.git" "$aurdir"

# every tracked file of the package except our automation glue belongs on
# the AUR (PKGBUILD, .SRCINFO, .desktop files, .install files, ...)
while IFS= read -r f; do
  [[ "$(basename "$f")" == "pkg.sh" ]] && continue
  cp "$f" "$aurdir/"
done < <(git ls-files "$pkg")

cd "$aurdir"
git config user.name "${AUR_GIT_NAME:-Felitendo}"
git config user.email "${AUR_GIT_EMAIL:-95575686+Felitendo@users.noreply.github.com}"
git add -A
if git diff --cached --quiet && [[ -n "$(git ls-remote origin)" ]]; then
  echo "$pkg: AUR package is already up to date"
else
  git commit -m "Update to $ver-$rel"
  git push origin HEAD:master
  echo "$pkg: pushed $ver-$rel to the AUR"
fi

### 6: prune superseded GitHub releases ######################################

# Build-mode packages get one release per version; once a newer version is
# fully published (asset built, PKGBUILD updated, AUR pushed - i.e. we got
# this far) the older releases are no longer referenced by anything, so drop
# them together with their tags. Runs every time to also catch leftovers.
cd "$repo_root"
if declare -f build_artifact >/dev/null; then
  while IFS= read -r tag; do
    [[ "$tag" == "$pkg-$ver" ]] && continue
    rest="${tag#"$pkg-"}"
    # only this package's tags: "<pkg>-<version>" (a pkgver never contains
    # "-", which also keeps prefix-sharing package names apart)
    [[ "$tag" == "$pkg-"* && "$rest" != *-* ]] || continue
    echo "$pkg: deleting superseded release $tag"
    gh release delete "$tag" --cleanup-tag --yes
  done < <(gh release list --limit 100 --json tagName -q '.[].tagName')
fi
