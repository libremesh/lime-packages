#!/usr/bin/env bash
#
# Compute the GitHub Actions matrix outputs from .github/ci/targets.yml.
#
# Inputs (env vars):
#   TARGETS_INPUT              comma-separated devices or "all"
#   RELEASES_OVERRIDE          comma-separated OpenWrt releases ("" -> targets.yml default)
#   PHYSICAL_RELEASES_OVERRIDE comma-separated lab releases ("" -> targets.yml default)
#   MESH_COUNT_INPUT           "0", "2" or "3"; ignored on pull_request (forced to 3)
#   EVENT_NAME                 github.event_name (e.g. pull_request)
#   GITHUB_OUTPUT              path to GHA output file
#
# Outputs (written to GITHUB_OUTPUT):
#   targets_matrix, test_targets_matrix, mesh_test_matrix, mesh_pairs_matrix,
#   qemu_single_matrix, qemu_mesh_matrix, archs_matrix, lime_packages_list,
#   feed_hash

set -euo pipefail

TARGETS_INPUT="${TARGETS_INPUT:-all}"
RELEASES_OVERRIDE="${RELEASES_OVERRIDE:-}"
PHYSICAL_RELEASES_OVERRIDE="${PHYSICAL_RELEASES_OVERRIDE:-}"
MESH_COUNT_INPUT="${MESH_COUNT_INPUT:-0}"
EVENT_NAME="${EVENT_NAME:-}"

if grep -RIn '^PKG_MIRROR_HASH:=skip' packages/; then
  echo "PKG_MIRROR_HASH:=skip is deprecated on OpenWrt 24.10; pin PKG_SOURCE_VERSION and set a real sha256." >&2
  exit 1
fi

all_targets_json="$(yq -r '.targets | tojson' .github/ci/targets.yml)"
default_releases_json="$(yq -r '.openwrt_releases | tojson' .github/ci/targets.yml)"
feed_branches_json="$(yq -r '.feed_branches | tojson' .github/ci/targets.yml)"
default_physical_releases_json="$(yq -r '.default_physical_releases | tojson' .github/ci/targets.yml)"
packages="$(yq -r '.packages' .github/ci/targets.yml)"

if [[ -n "$RELEASES_OVERRIDE" ]]; then
  releases_json="$(
    jq -cn --arg list "$RELEASES_OVERRIDE" '
      $list | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))
    '
  )"
else
  releases_json="$default_releases_json"
fi
if [[ "$(jq 'length' <<< "$releases_json")" -eq 0 ]]; then
  echo "No OpenWrt releases selected (override='$RELEASES_OVERRIDE')" >&2
  exit 1
fi

# Every release must have a feed_branches entry, otherwise build_image.sh
# would route the local feed against the wrong upstream branch.
missing="$(
  jq -cn --argjson rel "$releases_json" --argjson fb "$feed_branches_json" '
    $rel - ($fb | keys)
  '
)"
if [[ "$(jq 'length' <<< "$missing")" -gt 0 ]]; then
  echo "openwrt_releases entries missing from feed_branches map: $missing" >&2
  exit 1
fi

if [[ -n "$PHYSICAL_RELEASES_OVERRIDE" ]]; then
  physical_releases_json="$(
    jq -cn --arg list "$PHYSICAL_RELEASES_OVERRIDE" '
      $list | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))
    '
  )"
else
  physical_releases_json="$default_physical_releases_json"
fi

if [[ "$TARGETS_INPUT" == "all" ]]; then
  selected_targets="$all_targets_json"
else
  selected_targets="$(
    jq -c --arg list "$TARGETS_INPUT" '
      ($list | split(",") | map(gsub("^\\s+|\\s+$"; ""))) as $wanted
      | map(select((.device as $d | any($wanted[]; . == $d))))
    ' <<< "$all_targets_json"
  )"
fi

if [[ "$(jq 'length' <<< "$selected_targets")" -eq 0 ]]; then
  echo "No targets selected after filtering input: $TARGETS_INPUT" >&2
  exit 1
fi

