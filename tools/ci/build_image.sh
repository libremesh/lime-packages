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

# BUILD_INITRAMFS=1 repacks the ImageBuilder rootfs into a RAM-bootable
# kernel+CPIO image and ships THAT as the firmware artifact. Otherwise the
# squashfs-sysupgrade is uploaded for IPK validation only.
BUILD_INITRAMFS="${BUILD_INITRAMFS:-0}"

# fit          -> kernel + DTB + CPIO under one FIT config (mediatek/filogic).
# multi-uimage -> legacy IH_TYPE_MULTI uImage (ath79 boards w/o FIT).
# x86-combined -> ImageBuilder's GRUB+kernel+ext4 disk image (QEMU x86_64).
# dual-tftp    -> kernel.bin + rootfs.uimage (uImage-wrapped CPIO) as TWO
#                 separate files (ath79 LibreRouter: U-Boot TFTP-loads each
#                 to a distinct RAM address; `bootm <kernel> <ramdisk>`).
IMAGE_FORMAT="${IMAGE_FORMAT:-fit}"
case "${IMAGE_FORMAT}" in
  fit|multi-uimage|x86-combined|dual-tftp) ;;
  *)
    echo "ERROR: invalid IMAGE_FORMAT=${IMAGE_FORMAT} (expected: fit | multi-uimage | x86-combined | dual-tftp)" >&2
    exit 1
    ;;
esac

FIT_ARCH="${FIT_ARCH:-}"
FIT_KERNEL_LOADADDR="${FIT_KERNEL_LOADADDR:-}"
FIT_DTS="${FIT_DTS:-}"
FIT_CONFIG="${FIT_CONFIG:-config-1}"
# CRITICAL: FIT_BOOTARGS must NOT contain `root=...`; the upstream
# mediatek/filogic chosen/bootargs has `root=/dev/fit0 rootwait ubi.block=0,fit`
# which would mount the on-flash squashfs over our initramfs.
FIT_BOOTARGS="${FIT_BOOTARGS:-console=ttyS0,115200n1 pci=pcie_bus_perf}"

# Patch the FIT-shipped DTB to inject local-mac-address (workaround for
# openwrt#22858) on boards whose OEM MAC lives in a UBI factory volume.
DTB_PATCH_NVMEM_MAC="${DTB_PATCH_NVMEM_MAC:-0}"

# Rewrite SPI-NAND partitioning to the legacy 23.05 layout (separate
# bl2/fip/factory/ubi MTDs) on Belkin RT3200 layout 1.0 units; without it
# the kernel UBI MTD overwrites BL31/FIP and bricks the device.
DTB_FORCE_LEGACY_PARTITIONS="${DTB_FORCE_LEGACY_PARTITIONS:-0}"

if [[ "${BUILD_INITRAMFS}" == "1" && "${IMAGE_FORMAT}" == "x86-combined" ]]; then
  echo "ERROR: BUILD_INITRAMFS=1 is incompatible with IMAGE_FORMAT=x86-combined" >&2
  exit 1
fi

if [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  # dual-tftp ships kernel.bin + rootfs.cpio as separate TFTP artifacts;
  # no FIT/uImage repacking, so FIT_* vars are not required.
  if [[ "${IMAGE_FORMAT}" != "dual-tftp" ]]; then
    required_vars=(FIT_ARCH FIT_KERNEL_LOADADDR FIT_CONFIG FIT_BOOTARGS)
    # ath79 (multi-uimage) fuses the DTB into kernel-bin so FIT_DTS is empty.
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
fi

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

# 24.10.x = .ipk + opkg + Packages[.gz]; 25.12.x = .apk + apk-tools +
# packages.adb. Branches downstream config and `make image` flags.
case "${OPENWRT_RELEASE}" in
  24.10.*) PKG_FORMAT=ipk ;;
  *)       PKG_FORMAT=apk ;;
