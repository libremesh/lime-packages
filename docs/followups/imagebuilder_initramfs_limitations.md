# Follow-up: ImageBuilder cannot build RAM-bootable LibreMesh for ath79 / legacy linksys_e8450

## Status

Documented as a known limitation of the current `tools/ci/build_image.sh`
firmware pipeline. The CI on `master` builds and tests real LibreMesh
images for `openwrt_one`, `bananapi_bpi-r4` and `linksys_e8450` (now via
the `linksys_e8450-ubi` profile, expanded across the three Belkin RT3200
units in the testbed). Two OpenWrt devices/profiles are intentionally NOT
in the build matrix because OpenWrt's ImageBuilder cannot emit a
RAM-bootable LibreMesh image for them without a full kernel rebuild:

- `librerouter_librerouter-v1` (ath79/generic, MIPS) — fully removed from
  `targets.yml` (April 2026). Was previously kept in `build-image` for IPK
  validation only; we dropped it because the only viable build path is a
  full OpenWrt source tree build that would dominate CI wall time, and
  the IPK validation it provided was not load-bearing (the `mips_24kc`
  arch has no other consumers in the matrix). The labgrid YAML
  `libremesh-tests/targets/librerouter_librerouter-v1.yaml` is preserved
  for manual local/remote test runs against a pre-staged
  `*-initramfs-kernel.bin`.
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

## What we tried and discarded for `librerouter_librerouter-v1`

Three build paths were prototyped and rejected. Documenting them so the
next person doesn't repeat the experiments.

1. **`image_format: multi-uimage`** (legacy `IH_TYPE_MULTI` uImage
   carrying `[kernel.lzma, rootfs.cpio]`, repacked by `build_image.sh`).
   The kernel boots, but the LibreRouter U-Boot 1.1.x fork
   ([LibreRouterOrg/u-boot](https://github.com/LibreRouterOrg/u-boot),
   `lib_mips/mips_linux.c`) does not propagate sub-image-1 to the MIPS
   kernel as `initrd_start` / `initrd_size`. The kernel cmdline ends up
   `console=ttyS0,115200n8 rootfstype=squashfs,jffs2`, the initramfs
   unpacker never runs, and the device falls through to mounting the
   on-flash squashfs. CI symptom: `root@margarita:/#` instead of
   `root@LiMe-XXXXXX:/#` (pexpect TIMEOUT in `_await_login`).

2. **OpenWrt SDK** (`ghcr.io/openwrt/sdk:ath79-generic-*`, driven by a
   `build_image_sdk.sh` wrapper). `make image` inside the SDK fails
   immediately:

       make[1]: *** No rule to make target 'image'. Stop.

   The SDK ships only the `package/` subtree and the host toolchain; its
   `target/` and `include/image.mk` are deliberately stripped. By design
   it compiles `.ipk`s against a pre-built kernel — it cannot rebuild
   the kernel, which is exactly what an embedded CPIO needs.

3. **OpenWrt ImageBuilder with `CONFIG_TARGET_ROOTFS_INITRAMFS=y`**. Even
   forcing the kconfig flag, ImageBuilder only emits
   `*-squashfs-sysupgrade.bin`. `include/image.mk` skips the initramfs
   recipe entirely under `$(if $(IB),,…)`, again because there are no
   kernel sources to recompile.

The only viable path that survived investigation is a full OpenWrt
source-tree build (`make world`) with `CONFIG_INITRAMFS_SOURCE` pointing
at the LibreMesh CPIO. A prototype script (`build_image_source.sh`,
~780 lines) wired this up against `v24.10.6` with GHA caching; cold runs
took ~50–60 min, warm runs ~10–20 min. We discarded it because:

- LibreMesh CI testing on ath79 is not a release-blocker.
- The full source build dominates wall-clock time for the entire
  workflow, even when run in parallel with the other matrix entries.
- The maintenance surface (toolchain bumps, OpenWrt release tag drift,
  feed src-link plumbing, `libremesh.mk` symlink dance) is significant.

The prototype lives in the git history if it ever becomes worth
reviving.

## What it would take to fix each one

### librerouter_librerouter-v1

Resurrect the source-build path described above (or write a fresh one)
and wire it into `build-firmware.yml` as a separate job. Key inputs:

1. Check out `openwrt/openwrt` at the matching tag (`v24.10.6`).
2. `make defconfig` with `CONFIG_TARGET_ath79=y`,
   `CONFIG_TARGET_ath79_generic=y`,
   `CONFIG_TARGET_ath79_generic_DEVICE_librerouter_librerouter-v1=y`.
3. `CONFIG_TARGET_ROOTFS_INITRAMFS=y` and
   `CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y` (gzip works too on
   ath79 but lzma is the historical default and gives a smaller uImage).
4. Wire `pi-lime-packages` as a `src-link` feed and ensure
   `libremesh.mk` is reachable from `package/feeds/lime_packages/`
   (without it the `include ../../libremesh.mk` lookups in lime-proto-*
   / lime-hwd-* silently drop those packages from the kconfig).
5. `make -j$(nproc) world` — produces
   `bin/targets/ath79/generic/openwrt-*-librerouter_librerouter-v1-initramfs-kernel.bin`.

For local / manual labgrid runs in the meantime: build the artefact
with the procedure above (or grab a LibreMesh release matching the
target OpenWrt version), stage it on the testbed TFTP server, and run
`libremesh-tests` directly:

    labgrid-client -p labgrid-fcefyn-librerouter_1 acquire
    export LG_PLACE=labgrid-fcefyn-librerouter_1
    export LG_ENV=targets/librerouter_librerouter-v1.yaml
    export LG_IMAGE=/srv/tftp/firmwares/librerouter_librerouter-v1/libremesh/<artifact>.bin
    uv run python -m pytest tests/test_libremesh.py tests/test_base.py tests/test_lan.py -v --log-cli-level=INFO
    labgrid-client -p labgrid-fcefyn-librerouter_1 release

### linksys_e8450 legacy

Not worth fixing. The `-ubi` profile targets identical hardware with
better boot characteristics (atomic UBI volume swaps, recovery image)
and is the OpenWrt-recommended path going forward. We keep
`device: linksys_e8450` (so the labgrid place mapping still resolves
to `belkin_rt3200_2`) and only change `profile:` in `targets.yml`.

## See also

- `docs/ci/firmware-build.md` — high-level overview of the firmware
  build pipeline (what it builds and why).
- `tools/ci/build_image.sh` — the manual `mkimage` repack flow.
- `.github/ci/targets.yml` — `build_initramfs` / `test_firmware` keys.
- `.github/workflows/build-firmware.yml` — `targets_matrix` vs
  `test_targets_matrix` filtering.
