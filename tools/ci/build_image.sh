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
# .github/ci/targets.yml (fit_arch / fit_kernel_loadaddr / fit_dts) and
# forwarded by build-firmware.yml.
FIT_ARCH="${FIT_ARCH:-}"
FIT_KERNEL_LOADADDR="${FIT_KERNEL_LOADADDR:-}"
FIT_DTS="${FIT_DTS:-}"

if [[ "${BUILD_INITRAMFS}" == "1" ]]; then
  for var in FIT_ARCH FIT_KERNEL_LOADADDR FIT_DTS; do
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
export BUILD_INITRAMFS FIT_ARCH FIT_KERNEL_LOADADDR FIT_DTS PROFILE PACKAGES \
       ARCH OPENWRT_RELEASE

docker run --rm \
  --user root \
  -e BUILD_INITRAMFS \
  -e FIT_ARCH \
  -e FIT_KERNEL_LOADADDR \
  -e FIT_DTS \
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
      ROOT_DIR="$(ls -d ${ARCH_DIR}/root-*/ 2>/dev/null | head -n 1 | sed "s|/$||")"
      if [ ! -d "${LINUX_DIR}" ] || [ ! -d "${ROOT_DIR}" ]; then
        echo "ERROR: cannot locate linux-* / root-* under ${ARCH_DIR}" >&2
        ls -la "${ARCH_DIR}" >&2 || true
        exit 1
      fi
      echo "  linux build dir: ${LINUX_DIR}"
      echo "  rootfs dir     : ${ROOT_DIR}"

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
      echo "  packing rootfs CPIO from ${ROOT_DIR}"
      ( cd "${ROOT_DIR}" && \
        find . | /builder/staging_dir/host/bin/cpio -o -H newc 2>/dev/null ) \
          | gzip -9n > "${REPACK_DIR}/rootfs.cpio.gz"
      ls -la "${REPACK_DIR}/rootfs.cpio.gz"

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
      # The FIT config name MUST match the bootconf env variable set in
      # the U-Boot environment of each device by OpenWrt. Both
      # targets/openwrt_one.yaml and targets/linksys_e8450.yaml boot
      # with "bootm $loadaddr#$bootconf", and on a stock OpenWrt NAND
      # bootconf is exactly the DTS basename (e.g. mt7981b-openwrt-one,
      # mt7622-linksys-e8450-ubi, mt7988a-bananapi-bpi-r4). Using a
      # generic name like config-1 would cause bootm to fail with
      # "config not found" once U-Boot tries to resolve $bootconf. We
      # therefore name the configuration after FIT_DTS (which is also
      # the .dtb basename), mirroring what the upstream OpenWrt
      # KERNEL_INITRAMFS recipe does.
      PATH="${DTC_DIR}:${PATH}" /builder/scripts/mkits.sh \
        -A "${FIT_ARCH}" \
        -C gzip \
        -a "${FIT_KERNEL_LOADADDR}" \
        -e "${FIT_KERNEL_LOADADDR}" \
        -c "${FIT_DTS}" \
        -v "OpenWrt LibreMesh ${PROFILE}" \
        -k "${KERNEL_BIN}" \
        -D "${PROFILE}" \
        -d "${DTB_FILE}" \
        -i "${REPACK_DIR}/rootfs.cpio.gz" \
        -o "${REPACK_DIR}/initramfs.its"

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
      echo "=== Initramfs FIT generated ==="
      ls -la "${INITRAMFS_OUT}"
      /builder/staging_dir/host/bin/mkimage -l "${INITRAMFS_OUT}" \
        | grep -E "Image |Type:|Compression:|Data Size|Architecture|Load Address|Entry Point|Configuration |Kernel:|FDT:|Init Ramdisk:" || true
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