esac
echo ">>> Package format for ${OPENWRT_RELEASE}: ${PKG_FORMAT}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "${WORK_DIR}/out" "${WORK_DIR}/keys" "${OUTPUT_DIR}"
chmod 0755 "${WORK_DIR}"

# Stage the DTB patchers in WORK_DIR; the in-container repack step
# only sees /work and /feed.
if [[ -f "${DTB_PATCHER_HOST}" ]]; then
  cp "${DTB_PATCHER_HOST}" "${WORK_DIR}/patch_dtb_local_mac.py"
  chmod 0755 "${WORK_DIR}/patch_dtb_local_mac.py"
fi
if [[ -f "${DTB_PARTITIONS_PATCHER_HOST}" ]]; then
  cp "${DTB_PARTITIONS_PATCHER_HOST}" "${WORK_DIR}/patch_dtb_partitions.py"
  chmod 0755 "${WORK_DIR}/patch_dtb_partitions.py"
fi

# Repositories snippet appended to the IB's repos config.
#   ipk -> repositories.conf (one `src/gz <name> <url>` per line).
#   apk -> repositories       (one URL per line, file:// required).
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

# Make bind-mounted files readable by the container `buildbot` user (uid 1000).
chmod -R a+rX "${WORK_DIR}" "${FEED_DIR}"
chmod a+w "${WORK_DIR}/out"

# Export so docker `-e VAR` (no =value) forwards real values to the in-container script.
export BUILD_INITRAMFS IMAGE_FORMAT FIT_ARCH FIT_KERNEL_LOADADDR FIT_DTS \
       FIT_CONFIG FIT_BOOTARGS DTB_PATCH_NVMEM_MAC \
       DTB_FORCE_LEGACY_PARTITIONS PROFILE PACKAGES \
       ARCH OPENWRT_RELEASE PKG_FORMAT

