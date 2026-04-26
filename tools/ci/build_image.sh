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

    make image PROFILE=${PROFILE} BIN_DIR=/work/out PACKAGES=\"${PACKAGES}\"
  "

SOURCE_FILE="$(
  find "${WORK_DIR}/out" -type f -name "*${PROFILE}*initramfs*" 2>/dev/null | head -n 1 || true
)"
if [[ -z "${SOURCE_FILE}" ]]; then
  if [[ "${IMAGEBUILDER}" == "mediatek-filogic" ]]; then
    SOURCE_FILE="$(compgen -G "${WORK_DIR}/out/*${PROFILE}*initramfs*.itb" | head -n 1 || true)"
  else
    SOURCE_FILE="$(compgen -G "${WORK_DIR}/out/*${PROFILE}*initramfs*.bin" | head -n 1 || true)"
  fi
fi

if [[ -z "${SOURCE_FILE}" || ! -f "${SOURCE_FILE}" ]]; then
  echo "ERROR: Could not locate built initramfs image for profile ${PROFILE}" >&2
  exit 1
fi

EXTENSION="${SOURCE_FILE##*.}"
DEVICE_NAME="${DEVICE_NAME:-${PROFILE}}"
TARGET_FILE="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.${EXTENSION}"
cp "${SOURCE_FILE}" "${TARGET_FILE}"

echo ">>> Firmware output: ${TARGET_FILE}"
