# Follow-up: ImageBuilder cannot build RAM-bootable LibreMesh for ath79 / legacy linksys_e8450

## Status

Documented as a known limitation of the current `tools/ci/build_image.sh`
firmware pipeline. The CI on `master` builds and tests real LibreMesh
images for `openwrt_one`, `bananapi_bpi-r4` and `linksys_e8450` (now via
the `linksys_e8450-ubi` profile). Two OpenWrt devices/profiles are
intentionally NOT covered by `test-firmware` because OpenWrt's
ImageBuilder cannot emit a RAM-bootable LibreMesh image for them
without a full kernel rebuild:

- `librerouter_librerouter-v1` (ath79/generic, MIPS) — kept in
  `build-image` for IPK validation, dropped from `test-firmware`.
- `linksys_e8450` legacy profile (mediatek/mt7622, NAND non-UBI) —
  replaced in `targets.yml` with `linksys_e8450-ubi`, which targets the
  same Belkin RT3200 hardware via the UBI boot path.

## Why ImageBuilder can't do it for ath79

`build_image.sh` produces the firmware artifact by repacking three
files coming out of `make image PROFILE=...`:

1. The pre-built kernel binary `<profile>-kernel.bin`.
2. The pre-built device tree blob `image-<dts>.dtb`.
3. A freshly-built rootfs CPIO archive of the LibreMesh root.

It then assembles them into a FIT (`mkits.sh` + `mkimage`) that the
testbed TFTP-boots from RAM. This works on Mediatek Filogic / MT7622
because their U-Boot uses FIT and the OpenWrt build emits `KERNEL_INITRAMFS`
recipes whose intermediate kernel binary is RAM-bootable on its own.

ath79/generic boots the legacy uImage format. There is no separate
initramfs FIT pipeline; instead, OpenWrt builds a single kernel image
in which the initramfs CPIO is **statically linked at compile time**
via `CONFIG_INITRAMFS_SOURCE`. The shipped `<profile>-kernel.bin`
already has the upstream OpenWrt rootfs hardcoded into the kernel, and
ImageBuilder has no way to substitute our LibreMesh CPIO without
recompiling the kernel — which it cannot do, because it ships no
kernel sources, no compiler, and no build infrastructure.

## Why ImageBuilder can't do it for legacy `linksys_e8450`

The legacy `linksys_e8450` profile in `target/linux/mediatek/image/mt7622.mk`
does not define a `KERNEL_INITRAMFS` recipe. As a consequence,
`build_dir/.../linux-mediatek_mt7622/linksys_e8450-kernel.bin` is not
produced by `make image`, so `build_image.sh` cannot pick it up to
repack a RAM-bootable FIT. The `linksys_e8450-ubi` profile (same
hardware: Belkin RT3200) does define `KERNEL_INITRAMFS` and is the
upstream-recommended boot path, so we now use it everywhere in CI.

## What it would take to fix each one

### librerouter_librerouter-v1

Switch the build pipeline (or at least this one target) from
`gh-action-sdk` + ImageBuilder to a full OpenWrt buildroot:

1. Check out `openwrt/openwrt` at the matching tag (`v24.10.6`).
2. `make defconfig` with `CONFIG_TARGET_ath79=y`,
   `CONFIG_TARGET_ath79_generic=y`,
   `CONFIG_TARGET_ath79_generic_DEVICE_librerouter_librerouter-v1=y`.
3. `CONFIG_TARGET_ROOTFS_INITRAMFS=y` and `CONFIG_TARGET_INITRAMFS_COMPRESSION_GZIP=y`.
4. `make package/lime-system/install` (etc.) so the LibreMesh feed
   contributes packages to the embedded initramfs.
5. `make target/linux/install V=s` — produces `bin/targets/ath79/generic/openwrt-ath79-generic-librerouter_librerouter-v1-initramfs-kernel.bin`.

This roughly triples the build time per CI run and complicates feed
caching. Worth doing only if/when ath79 LibreMesh testing becomes a
release-blocker.

### linksys_e8450 legacy

Not worth fixing. The `-ubi` profile targets identical hardware with
better boot characteristics (atomic UBI volume swaps, recovery image)
and is the OpenWrt-recommended path going forward. We keep
`device: linksys_e8450` (so the labgrid place mapping still resolves
to `belkin_rt3200_2`) and only change `profile:` in `targets.yml`.

## See also

- `tools/ci/build_image.sh` — the manual `mkimage` repack flow.
- `.github/ci/targets.yml` — `build_initramfs` / `test_firmware` keys.
- `.github/workflows/build-firmware.yml` — `targets_matrix` vs
  `test_targets_matrix` filtering.