# apk needs to (re)generate packages.adb in /feed; ipk's index is static.
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
      # opkg-lede treats `option check_signature` (any value) as enabled.
      sed -i "/^option check_signature/d" repositories.conf
      cat /work/repositories.snippet >> repositories.conf

      echo "=== final repositories.conf ==="
      cat repositories.conf
      echo "=== mounted feed contents (/feed/lime_packages) ==="
      ls -la /feed/lime_packages/ | head -40
      feed_ipks=$(find /feed/lime_packages -maxdepth 1 -name "*.ipk" | wc -l)
      feed_pkgs=$(grep -c "^Package:" /feed/lime_packages/Packages 2>/dev/null || echo 0)
      echo "Feed has ${feed_ipks} IPKs and ${feed_pkgs} Packages entries"

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
      cat /work/repositories.snippet >> repositories

      # The IB Makefile drops `--allow-untrusted` from apk invocations
      # when CONFIG_SIGNATURE_CHECK=y; our local feed is unsigned.
      if grep -q "^CONFIG_SIGNATURE_CHECK=y" .config; then
        echo ">>> Disabling CONFIG_SIGNATURE_CHECK in IB .config (local apk feed is unsigned)"
        sed -i "s/^CONFIG_SIGNATURE_CHECK=y/# CONFIG_SIGNATURE_CHECK is not set/" .config
      fi

      echo "=== final repositories ==="
      cat repositories
      echo "=== mounted feed contents (/feed/lime_packages) ==="
      ls -la /feed/lime_packages/ | head -40
      feed_apks=$(find /feed/lime_packages -maxdepth 1 -name "*.apk" | wc -l)
      echo "Feed has ${feed_apks} APKs"

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

      # apk 3.x: `--allow-untrusted` is a global flag (before sub-command).
      if [ ! -f /feed/lime_packages/packages.adb ]; then
        echo ">>> packages.adb missing - generating with the IB-host apk"
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

      # apk pre-flight: list lime-system against an empty offline root.
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

      make image \
        PROFILE="${PROFILE}" \
        BIN_DIR=/work/out \
        PACKAGES="${PACKAGES}" \
        APK_FLAGS="--allow-untrusted --repository file:///feed/lime_packages/packages.adb"
    fi

    echo "=== /work/out contents (post make image) ==="
    ls -la /work/out/
    find /work/out -type f -printf "%p (%s bytes)\n"

    # IB does not regenerate the staging initramfs FIT under
    # CONFIG_TARGET_ROOTFS_INITRAMFS=y; it carries vanilla OpenWrt
    # without our packages. Assemble it from kernel-bin + DTB + CPIO.
    if [ "${BUILD_INITRAMFS:-0}" = "1" ]; then
      echo "=== Repacking initramfs FIT (RAM-bootable, embedded LibreMesh) ==="

      ARCH_DIR="$(echo /builder/build_dir/target-*_musl)"
      if [ ! -d "${ARCH_DIR}" ]; then
        echo "ERROR: cannot locate target-<arch>_musl under /builder/build_dir" >&2
        ls -la /builder/build_dir >&2 || true
        exit 1
      fi
      LINUX_DIR="$(ls -d ${ARCH_DIR}/linux-*/ 2>/dev/null | head -n 1 | sed "s|/$||")"
      # Skip root.orig-<board> (IB pristine snapshot, no packages).
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

      # Catch the "vanilla OpenWrt CPIO" failure mode at build time.
      ROOTFS_FILES="$(find "${ROOT_DIR}" -mindepth 1 2>/dev/null | wc -l)"
      ROOTFS_BYTES="$(du -sb "${ROOT_DIR}" 2>/dev/null | cut -f1)"
      ROOTFS_HUMAN="$(du -sh "${ROOT_DIR}" 2>/dev/null | cut -f1)"
      echo "  rootfs entries : ${ROOTFS_FILES}"
      echo "  rootfs size    : ${ROOTFS_HUMAN} (${ROOTFS_BYTES} bytes)"
      echo "  /lib/modules/* :"
      ls -la "${ROOT_DIR}/lib/modules" 2>/dev/null | head -10 || \
        echo "    (no /lib/modules - kmod packages were not installed!)"
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
      # Bounds catch an obviously broken rootfs (LibreMesh baseline ~1100/120).
      if [ "${ROOTFS_FILES:-0}" -lt 800 ] || [ "${ko_count}" -lt 30 ]; then
        echo "ERROR: rootfs at ${ROOT_DIR} is implausibly small (${ROOTFS_FILES} entries, ${ko_count} .ko)" >&2
        exit 1
      fi

      KERNEL_BIN="${LINUX_DIR}/${PROFILE}-kernel.bin"
      if [ ! -f "${KERNEL_BIN}" ]; then
        echo "ERROR: missing ${KERNEL_BIN}" >&2
        ls -la "${LINUX_DIR}" >&2 | head -40
        exit 1
      fi
      echo "  kernel-bin     : ${KERNEL_BIN} ($(stat -c%s "${KERNEL_BIN}") bytes)"
      # mediatek/filogic: gzipped vmlinux (1f8b0800).
      # ath79: legacy uImage wrapping lzma kernel+DTB (27051956).
      kernel_magic=$(od -An -tx1 -N4 "${KERNEL_BIN}" | tr -d " ")
      case "${IMAGE_FORMAT}" in
        fit)
          if [ "${kernel_magic}" != "1f8b0800" ]; then
            echo "ERROR: ${KERNEL_BIN} is not a gzip stream (magic=${kernel_magic})" >&2
            exit 1
          fi
          ;;
        multi-uimage|dual-tftp)
          if [ "${kernel_magic}" != "27051956" ]; then
            echo "ERROR: ${KERNEL_BIN} is not a uImage (magic=${kernel_magic})" >&2
            exit 1
          fi
          ;;
      esac

      # ath79 fuses DTB into kernel-bin; DTB + dtc lookup is FIT-only.
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
        DTC_BIN="$(find ${LINUX_DIR} -name dtc -type f -executable 2>/dev/null | head -n 1)"
        if [ -z "${DTC_BIN}" ] || [ ! -x "${DTC_BIN}" ]; then
          echo "ERROR: cannot find dtc under ${LINUX_DIR}" >&2
          find "${LINUX_DIR}" -name dtc -type f 2>/dev/null >&2 || true
          exit 1
        fi
        DTC_DIR="$(dirname "${DTC_BIN}")"
        echo "  using dtc      : ${DTC_BIN}"
      else
        echo "  IMAGE_FORMAT   : ${IMAGE_FORMAT} (no separate DTB; ath79 appends DTB to kernel-bin)"
      fi

      REPACK_DIR="/tmp/initramfs-repack"
      rm -rf "${REPACK_DIR}"
      mkdir -p "${REPACK_DIR}"

      # Optional FIT-only DTB transforms (each gated, share dtc round-trip):
      #   DTB_PATCH_NVMEM_MAC=1        -> inject local-mac-address into
      #                                   GMAC/WAN nodes (openwrt#22858).
      #   DTB_FORCE_LEGACY_PARTITIONS=1 -> rewrite SPI-NAND partitions to
      #                                    23.05 layout for Belkin RT3200
      #                                    layout 1.0 units.
      # NOTE: this block runs under `sh -lc`, so no apostrophes in comments.
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
        "${DTC_BIN}" -I dtb -O dts -q -o "${DTB_DTS_ORIG}" "${DTB_FILE}"
        # Stage 1: local-mac-address injection. --require-patch makes the
        # build fail if the GMAC/WAN nodes the patcher targets are gone
        # (e.g. an upstream kernel rename) instead of shipping a no-op patch.
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
        # Stage 1 only adds properties; stage 2 may legitimately shrink.
        orig_sz=$(stat -c%s "${DTB_FILE}")
        new_sz=$(stat -c%s "${DTB_PATCHED}")
        if [ "${DTB_FORCE_LEGACY_PARTITIONS:-0}" != "1" ] && [ "${new_sz}" -lt "${orig_sz}" ]; then
          echo "ERROR: patched DTB shrunk from ${orig_sz} to ${new_sz} bytes - refusing to ship" >&2
          exit 1
        fi
        if [ "${new_sz}" -lt 1024 ]; then
          echo "ERROR: patched DTB is implausibly small (${new_sz} bytes) - dtc likely dropped data" >&2
          exit 1
        fi
        DTB_FILE="${DTB_PATCHED}"
      elif [ "${IMAGE_FORMAT}" != "fit" ] && [ "${DTB_NEEDS_PATCH}" = "1" ]; then
        echo "ERROR: DTB patching is incompatible with IMAGE_FORMAT=${IMAGE_FORMAT}" >&2
        echo "       DTB_PATCH_NVMEM_MAC=${DTB_PATCH_NVMEM_MAC:-0} DTB_FORCE_LEGACY_PARTITIONS=${DTB_FORCE_LEGACY_PARTITIONS:-0}" >&2
        exit 1
      else
        echo "=== Skipping DTB patch (DTB_PATCH_NVMEM_MAC=${DTB_PATCH_NVMEM_MAC:-0} DTB_FORCE_LEGACY_PARTITIONS=${DTB_FORCE_LEGACY_PARTITIONS:-0}) ==="
      fi

      # Initramfs CPIO must be uncompressed: IB reuses the sysupgrade
      # kernel without RD_GZIP/LZ4/XZ. A gzipped CPIO falls back to the
      # on-flash root silently. Raw newc magic 070701 is consumed directly.
      BUILD_MARKER="ci-${OPENWRT_RELEASE:-unknown}-${PROFILE}-$(date -u +%Y%m%dT%H%M%SZ)"
      mkdir -p "${ROOT_DIR}/etc"
      printf "%s\n" "${BUILD_MARKER}" > "${ROOT_DIR}/etc/lime-build-marker"
      echo "  build marker   : ${BUILD_MARKER}"

      # Kernel mountpoints: preinit needs /proc, /sys, /dev, /tmp to exist
      # as directories so mount -t proc/sysfs/tmpfs succeeds. base-files
      # creates them, but verify anyway.
      for mp in proc sys dev tmp; do
        if [ ! -d "${ROOT_DIR}/${mp}" ]; then
          echo "  creating missing /${mp} mountpoint"
          mkdir -p "${ROOT_DIR}/${mp}"
        fi
      done

      # /init script: the kernel runs /init as PID 1. For initramfs boots
      # this MUST export INITRAMFS=1 so that /lib/preinit/80_mount_root
      # skips do_mount_root (which would pivot_root into the flash overlay
      # and break /proc). This matches OpenWrt upstream target/linux/generic/
      # other-files/init. Without it, mount_root finds rootfs_data on flash,
      # pivot_root fails on rootfs, ramoverlay loses /proc, lime-config
      # never runs, and the device boots as root@(none).
      rm -f "${ROOT_DIR}/init"
      cat > "${ROOT_DIR}/init" <<INITEOF
