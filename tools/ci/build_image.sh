#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <imagebuilder> <profile> <openwrt_release> <feed_dir> <output_dir>" >&2
  exit 1
fi

IMAGEBUILDER="$1"
PROFILE="$2"
OPENWRT_RELEASE="$3"
FEED_DIR="$(realpath -m "$4")"
OUTPUT_DIR="$(realpath -m "$5")"

ARCH="${ARCH:?ARCH env var is required}"
FEED_BRANCH="${FEED_BRANCH:?FEED_BRANCH env var is required}"
PACKAGES="${PACKAGES:?PACKAGES env var is required}"

# When BUILD_INITRAMFS=1, build_image.sh repacks the ImageBuilder rootfs into a
# RAM-bootable image (kernel + LibreMesh CPIO ramdisk) and ships THAT as the
# firmware artifact. Targets that do not set this flag keep producing the
# squashfs-sysupgrade as their build artifact for IPK validation only; they
# are filtered out of the test-firmware matrix in `prepare-matrix`.
BUILD_INITRAMFS="${BUILD_INITRAMFS:-0}"

# Format of the repack output. Three paths are supported:
#
#   * `fit` (default): mediatek/filogic boards (openwrt_one, bananapi_bpi-r4,
#     linksys_e8450-ubi). U-Boot ≥2018 with `CONFIG_FIT=y` parses a single
#     `*-initramfs-libremesh.itb` file containing `kernel-1` (raw lzma) +
#     `fdt-1` (separate DTB) + `rootfs-1` (raw CPIO ramdisk) under one
#     configuration node, with `bootargs` embedded in the FIT config.
#
#   * `multi-uimage`: ath79 boards (librerouter_v1). U-Boot 1.1.x on
#     QCA9558 has no FIT parser but understands the legacy `IH_TYPE_MULTI`
#     uImage. The output is a single `*-initramfs-libremesh.uimage` whose
#     payload is `[kernel.lzma, rootfs.cpio]`: U-Boot's `bootm` decompresses
#     the first component to `FIT_KERNEL_LOADADDR` (because the outer
#     uImage carries `-C lzma`), keeps the second one in place, and tells
#     the MIPS kernel where the ramdisk lives via the `initrd_start` /
#     `initrd_size` PROM env vars (see arch/mips/.../prom.c). The DTB is
#     NOT a separate component because ath79 fuses it into kernel-bin via
#     the `append-dtb | lzma | uImage lzma` recipe; we ship the kernel
#     uImage's payload as-is and let the kernel parse its appended DTB at
#     decompression time. Bootargs cannot be embedded in a legacy uImage,
#     so the labgrid YAML must `setenv bootargs` before `bootm`.
#
#   * `x86-combined`: QEMU x86_64 (qemu_x86_64). ImageBuilder ships a
#     single `*-x86-64-generic-ext4-combined.img.gz` containing GRUB +
#     kernel + ext4 rootfs in one MBR-partitioned disk image — exactly
#     what `qemu-system-x86_64 -drive if=virtio,file=...,format=raw`
#     wants. There is NO RAM-bootable initramfs FIT involved (the QEMU
#     boot path runs full disk init, not TFTP), so build_image.sh
#     forbids `BUILD_INITRAMFS=1` for this format. The artifact
#     selection branch below ungzips the combined image so downstream
#     consumers (test-firmware-qemu) can mount/boot it directly without
#     a runtime gunzip step.
IMAGE_FORMAT="${IMAGE_FORMAT:-fit}"
case "${IMAGE_FORMAT}" in
  fit|multi-uimage|x86-combined) ;;
  *)
    echo "ERROR: invalid IMAGE_FORMAT=${IMAGE_FORMAT} (expected: fit | multi-uimage | x86-combined)" >&2
    exit 1
    ;;
esac

# Used only when BUILD_INITRAMFS=1. Filled per-target in
# .github/ci/targets.yml (fit_arch / fit_kernel_loadaddr / fit_dts /
# fit_config) and forwarded by build-firmware.yml.
FIT_ARCH="${FIT_ARCH:-}"
FIT_KERNEL_LOADADDR="${FIT_KERNEL_LOADADDR:-}"
# FIT_DTS is the *.dts basename whose compiled DTB lives at
# `${LINUX_DIR}/image-${FIT_DTS}.dtb`. Only meaningful for IMAGE_FORMAT=fit;
# ath79 boards (multi-uimage) have no separate DTB file (it is appended to
# kernel-bin at link time) so we leave this empty for them.
FIT_DTS="${FIT_DTS:-}"

# FIT_CONFIG: the FIT configuration node name embedded in the .itb. U-Boot
# resolves it at boot via `bootm $loadaddr#$bootconf`, where `$bootconf` is
# whatever the device's U-Boot env has saved. The upstream OpenWrt
# defaults set `bootconf=config-1` for openwrt_one and linksys_e8450-ubi
# (and `config-mt7988a-bananapi-bpi-r4` for bpi-r4). The matching
# libremesh-tests labgrid YAMLs unconditionally `setenv bootconf config-1`
# in U-Boot init_commands so the FIT we ship can use a single uniform
# config name across all targets — which is what the default value below
# encodes. Override per-target via `fit_config:` in targets.yml only if a
# specific board's U-Boot env cannot be touched at runtime.
FIT_CONFIG="${FIT_CONFIG:-config-1}"

# FIT_BOOTARGS: kernel command line to embed in the FIT configuration.
# CRITICAL: must NOT contain `root=...` for the initramfs to survive past
# /sbin/init. Background, paid for in CI test slots:
#
# OpenWrt's mediatek/filogic builds (openwrt_one, bananapi_bpi-r4) ship a
# device tree with chosen/bootargs that includes
#   `root=/dev/fit0 rootwait ubi.block=0,fit`
# pointing at the on-flash UBI `fit` volume's filesystem sub-image. When
# the kernel boots from our TFTP-loaded FIT, it correctly unpacks our
# initramfs CPIO ramdisk into rootfs (verified in dmesg:
# `Freeing initrd memory: 30076K`). It then walks the rootfs= cmdline
# arg, finds `/dev/fit0` available (the device's flash still has
# whatever vanilla OpenWrt was sysupgraded into the `fit` UBI volume),
# mounts THAT squashfs as `/`, and runs `/sbin/init` from FLASH — not
# from our LibreMesh initramfs.
#
# Symptom on openwrt_one: kernel says `Linux version 6.6.127` (our IB
# kernel), then mounts /dev/fit0 (vanilla 24.10.5 squashfs), then prints
# `kmodloader: no module folders for kernel version 6.6.127 found`
# (the flash rootfs has /lib/modules/6.6.119/, mismatch), then a vanilla
# OpenWrt 24.10.5 banner with hostname `(none)` and zero LibreMesh
# customizations.
# Symptom on bananapi_bpi-r4: same kernel cmdline, but the device's
# flash UBI has no valid `fit` volume, so `fitblk: probe of fitblk
# failed with error -2` and the kernel hangs forever in
# `Waiting for root device /dev/fit0...`.
#
# Embedding `bootargs` in the FIT configuration node makes U-Boot pass
# the override to the kernel's chosen/bootargs, and Linux then keeps
# the unpacked initramfs as `/` for the entire boot. The default below
# is the mediatek/filogic baseline (console + the standard pci tuning
# OpenWrt ships) MINUS the `root=...` part. Override per-target via
# `fit_bootargs:` in targets.yml only if a board needs different
# console settings (e.g. mt7622 uses 115200n8).
FIT_BOOTARGS="${FIT_BOOTARGS:-console=ttyS0,115200n1 pci=pcie_bus_perf}"

# DTB_PATCH_NVMEM_MAC: when "1", patch the device-tree blob shipped inside
# the FIT to inject `local-mac-address` properties into every GMAC and DSA
# port whose existing definition references a `nvmem-cell-names = "mac-address"`
# from a UBI factory volume. This is a workaround for OpenWrt issue #22858
# (NVMEM core perpetual `-EPROBE_DEFER` blocks fallback) which manifests
# on the Belkin RT3200 / Linksys E8450 (UBI variant): mtk_eth_soc.probe()
# stalls forever waiting on the UBI factory NVMEM provider, leaving the
# device with `platform 1b100000.ethernet: deferred probe pending` and
# no networking. Defaulted off for boards whose factory NVMEM does NOT
# come from a UBI volume (openwrt_one, bananapi_bpi-r4 — they read MAC
# from a fixed SPI-NOR partition that is alive long before mtk_eth_soc
# probes), since injecting a synthetic MAC there would override the OEM
# label MAC for no benefit.
DTB_PATCH_NVMEM_MAC="${DTB_PATCH_NVMEM_MAC:-0}"

# DTB_FORCE_LEGACY_PARTITIONS: when "1", rewrite the SPI-NAND
# partitioning of the FIT-shipped DTB to the legacy 23.05 layout
# (separate `bl2`, `fip`, `factory`, `ubi` MTD partitions) instead of
# the OpenWrt 24.10 all-UBI layout (`bl2` + `ubi`-with-volumes-inside).
# Required ONLY on linksys_e8450-ubi (Belkin RT3200) units that are
# physically still on layout 1.0: with the 24.10 DTS, the kernel
# attaches UBI starting at MTD offset 0x80000 and overwrites the
# on-flash BL31/FIP region (0x80000-0x1c0000) and the calibration
# `factory` region (0x1c0000-0x2c0000) with UBI EC headers, KOD'ing
# the device on the next power cycle (BL2 then fails to load BL31).
# After this patch the kernel UBI MTD is constrained to 0x300000+,
# matching where on-flash UBI volumes actually live, and
# fip/factory bytes are no longer reachable. See
# docs/followups/belkin_rt3200_layout_1_0_dtb_patch.md for the full
# diagnosis and the rationale for patching the FIT instead of
# migrating the hardware to layout 2.0.
#
# Defaulted off everywhere else: openwrt_one and bananapi_bpi-r4 do
# not use a UBI-on-NAND boot path and there is no `linux,ubi`
# partition for the patcher to find — the script would hard-fail.
DTB_FORCE_LEGACY_PARTITIONS="${DTB_FORCE_LEGACY_PARTITIONS:-0}"

