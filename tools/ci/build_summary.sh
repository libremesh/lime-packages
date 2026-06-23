#!/usr/bin/env bash
#
# Render the workflow summary to $GITHUB_STEP_SUMMARY and enforce the
# CI gate: exit non-zero if any critical job failed or was cancelled.
#
# All matrices and job results are passed as opaque env vars (instead of
# `${{ ... }}` interpolation) so the JSON values are not parsed as bash
# tokens.

set -euo pipefail

OUT="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

{
  printf '## Firmware build summary\n\n'
  printf -- '- Trigger: `%s`\n'                              "${TRIGGER:-}"
  printf -- '- Targets matrix: `%s`\n'                       "${TARGETS_MATRIX:-}"
  printf -- '- Arch matrix: `%s`\n'                          "${ARCHS_MATRIX:-}"
  printf -- '- Physical test matrix: `%s`\n'                 "${TEST_TARGETS_MATRIX:-}"
  printf -- '- Mesh test matrix: `%s`\n'                     "${MESH_TEST_MATRIX:-}"
  printf -- '- Mesh pairs matrix (daily): `%s`\n'            "${MESH_PAIRS_MATRIX:-}"
  printf -- '- QEMU single-node matrix: `%s`\n'              "${QEMU_SINGLE_MATRIX:-}"
  printf -- '- QEMU mesh matrix: `%s`\n'                     "${QEMU_MESH_MATRIX:-}"
  printf -- '- Feed stage result: `%s`\n'                    "${BUILD_FEED_RESULT:-}"
  printf -- '- Image stage result: `%s`\n'                   "${BUILD_IMAGE_RESULT:-}"
  printf -- '- test-firmware result: `%s`\n'                 "${TEST_FIRMWARE_RESULT:-}"
  printf -- '- test-mesh result: `%s`\n'                     "${TEST_MESH_RESULT:-}"
  printf -- '- test-mesh-pairs result: `%s`\n'               "${TEST_MESH_PAIRS_RESULT:-}"
  printf -- '- test-firmware-qemu-single result: `%s`\n'     "${TEST_FIRMWARE_QEMU_SINGLE_RESULT:-}"
  printf -- '- test-mesh-qemu result: `%s`\n'                "${TEST_MESH_QEMU_RESULT:-}"
} >> "$OUT"

# --- CI gate ---
# `skipped` is acceptable (job condition not met for this event type).
# `failure` or `cancelled` on any stage blocks the merge.
gate_ok=true
declare -A job_results=(
  [build-feed]="${BUILD_FEED_RESULT:-}"
  [build-image]="${BUILD_IMAGE_RESULT:-}"
  [test-firmware]="${TEST_FIRMWARE_RESULT:-}"
  [test-mesh]="${TEST_MESH_RESULT:-}"
  [test-mesh-pairs]="${TEST_MESH_PAIRS_RESULT:-}"
  [test-firmware-qemu-single]="${TEST_FIRMWARE_QEMU_SINGLE_RESULT:-}"
  [test-mesh-qemu]="${TEST_MESH_QEMU_RESULT:-}"
)

{
  printf '\n## CI gate\n\n'
  printf '| Job | Result | Pass |\n'
  printf '|-----|--------|------|\n'
} >> "$OUT"

for job in build-feed build-image test-firmware test-mesh test-mesh-pairs \
           test-firmware-qemu-single test-mesh-qemu; do
  result="${job_results[$job]}"
  case "$result" in
    success|skipped) icon="✅" ;;
    *)               icon="❌"; gate_ok=false ;;
  esac
  printf '| %s | `%s` | %s |\n' "$job" "$result" "$icon" >> "$OUT"
done

if $gate_ok; then
  printf '\n**CI gate: PASS** — all jobs succeeded or were legitimately skipped.\n' >> "$OUT"
else
  printf '\n**CI gate: FAIL** — one or more jobs failed or were cancelled.\n' >> "$OUT"
  exit 1
fi
