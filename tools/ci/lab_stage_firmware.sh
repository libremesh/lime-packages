#!/usr/bin/env bash
#
# Stage a single-node firmware artifact for a labgrid place.
#
# Renames `firmware-<DEVICE>.*` under fw/ to `firmware-<PLACE>.*` so parallel
# jobs against units sharing the same hardware profile do not race on the
# labgrid TFTP symlink. Exports `LG_IMAGE` to GITHUB_ENV.
#
# Inputs (env vars):
#   DEVICE           build artifact device name
#   PLACE            labgrid place name
#   OPENWRT_RELEASE  release dimension (separates 24.10.x vs 25.12.x)
#   RUN_ID           github.run_id (used in TFTP path to isolate runs)
#   GITHUB_ENV       path to GHA env file (set by the runner)

set -euo pipefail

DEVICE="${DEVICE:?DEVICE required}"
PLACE="${PLACE:?PLACE required}"
OPENWRT_RELEASE="${OPENWRT_RELEASE:?OPENWRT_RELEASE required}"
RUN_ID="${RUN_ID:?RUN_ID required}"

echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') staging firmware for $DEVICE@$OPENWRT_RELEASE on place $PLACE"

BASE="/srv/tftp/firmwares/ci"
STAGE="$BASE/$RUN_ID/$PLACE/$OPENWRT_RELEASE"
if ! mkdir -p "$STAGE" 2>/tmp/mkdir.err; then
  echo "::error::Cannot create $STAGE: $(cat /tmp/mkdir.err)"
  echo "Fix on the lab host (one-time):"
  echo "  sudo install -d -o \$RUNNER_USER -g \$RUNNER_USER -m 0775 $BASE"
  ls -ld /srv/tftp /srv/tftp/firmwares "$BASE" 2>/dev/null || true
  exit 1
fi

shopt -s nullglob
files=(fw/firmware-"$DEVICE".*)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "::error::No firmware-$DEVICE.* under fw/"
  ls -la fw/ || true
  exit 1
fi

src_prefix="firmware-$DEVICE"
dst_prefix="firmware-$PLACE"
for f in "${files[@]}"; do
  base="$(basename "$f")"
  if [[ "$base" != "$src_prefix"* ]]; then
    echo "::warning::Unexpected artifact name $base (does not start with $src_prefix); copying as-is"
    cp -a "$f" "$STAGE/"
    continue
  fi
  suffix="${base#$src_prefix}"
  cp -a "$f" "$STAGE/${dst_prefix}${suffix}"
done

# Dual-TFTP mode: build_image.sh emits firmware-<device>.bin (kernel) and
# firmware-<device>.uimage (ramdisk-wrapped rootfs CPIO) for devices that
# need two TFTP loads + `bootm <kernel> <ramdisk>`.
KERNEL_FILE="$STAGE/firmware-$PLACE.bin"
RAMDISK_FILE="$STAGE/firmware-$PLACE.uimage"

if [[ -f "$KERNEL_FILE" && -f "$RAMDISK_FILE" ]]; then
  echo "=== dual-tftp mode: kernel + rootfs ramdisk uImage ==="
  echo "LG_IMAGE=$KERNEL_FILE" >> "${GITHUB_ENV:-/dev/null}"
  echo "LG_IMAGE_INITRD=$RAMDISK_FILE" >> "${GITHUB_ENV:-/dev/null}"
  echo "Staged LG_IMAGE=$KERNEL_FILE"
  echo "Staged LG_IMAGE_INITRD=$RAMDISK_FILE"
  echo "=== firmware sanity ==="
  file "$KERNEL_FILE" || true
  ls -la "$KERNEL_FILE"
  sha256sum "$KERNEL_FILE"
  file "$RAMDISK_FILE" || true
  ls -la "$RAMDISK_FILE"
  sha256sum "$RAMDISK_FILE"
else
  # Single-image mode (FIT, multi-uimage, x86-combined, sysupgrade).
  image_candidates=("$STAGE"/firmware-"$PLACE".*)
  LG_IMAGE=""
  for f in "${image_candidates[@]}"; do
    case "$f" in
      *.manifest|*.sha256|*.txt|*.log) ;;
      *) LG_IMAGE="$f"; break ;;
    esac
  done
  if [[ -z "$LG_IMAGE" ]]; then
    echo "::error::No bootable firmware artifact under $STAGE (only sidecars?)"
    ls -la "$STAGE" || true
    exit 1
  fi

  echo "LG_IMAGE=$LG_IMAGE" >> "${GITHUB_ENV:-/dev/null}"
  echo "Staged LG_IMAGE=$LG_IMAGE"
  echo "=== firmware sanity ==="
  file "$LG_IMAGE" || true
  ls -la "$LG_IMAGE"
  sha256sum "$LG_IMAGE"
fi

# Print the LibreMesh subset of the manifest for at-a-glance verification.
MANIFEST="$STAGE/firmware-$PLACE.manifest"
if [[ -f "$MANIFEST" ]]; then
  echo "=== manifest sidecar ($(wc -l < "$MANIFEST") packages): LibreMesh entries ==="
  grep -E '^(lime-|shared-state-|batctl|babeld|firewall4)' "$MANIFEST" \
    || echo "(no LibreMesh entries; image is NOT LibreMesh)"
else
  echo "::warning::No manifest sidecar at $MANIFEST"
fi