#!/bin/sh
export INITRAMFS=1
exec /sbin/init
INITEOF
      chmod 0755 "${ROOT_DIR}/init"
      echo "  /init script   :"
      cat "${ROOT_DIR}/init"
      if [ ! -x "${ROOT_DIR}/init" ]; then
        echo "ERROR: ${ROOT_DIR}/init is not executable" >&2
        exit 1
      fi
      if [ ! -e "${ROOT_DIR}/sbin/init" ] && [ ! -L "${ROOT_DIR}/sbin/init" ]; then
        echo "ERROR: ${ROOT_DIR}/sbin/init does not exist; /init exec will fail" >&2
        ls -la "${ROOT_DIR}/sbin/" 2>/dev/null | head -20 >&2 || true
        exit 1
      fi

      echo "  packing rootfs CPIO from ${ROOT_DIR}"
      ( cd "${ROOT_DIR}" && \
        find . | /builder/staging_dir/host/bin/cpio -o -H newc 2>/dev/null ) \
          > "${REPACK_DIR}/rootfs.cpio"
      ls -la "${REPACK_DIR}/rootfs.cpio"
      cpio_bytes=$(stat -c%s "${REPACK_DIR}/rootfs.cpio")
      echo "  cpio size      : $((cpio_bytes / 1024 / 1024)) MiB (${cpio_bytes} bytes) vs rootfs ${ROOTFS_HUMAN}"
      cpio_magic=$(head -c 6 "${REPACK_DIR}/rootfs.cpio")
      if [ "${cpio_magic}" != "070701" ]; then
        echo "ERROR: rootfs.cpio has unexpected magic \"${cpio_magic}\" (expected 070701 newc)" >&2
        head -c 16 "${REPACK_DIR}/rootfs.cpio" | od -c | head >&2
        exit 1
      fi
      cpio_min=$((ROOTFS_BYTES * 80 / 100))
      if [ "${cpio_bytes}" -lt "${cpio_min}" ]; then
        echo "ERROR: cpio size ${cpio_bytes} is <80% of rootfs ${ROOTFS_BYTES} - likely truncated/compressed" >&2
        exit 1
      fi
      echo "  cpio file types (top 10):"
      /builder/staging_dir/host/bin/cpio -tv < "${REPACK_DIR}/rootfs.cpio" 2>/dev/null \
        | awk "{print \$1}" | sort | uniq -c | sort -rn | head -10 || true

      # `cpio -t` (no -v): GNU cpio strips leading ./ in -tv listings.
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

      if [ "${IMAGE_FORMAT}" = "dual-tftp" ]; then
        # dual-tftp (ath79 LibreRouter): ship kernel.bin and a ramdisk
        # uImage wrapping the rootfs CPIO. U-Boot TFTP-loads each to a
        # distinct RAM address; `bootm <kernel> <ramdisk>` makes U-Boot
        # pass initrd_start/initrd_end to the kernel natively via the
        # MIPS boot params (not via kernel command line / DT bootargs).
        echo "=== dual-tftp: shipping kernel.bin + rootfs ramdisk uImage ==="
        KERNEL_OUT="/work/out/openwrt-${OPENWRT_RELEASE:-}-${PROFILE}-kernel.bin"
        RAMDISK_OUT="/work/out/openwrt-${OPENWRT_RELEASE:-}-${PROFILE}-rootfs.uimage"
        cp "${KERNEL_BIN}" "${KERNEL_OUT}"
        /builder/staging_dir/host/bin/mkimage \
          -A mips -O linux -T ramdisk -C none \
          -a 0 -e 0 \
          -n "LibreMesh rootfs ${PROFILE}" \
          -d "${REPACK_DIR}/rootfs.cpio" "${RAMDISK_OUT}"
        echo "  kernel  : ${KERNEL_OUT} ($(stat -c%s "${KERNEL_OUT}") bytes)"
        echo "  ramdisk : ${RAMDISK_OUT} ($(stat -c%s "${RAMDISK_OUT}") bytes)"
        /builder/staging_dir/host/bin/mkimage -l "${RAMDISK_OUT}" || true
      elif [ "${IMAGE_FORMAT}" = "fit" ]; then
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

      # mkits.sh has no `bootargs` flag inside `configurations`. Without
      # an explicit override U-Boot falls back to chosen/bootargs which
      # has `root=/dev/fit0 ...` and ignores our initramfs.
      echo "=== Injecting bootargs=\"${FIT_BOOTARGS}\" into FIT config ${FIT_CONFIG} ==="
      sed -i "/^[[:space:]]*${FIT_CONFIG} {[[:space:]]*\$/,/^[[:space:]]*};[[:space:]]*\$/ s|^\\([[:space:]]*\\)};[[:space:]]*\$|\\1        bootargs = \"${FIT_BOOTARGS}\";\\n\\1};|" "${REPACK_DIR}/initramfs.its"

      bootargs_count=$(grep -c "bootargs = \"${FIT_BOOTARGS}\";" "${REPACK_DIR}/initramfs.its" || true)
      if [ "${bootargs_count}" -ne 1 ]; then
        echo "ERROR: bootargs injection produced ${bootargs_count} matches in initramfs.its (expected exactly 1)" >&2
        echo "----- initramfs.its (configurations section) -----" >&2
        sed -n "/configurations {/,/^};/p" "${REPACK_DIR}/initramfs.its" >&2 || true
        exit 1
      fi
      echo "  bootargs injected: ${bootargs_count} occurrence(s) (expected 1) - OK"
      echo "----- initramfs.its configurations block -----"
      sed -n "/configurations {/,/^};/p" "${REPACK_DIR}/initramfs.its"

      PATH="${DTC_DIR}:${PATH}" /builder/staging_dir/host/bin/mkimage \
        -f "${REPACK_DIR}/initramfs.its" \
        "${REPACK_DIR}/initramfs-libremesh.itb"

      INITRAMFS_OUT="/work/out/openwrt-${OPENWRT_RELEASE:-}-${PROFILE}-initramfs-libremesh.itb"
      cp "${REPACK_DIR}/initramfs-libremesh.itb" "${INITRAMFS_OUT}"
      echo "=== Initramfs FIT generated (FIT_CONFIG=${FIT_CONFIG}) ==="
      ls -la "${INITRAMFS_OUT}"
      /builder/staging_dir/host/bin/mkimage -l "${INITRAMFS_OUT}" \
        | grep -E "Image |Type:|Compression:|Data Size|Architecture|Load Address|Entry Point|Configuration |Kernel:|FDT:|Init Ramdisk:" || true
      if ! grep -q "default = \"${FIT_CONFIG}\"" "${REPACK_DIR}/initramfs.its"; then
        echo "ERROR: initramfs.its has no default config = \"${FIT_CONFIG}\"" >&2
        head -80 "${REPACK_DIR}/initramfs.its" >&2 || true
        exit 1
      fi
      else
        # multi-uimage (ath79): IH_TYPE_MULTI image with sub0=kernel.lzma,
        # sub1=rootfs.cpio. DTB is fused into kernel-bin upstream.
        echo "=== Building multi-uimage (kernel.lzma + rootfs.cpio) for ath79 ==="
        # mkimage prepends a 64-byte image_header; strip it.
        KERNEL_LZMA="${REPACK_DIR}/kernel.lzma"
        dd if="${KERNEL_BIN}" of="${KERNEL_LZMA}" bs=1 skip=64 status=none
        kernel_lzma_size=$(stat -c%s "${KERNEL_LZMA}")
        uimage_data_line=$(/builder/staging_dir/host/bin/mkimage -l "${KERNEL_BIN}" 2>/dev/null \
                           | awk -F"[: ]+" "/Data Size/ {print \$3; exit}")
        if [ -n "${uimage_data_line}" ] && [ "${kernel_lzma_size}" -ne "${uimage_data_line}" ]; then
          echo "ERROR: stripped lzma size ${kernel_lzma_size} != uImage data length ${uimage_data_line}" >&2
          exit 1
        fi
        # OpenWrt lzma uses `-lc1 -lp2 -pb2` so the first byte is 0x6d
        # (not 0x5d). Property bytes are <= 0xe0; we reject competing magics.
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

