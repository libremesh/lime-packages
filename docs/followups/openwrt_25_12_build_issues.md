# OpenWrt 25.12 SDK build issues — RESOLVED (closed)

> Status: closed. The original "infinite `iproute2` loop" was a
> misdiagnosis; it was the normal per-package recompile pattern that
> `gh-action-sdk` walks. The 25.12 cells of `build-feed` were
> completing successfully (~80 min cold, 31 `.apk` packages produced),
> but the post-build verification was searching for `*.ipk` files and
> aborting with `ERROR: feed produced no IPKs`. The full apk-tools
> migration is now implemented in `tools/ci/build_image.sh` and
> `.github/workflows/build-firmware.yml`, see
> [`docs/ci/firmware-build.md`](../ci/firmware-build.md#openwrt-releases-in-the-build-matrix).

## What was actually wrong

OpenWrt 25.12 replaced opkg (`.ipk` + `Packages.gz`) with apk-tools
(`.apk` + `packages.adb`). Our CI was hardcoded for ipk:

- `Diagnose feed build output` failed because no `*.ipk` were found.
- `Assemble lime_packages feed artifact` always called
  `ipkg-make-index.sh`, which does not exist on the 25.12 IB.
- `tools/ci/build_image.sh` wrote `repositories.conf` lines in opkg
  syntax (`src/gz <name> <url>`) and used `opkg --offline-root` for
  the pre-flight; both are no-ops on apk-tools.

The Kconfig "recursive dependency detected" warnings on 25.12 are
harmless (a Kbuild side-effect of the `bool → tristate` symbol
changes upstream) and do not abort the build. The `iproute2`
clean-build/compile cycles in the log are the SDK serially
recompiling each requested package, not an infinite loop.

## Fix shipped

A single `PKG_FORMAT` variable derived from `OPENWRT_RELEASE`
controls the bifurcation across the pipeline:

- `build-firmware.yml`
  - Diagnose step accepts `*.{ipk,apk}` globs.
  - Assemble step generates `Packages` + `Packages.gz` (24.10) or
    `packages.adb` via `apk mkndx` / `apk index` (25.12).
  - `extra_packages` lookup probes both `*-*.apk` and `*_*.ipk`
    naming under both `bin/packages/` and `bin/targets/`.
- `tools/ci/build_image.sh`
  - Writes a per-format `repositories.snippet` (opkg `src/gz` lines
    vs apk URL lines, including the local `file:///feed/...`).
  - Mounts `/feed` rw on apk so the IB can refresh `packages.adb`
    in place if the assemble step skipped it.
  - Uses `apk --root /tmp/preflight ... list lime-system` instead
    of `opkg --offline-root ... list` for the pre-flight on apk.
  - Passes
    `APK_FLAGS="--allow-untrusted --repository file:///feed/lime_packages/packages.adb"`
    to `make image` for apk targets (per openwrt#18032 / PR#18048).

## What this no longer blocks

- 25.12 cells of `build-feed` and `build-image` succeed and produce
  artefacts comparable to the 24.10 cells (the `firmware-<device>-25.12.2`
  artifact uploaded by the workflow can be flashed/booted normally).
- `test-firmware-qemu-single` and `test-mesh-qemu` against
  `qemu_x86_64 / 25.12.2` follow the standard QEMU happy-path; the
  guest exposes `apk` instead of `opkg`, and the few diagnostic
  commands in `libremesh-tests` now fall back to whichever package
  manager is present.

## Pointers if 25.12 builds regress again

- Kick off only the affected matrix cell:
  `gh workflow run build-firmware.yml -f openwrt_releases=25.12.2`.
- The first place to look for "no packages produced" is the
  `Diagnose feed build output` step's package-format banner; a
  mismatch between `OPENWRT_RELEASE` and the actual files on disk
  means the assemble step ran for the wrong format.
- The `apk` binary inside the IB is at
  `/builder/staging_dir/host/bin/apk`. Use `apk index --help` /
  `apk mkndx --help` to confirm which subcommand is available in
  that release's IB image.