# `targets_matrix`: cross-product of selected targets x release. Per-target
# `packages:` may include the `{{ packages_default }}` placeholder which is
# replaced by the top-level default at this step.
targets_matrix="$(
  jq -c --argjson releases "$releases_json" --argjson feeds "$feed_branches_json" --arg pkg "$packages" '
    {include: (
      . as $tgts
      | $releases
      | map(. as $rel
        | $tgts
        | map(. + {
            openwrt_release: $rel,
            feed_branch: ($feeds[$rel] // ""),
            packages: ((.packages // $pkg) | gsub("\\{\\{\\s*packages_default\\s*\\}\\}"; $pkg)),
            build_initramfs: (if (.build_initramfs == true) then "1" else "0" end),
            image_format: (.image_format // "fit"),
            fit_arch: (.fit_arch // ""),
            fit_kernel_loadaddr: (.fit_kernel_loadaddr // ""),
            fit_dts: (.fit_dts // ""),
            fit_config: (.fit_config // "config-1"),
            fit_bootargs: (.fit_bootargs // ""),
            dtb_patch_nvmem_mac: (if (.dtb_patch_nvmem_mac == true) then "1" else "0" end),
            dtb_force_legacy_partitions: (if (.dtb_force_legacy_partitions == true) then "1" else "0" end),
            test_firmware: (if (.test_firmware == false) then "0" else "1" end),
            test_qemu: (if (.test_qemu == true) then "1" else "0" end),
            test_places: (.test_places // [.device]),
            uboot_interrupt_spam_sec: (.uboot_interrupt_spam_sec // "" | tostring)
          })
      ) | add
    )}
  ' <<< "$selected_targets"
)"

# `test_targets_matrix`: physical single-node entries, expanded by labgrid
# place. Filtered by `physical_releases_json` so build-only smoke releases
# (e.g. 25.12.2 today) do not enqueue any lab job.
test_targets_matrix="$(
  jq -c --argjson phys "$physical_releases_json" '
    {include: (
      .include
      | map(select(.test_firmware == "1"))
      | map(select([.openwrt_release] | inside($phys)))
      | map(. as $t | $t.test_places | map($t + {place: .}))
      | add // []
    )}
  ' <<< "$targets_matrix"
)"

# mesh_test_matrix: physical mesh shape from MESH_COUNT_INPUT.
# pull_request cannot pass workflow inputs, so it forces N=3.
if [[ "$EVENT_NAME" == "pull_request" ]]; then
  MESH_COUNT_INPUT="3"
fi
case "$MESH_COUNT_INPUT" in
  "2") mesh_places_json='["openwrt_one","bananapi_bpi-r4"]' ;;
  "3") mesh_places_json='["openwrt_one","bananapi_bpi-r4","belkin_rt3200_2"]' ;;
  *)   mesh_places_json='[]' ;;
esac
mesh_device_map_json='{"openwrt_one":"openwrt_one","bananapi_bpi-r4":"bananapi_bpi-r4","belkin_rt3200_2":"linksys_e8450","belkin_rt3200_3":"linksys_e8450"}'
if [[ "$mesh_places_json" == "[]" ]]; then
  mesh_test_matrix='{"include":[]}'
else
  mesh_test_matrix="$(
    jq -cn --argjson phys "$physical_releases_json" --argjson places "$mesh_places_json" --argjson devmap "$mesh_device_map_json" '
      {include: ($phys | map({
        openwrt_release: .,
        places: $places,
        devices: ($places | map($devmap[.]))
      }))}
    '
  )"
fi

# `mesh_pairs_matrix`: walking-chain matrix used by the daily cron.
# Three 2-node pairs that share devices on purpose so each unit gets two
# end-to-end mesh validations per day. Excludes belkin_rt3200_1 (in repair).
# Note: pair #3 pairs bananapi_bpi-r4 (wired-only) with belkin_rt3200_3 on
# VLAN 200; two identical-model belkins are NOT paired because LibreMesh's
# primary_mac() derives identity from eth0 and same-model devices in
# initramfs mode share that MAC, producing a mesh identity collision.
if [[ "$(jq 'length' <<< "$physical_releases_json")" -eq 0 ]]; then
  mesh_pairs_matrix='{"include":[]}'
else
  primary_release="$(jq -r '.[0]' <<< "$physical_releases_json")"
  mesh_pairs_matrix="$(
    jq -cn --arg rel "$primary_release" '
      {include: [
        {pair: 1, place_a: "belkin_rt3200_2", device_a: "linksys_e8450",
                  place_b: "openwrt_one",     device_b: "openwrt_one",
                  openwrt_release: $rel},
        {pair: 2, place_a: "openwrt_one",     device_a: "openwrt_one",
                  place_b: "bananapi_bpi-r4", device_b: "bananapi_bpi-r4",
                  openwrt_release: $rel},
        {pair: 3, place_a: "bananapi_bpi-r4", device_a: "bananapi_bpi-r4",
                  place_b: "belkin_rt3200_3", device_b: "linksys_e8450",
                  openwrt_release: $rel}
      ]}
    '
  )"
fi

# QEMU matrices. Crossed against the FULL release list (not the physical
# filter) so QEMU validation runs on every supported branch.
qemu_single_matrix="$(
  jq -c '{include: (.include | map(select(.test_qemu == "1")))}' <<< "$targets_matrix"
)"
qemu_mesh_matrix="$qemu_single_matrix"

# `archs_matrix` drives build-feed. Keyed on (arch, release) because the SDK
# toolchain differs across releases and the resulting IPKs are not
# interchangeable. extra_feeds / extra_packages aggregate per (arch, release).
archs_matrix="$(
  jq -c --argjson releases "$releases_json" '
    ([.[] | {
      arch,
      sdk_arch,
      index_imagebuilder,
      extra_feeds: (.extra_feeds // []),
      extra_packages: (.extra_packages // [])
    }]) as $base
    | {
        include: (
          $releases
          | map(. as $rel
            | $base
            | map(. + {openwrt_release: $rel,
                       sdk_arch: (
                         .sdk_arch | sub("-openwrt-[0-9]+\\.[0-9]+(\\.[0-9]+)?$";
                                         "-openwrt-" + ($rel | split(".") | .[:2] | join(".")))
                       )})
          )
          | add
          | group_by([.arch, .openwrt_release])
          | map({
              arch: .[0].arch,
              sdk_arch: .[0].sdk_arch,
              index_imagebuilder: .[0].index_imagebuilder,
              openwrt_release: .[0].openwrt_release,
              extra_feeds: ([.[] | .extra_feeds[]] | unique | join(" ")),
              extra_packages: ([.[] | .extra_packages[]] | unique | join(" "))
            })
        )
      }
  ' <<< "$selected_targets"
)"

# extra_hash: 12-char sha256 prefix over (extra_feeds, extra_packages) so the
# build-feed cache key busts whenever the upstream commit pin or package
# selection of an extra src-git feed changes.
archs_matrix="$(
  entries="$(jq -c '.include[]' <<<"$archs_matrix")"
  updated="[]"
  while IFS= read -r entry; do
    ef="$(jq -r '.extra_feeds' <<<"$entry")"
    ep="$(jq -r '.extra_packages' <<<"$entry")"
    eh="$(printf '%s|%s' "$ef" "$ep" | sha256sum | cut -c1-12)"
    updated="$(jq -c --argjson e "$entry" --arg eh "$eh" '. + [$e + {extra_hash: $eh}]' <<<"$updated")"
  done <<<"$entries"
  jq -cn --argjson inc "$updated" '{include: $inc}'
)"

# `lime_packages_list`: union of every package name listed in targets.yml,
# filtered to names that exist as `packages/<name>/Makefile`. Restricting to
# requested packages keeps gh-action-sdk's per-package compile loop bounded.
requested_pkgs="$(
  yq -r '[.packages, (.targets[].packages // empty)]
         | map(select(. != null))
         | join(" ")' .github/ci/targets.yml \
    | tr ' \t' '\n' \
    | sed -n 's/^[A-Za-z0-9_+-][A-Za-z0-9_+-]*$/&/p' \
    | grep -v '^-' \
    | grep -vw 'packages_default' \
    | sort -u
)"
available_lime="$(
  find packages -mindepth 2 -maxdepth 2 -name Makefile -printf '%h\n' \
    | xargs -n1 basename | sort -u
)"
lime_packages_list="$(
  comm -12 <(printf '%s\n' "$requested_pkgs") <(printf '%s\n' "$available_lime") \
    | tr '\n' ' ' | sed 's/[[:space:]]*$//'
)"
echo "Computed package list ($(echo "$lime_packages_list" | wc -w) packages):"
echo "$lime_packages_list" | tr ' ' '\n'