if [[ "${BUILD_INITRAMFS}" == "1" && "${IMAGE_FORMAT}" == "x86-combined" ]]; then
  echo "ERROR: BUILD_INITRAMFS=1 is incompatible with IMAGE_FORMAT=x86-combined" >&2
  echo "       The combined disk image already carries GRUB + kernel + rootfs;" >&2
  echo "       there is no RAM-bootable FIT to repack." >&2
  exit 1
fi

if [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  required_vars=(FIT_ARCH FIT_KERNEL_LOADADDR FIT_CONFIG FIT_BOOTARGS)
  # FIT_DTS is only required for the FIT path: mediatek/filogic builds carry
  # a separate `image-${FIT_DTS}.dtb` next to the kernel, while ath79 fuses
  # the DTB into kernel-bin and leaves no standalone `.dtb` file we could
  # embed. Multi-uimage callers therefore legitimately leave it empty —
  # validating it would just trip the build with a misleading error.
  if [[ "${IMAGE_FORMAT}" == "fit" ]]; then
    required_vars+=(FIT_DTS)
  fi
  for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
      echo "ERROR: BUILD_INITRAMFS=1 (IMAGE_FORMAT=${IMAGE_FORMAT}) requires ${var} env var" >&2
      exit 1
    fi
  done
fi

# Resolve the location of the DTB patchers relative to this script.
# Both patchers live next to build_image.sh under tools/ci/ in the
# source tree, and we copy them into WORK_DIR below so they are
# reachable from inside the ImageBuilder container via the /work bind
# mount. patch_dtb_local_mac.py injects local-mac-address; patch_dtb_partitions.py
# rewrites the SPI-NAND partitioning to the legacy 23.05 layout.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DTB_PATCHER_HOST="${SCRIPT_DIR}/patch_dtb_local_mac.py"
DTB_PARTITIONS_PATCHER_HOST="${SCRIPT_DIR}/patch_dtb_partitions.py"
if [[ "${DTB_PATCH_NVMEM_MAC}" == "1" && ! -f "${DTB_PATCHER_HOST}" ]]; then
  echo "ERROR: DTB_PATCH_NVMEM_MAC=1 but ${DTB_PATCHER_HOST} not found" >&2
  exit 1
fi
if [[ "${DTB_FORCE_LEGACY_PARTITIONS}" == "1" && ! -f "${DTB_PARTITIONS_PATCHER_HOST}" ]]; then
  echo "ERROR: DTB_FORCE_LEGACY_PARTITIONS=1 but ${DTB_PARTITIONS_PATCHER_HOST} not found" >&2
  exit 1
fi

if [[ ! -d "${FEED_DIR}/lime_packages" ]]; then
  echo "ERROR: Feed dir must contain lime_packages/: ${FEED_DIR}/lime_packages" >&2
  exit 1
fi

# Package format dispatch. OpenWrt 24.10.x ships .ipk packages indexed
# by `Packages` / `Packages.gz` and managed by opkg. OpenWrt 25.12.x
# replaced opkg with apk-tools (Alpine package format), so the indexed
# file is `packages.adb` and ImageBuilder consumes the local feed via
# `--repository file:///<dir>/packages.adb` (see openwrt PR #18048).
# This script branches the repositories config, the pre-flight, and
# the `make image` flags off this single variable.
case "${OPENWRT_RELEASE}" in
  24.10.*) PKG_FORMAT=ipk ;;
  *)       PKG_FORMAT=apk ;;
esac
echo ">>> Package format for ${OPENWRT_RELEASE}: ${PKG_FORMAT}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "${WORK_DIR}/out" "${WORK_DIR}/keys" "${OUTPUT_DIR}"
chmod 0755 "${WORK_DIR}"

# Stage the DTB patchers inside WORK_DIR so the in-container repack
# step (which only sees /work and /feed) can invoke them. We always
# copy whichever script exists so a future build that flips
# DTB_PATCH_NVMEM_MAC=1 or DTB_FORCE_LEGACY_PARTITIONS=1 on the same
# checkout has the patcher available with no extra plumbing.
if [[ -f "${DTB_PATCHER_HOST}" ]]; then
  cp "${DTB_PATCHER_HOST}" "${WORK_DIR}/patch_dtb_local_mac.py"
  chmod 0755 "${WORK_DIR}/patch_dtb_local_mac.py"
fi
if [[ -f "${DTB_PARTITIONS_PATCHER_HOST}" ]]; then
  cp "${DTB_PARTITIONS_PATCHER_HOST}" "${WORK_DIR}/patch_dtb_partitions.py"
  chmod 0755 "${WORK_DIR}/patch_dtb_partitions.py"
fi

# repositories.snippet: appended to the IB's repositories config.
#
# - opkg (24.10.x): file is `repositories.conf`. Each line of the
#   form `src/gz <name> <url>` adds an opkg feed. We add both the
#   bind-mounted local feed and the upstream LibreMesh remote.
#   The `lime_packages_local` name has to match
#   `feed.libremesh.org/master/<branch>/<arch>` only by convention;
#   opkg keys feeds by their unique `<name>` token.
#
# - apk (25.12+): file is `repositories` (no .conf). apk-tools accepts
#   one URL per line (no `src/gz` keyword), and absolute file:// URLs
#   are required (see openwrt#18032 / PR#18048). For the local feed
#   we point at the indexed packages.adb directly. The remote line
#   uses the same `packages.adb` path the upstream feed serves.
if [[ "${PKG_FORMAT}" == "ipk" ]]; then
  cat > "${WORK_DIR}/repositories.snippet" <<EOF
src/gz lime_packages_local file:///feed/lime_packages
src/gz libremesh https://feed.libremesh.org/master/${FEED_BRANCH}/${ARCH}
EOF
else
  cat > "${WORK_DIR}/repositories.snippet" <<EOF
file:///feed/lime_packages/packages.adb
https://feed.libremesh.org/master/${FEED_BRANCH}/${ARCH}/packages.adb
EOF
fi

cat > "${WORK_DIR}/keys/a71b3c8285abd28b" <<'EOF'
untrusted comment: signed by libremesh.org key a71b3c8285abd28b
RWSnGzyChavSiyQ+vLk3x7F0NqcLa4kKyXCdriThMhO78ldHgxGljM/8
EOF

IMAGE_TAG="ghcr.io/openwrt/imagebuilder:${IMAGEBUILDER}-v${OPENWRT_RELEASE}"
echo ">>> Building ${PROFILE} with ${IMAGE_TAG} (BUILD_INITRAMFS=${BUILD_INITRAMFS})"

# Make sure container 'buildbot' user (uid 1000) can read the bind-mounted files.
chmod -R a+rX "${WORK_DIR}" "${FEED_DIR}"
chmod a+w "${WORK_DIR}/out"

# Export every variable consumed by the in-container script so `-e VAR`
# (no =value) forwards a real value. Local shell vars are NOT in the
# process env unless exported, and Docker's `-e VAR` reads from the
# calling process env, not from the script's lexical scope.
export BUILD_INITRAMFS IMAGE_FORMAT FIT_ARCH FIT_KERNEL_LOADADDR FIT_DTS \
       FIT_CONFIG FIT_BOOTARGS DTB_PATCH_NVMEM_MAC \
       DTB_FORCE_LEGACY_PARTITIONS PROFILE PACKAGES \
       ARCH OPENWRT_RELEASE PKG_FORMAT

# When PKG_FORMAT=apk we may need to (re)generate `packages.adb`
# inside the IB if the assemble step produced .apk packages but no
# index. Mount /feed read-write to let the in-container apk-tools
# refresh the index in place. For PKG_FORMAT=ipk the index is
# already on disk (Packages + Packages.gz) and a read-only mount
# matches the historical behavior.
if [[ "${PKG_FORMAT}" == "apk" ]]; then
  FEED_MOUNT_FLAGS=":rw"
else
  FEED_MOUNT_FLAGS=":ro"
fi

