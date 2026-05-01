#!/usr/bin/env bash
#
# Stage firmware artifacts for a mesh test (multi-node) and run pytest.
#
# Inputs (env vars):
#   MODE              "full"  -> N-node mesh from MESH_PLACES_JSON / MESH_DEVICES_JSON
#                     "pair"  -> 2-node walking-chain pair from PLACE_A/DEVICE_A/PLACE_B/DEVICE_B
#   OPENWRT_RELEASE   release dimension
#   RUN_ID            github.run_id
#   PAIR              pair index (only when MODE=pair)
#   MESH_PLACES_JSON  JSON array of labgrid places (when MODE=full)
#   MESH_DEVICES_JSON JSON array of artifact device names (when MODE=full)
#   PLACE_A, DEVICE_A, PLACE_B, DEVICE_B (when MODE=pair)
#   SRC_DIR           source dir under workspace ("fw-mesh" or "fw-pair")
#   LOGS_DIR          relative log output dir ("mesh-logs" or "mesh-pairs-logs")
#   GITHUB_WORKSPACE  set by the runner

set -euo pipefail

MODE="${MODE:-full}"
OPENWRT_RELEASE="${OPENWRT_RELEASE:?OPENWRT_RELEASE required}"
RUN_ID="${RUN_ID:?RUN_ID required}"
SRC_DIR="${SRC_DIR:-fw-mesh}"
LOGS_DIR="${LOGS_DIR:-mesh-logs}"

case "$MODE" in
  full)
    BASE="/srv/tftp/firmwares/ci/$RUN_ID/mesh/$OPENWRT_RELEASE"
    mapfile -t PLACES < <(echo "${MESH_PLACES_JSON:?}" | jq -r '.[]')
    mapfile -t DEVICES < <(echo "${MESH_DEVICES_JSON:?}" | jq -r '.[]')
    if [[ ${#PLACES[@]} -ne ${#DEVICES[@]} ]]; then
      echo "::error::places/devices length mismatch (${#PLACES[@]} vs ${#DEVICES[@]})" >&2
      exit 1
    fi
    ;;
  pair)
    BASE="/srv/tftp/firmwares/ci/$RUN_ID/mesh-pairs/${PAIR:?}/$OPENWRT_RELEASE"
    PLACES=("${PLACE_A:?}" "${PLACE_B:?}")
    DEVICES=("${DEVICE_A:?}" "${DEVICE_B:?}")
    ;;
  *)
    echo "::error::Unknown MODE=$MODE" >&2
    exit 1
    ;;
esac

for place in "${PLACES[@]}"; do
  if ! mkdir -p "$BASE/$place" 2>/tmp/mkdir.err; then
    echo "::error::Cannot create $BASE/$place: $(cat /tmp/mkdir.err)"
    echo "Fix on the lab host (one-time):"
    echo "  sudo install -d -o \$RUNNER_USER -g \$RUNNER_USER -m 0775 /srv/tftp/firmwares/ci"
    ls -ld /srv/tftp /srv/tftp/firmwares /srv/tftp/firmwares/ci 2>/dev/null || true
    exit 1
  fi
done

pick_image() {
  local dir="$1" base_prefix="$2" picked=""
  for f in "$dir"/${base_prefix}.*; do
    case "$f" in
      *.manifest|*.sha256|*.txt|*.log) ;;
      *) picked="$f"; break ;;
    esac
  done
  if [[ -z "$picked" ]]; then
    echo "::error::No bootable firmware under $dir (only sidecars?)" >&2
    ls -la "$dir" >&2 || true
    return 1
  fi
  echo "$picked"
}

mesh_places=()
mesh_image_map_entries=()
for i in "${!PLACES[@]}"; do
  place="${PLACES[$i]}"
  device="${DEVICES[$i]}"
  src_dir="$GITHUB_WORKSPACE/$SRC_DIR/$device"
  if [[ ! -d "$src_dir" ]]; then
    echo "::error::Missing artifact dir $src_dir for place=$place device=$device" >&2
    exit 1
  fi
  src_prefix="firmware-${device}"
  dst_prefix="firmware-${place}"
  for f in "$src_dir"/${src_prefix}.*; do
    base="$(basename "$f")"
    suffix="${base#$src_prefix}"
    cp -a "$f" "$BASE/$place/${dst_prefix}${suffix}"
  done
  img=$(pick_image "$BASE/$place" "${dst_prefix}")
  echo "=== mesh firmware sanity (place=$place / device=$device) ==="
  file "$img" || true
  ls -la "$img"
  sha256sum "$img"
  manifest="${img%.*}.manifest"
  if [[ -f "$manifest" ]]; then
    echo "=== manifest for $(basename "$img"): LibreMesh entries ==="
    grep -E '^(lime-|shared-state-|batctl|babeld|firewall4)' "$manifest" \
      || echo "(no LibreMesh entries; image is NOT LibreMesh)"
  else
    echo "::warning::No manifest sidecar at $manifest"
  fi
  mesh_places+=("labgrid-fcefyn-$place")
  mesh_image_map_entries+=("labgrid-fcefyn-$place=$img")
done

IFS=',' LG_MESH_PLACES_VALUE="${mesh_places[*]}"
IFS=',' LG_IMAGE_MAP_VALUE="${mesh_image_map_entries[*]}"
unset IFS
export LG_PROXY=labgrid-fcefyn
export LG_MESH_PLACES="$LG_MESH_PLACES_VALUE"
export LG_IMAGE_MAP="$LG_IMAGE_MAP_VALUE"
mkdir -p "$GITHUB_WORKSPACE/$LOGS_DIR"
echo "LG_MESH_PLACES=$LG_MESH_PLACES"
echo "LG_IMAGE_MAP=$LG_IMAGE_MAP"
cd libremesh-tests
uv run pytest tests/test_mesh.py \
  --lg-log "$GITHUB_WORKSPACE/$LOGS_DIR/" \
  --junitxml="$GITHUB_WORKSPACE/$LOGS_DIR/report.xml" \
  --log-cli-level=INFO -v
rm -rf "$BASE"