# `feed_hash`: sha256 over package sources, build_feed.sh and the resolved
# package list. Other targets.yml or workflow edits do NOT bust the cache.
feed_hash="$(
  {
    find packages -type f \( -name 'Makefile' -o -path 'packages/*/files/*' -o -path 'packages/*/patches/*' -o -path 'packages/*/src/*' \) -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 sha256sum
    sha256sum tools/ci/build_feed.sh
    printf 'lime_packages_list=%s\n' "$lime_packages_list"
  } | sha256sum | cut -d' ' -f1
)"
echo "Computed feed_hash=$feed_hash"

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "GITHUB_OUTPUT not set; printing values to stdout instead." >&2
  GITHUB_OUTPUT="/dev/stdout"
fi

{
  echo "targets_matrix=$targets_matrix"
  echo "test_targets_matrix=$test_targets_matrix"
  echo "mesh_test_matrix=$mesh_test_matrix"
  echo "mesh_pairs_matrix=$mesh_pairs_matrix"
  echo "qemu_single_matrix=$qemu_single_matrix"
  echo "qemu_mesh_matrix=$qemu_mesh_matrix"
  echo "archs_matrix=$archs_matrix"
  echo "lime_packages_list=$lime_packages_list"
  echo "feed_hash=$feed_hash"
} >> "$GITHUB_OUTPUT"
