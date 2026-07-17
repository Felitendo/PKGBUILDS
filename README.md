# PKGBUILDS

Automated `-bin` packages for the [AUR](https://aur.archlinux.org), kept up to
date by GitHub Actions.

Every 6 hours the [update workflow](.github/workflows/update.yml) checks each
package's upstream for a new release. When one is found it:

1. builds the software in an Arch Linux container,
2. publishes the resulting install tree as a `.tar.zst` asset on a GitHub
   release of **this** repository (tag `<pkgname>-<version>`),
3. updates the `PKGBUILD` (pkgver/pkgrel/sha256sums), test-builds it with
   `makepkg` and regenerates `.SRCINFO`,
4. commits the changes back to this repository, and
5. pushes `PKGBUILD` + `.SRCINFO` to the AUR.

The AUR packages themselves only download the prebuilt asset from step 2, so
users don't need any build dependencies.

## Packages

| Package | Upstream | AUR |
|---|---|---|
| `timetable-bin` | [ostfriese4/untis](https://codeberg.org/ostfriese4/untis) — "Timetable", a GTK4 + LibAdwaita client for WebUntis | [timetable-bin](https://aur.archlinux.org/packages/timetable-bin) |

## Setup (one-time)

1. Create an [AUR account](https://aur.archlinux.org/register) and add an SSH
   public key to it (AUR account settings).
2. Add the matching **private** key as a repository secret named
   `AUR_SSH_PRIVATE_KEY`
   (Settings → Secrets and variables → Actions → New repository secret).
3. Optionally set the repository **variables** `AUR_GIT_NAME` and
   `AUR_GIT_EMAIL` to control the commit identity used on the AUR
   (defaults: `Felitendo` / `95575686+Felitendo@users.noreply.github.com`).

The first push to `ssh://aur@aur.archlinux.org/<pkgname>.git` creates the AUR
package automatically.

## Adding a package

Create a new directory named after the AUR package containing:

- **`PKGBUILD`** — sources the prebuilt asset from
  `https://github.com/Felitendo/PKGBUILDS/releases/download/<pkgname>-<pkgver>/<pkgname>-<pkgver>.tar.zst`.
  `pkgver`, `pkgrel` and `sha256sums` are maintained by CI.
- **`pkg.sh`** — bash sourced by [scripts/update-package.sh](scripts/update-package.sh),
  providing:
  - `BUILD_DEPS` — array of Arch packages installed before building,
  - `latest_version` — prints the latest upstream version (no `v` prefix),
  - `build_artifact <version> <output-file>` — downloads/builds upstream and
    writes the install tree (a tarball containing `usr/`) to `<output-file>`.

The workflow discovers package directories automatically. Trigger a run
manually via *Actions → Update AUR packages → Run workflow* to publish it
immediately.
