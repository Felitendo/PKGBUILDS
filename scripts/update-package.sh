#!/usr/bin/env bash
# Update one package directory:
#   1. determine the latest upstream version (pkg.sh: latest_version)
#   2. build the binary artifact if the matching GitHub release asset is
#      missing (pkg.sh: build_artifact), otherwise reuse the published one
#   3. refresh PKGBUILD (pkgver/pkgrel/sha256sums), test-build it with
#      makepkg and regenerate .SRCINFO
#   4. commit changes back to this repository
#   5. push PKGBUILD + .SRCINFO to the AUR
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

source "$pkg/pkg.sh"

ver="$(latest_version || true)"
if [[ -z "$ver" || "$ver" == "null" ]]; then
  echo "::error::$pkg: could not determine the latest upstream version"
  exit 1
fi
echo "$pkg: latest upstream version is $ver"

oldver="$(grep -Po '^pkgver=\K.*' "$pkg/PKGBUILD")"
oldrel="$(grep -Po '^pkgrel=\K.*' "$pkg/PKGBUILD")"
oldsha="$(grep -Po "^sha256sums=\('\K[0-9a-f]{64}" "$pkg/PKGBUILD" || true)"

tag="$pkg-$ver"
asset="$pkg-$ver.tar.zst"

### 1+2: make sure the release asset exists, get a local copy of it #########

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

### 3: refresh PKGBUILD, test-build, regenerate .SRCINFO ####################

if [[ "$ver" != "$oldver" ]]; then
  rel=1
elif [[ "$sha" != "$oldsha" ]]; then
  rel=$((oldrel + 1))
else
  rel="$oldrel"
fi

sed -i \
  -e "s|^pkgver=.*|pkgver=$ver|" \
  -e "s|^pkgrel=.*|pkgrel=$rel|" \
  -e "s|^sha256sums=.*|sha256sums=('$sha')|" \
  "$pkg/PKGBUILD"

# makepkg refuses to run as root (the CI container), so hand the build to an
# unprivileged user there. -d: the runner only needs to package, not run.
if [[ "$EUID" -eq 0 ]]; then
  useradd -m builder 2>/dev/null || true
  chown -R builder "$pkg"
  (cd "$pkg" && runuser -u builder -- makepkg -fdc)
  (cd "$pkg" && runuser -u builder -- makepkg --printsrcinfo > .SRCINFO)
  chown -R 0:0 "$pkg"
else
  (cd "$pkg" && makepkg -fdc)
  (cd "$pkg" && makepkg --printsrcinfo > .SRCINFO)
fi
echo "$pkg: makepkg test build succeeded"
rm -f "$pkg/$asset" "$pkg"/*.pkg.tar.*

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
cp "$pkg/PKGBUILD" "$pkg/.SRCINFO" "$aurdir/"

cd "$aurdir"
git config user.name "${AUR_GIT_NAME:-Felitendo}"
git config user.email "${AUR_GIT_EMAIL:-95575686+Felitendo@users.noreply.github.com}"
git add PKGBUILD .SRCINFO
if git diff --cached --quiet && [[ -n "$(git ls-remote origin)" ]]; then
  echo "$pkg: AUR package is already up to date"
else
  git commit -m "Update to $ver-$rel"
  git push origin HEAD:master
  echo "$pkg: pushed $ver-$rel to the AUR"
fi