# Verify the produced image actually carries LibreMesh by grepping the
# manifest. `make image` can silently drop PACKAGES on dep conflicts and
# ship a vanilla OpenWrt artifact otherwise.
MANIFEST_FILE="$(compgen -G "${WORK_DIR}/out/*${PROFILE}*.manifest" 2>/dev/null | head -n 1 || true)"
if [[ -z "${MANIFEST_FILE}" || ! -f "${MANIFEST_FILE}" ]]; then
  echo "::error::ImageBuilder produced no .manifest for ${PROFILE} - cannot verify LibreMesh content" >&2
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

# Pick the artifact to ship to test-firmware.
#   dual-tftp            -> kernel.bin + rootfs.cpio (two files).
#   x86-combined         -> gunzip the *-ext4-combined.img.gz disk image.
#   BUILD_INITRAMFS=1    -> *-initramfs-libremesh.{itb,uimage} (FIT or multi-uimage).
#   BUILD_INITRAMFS=0    -> *-squashfs-sysupgrade.{itb,bin} (IPK validation only).
DEVICE_NAME="${DEVICE_NAME:-${PROFILE}}"
SOURCE_FILE=""
if [[ "${IMAGE_FORMAT}" == "dual-tftp" ]]; then
  KERNEL_SRC="$(compgen -G "${WORK_DIR}/out/*${PROFILE}-kernel.bin" 2>/dev/null | head -n 1 || true)"
  RAMDISK_SRC="$(compgen -G "${WORK_DIR}/out/*${PROFILE}-rootfs.uimage" 2>/dev/null | head -n 1 || true)"
  if [[ -z "${KERNEL_SRC}" || -z "${RAMDISK_SRC}" ]]; then
    echo "::error::dual-tftp: expected *-kernel.bin + *-rootfs.uimage under ${WORK_DIR}/out" >&2
    find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
    exit 1
  fi
  cp "${KERNEL_SRC}"  "${OUTPUT_DIR}/firmware-${DEVICE_NAME}.bin"
  cp "${RAMDISK_SRC}" "${OUTPUT_DIR}/firmware-${DEVICE_NAME}.uimage"
  MANIFEST_TARGET="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.manifest"
  cp "${MANIFEST_FILE}" "${MANIFEST_TARGET}"
  echo ">>> dual-tftp kernel  : ${OUTPUT_DIR}/firmware-${DEVICE_NAME}.bin ($(stat -c%s "${OUTPUT_DIR}/firmware-${DEVICE_NAME}.bin") bytes)"
  echo ">>> dual-tftp ramdisk : ${OUTPUT_DIR}/firmware-${DEVICE_NAME}.uimage ($(stat -c%s "${OUTPUT_DIR}/firmware-${DEVICE_NAME}.uimage") bytes)"
  echo ">>> Manifest output   : ${MANIFEST_TARGET} ($(wc -l < "${MANIFEST_TARGET}") packages)"
  echo ">>> Kernel sha256     : $(sha256sum "${OUTPUT_DIR}/firmware-${DEVICE_NAME}.bin" | cut -d' ' -f1)"
  echo ">>> Ramdisk sha256    : $(sha256sum "${OUTPUT_DIR}/firmware-${DEVICE_NAME}.uimage" | cut -d' ' -f1)"
  exit 0
elif [[ "${IMAGE_FORMAT}" == "x86-combined" ]]; then
  combined_gz="$(compgen -G "${WORK_DIR}/out/*ext4-combined.img.gz" 2>/dev/null | head -n 1 || true)"
  if [[ -z "${combined_gz}" ]]; then
    echo "::error::IMAGE_FORMAT=x86-combined: no *ext4-combined.img.gz under ${WORK_DIR}/out." >&2
    echo "       Confirm the x86-64/generic ImageBuilder profile produced the combined recipe." >&2
    find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
    exit 1
  fi
  combined_img="${combined_gz%.gz}"
  if [[ ! -f "${combined_img}" ]]; then
    # OpenWrt pads the combined image past the gzip stream, so gunzip
    # exits 2 with a "trailing garbage ignored" warning. The bytes are
    # correct; treat 0 and 2 as success.
    set +e
    gunzip -kc "${combined_gz}" > "${combined_img}" 2>/tmp/gunzip.err
    gz_rc=$?
    set -e
    if [[ $gz_rc -ne 0 && $gz_rc -ne 2 ]]; then
      echo "::error::gunzip failed on ${combined_gz} (rc=$gz_rc)" >&2
      cat /tmp/gunzip.err >&2 || true
      exit 1
    fi
    if [[ ! -s "${combined_img}" ]]; then
      echo "::error::gunzip produced empty output for ${combined_gz}" >&2
      exit 1
    fi
    if [[ -s /tmp/gunzip.err ]]; then
      echo ">>> gunzip notice (non-fatal): $(cat /tmp/gunzip.err)"
    fi
  fi
  SOURCE_FILE="${combined_img}"
  echo ">>> Matched x86-combined image: ${combined_gz} -> ${SOURCE_FILE} (gunzip)"
elif [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  case "${IMAGE_FORMAT}" in
    fit)          initramfs_patterns=("*${PROFILE}-initramfs-libremesh.itb" "*${PROFILE}*initramfs-libremesh.itb") ;;
    multi-uimage) initramfs_patterns=("*${PROFILE}-initramfs-libremesh.uimage" "*${PROFILE}*initramfs-libremesh.uimage") ;;
    dual-tftp)    echo "BUG: dual-tftp should have exited earlier" >&2; exit 1 ;;
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

if [[ "${IMAGE_FORMAT}" == "x86-combined" ]]; then
  EXTENSION="img"
else
  EXTENSION="${SOURCE_FILE##*.}"
fi
TARGET_FILE="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.${EXTENSION}"
cp "${SOURCE_FILE}" "${TARGET_FILE}"

MANIFEST_TARGET="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.manifest"
cp "${MANIFEST_FILE}" "${MANIFEST_TARGET}"

echo ">>> Firmware output: ${TARGET_FILE} ($(stat -c%s "${TARGET_FILE}") bytes)"
echo ">>> Manifest output: ${MANIFEST_TARGET} ($(wc -l < "${MANIFEST_TARGET}") packages)"
echo ">>> Firmware sha256: $(sha256sum "${TARGET_FILE}" | cut -d' ' -f1)"
