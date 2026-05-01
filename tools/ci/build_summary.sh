#!/usr/bin/env bash
#
# Render the workflow summary to $GITHUB_STEP_SUMMARY. All matrices and
# job results are passed as opaque env vars (instead of `${{ ... }}`
# interpolation) so the JSON values are not parsed as bash tokens.

set -euo pipefail

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
} >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