docker run --rm \
  --user root \
  -e BUILD_INITRAMFS \
  -e IMAGE_FORMAT \
  -e FIT_ARCH \
  -e FIT_KERNEL_LOADADDR \
  -e FIT_DTS \
  -e FIT_CONFIG \
  -e FIT_BOOTARGS \
  -e DTB_PATCH_NVMEM_MAC \
  -e DTB_FORCE_LEGACY_PARTITIONS \
  -e PROFILE \
  -e PACKAGES \
  -e ARCH \
  -e OPENWRT_RELEASE \
  -e PKG_FORMAT \
  -v "${WORK_DIR}:/work" \
  -v "${FEED_DIR}:/feed${FEED_MOUNT_FLAGS}" \
  "${IMAGE_TAG}" \
  sh -lc '
    set -e
    cp /work/keys/* keys/ 2>/dev/null || true

    if [ "${PKG_FORMAT}" = "ipk" ]; then
      # opkg config lives in repositories.conf. Drop the
      # `option check_signature` line so opkg-lede does not reject our
      # unsigned local feed; opkg-lede ignores the *value* of that
      # option (any presence enables verification), so the only way
      # to keep it off is to remove the line outright.
      sed -i "/^option check_signature/d" repositories.conf
      cat /work/repositories.snippet >> repositories.conf

      echo "=== final repositories.conf ==="
      cat repositories.conf
      echo "=== mounted feed contents (/feed/lime_packages) ==="
      ls -la /feed/lime_packages/ | head -40
      feed_ipks=$(find /feed/lime_packages -maxdepth 1 -name "*.ipk" | wc -l)
      feed_pkgs=$(grep -c "^Package:" /feed/lime_packages/Packages 2>/dev/null || echo 0)
      echo "Feed has ${feed_ipks} IPKs and ${feed_pkgs} Packages entries"

      # Pre-flight: confirm opkg can actually see the local feed before
      # we spend ~30 min on `make image`. If `lime-system` is not
      # visible after `opkg update`, failing here is far cheaper than
      # failing at the very end of package_install with no diagnostic
      # context.
      mkdir -p /tmp/preflight/tmp /tmp/preflight-lists
      /builder/staging_dir/host/bin/opkg \
        --offline-root /tmp/preflight \
        --add-arch all:100 \
        --add-arch "${ARCH}:200" \
        -f /builder/repositories.conf \
        --cache /tmp/preflight-cache \
        --lists-dir /tmp/preflight-lists \
        update >/tmp/preflight.log 2>&1 || true
      echo "=== opkg pre-flight update (last 25 lines) ==="
      tail -n 25 /tmp/preflight.log
      if ! /builder/staging_dir/host/bin/opkg \
          --offline-root /tmp/preflight \
          --add-arch all:100 \
          --add-arch "${ARCH}:200" \
          -f /builder/repositories.conf \
          --cache /tmp/preflight-cache \
          --lists-dir /tmp/preflight-lists \
          list 2>/dev/null | grep -q "^lime-system "; then
        echo "ERROR: opkg cannot see lime-system in any configured feed" >&2
        /builder/staging_dir/host/bin/opkg \
          --offline-root /tmp/preflight \
          --add-arch all:100 \
          --add-arch "${ARCH}:200" \
          -f /builder/repositories.conf \
          --cache /tmp/preflight-cache \
          --lists-dir /tmp/preflight-lists \
          list 2>/dev/null | grep -E "^(lime|shared-state|babeld-auto|check-date|batctl)" >&2 || true
        exit 1
      fi
      echo "=== Pre-flight OK: local feed is visible to opkg ==="

      make image PROFILE="${PROFILE}" BIN_DIR=/work/out PACKAGES="${PACKAGES}"

    else
      # apk-tools (OpenWrt 25.12+). Config file is `repositories`
      # (no .conf). Each line is a single repo URL; no `src/gz`
      # keyword. Absolute `file://` URLs are required for local
      # feeds since openwrt#18032 / PR#18048.
      cat /work/repositories.snippet >> repositories

      echo "=== final repositories ==="
      cat repositories
      echo "=== mounted feed contents (/feed/lime_packages) ==="
      ls -la /feed/lime_packages/ | head -40
      feed_apks=$(find /feed/lime_packages -maxdepth 1 -name "*.apk" | wc -l)
      echo "Feed has ${feed_apks} APKs"

      # Locate the apk binary (host path varies between OpenWrt
      # 25.12 RCs and final). Probe a few well-known spots and the
      # PATH; bail out with diagnostics if absent.
      APK=""
      for cand in \
        /builder/staging_dir/host/usr/bin/apk \
        /builder/staging_dir/host/bin/apk \
        /builder/staging_dir/hostpkg/usr/bin/apk \
        /usr/bin/apk \
        $(command -v apk 2>/dev/null || true)
      do
        if [ -n "$cand" ] && [ -x "$cand" ]; then
          APK="$cand"; break
        fi
      done
      if [ -z "$APK" ]; then
        echo "ERROR: cannot locate apk binary in the IB" >&2
        find /builder/staging_dir/host -maxdepth 4 -name apk 2>/dev/null >&2 || true
        exit 1
      fi
      echo "Using apk binary: $APK"

      # Regenerate packages.adb in place if the assemble step did
      # not ship one (defense in depth: the workflow always indexes,
      # but a future code path that bypasses the assemble step would
      # otherwise silently fail at make image time).
      # apk 3.x removed `--no-keychain`; the working idiom for
      # unsigned local feeds is the global `--allow-untrusted` flag
      # BEFORE the sub-command.
      if [ ! -f /feed/lime_packages/packages.adb ]; then
        echo ">>> packages.adb missing — generating with the IB-host apk"
        cd /feed/lime_packages
        help_text=$("$APK" --help 2>&1 || true)
        if printf "%s\n" "$help_text" | grep -qw mkndx; then
          "$APK" --allow-untrusted mkndx --output packages.adb -- *.apk
        elif printf "%s\n" "$help_text" | grep -qw index; then
          "$APK" --allow-untrusted index --output packages.adb *.apk
        else
          "$APK" --allow-untrusted mkndx --output packages.adb -- *.apk
        fi
        cd /builder
      fi

      # apk pre-flight: ensure lime-system is resolvable from the
      # configured repositories. We use `apk list` against an empty
      # offline root: if the index is broken or the repository entry
      # is malformed, this returns no rows and we abort early.
      # `--allow-untrusted` skips signature verification (our local
      # feed is unsigned and we did not add the LibreMesh signing
      # key for the apk-tools keystore yet).
      mkdir -p /tmp/preflight
      "$APK" \
        --root /tmp/preflight \
        --no-cache \
        --allow-untrusted \
        --repositories-file /builder/repositories \
        --repository /feed/lime_packages/packages.adb \
        update >/tmp/preflight.log 2>&1 || true
      echo "=== apk pre-flight update (last 25 lines) ==="
      tail -n 25 /tmp/preflight.log || true
      if ! "$APK" \
          --root /tmp/preflight \
          --no-cache \
          --allow-untrusted \
          --repositories-file /builder/repositories \
          --repository /feed/lime_packages/packages.adb \
          list lime-system 2>/dev/null | grep -q "^lime-system-"; then
        echo "WARNING: apk pre-flight could not list lime-system" >&2
        echo "(non-fatal: apk-tools list semantics are looser than opkg; we proceed and let make image surface any real error)" >&2
      else
        echo "=== Pre-flight OK: local feed is visible to apk ==="
      fi

      # `make image` for 25.12 ImageBuilder. APK_FLAGS is forwarded
      # to every `apk` invocation under the hood and must include:
      #   --allow-untrusted: our local feed is not signed.
      #   --repository file:///feed/lime_packages/packages.adb:
      #     ensures the local feed is queried in addition to whatever
      #     the IB Makefile defaults to (it adds /builder/packages
      #     automatically; we are appending, not replacing).
      make image \
        PROFILE="${PROFILE}" \
        BIN_DIR=/work/out \
        PACKAGES="${PACKAGES}" \
        APK_FLAGS="--allow-untrusted --repository file:///feed/lime_packages/packages.adb"
    fi

    echo "=== /work/out contents (post make image) ==="
    ls -la /work/out/
    find /work/out -type f -printf "%p (%s bytes)\n"

    # ------------------------------------------------------------------
    # Optional: repack a true RAM-bootable initramfs FIT containing the
    # LibreMesh rootfs we just installed.
    #
    # Why this is needed (and why the obvious alternative does not work):
    # ImageBuilder ships pre-built device kernel binaries
    # (`<profile>-kernel.bin`, gzip-compressed for the sysupgrade FIT)
    # and DTBs (`image-<dts>.dtb`), but it does NOT ship kernel sources
    # nor a re-packable initramfs FIT for arbitrary devices. `make image`
    # with `CONFIG_TARGET_ROOTFS_INITRAMFS=y` on an IB does not regenerate
    # `staging_dir/.../<board>-initramfs*.itb` — empirically verified by
    # SHA-comparing the staging FIT before and after the make. The
    # staging FIT, when present, contains the upstream OpenWrt rootfs
    # CPIO (vanilla), not our LibreMesh one. So even if we copied it
    # verbatim, the testbed would boot vanilla 24.10.6 and the tests
    # would silently pass against the wrong firmware.
    #
    # The fix is to assemble the FIT ourselves from the bits ImageBuilder
    # already produced for `make image`:
    #   1. Pre-built kernel binary       <build_dir>/linux-*/<profile>-kernel.bin
    #      (gzip-compressed; we set `compression=gzip` in the FIT and let
    #      U-Boot/Linux decompress at boot).
    #   2. Pre-built DTB                 <build_dir>/linux-*/image-<dts>.dtb
    #   3. Freshly-installed rootfs      <build_dir>/root-*/  (LibreMesh)
    #      packed as a gzip-CPIO via `find . | cpio -o -H newc | gzip`.
    #
    # Then we feed the three files to `scripts/mkits.sh` (ships in IB)
    # to generate a .its source, and to `mkimage -f` (also ships in IB)
    # to produce the final .itb. `dtc` is required by mkimage internally
    # and is provided by the kernel source unpacked under
    # `linux-*/linux-<kver>/scripts/dtc/dtc` after `make image`.
    if [ "${BUILD_INITRAMFS:-0}" = "1" ]; then
      echo "=== Repacking initramfs FIT (RAM-bootable, embedded LibreMesh) ==="

      # Locate per-target build_dir entries. ImageBuilder uses exactly
      # one `target-<arch>_musl/` per container; inside, exactly one
      # `linux-<sub>/` (kernel) and one `root-<sub>/` (rootfs).
      ARCH_DIR="$(echo /builder/build_dir/target-*_musl)"
      if [ ! -d "${ARCH_DIR}" ]; then
        echo "ERROR: cannot locate target-<arch>_musl under /builder/build_dir" >&2
        ls -la /builder/build_dir >&2 || true
        exit 1
      fi
      LINUX_DIR="$(ls -d ${ARCH_DIR}/linux-*/ 2>/dev/null | head -n 1 | sed "s|/$||")"
      # IMPORTANT: ImageBuilder names the rootfs staging dir after the BOARD
      # (target name), not the subtarget. For mediatek/filogic the dir is
      # `root-mediatek` (NOT `root-mediatek_filogic`). A bare `root-*` glob
      # also matches `root.orig-<board>` which is the pristine pre-package
      # snapshot kept around by IB for diff debugging — it has only base
      # files (~999 entries) and NONE of our lime-* / kmod-* installed,
      # which would silently produce a "vanilla OpenWrt" CPIO and a DUT
      # that boots with empty /lib/modules/<kver>/ and hostname (none).
      # We exclude root.orig-* explicitly to avoid that.
      ROOT_DIR="$(ls -d ${ARCH_DIR}/root-*/ 2>/dev/null \
                  | grep -v "/root\.orig-" \
                  | head -n 1 | sed "s|/$||")"
      if [ ! -d "${LINUX_DIR}" ] || [ ! -d "${ROOT_DIR}" ]; then
        echo "ERROR: cannot locate linux-* / root-* under ${ARCH_DIR}" >&2
        ls -la "${ARCH_DIR}" >&2 || true
        exit 1
      fi
      echo "  linux build dir: ${LINUX_DIR}"
      echo "  rootfs dir     : ${ROOT_DIR}"

      # Pre-CPIO sanity dump. The CI bug we are chasing is "DUT boots,
      # kernel unpacks initramfs, but kmodloader complains
      # `no module folders for kernel version 6.6.127 found` and hostname
      # stays at `(none)` — which means the rootfs we packed is missing
      # /lib/modules/<kver>/ and /etc/uci-defaults/ ran but produced no
      # hostname". By printing the rootfs snapshot here, the failure is
      # caught at build time (cheap) instead of at TFTP-boot time (slow,
      # requires hardware).
      ROOTFS_FILES="$(find "${ROOT_DIR}" -mindepth 1 2>/dev/null | wc -l)"
      ROOTFS_BYTES="$(du -sb "${ROOT_DIR}" 2>/dev/null | cut -f1)"
      ROOTFS_HUMAN="$(du -sh "${ROOT_DIR}" 2>/dev/null | cut -f1)"
      echo "  rootfs entries : ${ROOTFS_FILES}"
      echo "  rootfs size    : ${ROOTFS_HUMAN} (${ROOTFS_BYTES} bytes)"
      echo "  /lib/modules/* :"
      ls -la "${ROOT_DIR}/lib/modules" 2>/dev/null | head -10 || \
        echo "    (no /lib/modules — kmod packages were not installed!)"
      echo "  kmod .ko count :"
      ko_count=$(find "${ROOT_DIR}/lib/modules" -name "*.ko" 2>/dev/null | wc -l)
      echo "    ${ko_count} .ko files"
      echo "  /etc/banner    :"
      head -3 "${ROOT_DIR}/etc/banner" 2>/dev/null || echo "    (no banner)"
      echo "  /etc/uci-defaults entries:"
      ls "${ROOT_DIR}/etc/uci-defaults" 2>/dev/null | head -20 || \
        echo "    (no uci-defaults dir)"
      echo "  lime-system traces:"
      find "${ROOT_DIR}" -maxdepth 5 -path "*/lime/*" 2>/dev/null | head -10 || true
      # Hard-fail if kmod count or rootfs is implausibly small. Empirical
      # baseline on mediatek/filogic openwrt_one with the LibreMesh
      # PACKAGES list: ~1100 entries, ~28 MiB, ~120 .ko files. We pick
      # safe lower bounds well below that to catch a clearly-broken
      # rootfs without false-positive on minor PACKAGES tweaks.
      if [ "${ROOTFS_FILES:-0}" -lt 800 ] || [ "${ko_count}" -lt 30 ]; then
        echo "ERROR: rootfs at ${ROOT_DIR} is implausibly small (${ROOTFS_FILES} entries, ${ko_count} .ko)" >&2
        echo "       This is the same failure mode that boots with kmodloader" >&2
        echo "       complaining \"no module folders for kernel version found\"" >&2
        echo "       and hostname (none) — caught at build time instead of" >&2
        echo "       wasting a hardware test slot on it." >&2
        exit 1
      fi

      KERNEL_BIN="${LINUX_DIR}/${PROFILE}-kernel.bin"
      if [ ! -f "${KERNEL_BIN}" ]; then
        echo "ERROR: missing ${KERNEL_BIN}" >&2
        ls -la "${LINUX_DIR}" >&2 | head -40
        exit 1
      fi
      echo "  kernel-bin     : ${KERNEL_BIN} ($(stat -c%s "${KERNEL_BIN}") bytes)"
      # The kernel-bin format depends on the target subtarget recipe — and
      # therefore on IMAGE_FORMAT in our pipeline:
      #
      #   * mediatek/filogic (IMAGE_FORMAT=fit): KERNEL is the raw vmlinux
      #     gzip-compressed once (`kernel-bin | gzip`). The FIT we build
      #     wraps it under `compression = "gzip"` and U-Boots fitImage
      #     loader decompresses at boot. Magic bytes: `1f 8b 08 ..`.
      #
      #   * ath79 (IMAGE_FORMAT=multi-uimage): KERNEL is a legacy uImage
      #     wrapping an lzma-compressed `kernel + appended DTB`
      #     (`kernel-bin | append-dtb | lzma | uImage lzma`). Magic bytes:
      #     `27 05 19 56`. We will strip the 64-byte uImage header below
      #     to recover the inner lzma blob and feed it to mkimage in
      #     multi-image mode.
      #
      # Validate the magic per-format so a future ImageBuilder rev that
      # changes the wrapper (e.g. switches the gzip compression to xz)
      # fails loudly here instead of producing a silently non-bootable
      # FIT / uImage.
      kernel_magic=$(od -An -tx1 -N4 "${KERNEL_BIN}" | tr -d " ")
      case "${IMAGE_FORMAT}" in
        fit)
          if [ "${kernel_magic}" != "1f8b0800" ]; then
            echo "ERROR: ${KERNEL_BIN} is not a gzip stream (magic=${kernel_magic}, expected 1f8b0800)" >&2
            echo "       The FIT path expects the mediatek/filogic kernel-bin gzip recipe output." >&2
            exit 1
          fi
          ;;
        multi-uimage)
          if [ "${kernel_magic}" != "27051956" ]; then
            echo "ERROR: ${KERNEL_BIN} is not a uImage (magic=${kernel_magic}, expected 27051956)" >&2
            echo "       The multi-uimage path expects the ath79 lzma+uImage lzma recipe output." >&2
            exit 1
          fi
          ;;
      esac

      # The DTB lookup is FIT-only: ath79 (multi-uimage) fuses the DTB into
      # kernel-bin via `append-dtb | lzma | uImage lzma` upstream, so there
      # is no standalone `image-*.dtb` to grab. Same for `dtc`, which is
      # only needed when we actually patch a DTB or hand a DTS to mkits.
      DTB_FILE=""
      DTC_BIN=""
      DTC_DIR=""
      if [ "${IMAGE_FORMAT}" = "fit" ]; then
        DTB_FILE="${LINUX_DIR}/image-${FIT_DTS}.dtb"
        if [ ! -f "${DTB_FILE}" ]; then
          echo "ERROR: missing ${DTB_FILE}" >&2
          ls "${LINUX_DIR}" 2>/dev/null | grep -E "\.dtb$" >&2 | head -40
          exit 1
        fi

        # `dtc` is required by mkimage to compile the .its (DTS source)
        # into a FIT (DTB). It is built as part of the kernel unpack and
        # lives at linux-*/linux-<kver>/scripts/dtc/dtc.
        DTC_BIN="$(find ${LINUX_DIR} -name dtc -type f -executable 2>/dev/null | head -n 1)"
        if [ -z "${DTC_BIN}" ] || [ ! -x "${DTC_BIN}" ]; then
          echo "ERROR: cannot find dtc under ${LINUX_DIR}" >&2
          find "${LINUX_DIR}" -name dtc -type f 2>/dev/null >&2 || true
          exit 1
        fi
        DTC_DIR="$(dirname "${DTC_BIN}")"
        echo "  using dtc      : ${DTC_BIN}"
      else
        echo "  IMAGE_FORMAT   : multi-uimage (no separate DTB; ath79 appends DTB to kernel-bin)"
      fi

      REPACK_DIR="/tmp/initramfs-repack"
      rm -rf "${REPACK_DIR}"
      mkdir -p "${REPACK_DIR}"

      # ------------------------------------------------------------------
      # Optional DTB patches. Two independent transforms can be applied
      # in series to the FIT-shipped DTB; each is gated by its own
      # env-var flag and either may be off, but both share the dtc
      # round-trip (decompile -> text edit -> recompile).
      #
      # 1) DTB_PATCH_NVMEM_MAC=1 (workaround openwrt#22858):
      #    Inject `local-mac-address` into GMAC / DSA-WAN nodes whose
      #    stock DTS pulls the MAC from a UBI factory NVMEM cell.
      #    `nvmem_cell_get()` returns `-EPROBE_DEFER` perpetually for
      #    UBI-backed providers, blocking mtk_eth_soc.probe and
      #    leaving the device with no ethernet at all (`platform
      #    1b100000.ethernet: deferred probe pending`). Adding a DT
      #    property short-circuits the NVMEM lookup entirely (the
      #    kernel `of_get_mac_address()` helper checks DT properties
      #    before falling back to NVMEM) and unblocks probe.
      #    Implemented by /work/patch_dtb_local_mac.py.
      #
      # 2) DTB_FORCE_LEGACY_PARTITIONS=1 (workaround Belkin layout-1.0
      #    KOD): rewrite the SPI-NAND `partitions { ... }` block from
      #    the OpenWrt 24.10 all-UBI shape to the legacy 23.05 layout
      #    (separate `bl2` + `fip` + `factory` + `ubi` partitions,
      #    ubi starting at MTD offset 0x300000). Required on Belkin
      #    RT3200 units that are still on layout 1.0: with the 24.10
      #    DTS, the kernel attaches UBI from offset 0x80000 onward
      #    and overwrites BL31/FIP and the factory calibration
      #    region with UBI EC headers, KODing the device on the
      #    next power cycle. Implemented by
      #    /work/patch_dtb_partitions.py. See
      #    docs/followups/belkin_rt3200_layout_1_0_dtb_patch.md for
      #    the full diagnosis.
      #
      # Implementation: a single dtc -I dtb -O dts decompile, then
      # patcher chain over the resulting DTS text, then dtc -I dts -O dtb
      # recompile. dtc is the in-tree binary we located above. The
      # patchers live at /work/patch_dtb_local_mac.py and
      # /work/patch_dtb_partitions.py (both staged by the host side
      # of build_image.sh into WORK_DIR before docker run, see the
      # `cp ... patch_dtb_*.py` block).
      #
      # NOTE: comments in this section MUST avoid literal apostrophes,
      # since the whole block lives inside a `sh -lc "..."`-style
      # single-quoted argument and a stray apostrophe would terminate
      # the quoting and reparent the rest of the script to the outer
      # bash. Use plain English (e.g. "the kernel helper" instead of
      # "kernel apostrophe s helper") and double quotes for inline
      # quoting if needed.
      DTB_NEEDS_PATCH=0
      if [ "${DTB_PATCH_NVMEM_MAC:-0}" = "1" ]; then DTB_NEEDS_PATCH=1; fi
      if [ "${DTB_FORCE_LEGACY_PARTITIONS:-0}" = "1" ]; then DTB_NEEDS_PATCH=1; fi

      if [ "${IMAGE_FORMAT}" = "fit" ] && [ "${DTB_NEEDS_PATCH}" = "1" ]; then
        if ! command -v python3 >/dev/null 2>&1; then
          echo "ERROR: DTB patching requires python3 inside the ImageBuilder container" >&2
          exit 1
        fi
        DTB_DTS_ORIG="${REPACK_DIR}/$(basename "${DTB_FILE}").orig.dts"
        DTB_DTS_STAGE1="${REPACK_DIR}/$(basename "${DTB_FILE}").stage1.dts"
        DTB_DTS_STAGE2="${REPACK_DIR}/$(basename "${DTB_FILE}").stage2.dts"
        DTB_PATCHED="${REPACK_DIR}/$(basename "${DTB_FILE}")"
        # dtc decompiles the DTB into DTS we can grep/patch. -q
        # because the IB-shipped DTBs sometimes encode reg without a
        # leading `0x` and dtc warns about it loudly; the warnings are
        # harmless and pollute the CI log.
        "${DTC_BIN}" -I dtb -O dts -q -o "${DTB_DTS_ORIG}" "${DTB_FILE}"
        # Stage 1: local-mac-address injection. Bypass step:
        # `cp` the original DTS unchanged when the flag is off.
        # `--require-patch` makes the build fail loudly if the DTS
        # no longer contains the GMAC / WAN nodes the patcher knows
        # about (e.g. a future kernel rev renames `mac@0` to
        # `port@0` under `&eth`); a silent pass would ship a
        # still-broken firmware.
        if [ "${DTB_PATCH_NVMEM_MAC:-0}" = "1" ]; then
          if [ ! -f /work/patch_dtb_local_mac.py ]; then
            echo "ERROR: DTB_PATCH_NVMEM_MAC=1 but /work/patch_dtb_local_mac.py is missing" >&2
            ls -la /work >&2 || true
            exit 1
          fi
          echo "=== Patching DTB stage 1: local-mac-address (workaround openwrt#22858) ==="
          python3 /work/patch_dtb_local_mac.py "${PROFILE}" \
            --in "${DTB_DTS_ORIG}" --out "${DTB_DTS_STAGE1}" --require-patch
        else
          cp "${DTB_DTS_ORIG}" "${DTB_DTS_STAGE1}"
        fi
        # Stage 2: SPI-NAND partitioning rewrite. Bypass step:
        # `cp` the stage-1 DTS unchanged when the flag is off. The
        # patcher hard-fails if the input DTS is already on layout
        # 1.0 (no `linux,ubi` partition to find) or if dtc dropped
        # the factory cell labels — both conditions would silently
        # ship a half-broken DTB without this guard.
        if [ "${DTB_FORCE_LEGACY_PARTITIONS:-0}" = "1" ]; then
          if [ ! -f /work/patch_dtb_partitions.py ]; then
            echo "ERROR: DTB_FORCE_LEGACY_PARTITIONS=1 but /work/patch_dtb_partitions.py is missing" >&2
            ls -la /work >&2 || true
            exit 1
          fi
          echo "=== Patching DTB stage 2: legacy 23.05 SPI-NAND partitioning ==="
          python3 /work/patch_dtb_partitions.py \
            --in "${DTB_DTS_STAGE1}" --out "${DTB_DTS_STAGE2}"
        else
          cp "${DTB_DTS_STAGE1}" "${DTB_DTS_STAGE2}"
        fi
        "${DTC_BIN}" -I dts -O dtb -q -o "${DTB_PATCHED}" "${DTB_DTS_STAGE2}"
        echo "  patched DTB    : ${DTB_PATCHED} ($(stat -c%s "${DTB_PATCHED}") bytes; original $(stat -c%s "${DTB_FILE}") bytes)"
        # Sanity: with stage 1 only (local-mac-address inject) we
        # only ADD properties, so the patched DTB must be at least
        # as large as the original. With stage 2 active we REPLACE
        # the partitioning block, so a small shrink is legitimate
        # (the all-UBI block declares more nested volumes than the
        # 23.05 layout uses). We therefore only enforce the
        # "patched >= original" guard when stage 2 is OFF; with
        # stage 2 on, we accept any non-empty output. The
        # round-tripped recompile already crashes if the DTS is
        # malformed, which is the actual failure mode worth
        # catching.
        orig_sz=$(stat -c%s "${DTB_FILE}")
        new_sz=$(stat -c%s "${DTB_PATCHED}")
        if [ "${DTB_FORCE_LEGACY_PARTITIONS:-0}" != "1" ] && [ "${new_sz}" -lt "${orig_sz}" ]; then
          echo "ERROR: patched DTB shrunk from ${orig_sz} to ${new_sz} bytes — refusing to ship" >&2
          exit 1
        fi
        if [ "${new_sz}" -lt 1024 ]; then
          echo "ERROR: patched DTB is implausibly small (${new_sz} bytes) — dtc likely dropped data" >&2
          exit 1
        fi
        DTB_FILE="${DTB_PATCHED}"
      elif [ "${IMAGE_FORMAT}" != "fit" ] && [ "${DTB_NEEDS_PATCH}" = "1" ]; then
        # The DTB patchers only know how to operate on a free-standing
        # DTB file. ath79 multi-uimage builds bake the DTB into the
        # lzma kernel blob, so there is no DTB we could
        # decompile/patch/recompile here. Surface the misconfiguration
        # instead of silently shipping an unpatched image.
        echo "ERROR: DTB patching is incompatible with IMAGE_FORMAT=${IMAGE_FORMAT}" >&2
        echo "       (the DTB is fused inside kernel-bin and cannot be patched offline)" >&2
        echo "       DTB_PATCH_NVMEM_MAC=${DTB_PATCH_NVMEM_MAC:-0} DTB_FORCE_LEGACY_PARTITIONS=${DTB_FORCE_LEGACY_PARTITIONS:-0}" >&2
        exit 1
      else
        echo "=== Skipping DTB patch (DTB_PATCH_NVMEM_MAC=${DTB_PATCH_NVMEM_MAC:-0} DTB_FORCE_LEGACY_PARTITIONS=${DTB_FORCE_LEGACY_PARTITIONS:-0}) ==="
      fi

      # Build initramfs CPIO. Running as root inside the container so
      # device nodes (/dev/console etc.) and setuid bits inside the
      # rootfs are preserved by `cpio -H newc`. `find -print` order
      # matches the canonical kernel initramfs convention.
      #
      # The CPIO is NOT gzip-compressed on purpose. ImageBuilder ships
      # the sysupgrade-mode kernel for these mediatek targets
      # (linksys_e8450-ubi, openwrt_one, bananapi_bpi-r4): a single
      # binary that normally boots from /dev/fit0 on flash, with
      # CONFIG_RD_GZIP / CONFIG_RD_LZ4 / CONFIG_RD_XZ disabled (those
      # only get enabled in the dedicated KERNEL_INITRAMFS recipe,
      # which ImageBuilder does not run because it has no kernel
      # toolchain). Feeding a gzipped CPIO through bootm makes the
      # kernel print "Initramfs unpacking failed: compression method
      # gzip not configured" and silently fall back to mounting
      # root=/dev/fit0 — i.e. it boots whatever vanilla OpenWrt was
      # last sysupgraded to flash, which is the exact bug we saw in
      # CI (the device greeted us with the OpenWrt 23.05.5 banner
      # instead of LibreMesh).
      #
      # A raw CPIO sidesteps that path entirely: the first bytes
      # carry the newc magic 070701, the kernel initramfs unpacker
      # consumes them with no compression module, and procd from our
      # LibreMesh rootfs takes over. The size penalty is bounded —
      # the squashfs-decompressed rootfs is ~25 MiB on these targets,
      # well under the 512 MiB / 1 GiB / 2 GiB DRAM available, and
      # TFTP throughput is unaffected on the gigabit lab network.
      # Embed a build marker in the rootfs so the booted DUT can prove
      # which artifact actually loaded. Without this, "device shows
      # vanilla OpenWrt banner" is ambiguous: it could mean (a) our FIT
      # never booted and the device fell back to flash, or (b) our FIT
      # booted but the rootfs is missing LibreMesh customizations.
      # Comparing /etc/lime-build-marker on the DUT against this CI
      # build_id distinguishes them in a single grep.
      BUILD_MARKER="ci-${OPENWRT_RELEASE:-unknown}-${PROFILE}-$(date -u +%Y%m%dT%H%M%SZ)"
      mkdir -p "${ROOT_DIR}/etc"
      printf "%s\n" "${BUILD_MARKER}" > "${ROOT_DIR}/etc/lime-build-marker"
      echo "  build marker   : ${BUILD_MARKER}"

      # Add /init -> /sbin/init symlink to the rootfs.
      #
      # Required for an initramfs CPIO boot. When the kernel finishes
      # populate_rootfs() it goes to kernel_init_freeable(), which
      # checks ramdisk_execute_command (default "/init") via sys_access.
      # If /init exists, the kernel execs it as PID 1 and the in-RAM
      # rootfs IS the runtime root (exactly what we want). If /init
      # is missing the kernel falls through to prepare_namespace()
      # which tries to mount root= from the cmdline; with no root=
      # (our setup, intentionally) the cmdline root is empty and the
      # kernel panics with:
      #   /dev/root: Cannot open root device "" or unknown-block(0,0)
      #   Kernel panic - not syncing: VFS: Unable to mount root fs
      # which is what bit us in CI run 24973793128 (bananapi_bpi-r4):
      # initramfs unpacked successfully (33 MiB freed), bootargs were
      # ours (no root=), but no /init in the CPIO -> panic.
      #
      # OpenWrts ImageBuilder produces the squashfs-sysupgrade rootfs
      # without /init because squashfs is always mounted as root via
      # root=/dev/fit0 by the upstream bootloader, and the standard
      # init path /sbin/init is invoked by prepare_namespace after
      # the rootfs mount. For initramfs builds OpenWrts upstream
      # include/image.mk explicitly creates a symlink before cpio-packing:
      #   ln -sf /sbin/init $(KERNEL_BUILD_DIR)/cpiogz/init
      # We replicate that exact step here. Idempotent: -f overwrites
      # any existing /init from a previous repack iteration in the
      # same staging dir.
      #
      # NOTE on switch_root: upstreams modern Kernel/CompileImage/Initramfs
      # actually copies target/linux/generic/other-files/init (a tiny
      # script that exports INITRAMFS=1 and `exec switch_root /new_root
      # /sbin/init`). That avoids fstools mount_root probing the on-flash
      # UBI rootfs_data and triggering "pivot_root failed: Invalid
      # argument" / "BUG: no suitable fs found" messages on hardware that
      # has a leftover overlay. We tried that route in commit f333b66 but
      # had to revert: ImageBuilder ships a busybox compiled WITHOUT the
      # `switch_root` applet (CONFIG_BUSYBOX_CONFIG_SWITCH_ROOT is off
      # upstream and util-linuxs switch_root is `-Dbuild-pivot_root=disabled`
      # in the OpenWrt Makefile, see
      # https://git.openwrt.org/openwrt/openwrt/tree/?&path=package/utils/util-linux/Makefile),
      # and rebuilding busybox isnt possible from inside ImageBuilder.
      # The mount_root probe is harmless on devices whose YAML wipes the
      # `rootfs_data` UBI volume in init_commands BEFORE bootm
      # (see openwrt_one.yaml / linksys_e8450.yaml `ubi remove
      # rootfs_data || true`). New targets MUST do the same in their
      # labgrid YAML or they will boot LibreMesh but stall at
      # `root@(none):~#` because uci-defaults never run after the
      # mount_root failure cascade.
      ln -sf /sbin/init "${ROOT_DIR}/init"
      echo "  /init symlink  :"
      ls -la "${ROOT_DIR}/init"
      if [ ! -L "${ROOT_DIR}/init" ]; then
        echo "ERROR: ${ROOT_DIR}/init is not a symlink after ln -sf" >&2
        exit 1
      fi
      if [ ! -e "${ROOT_DIR}/sbin/init" ] && [ ! -L "${ROOT_DIR}/sbin/init" ]; then
        echo "ERROR: ${ROOT_DIR}/sbin/init does not exist; /init -> /sbin/init will dangle" >&2
        ls -la "${ROOT_DIR}/sbin/" 2>/dev/null | head -20 >&2 || true
        exit 1
      fi

      echo "  packing rootfs CPIO from ${ROOT_DIR}"
      ( cd "${ROOT_DIR}" && \
        find . | /builder/staging_dir/host/bin/cpio -o -H newc 2>/dev/null ) \
          > "${REPACK_DIR}/rootfs.cpio"
      ls -la "${REPACK_DIR}/rootfs.cpio"
      # Sanity: a healthy uncompressed CPIO of this rootfs should be
      # close to the source size (newc adds <5% overhead). A drastic
      # shrink would indicate cpio errored out silently or only a
      # subset of files was packed. Same applies for outright tiny
      # outputs (a few MiB), which would point at the exact bug we just
      # caught: gzip pipe sneaking back in or a wrong ROOT_DIR pick.
      cpio_bytes=$(stat -c%s "${REPACK_DIR}/rootfs.cpio")
      echo "  cpio size      : $((cpio_bytes / 1024 / 1024)) MiB (${cpio_bytes} bytes) vs rootfs ${ROOTFS_HUMAN}"
      # Magic: newc CPIO archives always start with the ASCII bytes
      # `070701`. Catching anything else (e.g. `1f 8b` for gzip,
      # `28 b5 2f fd` for zstd) at this stage prevents the kernel-side
      # "Initramfs unpacking failed: compression method X not configured"
      # silent fallback to flash that bit us before the gzip-pipe fix.
      cpio_magic=$(head -c 6 "${REPACK_DIR}/rootfs.cpio")
      if [ "${cpio_magic}" != "070701" ]; then
        echo "ERROR: rootfs.cpio has unexpected magic \"${cpio_magic}\" (expected 070701 newc)" >&2
        head -c 16 "${REPACK_DIR}/rootfs.cpio" | od -c | head >&2
        exit 1
      fi
      cpio_min=$((ROOTFS_BYTES * 80 / 100))
      if [ "${cpio_bytes}" -lt "${cpio_min}" ]; then
        echo "ERROR: cpio size ${cpio_bytes} is <80% of rootfs ${ROOTFS_BYTES} — likely truncated/compressed" >&2
        exit 1
      fi
      echo "  cpio file types (top 10):"
      /builder/staging_dir/host/bin/cpio -tv < "${REPACK_DIR}/rootfs.cpio" 2>/dev/null \
        | awk "{print \$1}" | sort | uniq -c | sort -rn | head -10 || true

      # Confirm /init landed in the CPIO. We use `cpio -t` (without -v)
      # which prints one path per line — this avoids the regex landmine
      # we hit in the previous iteration: GNU cpio bundled with OpenWrt
      # buildroot strips the leading `./` in `cpio -tv` listings, so a
      # pattern anchored on `./init` matches nothing even when the file
      # is present (we observed exactly that in CI run 24974719437,
      # where the rootfs went from 243 to 244 symlinks confirming the
      # /init entry, but the verifier still aborted). `cpio -t` gives
      # us deterministic paths to grep -Fx against, no escaping needed.
      # If no match, the kernel will panic at runtime with VFS: Unable
      # to mount root fs (see ln -sf rationale block above).
      # NOTE: no single quotes here. The whole script body is wrapped
      # in `sh -lc \x27...\x27` so a literal apostrophe terminates the
      # wrapper. Use double quotes and escape the regex backslashes.
      echo "  /init in CPIO  :"
      init_paths="$(/builder/staging_dir/host/bin/cpio -t < "${REPACK_DIR}/rootfs.cpio" 2>/dev/null \
                    | grep -E "^(\\./)?init$" || true)"
      if [ -z "${init_paths}" ]; then
        echo "ERROR: /init is missing from rootfs.cpio" >&2
        echo "       Without /init the kernel will fall through to prepare_namespace()" >&2
        echo "       and panic with \"Unable to mount root fs on unknown-block(0,0)\"." >&2
        echo "       cpio -t entries ending in init:" >&2
        /builder/staging_dir/host/bin/cpio -t < "${REPACK_DIR}/rootfs.cpio" 2>/dev/null \
          | grep -E "(^|/)init$" | head -20 >&2 || true
        exit 1
      fi
      echo "    ${init_paths}"

      if [ "${IMAGE_FORMAT}" = "fit" ]; then
      # Generate the .its source describing the FIT structure
      # (kernel + DTB + ramdisk).
      #
      # NOTE: avoid apostrophes in this block of comments. The whole
      # script is wrapped in a single-quoted argument to "sh -lc", so
      # any literal apostrophe (e.g. "devices") closes the wrapper
      # prematurely and the rest of the script is parsed by the OUTER
      # bash with a different argv0. See git blame: a "device s" typo
      # caused an "U-Boot: 162: Syntax error" CI failure once.
      #
      # The FIT config name MUST match the bootconf env variable that
      # U-Boot resolves at "bootm $loadaddr#$bootconf" time. The upstream
      # OpenWrt U-Boot defaults pin bootconf per-device:
      #   openwrt_one         -> config-1
      #   linksys_e8450-ubi   -> config-1
      #   bananapi_bpi-r4     -> config-mt7988a-bananapi-bpi-r4
      # Rather than per-device-tuning the FIT layout, the libremesh-tests
      # labgrid YAMLs (targets/openwrt_one.yaml, targets/linksys_e8450.yaml,
      # targets/bananapi_bpi-r4.yaml) issue an explicit
      # "setenv bootconf ${FIT_CONFIG}" in the U-Boot init_commands of every
      # test run, so the FIT we ship can carry a single uniform config
      # name. FIT_CONFIG defaults to "config-1" in build_image.sh; override
      # via fit_config: in .github/ci/targets.yml only if a board cannot
      # accept a runtime bootconf override.
      PATH="${DTC_DIR}:${PATH}" /builder/scripts/mkits.sh \
        -A "${FIT_ARCH}" \
        -C gzip \
        -a "${FIT_KERNEL_LOADADDR}" \
        -e "${FIT_KERNEL_LOADADDR}" \
        -c "${FIT_CONFIG}" \
        -v "OpenWrt LibreMesh ${PROFILE}" \
        -k "${KERNEL_BIN}" \
        -D "${PROFILE}" \
        -d "${DTB_FILE}" \
        -i "${REPACK_DIR}/rootfs.cpio" \
        -o "${REPACK_DIR}/initramfs.its"

      # Inject `bootargs = "${FIT_BOOTARGS}";` into the FIT configuration
      # node. mkits.sh (OpenWrts upstream helper script) does not expose
      # any flag for kernel command line in the configuration: it only
      # writes kernel/fdt/ramdisk references. Without a bootargs property
      # in the .itss configurations/${FIT_CONFIG} block, U-Boot falls
      # back to whatever chosen/bootargs the device tree carries — and
      # for mediatek/filogic that is the upstream OpenWrt
      #   `... root=/dev/fit0 rootwait ubi.block=0,fit`
      # which makes the kernel discard our successfully-unpacked
      # initramfs and mount the on-flash UBI fit volume as / instead
      # (and on bpi-r4 hangs forever because no fit volume exists).
      # Diagnosed in CI run 24973793128 (bananapi_bpi-r4) and
      # 24972903707 (openwrt_one).
      #
      # We post-process the .its with sed: inside the address range
      # bracketed by `^${FIT_CONFIG} {` ... `^};`, we replace the closing
      # `};` with `bootargs = "..."; \n };`. The address range bound is
      # strict (anchored to start-of-line + literal `{`/`};`) so the
      # match cannot leak into other blocks (kernel-1, fdt-1, initrd-1,
      # nor the `default = "config-1";` line whose substring also says
      # `config-1`).
      echo "=== Injecting bootargs=\"${FIT_BOOTARGS}\" into FIT config ${FIT_CONFIG} ==="
      sed -i "/^[[:space:]]*${FIT_CONFIG} {[[:space:]]*\$/,/^[[:space:]]*};[[:space:]]*\$/ s|^\\([[:space:]]*\\)};[[:space:]]*\$|\\1        bootargs = \"${FIT_BOOTARGS}\";\\n\\1};|" "${REPACK_DIR}/initramfs.its"

      # Sanity-check the injection landed exactly once and inside the
      # expected configuration block. Failure here is hard-fail because
      # silently shipping a FIT without bootargs lands us right back in
      # the "kernel boots vanilla OpenWrt from flash" rabbit hole that
      # cost us run 24972903707.
      bootargs_count=$(grep -c "bootargs = \"${FIT_BOOTARGS}\";" "${REPACK_DIR}/initramfs.its" || true)
      if [ "${bootargs_count}" -ne 1 ]; then
        echo "ERROR: bootargs injection produced ${bootargs_count} matches in initramfs.its (expected exactly 1)" >&2
        echo "----- initramfs.its (configurations section) -----" >&2
        sed -n "/configurations {/,/^};/p" "${REPACK_DIR}/initramfs.its" >&2 || true
        exit 1
      fi
      echo "  bootargs injected: ${bootargs_count} occurrence(s) (expected 1) — OK"
      echo "----- initramfs.its configurations block -----"
      sed -n "/configurations {/,/^};/p" "${REPACK_DIR}/initramfs.its"

      # Compile the .its into a real FIT.
      PATH="${DTC_DIR}:${PATH}" /builder/staging_dir/host/bin/mkimage \
        -f "${REPACK_DIR}/initramfs.its" \
        "${REPACK_DIR}/initramfs-libremesh.itb"

      # Land the FIT in BIN_DIR alongside ImageBuilder outputs so the
      # downstream artifact selection picks it up. Naming mirrors the
      # OpenWrt convention so it is obvious which file is the real
      # bootable image vs. the harmless sysupgrade sidecar.
      INITRAMFS_OUT="/work/out/openwrt-${OPENWRT_RELEASE:-}-${PROFILE}-initramfs-libremesh.itb"
      cp "${REPACK_DIR}/initramfs-libremesh.itb" "${INITRAMFS_OUT}"
      echo "=== Initramfs FIT generated (FIT_CONFIG=${FIT_CONFIG}) ==="
      ls -la "${INITRAMFS_OUT}"
      /builder/staging_dir/host/bin/mkimage -l "${INITRAMFS_OUT}" \
        | grep -E "Image |Type:|Compression:|Data Size|Architecture|Load Address|Entry Point|Configuration |Kernel:|FDT:|Init Ramdisk:" || true
      # Sanity check: confirm mkits.sh embedded our FIT_CONFIG. The .its
      # we just generated declares default = "<FIT_CONFIG>"; the .itb
      # is its mkimage output. Grepping the .its avoids parsing
      # mkimage -l (which prints config names enclosed in apostrophes
      # and would close the surrounding sh -lc single-quoted wrapper)
      # while still catching the failure mode that produced the original
      # CI bug: "Could not find configuration node" at U-Boot bootm
      # because the FIT config name silently drifted from FIT_CONFIG.
      if ! grep -q "default = \"${FIT_CONFIG}\"" "${REPACK_DIR}/initramfs.its"; then
        echo "ERROR: initramfs.its has no default config = \"${FIT_CONFIG}\"" >&2
        head -80 "${REPACK_DIR}/initramfs.its" >&2 || true
        exit 1
      fi
      else
        # ----------------------------------------------------------------
        # multi-uimage path (ath79 / librerouter_v1).
        #
        # LibreRouter v1 ships an Atheros QCA9558 SoC running a U-Boot
        # 1.1.x fork (see https://github.com/LibreRouterOrg/u-boot ;
        # `common/cmd_bootm.c` and `lib_mips/mips_linux.c`). That U-Boot
        # has NO FIT parser, but it does support legacy uImage
        # `IH_TYPE_MULTI`, which packs an arbitrary number of sub-images
        # behind a single 64-byte mkimage header followed by a length
        # table. `bootm` on a multi-uimage:
        #   * decompresses sub-image 0 according to the OUTER headers
        #     compression byte and treats it as the kernel image,
        #   * keeps sub-image 1 verbatim and exposes its physical
        #     location to the kernel via the PROM env vars
        #     `initrd_start` / `initrd_size`, which the OpenWrt MIPS
        #     prom code (arch/mips/.../prom.c) parses into the standard
        #     `initrd_start`/`initrd_end` Linux symbols.
        #
        # The OpenWrt ath79 recipe for sysupgrade is
        #   `kernel-bin | append-dtb | lzma | uImage lzma`
        # i.e. the DTB is APPENDED to the kernel ELF inside the lzma
        # blob, so when we extract the `<profile>-kernel.bin` payload we
        # already have a self-contained `kernel+DTB` lzma stream. There
        # is no separate DTB to ship, hence FIT_DTS is unused on this
        # path (and we elided the DTB lookup above).
        #
        # The repack steps:
        #   1. Strip the 64-byte uImage header from `<profile>-kernel.bin`
        #      to recover the raw lzma payload (the inner blob carries
        #      `5d 00 00 80 00` lzma magic).
        #   2. Use mkimage in multi-image mode with `-C lzma` so U-Boot
        #      decompresses sub-image 0 to FIT_KERNEL_LOADADDR. Sub-image
        #      1 is the rootfs CPIO we already produced (raw newc; no
        #      compression applied because the kernel initramfs unpacker
        #      handles raw CPIO directly and ath79 builds rarely ship
        #      RD_GZIP support in this branch — same rationale as the
        #      mediatek/filogic FIT path above).
        #   3. The kernel cmdline cannot live inside a legacy uImage.
        #      The labgrid YAML for LibreRouter must `setenv bootargs`
        #      before `bootm` (init_commands).
        # ----------------------------------------------------------------
        echo "=== Building multi-uimage (kernel.lzma + rootfs.cpio) for ath79 ==="
        # Extract the raw lzma payload from the uImage. mkimage prepends
        # exactly 64 bytes (`struct image_header`); `dd bs=1 skip=64` is
        # portable and matches OpenWrts own `unwrap_uimage` recipe.
        # We sanity-check the lzma magic afterwards so a future kernel
        # binary that switches compression (e.g. `xz`) does not get
        # silently shipped under a `-C lzma` claim.
        KERNEL_LZMA="${REPACK_DIR}/kernel.lzma"
        dd if="${KERNEL_BIN}" of="${KERNEL_LZMA}" bs=1 skip=64 status=none
        kernel_lzma_size=$(stat -c%s "${KERNEL_LZMA}")
        # Cross-check the strip yielded the data length advertised by the
        # uImage header. We compare against the human-readable line that
        # `mkimage -l` prints (`Data Size:   <N> Bytes`); that avoids
        # depending on od endianness flags whose availability differs
        # across busybox and coreutils builds inside the IB container.
        uimage_data_line=$(/builder/staging_dir/host/bin/mkimage -l "${KERNEL_BIN}" 2>/dev/null \
                           | awk -F"[: ]+" "/Data Size/ {print \$3; exit}")
        if [ -n "${uimage_data_line}" ] && [ "${kernel_lzma_size}" -ne "${uimage_data_line}" ]; then
          echo "ERROR: stripped lzma size ${kernel_lzma_size} != uImage data length ${uimage_data_line}" >&2
          exit 1
        fi
        # Sanity-check the payload is a real lzma1 stream and not some
        # other compression format snuck in by an ImageBuilder rev.
        #
        # OpenWrts upstream Build/lzma recipe runs the lzma binary with
        # `-lc1 -lp2 -pb2`, NOT the canonical lc=3/lp=0/pb=2 used by
        # most lzma tutorials. The first byte of an lzma1 stream encodes
        # the properties as `(pb*5 + lp)*9 + lc`, so OpenWrts kernels
        # start with `(2*5+2)*9 + 1 = 109 = 0x6d` (NOT 0x5d, which
        # would be the canonical setting). Property bytes for lzma1
        # are bounded at 224 (0xe0) by the spec, so we accept the full
        # valid range and only reject magics of competing formats:
        #   * 0x1f -> gzip   (`1f 8b 08 ..`)
        #   * 0xfd -> xz     (`fd 37 7a 58 5a`)
        #   * 0x28 -> zstd   (`28 b5 2f fd`)
        #   * 0x42 -> bzip2  (`BZh`)
        # An out-of-range first byte (>0xe0) also indicates a non-lzma1
        # payload — bail early so the actual lzma decoder failure at
        # boot does not leave us hunting in dmesg.
        # Read the first byte twice: once in hex (for case-arm pattern
        # matching against well-known competing-format magics, and for
        # error message formatting) and once in unsigned decimal (for
        # the numeric range comparison below). Doing the hex-to-decimal
        # conversion via `od -tu1` instead of `$((16#NN))` keeps us
        # compatible with the BusyBox / dash that ImageBuilders
        # `sh -lc` resolves to: ash does NOT implement bashs
        # `BASE#VALUE` arithmetic extension and aborts the script with
        # `arithmetic expression: expecting EOF: "16#6d"` (witnessed in
        # CI run 25021369701, librerouter_librerouter-v1 build).
        kernel_lzma_first=$(od -An -tx1 -N1 "${KERNEL_LZMA}" | tr -d " ")
        kernel_lzma_first_dec=$(od -An -tu1 -N1 "${KERNEL_LZMA}" | tr -d " ")
        case "${kernel_lzma_first}" in
          1f|fd|28|42)
            echo "ERROR: kernel payload after uImage strip starts with 0x${kernel_lzma_first} (gzip/xz/zstd/bzip2 magic, not lzma1)" >&2
            echo "       OpenWrt ath79 expects an lzma1-compressed kernel (kernel-bin then append-dtb then lzma then uImage lzma)." >&2
            exit 1
            ;;
        esac
        if [ "${kernel_lzma_first_dec}" -gt 224 ]; then
          echo "ERROR: kernel payload first byte 0x${kernel_lzma_first} (${kernel_lzma_first_dec}) exceeds lzma1 property byte max (224)" >&2
          exit 1
        fi
        echo "  kernel.lzma    : ${KERNEL_LZMA} (${kernel_lzma_size} bytes, first byte 0x${kernel_lzma_first})"

        # mkimage `-T multi` reads sub-images from a colon-separated
        # path list (`a:b:c`). The compression flag `-C lzma` applies
        # to sub-image 0 (the kernel); the remaining sub-images are
        # stored verbatim — exactly what we need for the raw CPIO
        # rootfs in slot 1.
        UIMAGE_OUT="${REPACK_DIR}/initramfs-libremesh.uimage"
        /builder/staging_dir/host/bin/mkimage \
          -A "${FIT_ARCH}" \
          -O linux \
          -T multi \
          -C lzma \
          -a "${FIT_KERNEL_LOADADDR}" \
          -e "${FIT_KERNEL_LOADADDR}" \
          -n "OpenWrt LibreMesh ${PROFILE} initramfs" \
          -d "${KERNEL_LZMA}:${REPACK_DIR}/rootfs.cpio" \
          "${UIMAGE_OUT}"

        echo "=== multi-uimage generated ==="
        ls -la "${UIMAGE_OUT}"
        /builder/staging_dir/host/bin/mkimage -l "${UIMAGE_OUT}" \
          | grep -E "Image |Type:|Compression:|Data Size|Architecture|Load Address|Entry Point|Image [0-9]+:" || true

        # Sanity: confirm the final image announces itself as
        # `Multi-File Image` so a downstream reader can spot a regression
        # the moment mkimages `-T` argument silently changes.
        if ! /builder/staging_dir/host/bin/mkimage -l "${UIMAGE_OUT}" \
            | grep -qE "(Image Type|Type:).*Multi[- ]File"; then
          echo "ERROR: ${UIMAGE_OUT} is not a multi-file uImage" >&2
          /builder/staging_dir/host/bin/mkimage -l "${UIMAGE_OUT}" >&2 || true
          exit 1
        fi

        INITRAMFS_OUT="/work/out/openwrt-${OPENWRT_RELEASE:-}-${PROFILE}-initramfs-libremesh.uimage"
        cp "${UIMAGE_OUT}" "${INITRAMFS_OUT}"
        echo "=== Initramfs multi-uimage exported ==="
        ls -la "${INITRAMFS_OUT}"
      fi
    else
      echo "=== Skipping initramfs repack (BUILD_INITRAMFS=0) ==="
      echo "Target will ship the squashfs-sysupgrade artifact and is filtered out of the test-firmware matrix."
    fi
  '

