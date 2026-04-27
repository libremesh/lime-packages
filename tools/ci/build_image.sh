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
# RAM-bootable FIT (kernel + DTB + LibreMesh CPIO ramdisk) and ships THAT as
# the firmware artifact. Targets that do not set this flag (e.g. ath79
# librerouter, whose subtarget has no `KERNEL_INITRAMFS` recipe and whose
# uImage layout requires the initramfs CPIO be linked into the kernel
# binary at compile time — impossible without kernel sources, which
# ImageBuilder does not ship) keep producing the squashfs-sysupgrade as
# their build artifact for IPK validation only; they are filtered out of
# the test-firmware matrix in `prepare-matrix`.
BUILD_INITRAMFS="${BUILD_INITRAMFS:-0}"

# Used only when BUILD_INITRAMFS=1. Filled per-target in
# .github/ci/targets.yml (fit_arch / fit_kernel_loadaddr / fit_dts /
# fit_config) and forwarded by build-firmware.yml.
FIT_ARCH="${FIT_ARCH:-}"
FIT_KERNEL_LOADADDR="${FIT_KERNEL_LOADADDR:-}"
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

if [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  for var in FIT_ARCH FIT_KERNEL_LOADADDR FIT_DTS FIT_CONFIG FIT_BOOTARGS; do
    if [[ -z "${!var}" ]]; then
      echo "ERROR: BUILD_INITRAMFS=1 requires ${var} env var" >&2
      exit 1
    fi
  done
fi

if [[ ! -d "${FEED_DIR}/lime_packages" ]]; then
  echo "ERROR: Feed dir must contain lime_packages/: ${FEED_DIR}/lime_packages" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "${WORK_DIR}/out" "${WORK_DIR}/keys" "${OUTPUT_DIR}"
chmod 0755 "${WORK_DIR}"

cat > "${WORK_DIR}/repositories.snippet" <<EOF
src/gz lime_packages_local file:///feed/lime_packages
src/gz libremesh https://feed.libremesh.org/master/${FEED_BRANCH}/${ARCH}
EOF

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
export BUILD_INITRAMFS FIT_ARCH FIT_KERNEL_LOADADDR FIT_DTS FIT_CONFIG \
       FIT_BOOTARGS PROFILE PACKAGES ARCH OPENWRT_RELEASE

docker run --rm \
  --user root \
  -e BUILD_INITRAMFS \
  -e FIT_ARCH \
  -e FIT_KERNEL_LOADADDR \
  -e FIT_DTS \
  -e FIT_CONFIG \
  -e FIT_BOOTARGS \
  -e PROFILE \
  -e PACKAGES \
  -e ARCH \
  -e OPENWRT_RELEASE \
  -v "${WORK_DIR}:/work" \
  -v "${FEED_DIR}:/feed:ro" \
  "${IMAGE_TAG}" \
  sh -lc '
    set -e
    # Disable signature checking for our local unsigned feed.
    #
    # opkg-lede ignores the value of `option check_signature`: any line
    # named that way enables verification regardless of the argument.
    # Replacing it with `... 0` or appending `0` both leave the flag on,
    # which silently rejects our unsigned local feed and produces
    # `opkg_install_cmd: Cannot install package lime-system.` for every
    # lime-* package. The only way to keep it off is to ensure no such
    # line is present (the in-memory default is 0).
    sed -i "/^option check_signature/d" repositories.conf
    cat /work/repositories.snippet >> repositories.conf
    cp /work/keys/* keys/ 2>/dev/null || true

    echo "=== final repositories.conf ==="
    cat repositories.conf
    echo "=== mounted feed contents (/feed/lime_packages) ==="
    ls -la /feed/lime_packages/ | head -40
    feed_ipks=$(find /feed/lime_packages -maxdepth 1 -name "*.ipk" | wc -l)
    feed_pkgs=$(grep -c "^Package:" /feed/lime_packages/Packages 2>/dev/null || echo 0)
    echo "Feed has ${feed_ipks} IPKs and ${feed_pkgs} Packages entries"

    # Pre-flight: confirm opkg can actually see the local feed before we
    # spend ~30 min on `make image`. If `lime-system` is not visible
    # after `opkg update`, failing here is far cheaper than failing at
    # the very end of package_install with no diagnostic context.
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
      DTB_FILE="${LINUX_DIR}/image-${FIT_DTS}.dtb"
      if [ ! -f "${KERNEL_BIN}" ]; then
        echo "ERROR: missing ${KERNEL_BIN}" >&2
        ls -la "${LINUX_DIR}" >&2 | head -40
        exit 1
      fi
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

      REPACK_DIR="/tmp/initramfs-repack"
      rm -rf "${REPACK_DIR}"
      mkdir -p "${REPACK_DIR}"

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
      # include/image.mk explicitly creates the symlink before
      # cpio-packing:
      #   ln -sf /sbin/init $(KERNEL_BUILD_DIR)/cpiogz/init
      # We replicate that exact step here. Idempotent: -f overwrites
      # any existing /init from a previous repack iteration in the
      # same staging dir.
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
      echo "  /init in CPIO  :"
      init_paths="$(/builder/staging_dir/host/bin/cpio -t < "${REPACK_DIR}/rootfs.cpio" 2>/dev/null \
                    | grep -E '^(\./)?init$' || true)"
      if [ -z "${init_paths}" ]; then
        echo "ERROR: /init is missing from rootfs.cpio" >&2
        echo "       Without /init the kernel will fall through to prepare_namespace()" >&2
        echo "       and panic with \"Unable to mount root fs on unknown-block(0,0)\"." >&2
        echo "       cpio -t (top entries containing 'init'):" >&2
        /builder/staging_dir/host/bin/cpio -t < "${REPACK_DIR}/rootfs.cpio" 2>/dev/null \
          | grep -E "(^|/)init$" | head -20 >&2 || true
        exit 1
      fi
      echo "    ${init_paths}"

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
# When BUILD_INITRAMFS=1 we look for the FIT we just repacked
# (`*-initramfs-libremesh.itb`). Its rootfs lives inside the kernel
# image as a gzip-CPIO ramdisk, which `bootm` hands to the kernel as
# initramfs and the testbed boots from RAM with no flash dependency.
#
# When BUILD_INITRAMFS=0 we fall back to the sysupgrade artifact
# (`*-squashfs-sysupgrade.{itb,bin}`). This branch is only used by
# targets we explicitly opted out of test-firmware, so the artifact is
# carried purely for IPK validation and never TFTP-booted.
SOURCE_FILE=""
if [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  for pattern in \
    "*${PROFILE}-initramfs-libremesh.itb" \
    "*${PROFILE}*initramfs-libremesh.itb"; do
    match="$(compgen -G "${WORK_DIR}/out/${pattern}" 2>/dev/null | head -n 1 || true)"
    if [[ -n "${match}" && -f "${match}" ]]; then
      SOURCE_FILE="${match}"
      echo ">>> Matched initramfs pattern '${pattern}' -> ${SOURCE_FILE}"
      break
    fi
  done
  if [[ -z "${SOURCE_FILE}" ]]; then
    echo "::error::BUILD_INITRAMFS=1 was set but no *-initramfs-libremesh.itb found in ${WORK_DIR}/out." >&2
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

EXTENSION="${SOURCE_FILE##*.}"
DEVICE_NAME="${DEVICE_NAME:-${PROFILE}}"
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
