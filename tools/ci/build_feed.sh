#!/usr/bin/env bash
# Local reproducer of the CI feed build (same logic as openwrt/gh-action-sdk@v9).
# Requires Docker (and QEMU/binfmt if the SDK arch differs from the host).
set -euo pipefail

usage() {
  echo "Usage: $0 <opkg_arch> <artifacts_dir>" >&2
  echo "  opkg_arch: OpenWrt package arch, e.g. aarch64_cortex-a53 or mips_24kc" >&2
  echo "  artifacts_dir: empty or writable directory; receives bin/packages/<arch>/<feed>/" >&2
  echo "Optional env: SDK_ARCH (default: <opkg_arch>-openwrt-24.10), FEEDNAME (default: lime_packages)," >&2
  echo "  SDK_PACKAGES or PACKAGES (default: empty -> compile whole feed), BUILD, BUILD_LOG, V" >&2
  exit 1
}

if [[ $# -ne 2 ]]; then
  usage
fi

ARCH_OPKG="$1"
ARTIFACTS_DIR="$(realpath -m "$2")"
FEEDNAME="${FEEDNAME:-lime_packages}"
PACKAGES="${SDK_PACKAGES:-${PACKAGES:-}}"
SDK_ARCH="${SDK_ARCH:-${ARCH_OPKG}-openwrt-24.10}"

mkdir -p "${ARTIFACTS_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

git clone --depth 1 --branch v9 https://github.com/openwrt/gh-action-sdk "${TMP_DIR}/gh-action-sdk"

docker build \
  --build-arg "ARCH=${SDK_ARCH}" \
  -t local/openwrt-gh-action-sdk:v9 \
  "${TMP_DIR}/gh-action-sdk"

docker run --rm \
  --env ARCH="${SDK_ARCH}" \
  --env BUILD="${BUILD:-1}" \
  --env BUILD_LOG="${BUILD_LOG:-1}" \
  --env FEEDNAME="${FEEDNAME}" \
  --env IGNORE_ERRORS="n m y" \
  --env INDEX="${INDEX:-0}" \
  --env "NO_REFRESH_CHECK=${NO_REFRESH_CHECK:-}" \
  --env "NO_SHFMT_CHECK=${NO_SHFMT_CHECK:-}" \
  --env PACKAGES="${PACKAGES}" \
  --env "V=${V:-}" \
  -v "$(pwd):/feed" \
  -v "${ARTIFACTS_DIR}:/artifacts" \
  local/openwrt-gh-action-sdk:v9

echo ">>> Feed output: ${ARTIFACTS_DIR}/bin/packages/${ARCH_OPKG}/${FEEDNAME}/"