echo "=== Selecting firmware artifact for ${PROFILE} ==="
ls -la "${WORK_DIR}/out/" || true

# Hard-fail if the produced image is not actually a LibreMesh build.
#
# ImageBuilder writes a `*.manifest` file alongside each image with the full
# list of installed packages (one `<name> <version>` per line). When PACKAGES
# resolution fails silently (DEPENDS conflict, opkg error swallowed by SDK,
# etc.) make image can still emit a vanilla OpenWrt initramfs and the test
# job ends up booting that, producing the elusive `root@OpenWrt`/`root@(none)`
# prompt instead of `root@LiMe-XXXXXX`. We detect that here, before the
# initramfs leaves this job, by grepping the manifest for the LibreMesh core
# packages we explicitly listed in PACKAGES.
MANIFEST_FILE="$(compgen -G "${WORK_DIR}/out/*${PROFILE}*.manifest" 2>/dev/null | head -n 1 || true)"
if [[ -z "${MANIFEST_FILE}" || ! -f "${MANIFEST_FILE}" ]]; then
  echo "::error::ImageBuilder produced no .manifest for ${PROFILE} — cannot verify LibreMesh content" >&2
  find "${WORK_DIR}/out" -maxdepth 1 -type f -printf '  %p (%s bytes)\n' >&2 || true
  exit 1
fi
echo "=== Manifest: ${MANIFEST_FILE} ==="
echo "Total packages in manifest: $(wc -l < "${MANIFEST_FILE}")"
required_pkgs=(lime-system lime-proto-batadv lime-proto-anygw batctl-default)
missing=()
for pkg in "${required_pkgs[@]}"; do
  if ! grep -qE "^${pkg} " "${MANIFEST_FILE}"; then
    missing+=("${pkg}")
  fi
done
if (( ${#missing[@]} > 0 )); then
  echo "::error::Image manifest is missing required LibreMesh packages: ${missing[*]}" >&2
  echo "This means make image silently dropped them despite the opkg pre-flight pass." >&2
  echo "=== Manifest contents (lime/shared-state/batctl entries) ===" >&2
  grep -E '^(lime|shared-state|batctl|babeld|firewall)' "${MANIFEST_FILE}" >&2 || true
  echo "=== First 40 manifest lines ===" >&2
  head -n 40 "${MANIFEST_FILE}" >&2 || true
  exit 1
fi
echo ">>> Manifest validation OK: lime-system + lime-proto-batadv + lime-proto-anygw + batctl-default present"
grep -E '^(lime-|shared-state-|batctl|babeld|firewall4)' "${MANIFEST_FILE}" || true

# Pick the artifact we will ship to test-firmware.
#
# When BUILD_INITRAMFS=1 we look for the artifact we just repacked. Its
# extension depends on IMAGE_FORMAT:
#
#   * fit          -> `*-initramfs-libremesh.itb` (mediatek/filogic).
#                     Rootfs lives inside the FIT as a raw CPIO ramdisk
#                     under `rootfs-1`; bootargs are embedded in the
#                     `${FIT_CONFIG}` configuration node.
#   * multi-uimage -> `*-initramfs-libremesh.uimage` (ath79).
#                     Rootfs is sub-image 1 of a legacy multi-file
#                     uImage; bootargs are set by the labgrid YAML via
#                     `setenv bootargs` before `bootm` (cannot be
#                     embedded in a non-FIT uImage).
#
# When BUILD_INITRAMFS=0 we fall back to the sysupgrade artifact
# (`*-squashfs-sysupgrade.{itb,bin}`). This branch is only used by
# targets we explicitly opted out of test-firmware, so the artifact is
# carried purely for IPK validation and never TFTP-booted.
SOURCE_FILE=""
if [[ "${IMAGE_FORMAT}" == "x86-combined" ]]; then
  # ImageBuilder's x86-64/generic recipe outputs the combined image
  # gzip-compressed (`*-ext4-combined.img.gz`) plus an uncompressed
  # `*-rootfs.tar.gz` and a separate `*-kernel.bin`. We want the
  # combined disk image: it carries GRUB + kernel + ext4 rootfs in one
  # MBR-partitioned blob that QEMU boots directly with
  # `-drive if=virtio,format=raw`. We `gunzip -k` (keep) the .gz so
  # downstream consumers do not need to handle compression at boot
  # time, and keep the rest of the staging dir intact for debug.
  combined_gz="$(compgen -G "${WORK_DIR}/out/*ext4-combined.img.gz" 2>/dev/null | head -n 1 || true)"
  if [[ -z "${combined_gz}" ]]; then
    echo "::error::IMAGE_FORMAT=x86-combined: no *ext4-combined.img.gz under ${WORK_DIR}/out." >&2
    echo "       Confirm the x86-64/generic ImageBuilder profile produced the combined recipe." >&2
    find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
    exit 1
  fi
  combined_img="${combined_gz%.gz}"
  if [[ ! -f "${combined_img}" ]]; then
    gunzip -kc "${combined_gz}" > "${combined_img}"
  fi
  SOURCE_FILE="${combined_img}"
  echo ">>> Matched x86-combined image: ${combined_gz} -> ${SOURCE_FILE} (gunzip)"
elif [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  case "${IMAGE_FORMAT}" in
    fit)          initramfs_patterns=("*${PROFILE}-initramfs-libremesh.itb" "*${PROFILE}*initramfs-libremesh.itb") ;;
    multi-uimage) initramfs_patterns=("*${PROFILE}-initramfs-libremesh.uimage" "*${PROFILE}*initramfs-libremesh.uimage") ;;
  esac
  for pattern in "${initramfs_patterns[@]}"; do
    match="$(compgen -G "${WORK_DIR}/out/${pattern}" 2>/dev/null | head -n 1 || true)"
    if [[ -n "${match}" && -f "${match}" ]]; then
      SOURCE_FILE="${match}"
      echo ">>> Matched initramfs pattern '${pattern}' -> ${SOURCE_FILE}"
      break
    fi
  done
  if [[ -z "${SOURCE_FILE}" ]]; then
    echo "::error::BUILD_INITRAMFS=1 (IMAGE_FORMAT=${IMAGE_FORMAT}) was set but no initramfs artifact found in ${WORK_DIR}/out." >&2
    echo "The mkimage repack step likely failed silently. /work/out contents:" >&2
    find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
    exit 1
  fi
else
  for pattern in \
    "*${PROFILE}*-squashfs-sysupgrade.itb" \
    "*${PROFILE}*-squashfs-sysupgrade.bin" \
    "*${PROFILE}*-sysupgrade.bin"; do
    match="$(compgen -G "${WORK_DIR}/out/${pattern}" 2>/dev/null | head -n 1 || true)"
    if [[ -n "${match}" && -f "${match}" ]]; then
      SOURCE_FILE="${match}"
      echo ">>> Matched sysupgrade pattern '${pattern}' -> ${SOURCE_FILE} (build-image-only target, not TFTP-booted)"
      break
    fi
  done
  if [[ -z "${SOURCE_FILE}" ]]; then
    echo "::error::No sysupgrade artifact found for ${PROFILE} despite a successful make image." >&2
    find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
    exit 1
  fi
fi

# Extension preservation. For most cases `.itb` / `.bin` / `.uimage`
# falls out of `${SOURCE_FILE##*.}` as-is. The x86-combined case is a
# trap: the source basename ends in `.img` AFTER the `gunzip -k`, but
# without explicit handling a `${SOURCE_FILE##*.}` against the original
# `*.img.gz` would emit `firmware-<dev>.gz` (wrong: clients would try
# to gunzip an already-decompressed file). We anchor the extension on
# the ungzipped `combined_img` path explicitly.
DEVICE_NAME="${DEVICE_NAME:-${PROFILE}}"
if [[ "${IMAGE_FORMAT}" == "x86-combined" ]]; then
  EXTENSION="img"
else
  EXTENSION="${SOURCE_FILE##*.}"
fi
TARGET_FILE="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.${EXTENSION}"
cp "${SOURCE_FILE}" "${TARGET_FILE}"

# Ship the manifest with the firmware so test-firmware (and downstream
# debugging) can answer "what packages are inside this image?" without
# rerunning the whole build. Same basename, .manifest extension.
MANIFEST_TARGET="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.manifest"
cp "${MANIFEST_FILE}" "${MANIFEST_TARGET}"

echo ">>> Firmware output: ${TARGET_FILE} ($(stat -c%s "${TARGET_FILE}") bytes)"
echo ">>> Manifest output: ${MANIFEST_TARGET} ($(wc -l < "${MANIFEST_TARGET}") packages)"
echo ">>> Firmware sha256: $(sha256sum "${TARGET_FILE}" | cut -d' ' -f1)"
