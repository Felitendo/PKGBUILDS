# PKGBUILDS

Automated AUR packages, kept up to date by GitHub Actions.

Every 6 hours the [update workflow](.github/workflows/update.yml) checks each
package's upstream for a new release. When one is found it:

1. updates the `PKGBUILD` (pkgver/pkgrel/sha256sums),
2. test-builds it with `makepkg` and regenerates `.SRCINFO`,
3. commits the changes back to this repository, and
4. pushes the package files to the AUR.

## Ground rule

**Nothing is ever built or hosted here.** Every `PKGBUILD` sources a
deliverable published by *upstream* — a release tarball, `.deb`, wheel or
AppImage — exactly like any hand-written AUR package would.

This is not a style preference. The
[AUR submission guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines#Rules_of_submission)
say:

> Packages that use **prebuilt** deliverables, when the sources are available,
> must use the `-bin` suffix. […] The AUR should not contain the binary
> tarball created by makepkg

A `-bin` package repackages what upstream ships. Building the software
yourself, publishing the result as a release asset and having the AUR
`PKGBUILD` download *that* makes this repository an unofficial binary
repository — users can no longer verify that the package matches what
upstream released. Packages set up that way were removed from the AUR in
July 2026; do not reintroduce the pattern.

If upstream ships no Linux binary, there are exactly two options: build from
source in the `PKGBUILD` (and drop the `-bin` suffix), or don't package it.

## Packages

| Package | Upstream | Upstream deliverable | AUR |
|---|---|---|---|
| `chiaki-ng-bin` | [streetpea/chiaki-ng](https://github.com/streetpea/chiaki-ng) — PlayStation Remote Play client (Qt6) | AppImage | [chiaki-ng-bin](https://aur.archlinux.org/packages/chiaki-ng-bin) |
| `faugus-launcher-bin` | [Faugus/faugus-launcher](https://github.com/Faugus/faugus-launcher) — launcher for Windows games via UMU-Launcher | `.deb` (`all`) | [faugus-launcher-bin](https://aur.archlinux.org/packages/faugus-launcher-bin) |
| `fluxer-bin` | [fluxer.app](https://fluxer.app) — Fluxer desktop client (Electron) | tarball | [fluxer-bin](https://aur.archlinux.org/packages/fluxer-bin) |
| `lunar-client-bin` | [lunarclient.com](https://lunarclient.com) — Minecraft PvP modpack launcher | AppImage | [lunar-client-bin](https://aur.archlinux.org/packages/lunar-client-bin) |
| `modrinth-app-bin` | [modrinth/code](https://github.com/modrinth/code) — Minecraft mod manager/launcher | `.deb` | [modrinth-app-bin](https://aur.archlinux.org/packages/modrinth-app-bin) |
| `sharpemu-bin` | [sharpemu/sharpemu](https://github.com/sharpemu/sharpemu) — experimental PlayStation 5 emulator | tarball | [sharpemu-bin](https://aur.archlinux.org/packages/sharpemu-bin) |
| `snapx-bin` | [SnapXL/SnapX](https://github.com/SnapXL/SnapX) — ShareX-fork screenshot/sharing tool | self-contained tarball | [snapx-bin](https://aur.archlinux.org/packages/snapx-bin) |
| `vacuumtube-bin` | [shy1132/VacuumTube](https://github.com/shy1132/VacuumTube) — YouTube Leanback (TV UI) with built-in adblocker | `.deb` | [vacuumtube-bin](https://aur.archlinux.org/packages/vacuumtube-bin) |
| `waydroid-helper-bin` | [ayasa520/waydroid-helper](https://github.com/ayasa520/waydroid-helper) — GTK4 GUI for Waydroid configuration and extensions | AppImage | [waydroid-helper-bin](https://aur.archlinux.org/packages/waydroid-helper-bin) |
| `wiiudownloader-bin` | [Xpl0itU/WiiUDownloader](https://github.com/Xpl0itU/WiiUDownloader) — Wii U title downloader (Go + GTK3) | AppImage | [wiiudownloader-bin](https://aur.archlinux.org/packages/wiiudownloader-bin) |
| `zapzap-bin` | [rafatosta/zapzap](https://github.com/rafatosta/zapzap) — WhatsApp desktop client (PyQt6 + WebEngine) | wheel | [zapzap-bin](https://aur.archlinux.org/packages/zapzap-bin) |

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

Check first that upstream actually publishes a Linux binary and that the AUR
does not already carry an equivalent package — a `-bin` next to a maintained
source package is fine, a second copy of the same thing is not.

Then create a directory named after the AUR package containing:

- **`PKGBUILD`** — sources upstream's release URLs directly. `pkgver`,
  `pkgrel` and `sha256sums` are maintained by CI, so keep `sha256sums` on a
  single line.
- **`pkg.sh`** — bash sourced by [scripts/update-package.sh](scripts/update-package.sh),
  defining:
  - `latest_version` — prints the latest upstream version, no `v` prefix.
  - `refresh_checksums <version> <pkgbuild-path>` — updates the `sha256sums*`
    lines for that version. If the asset name carries build metadata that does
    not follow from `pkgver` (see `snapx-bin`, `faugus-launcher-bin`), resolve
    it via the GitHub API here and sync an `_asset` variable in the `PKGBUILD`
    too.
  - `BUILD_DEPS` — optional array of Arch packages to install before the CI
    test build; only needed by packages that build from source.

  Other local source files in the directory (`.desktop` files, patches, …) are
  pushed to the AUR alongside `PKGBUILD` and `.SRCINFO`.

The workflow discovers package directories automatically. Trigger a run
manually via *Actions → Update AUR packages → Run workflow* to publish it
immediately.
