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
| `fluxer-bin` | [fluxer.app](https://fluxer.app) — Fluxer desktop client (Electron) | [fluxer-bin](https://aur.archlinux.org/packages/fluxer-bin) |
| `chromium-widevine-helper-bin` | [GloriousEggroll/chromium-widevine-helper](https://github.com/GloriousEggroll/chromium-widevine-helper) — extension + native helper installing Google's Widevine CDM into Chromium-based browser profiles | [chromium-widevine-helper-bin](https://aur.archlinux.org/packages/chromium-widevine-helper-bin) |

## Setup (one-time)

1. Create an [AUR account](https://aur.archlinux.org/register) and add an SSH
   public key to it (AUR account settings).
2. Add the matching **private** key as a repository secret named
   `AUR_SSH_PRIVATE_KEY`
   (Settings → Secrets and variables → Actions → New repository secret).
3. Optionally set the repository variable `AUR_GIT_NAME` and the repository
   **secret** `AUR_GIT_EMAIL` to control the commit identity used on the AUR
   (defaults: `Felitendo` / the maintainer's GitHub noreply address).

The first push to `ssh://aur@aur.archlinux.org/<pkgname>.git` creates the AUR
package automatically.

## Adding a package

Create a new directory named after the AUR package containing:

- **`PKGBUILD`** — sources the prebuilt asset from
  `https://github.com/Felitendo/PKGBUILDS/releases/download/<pkgname>-<pkgver>/<pkgname>-<pkgver>.tar.zst`.
  `pkgver`, `pkgrel` and `sha256sums` are maintained by CI.
- **`pkg.sh`** — bash sourced by [scripts/update-package.sh](scripts/update-package.sh).
  Always provides `latest_version` (prints the latest upstream version, no
  `v` prefix), plus one of two modes:
  - *upstream has no binaries* (e.g. `timetable-bin`): define
    `build_artifact <version> <output-file>` (build upstream and write the
    install tree as a tarball containing `usr/`) and `BUILD_DEPS` (array of
    Arch packages needed to build). CI hosts the result as a GitHub release
    asset which the PKGBUILD downloads.
  - *upstream hosts binaries* (e.g. `fluxer-bin`): define
    `refresh_checksums <version> <pkgbuild-path>` which updates the
    `sha256sums*` lines for the new version. The PKGBUILD sources upstream
    URLs directly and nothing is hosted here.

  Other local source files in the directory (`.desktop` files, etc.) are
  pushed to the AUR alongside `PKGBUILD` and `.SRCINFO`.

The workflow discovers package directories automatically. Trigger a run
manually via *Actions → Update AUR packages → Run workflow* to publish it
immediately.
