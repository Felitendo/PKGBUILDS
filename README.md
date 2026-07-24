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
4. commits the changes back to this repository,
5. pushes `PKGBUILD` + `.SRCINFO` to the AUR, and
6. deletes the package's superseded releases (older versions, tag included).

The AUR packages themselves only download the prebuilt asset from step 2, so
users don't need any build dependencies.

## Packages

| Package | Upstream | AUR |
|---|---|---|
| `timetable-bin` | [ostfriese4/untis](https://codeberg.org/ostfriese4/untis) — "Timetable", a GTK4 + LibAdwaita client for WebUntis | [timetable-bin](https://aur.archlinux.org/packages/timetable-bin) |
| `fluxer-bin` | [fluxer.app](https://fluxer.app) — Fluxer desktop client (Electron) | [fluxer-bin](https://aur.archlinux.org/packages/fluxer-bin) |
| `chromium-widevine-helper-bin` | [GloriousEggroll/chromium-widevine-helper](https://github.com/GloriousEggroll/chromium-widevine-helper) — extension + native helper installing Google's Widevine CDM into Chromium-based browser profiles | [chromium-widevine-helper-bin](https://aur.archlinux.org/packages/chromium-widevine-helper-bin) |
| `sharpemu-bin` | [sharpemu/sharpemu](https://github.com/sharpemu/sharpemu) — experimental PlayStation 5 emulator | [sharpemu-bin](https://aur.archlinux.org/packages/sharpemu-bin) |
| `thonny-bin` | [thonny/thonny](https://github.com/thonny/thonny) — Python IDE for beginners (bundles a standalone CPython + tcl/tk) | [thonny-bin](https://aur.archlinux.org/packages/thonny-bin) |
| `gearlever-bin` | [mijorus/gearlever](https://github.com/mijorus/gearlever) — "Gear Lever", a GTK4 + LibAdwaita AppImage manager | [gearlever-bin](https://aur.archlinux.org/packages/gearlever-bin) |
| `bottles-bin` | [bottlesdevs/Bottles](https://github.com/bottlesdevs/Bottles) — wine/proton prefix manager (GTK4 + LibAdwaita) | [bottles-bin](https://aur.archlinux.org/packages/bottles-bin) |
| `faugus-launcher-bin` | [Faugus/faugus-launcher](https://github.com/Faugus/faugus-launcher) — launcher for Windows games via UMU-Launcher | [faugus-launcher-bin](https://aur.archlinux.org/packages/faugus-launcher-bin) |
| `protonplus-bin` | [Vysp3r/ProtonPlus](https://github.com/Vysp3r/ProtonPlus) — compatibility-tools manager (Vala/GTK4) | [protonplus-bin](https://aur.archlinux.org/packages/protonplus-bin) |
| `zapzap-bin` | [rafatosta/zapzap](https://github.com/rafatosta/zapzap) — WhatsApp desktop client (PyQt6 + WebEngine) | [zapzap-bin](https://aur.archlinux.org/packages/zapzap-bin) |
| `vacuumtube-bin` | [shy1132/VacuumTube](https://github.com/shy1132/VacuumTube) — YouTube Leanback (TV UI) with built-in adblocker (repackaged upstream deb) | [vacuumtube-bin](https://aur.archlinux.org/packages/vacuumtube-bin) |
| `wiiudownloader-bin` | [Xpl0itU/WiiUDownloader](https://github.com/Xpl0itU/WiiUDownloader) — Wii U title downloader (Go + GTK3) | [wiiudownloader-bin](https://aur.archlinux.org/packages/wiiudownloader-bin) |
| `trayscale-bin` | [DeedleFake/trayscale](https://github.com/DeedleFake/trayscale) — GUI for the Tailscale CLI (Go + GTK4) | [trayscale-bin](https://aur.archlinux.org/packages/trayscale-bin) |
| `linux-wallpaperengine-bin` | [Almamu/linux-wallpaperengine](https://github.com/Almamu/linux-wallpaperengine) — Wallpaper Engine on Linux (commit snapshots, bundles CEF) | [linux-wallpaperengine-bin](https://aur.archlinux.org/packages/linux-wallpaperengine-bin) |
| `librepods-bin` | [librepods-org/librepods](https://github.com/librepods-org/librepods) — AirPods integration for Linux (Qt6) | [librepods-bin](https://aur.archlinux.org/packages/librepods-bin) |
| `planify-bin` | [alainm23/planify](https://github.com/alainm23/planify) — task manager with Todoist/Nextcloud support (Vala/GTK4, bundles gxml) | [planify-bin](https://aur.archlinux.org/packages/planify-bin) |
| `modrinth-app-bin` | [modrinth/code](https://github.com/modrinth/code) — Modrinth's Minecraft mod manager/launcher (repackaged upstream deb) | [modrinth-app-bin](https://aur.archlinux.org/packages/modrinth-app-bin) |
| `bazaar-bin` | [bazaar-org/bazaar](https://github.com/bazaar-org/bazaar) — GNOME app store for flatpaks/Flathub | [bazaar-bin](https://aur.archlinux.org/packages/bazaar-bin) |
| `snapx-bin` | [SnapXL/SnapX](https://github.com/SnapXL/SnapX) — ShareX-fork screenshot/sharing tool (repackaged upstream bundle) | [snapx-bin](https://aur.archlinux.org/packages/snapx-bin) |
| `chiaki-ng-bin` | [streetpea/chiaki-ng](https://github.com/streetpea/chiaki-ng) — PlayStation Remote Play client (Qt6) | [chiaki-ng-bin](https://aur.archlinux.org/packages/chiaki-ng-bin) |

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
