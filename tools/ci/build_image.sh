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
echo ">>> Building ${PROFILE} with ${IMAGE_TAG}"

# Make sure container 'buildbot' user (uid 1000) can read the bind-mounted files.
chmod -R a+rX "${WORK_DIR}" "${FEED_DIR}"
chmod a+w "${WORK_DIR}/out"

docker run --rm \
  --user root \
  -v "${WORK_DIR}:/work" \
  -v "${FEED_DIR}:/feed:ro" \
  "${IMAGE_TAG}" \
  sh -lc "
    set -e
    # Disable signature checking for our local unsigned feed.
    #
    # opkg-lede's boolean option parser (libopkg/opkg_conf.c) ignores the
    # value: encountering an 'option check_signature' line — with or without
    # an argument — sets the flag to 1. Replacing 'option check_signature'
    # with 'option check_signature 0' or appending '... 0' both keep
    # verification on, which silently rejects our unsigned local feed and
    # produces 'opkg_install_cmd: Cannot install package lime-system.' for
    # every lime-* package. The only way to keep it off is to ensure no
    # such line is present (the in-memory default is 0).
    sed -i '/^option check_signature/d' repositories.conf
    cat /work/repositories.snippet >> repositories.conf
    cp /work/keys/* keys/ 2>/dev/null || true

    echo '=== final repositories.conf ==='
    cat repositories.conf
    echo '=== mounted feed contents (/feed/lime_packages) ==='
    ls -la /feed/lime_packages/ | head -40
    feed_ipks=\$(find /feed/lime_packages -maxdepth 1 -name '*.ipk' | wc -l)
    feed_pkgs=\$(grep -c '^Package:' /feed/lime_packages/Packages 2>/dev/null || echo 0)
    echo \"Feed has \${feed_ipks} IPKs and \${feed_pkgs} Packages entries\"

    # Pre-flight: confirm opkg can actually see the local feed before we
    # spend ~30 min on 'make image'. If 'lime-system' is not visible after
    # 'opkg update', failing here is far cheaper than failing at the very
    # end of package_install with no diagnostic context.
    mkdir -p /tmp/preflight/tmp /tmp/preflight-lists
    /builder/staging_dir/host/bin/opkg \
      --offline-root /tmp/preflight \
      --add-arch all:100 \
      --add-arch ${ARCH}:200 \
      -f /builder/repositories.conf \
      --cache /tmp/preflight-cache \
      --lists-dir /tmp/preflight-lists \
      update >/tmp/preflight.log 2>&1 || true
    echo '=== opkg pre-flight update (last 25 lines) ==='
    tail -n 25 /tmp/preflight.log
    if ! /builder/staging_dir/host/bin/opkg \
        --offline-root /tmp/preflight \
        --add-arch all:100 \
        --add-arch ${ARCH}:200 \
        -f /builder/repositories.conf \
        --cache /tmp/preflight-cache \
        --lists-dir /tmp/preflight-lists \
        list 2>/dev/null | grep -q '^lime-system '; then
      echo 'ERROR: opkg cannot see lime-system in any configured feed' >&2
      echo 'opkg list (filtered to lime/shared-state):' >&2
      /builder/staging_dir/host/bin/opkg \
        --offline-root /tmp/preflight \
        --add-arch all:100 \
        --add-arch ${ARCH}:200 \
        -f /builder/repositories.conf \
        --cache /tmp/preflight-cache \
        --lists-dir /tmp/preflight-lists \
        list 2>/dev/null | grep -E '^(lime|shared-state|babeld-auto|check-date|batctl)' >&2 || true
      exit 1
    fi
    echo '=== Pre-flight OK: local feed is visible to opkg ==='

    # Force ImageBuilder to also emit the initramfs FIT (kernel + embedded
    # CPIO rootfs) on top of the default squashfs-sysupgrade FIT.
    #
    # Why: testbed nodes are TFTP-booted from RAM and never sysupgraded
    # in CI. The sysupgrade FIT is a *staged* image — its rootfs is a
    # 'Filesystem Image' (squashfs) packed as a FIT 'loadables' entry,
    # which bootm does NOT pass to the kernel as initramfs. A kernel
    # booted with that FIT comes up with an empty 'root=' cmdline; the
    # in-tree fitblk driver then walks UBI, finds the on-flash 'fit'
    # volume from whatever was previously sysupgraded onto the device
    # (vanilla OpenWrt 24.10.5 from 2025-12-17 in our lab), maps its
    # squashfs sub-image as /dev/fit0 and mounts that as /. We end up
    # running our fresh kernel against the old userspace, so lime-config
    # never executes and the DUT presents 'root@OpenWrt:~#' instead of
    # 'root@LiMe-XXXXXX:~#'.
    #
    # Setting CONFIG_TARGET_ROOTFS_INITRAMFS=y instructs make image to
    # also build the kernel-with-initramfs variant, which produces
    # *-initramfs-recovery.itb (filogic) / *-initramfs-kernel.bin (ath79)
    # — true RAM-only images whose rootfs lives inside kernel-1 and
    # therefore survive bootm without any flash dependency. The
    # downstream pattern selection in build_image.sh prefers those over
    # the sysupgrade FIT, so this single config tweak is what flips
    # test-firmware from 'tests on-flash 24.10.5' to 'tests today's PR'.
    #
    # Note: filogic 24.10 imagebuilders ship CONFIG_TARGET_ROOTFS_INITRAMFS=n
    # by default (initramfs is opt-in for production sysupgrades).
    sed -i '/^CONFIG_TARGET_ROOTFS_INITRAMFS\b/d' .config
    sed -i '/^CONFIG_TARGET_INITRAMFS_COMPRESSION_/d' .config
    {
      echo 'CONFIG_TARGET_ROOTFS_INITRAMFS=y'
      echo 'CONFIG_TARGET_INITRAMFS_COMPRESSION_NONE=n'
      echo 'CONFIG_TARGET_INITRAMFS_COMPRESSION_GZIP=y'
    } >> .config
    echo '=== Effective .config initramfs flags ==='
    grep -E '^CONFIG_TARGET_(ROOTFS_INITRAMFS|INITRAMFS_COMPRESSION_)' .config || true

    make image PROFILE=${PROFILE} BIN_DIR=/work/out PACKAGES=\"${PACKAGES}\"

    # Harvest the initramfs FIT from staging_dir.
    #
    # Several device profiles (e.g. mediatek/filogic openwrt_one,
    # ath79 librerouter-v1) build a true initramfs FIT — kernel + DTB
    # + RAMDisk-type rootfs sub-image, all addressable via bootm — but
    # only consume it internally as the source of the factory.ubi
    # 'recovery' volume. ImageBuilder leaves it under
    # /builder/staging_dir/target-<sdk_arch>/image/ instead of copying
    # it to BIN_DIR (=/work/out), because the device's IMAGES list in
    # filogic.mk / ath79.mk only declares the sysupgrade / factory
    # outputs. The downstream pattern matcher in this script needs the
    # file in /work/out to ship it as the testbed boot artifact, so we
    # copy any *initramfs*.{itb,bin} we find in staging into out/. This
    # is purely additive: it does not displace files that ImageBuilder
    # already wrote to BIN_DIR (sysupgrade FIT remains alongside).
    echo '=== Harvesting initramfs FITs from /builder/staging_dir ==='
    staged_initramfs=\$(find /builder/staging_dir -type f \\( -name '*initramfs*.itb' -o -name '*initramfs*.bin' \\) 2>/dev/null || true)
    if [ -n \"\${staged_initramfs}\" ]; then
      echo \"\${staged_initramfs}\" | while IFS= read -r f; do
        echo \"  found: \${f} (\$(stat -c%s \"\${f}\") bytes) -> /work/out/\"
        cp \"\${f}\" /work/out/
      done
    else
      echo '  (none — device profile may not build an initramfs FIT)'
    fi

    echo '=== /work/out contents (post make image + harvest) ==='
    ls -la /work/out/ || true
    find /work/out -type f -printf '%p (%s bytes)\n' || true
  "

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

# Initramfs-only patterns: these are the artifacts whose rootfs lives
# inside the kernel image (initramfs CPIO embedded in `kernel-1` of the
# FIT, or a flat kernel.bin with appended initramfs on ath79). They boot
# self-contained from RAM, which is exactly what the testbed strategy
# relies on. We deliberately ignore *-squashfs-sysupgrade.itb and
# *-squashfs-sysupgrade.bin here because their FIT rootfs is a
# `Filesystem Image` loadable that bootm does NOT hand to the kernel,
# making the DUT fall back to fitblk + on-flash UBI (vanilla OpenWrt
# leftover) instead of testing today's build. The earlier
# `CONFIG_TARGET_ROOTFS_INITRAMFS=y` tweak ensures these are produced;
# this guard turns "silently shipped sysupgrade" into a hard build-image
# failure with full /work/out listing for triage.
SOURCE_FILE=""
for pattern in \
  "*${PROFILE}-initramfs.itb" \
  "*${PROFILE}*initramfs-recovery.itb" \
  "*${PROFILE}*initramfs-kernel.bin" \
  "*${PROFILE}*initramfs*.itb" \
  "*${PROFILE}*initramfs*.bin"; do
  match="$(compgen -G "${WORK_DIR}/out/${pattern}" 2>/dev/null | head -n 1 || true)"
  if [[ -n "${match}" && -f "${match}" ]]; then
    SOURCE_FILE="${match}"
    echo ">>> Matched pattern '${pattern}' -> ${SOURCE_FILE}"
    break
  fi
done

if [[ -z "${SOURCE_FILE}" || ! -f "${SOURCE_FILE}" ]]; then
  echo "::error::No initramfs image produced by ImageBuilder for profile ${PROFILE}." >&2
  echo "Searched ${WORK_DIR}/out for: *${PROFILE}-initramfs.itb, *${PROFILE}*initramfs-recovery.itb, *${PROFILE}*initramfs-kernel.bin, *${PROFILE}*initramfs*.{itb,bin}" >&2
  echo "" >&2
  echo "This usually means CONFIG_TARGET_ROOTFS_INITRAMFS=y was not honored by" >&2
  echo "the imagebuilder (.config rewrite skipped, or the device profile in" >&2
  echo "this OpenWrt release does not define a KERNEL_INITRAMFS recipe). The" >&2
  echo "testbed strategy TFTP-boots from RAM and cannot use a sysupgrade FIT," >&2
  echo "whose rootfs is a 'Filesystem Image' loadable that bootm does not" >&2
  echo "pass to the kernel as initramfs — the DUT would silently boot the" >&2
  echo "previously-flashed userspace via fitblk and tests would run against" >&2
  echo "the wrong firmware. Failing now so the regression surfaces here," >&2
  echo "instead of as a TIMEOUT in test-firmware." >&2
  echo "" >&2
  echo "Actual /work/out contents:" >&2
  find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
  exit 1
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
