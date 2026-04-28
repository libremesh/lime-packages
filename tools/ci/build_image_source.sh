#!/usr/bin/env bash
set -euo pipefail

# build_image_source.sh — full OpenWrt source build for targets where neither
# the OpenWrt ImageBuilder NOR the OpenWrt SDK can produce a TFTP-bootable
# initramfs artifact (currently: librerouter_librerouter-v1).
#
# Why this script exists (the long version):
#
# build_image.sh uses the OpenWrt ImageBuilder (IB) and then repacks its
# pre-built kernel+rootfs into either a FIT (mediatek/filogic) or a
# multi-image legacy uImage (ath79). That works on every U-Boot ≥2018
# and on ath79 boards whose U-Boot fork supports IH_TYPE_MULTI ramdisk
# parameter passing — which is most of them.
#
# It does NOT work on the LibreRouter v1 (Atheros QCA9558, U-Boot 1.1.x
# fork at https://github.com/LibreRouterOrg/u-boot). That U-Boot:
#   * has no FIT parser, and
#   * its lib_mips/mips_linux.c does not propagate sub-image-1 of an
#     IH_TYPE_MULTI uImage to the MIPS kernel as `initrd_start /
#     initrd_size`. The RAM-disk pointer never reaches Linux, the
#     kernel cmdline ends up `console=ttyS0,115200n8 rootfstype=
#     squashfs,jffs2`, the initramfs unpacker never runs, and the
#     device boots whatever LibreMesh squashfs is on flash (CI symptom:
#     `root@margarita:/#` instead of `root@LiMe-XXXXXX:/#`, see CI run
#     25021369701, librerouter_librerouter-v1).
#
# The only canonical OpenWrt path to boot a fresh LibreMesh rootfs from
# RAM on ath79 is to compile the kernel with `CONFIG_INITRAMFS_SOURCE`
# pointing at the desired CPIO. The kernel then carries the rootfs
# inside its own .init.ramfs section, U-Boot just runs `bootm` against
# the resulting uImage, and the kernel`s populate_rootfs() drops the
# embedded CPIO into rootfs with no help from U-Boot.
#
# We previously tried the OpenWrt SDK for this (build_image_sdk.sh,
# now removed). Verified empirically against
# `ghcr.io/openwrt/sdk:ath79-generic-v24.10.6` (April 2026):
#
#     $ docker run … openwrt/sdk:ath79-generic-v24.10.6 make image
#     make[1]: *** No rule to make target 'image'.  Stop.
#
# The SDK is intentionally package-only — it ships the cross toolchain
# and a `package/` Makefile tree, but NOT the `target/` tree, NOT the
# kernel source tree, and NOT the top-level `image` Make target. That
# is by design: the SDK is meant for compiling individual .ipk packages
# against a pre-built kernel/toolchain, not for re-assembling firmware.
#
# Same story with the ImageBuilder: even with `CONFIG_TARGET_ROOTFS_
# INITRAMFS=y` forced into its `.config`, `include/image.mk` guards
# the initramfs build with `$(if $(IB),,…)`, so IB only ever produces
# `*-squashfs-sysupgrade.bin`. No `*-initramfs-kernel.bin` artifact.
#
# The official LibreMesh `lime-sdk` cooker is just an opinionated
# wrapper around `openwrt/sdk` + `openwrt/imagebuilder` (verified:
# `grep -i "kernel\|initramfs\|buildroot" cooker` returns nothing).
# Same dead end.
#
# Conclusion: we need the FULL OpenWrt source tree (the buildroot)
# with kernel sources, target/ recipes, and the top-level `image`
# rule. This script clones it at the pinned release tag and drives
# `make` to produce `*-${PROFILE}-initramfs-kernel.bin` with our
# LibreMesh rootfs CPIO embedded in the kernel`s .init.ramfs section.
#
# Cost: ~50 min cold (toolchain + kernel + ~120 lime-* packages),
# ~10–20 min warm (toolchain restored from cache, only kernel +
# rootfs CPIO get rebuilt because the LibreMesh package contents
# may have changed). Expensive vs ImageBuilder`s ~5 min, but the
# build runs in parallel with every other device in the matrix, so
# wall-clock CI time is bounded by this slowest job only.
#
# How:
#   1. Pull `ghcr.io/openwrt/sdk:<imagebuilder>-v<release>`. We do NOT
#      use it as an SDK — we just want its preinstalled Debian build
#      deps (gcc, perl, ncurses, swig, python3-setuptools, …) so we
#      avoid an `apt-get install` of ~30 packages on every CI run.
#      The ~2 GB SDK image is already pulled by other matrix jobs,
#      so the Docker layer cache amortises the cost.
#   2. Inside the container, clone https://github.com/openwrt/openwrt
#      at the pinned release tag (`v<release>`) into the (cached)
#      build directory. The clone is shallow (`--depth 1`) — we never
#      need history, only the tree at the tag.
#   3. Add our pi-lime-packages tree as a `src-link` feed and wire the
#      `libremesh.mk` symlink (same dance as the deleted
#      build_image_sdk.sh; see comments inline below for why).
#   4. Generate a `.config` seed enabling:
#        * the target subtarget + device,
#        * `CONFIG_TARGET_ROOTFS_INITRAMFS=y`,
#        * `CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y` (lzma is the
#          historical ath79 default — the ath79 kernel build always
#          has lzma decompression linked in, gzip might not, and
#          NONE bloats the uImage past the 8 MiB sysupgrade artefact
#          that the build also produces as a side product),
#        * `CONFIG_DEVEL=y` + `CONFIG_CCACHE=y` (ccache between runs
#          on the same staging_dir cache),
#        * each `CONFIG_PACKAGE_<name>=y` from PACKAGES, and
#        * a `# CONFIG_PACKAGE_<name> is not set` for every leading-
#          dash entry (the IB shorthand for `remove default package`).
#   5. `make defconfig` resolves transitive deps. `make download` then
#      pre-fetches every package source archive into `dl/` (cached).
#      Finally `make -j$(nproc) world` does the real work.
#   6. We copy the produced
#      `bin/targets/<target>/<sub>/<release>-<target>-<sub>-<profile>-
#      initramfs-kernel.bin` to OUTPUT_DIR as
#      `firmware-<DEVICE>.uimage` and the matching .manifest as
#      `firmware-<DEVICE>.manifest`. The labgrid YAML loads the .uimage
#      at 0x82000000 and runs `bootm 0x82000000` — same boot path that
#      LibreRouter`s sysupgrade uses, just with our CPIO inside.
#
# Inputs (positional, matches build_image.sh signature so the workflow
# can pick the script by image_format with no extra plumbing):
#   $1 imagebuilder      subtarget tag, e.g. `ath79-generic` (same value
#                        as `imagebuilder` in targets.yml). Used for the
#                        SDK Docker image tag (build env) AND to derive
#                        the OpenWrt subtarget Make target.
#   $2 profile           OpenWrt profile name, e.g. `librerouter_librerouter-v1`
#   $3 openwrt_release   e.g. `24.10.6`. Pinned to the release tag of
#                        https://github.com/openwrt/openwrt — the
#                        clone uses `--branch v<openwrt_release>` so a
#                        bumped release in targets.yml automatically
#                        bumps the source build too.
#   $4 feed_dir          lime-packages SOURCE ROOT (NOT the build-feed
#                        IPK artifact). Must contain BOTH:
#                          * `packages/<pkg>/Makefile` (one dir per package)
#                          * `libremesh.mk` (helper Makefile imported by
#                            most lime-* packages via `include
#                            ../../libremesh.mk`).
#                        For the production CI this is the workspace root
#                        of the pi-lime-packages checkout; for local runs
#                        point it at the same checkout. The whole tree is
#                        bind-mounted into the build container at
#                        /lime_pkg and the src-link feed targets
#                        /lime_pkg/packages. A symlink to libremesh.mk
#                        is wired into package/feeds/lime_packages/
#                        post-install so relative includes resolve.
#   $5 output_dir        where to drop firmware-<DEVICE>.uimage and
#                        firmware-<DEVICE>.manifest
#
# Required env:
#   PROFILE_TARGET   subtarget kconfig identifier, e.g. `ath79_generic`.
#                    Used to set `CONFIG_TARGET_<PROFILE_TARGET>=y` and
#                    `CONFIG_TARGET_<PROFILE_TARGET>_DEVICE_<PROFILE>=y`
#                    in the .config seed. Forwarded by the workflow
#                    from the `sdk_target_subtarget` key in targets.yml
#                    (we kept the field name for backwards compat with
#                    the now-deleted SDK path; rename later if desired).
#   PACKAGES         space-separated package list, same convention as
#                    build_image.sh (positive names = `=y`; leading-`-`
#                    names = `# CONFIG_PACKAGE_<name> is not set`).
#
# Optional env:
#   DEVICE_NAME             output basename suffix; defaults to PROFILE.
#   BUILD_IMAGE             full Docker reference for the build env
#                           (must have OpenWrt build deps preinstalled);
#                           defaults to
#                           `ghcr.io/openwrt/sdk:<imagebuilder>-v<release>`.
#   MAKE_JOBS               number of parallel `make` jobs; defaults to nproc.
#   OPENWRT_SRC_CACHE_DIR   if set, the OpenWrt clone, dl/, staging_dir/
#                           and the cacheable subset of build_dir/ are
#                           bind-mounted from this host path and persist
#                           across runs (the workflow points this at
#                           actions/cache restored content). Empty = no
#                           persistent cache (cold build, ~50 min on ath79).
#   OPENWRT_GIT_URL         override the OpenWrt git remote; defaults to
#                           https://github.com/openwrt/openwrt.git
#                           (mirror of git.openwrt.org/openwrt/openwrt.git
#                           — the GitHub mirror has historically been more
#                           reliable from GHA runners).

usage() {
  cat >&2 <<USAGE
Usage: $0 <imagebuilder> <profile> <openwrt_release> <feed_dir> <output_dir>

Required env:
  PROFILE_TARGET   e.g. ath79_generic
  PACKAGES         space-separated, leading '-' marks a removal

Optional env:
  DEVICE_NAME             defaults to <profile>
  BUILD_IMAGE             defaults to ghcr.io/openwrt/sdk:<imagebuilder>-v<release>
  MAKE_JOBS               defaults to nproc
  OPENWRT_SRC_CACHE_DIR   persistent cache for openwrt/ (clone + dl + staging_dir + build_dir cacheable subset)
  OPENWRT_GIT_URL         defaults to https://github.com/openwrt/openwrt.git
USAGE
}

if [[ $# -ne 5 ]]; then
  usage
  exit 1
fi

IMAGEBUILDER="$1"
PROFILE="$2"
OPENWRT_RELEASE="$3"
FEED_DIR="$(realpath -m "$4")"
OUTPUT_DIR="$(realpath -m "$5")"

PROFILE_TARGET="${PROFILE_TARGET:?PROFILE_TARGET env var is required (e.g. ath79_generic)}"
PACKAGES="${PACKAGES:?PACKAGES env var is required}"
DEVICE_NAME="${DEVICE_NAME:-${PROFILE}}"
BUILD_IMAGE="${BUILD_IMAGE:-ghcr.io/openwrt/sdk:${IMAGEBUILDER}-v${OPENWRT_RELEASE}}"
MAKE_JOBS="${MAKE_JOBS:-$(nproc)}"
OPENWRT_SRC_CACHE_DIR="${OPENWRT_SRC_CACHE_DIR:-}"
OPENWRT_GIT_URL="${OPENWRT_GIT_URL:-https://github.com/openwrt/openwrt.git}"

# Sanity: feed_dir must be the lime-packages SOURCE ROOT, with both
# `packages/` (per-pkg Makefiles) and `libremesh.mk` (the helper
# Makefile that most lime-* packages include via `include
# ../../libremesh.mk`). When `libremesh.mk` is missing inside the build
# container, `feeds update` collects only the few packages that don`t
# use the helper (lime-system, lime-app, lime-debug, lime-docs*,
# shared-state-async — the ones that include `$(TOPDIR)/rules.mk`
# directly), and silently DROPS every lime-proto-*, lime-hwd-*,
# shared-state-*, babeld-*, batman-adv-* … package without erroring.
# The build then ships a "LibreMesh" image with no protocol stack,
# the device boots, but nothing connects. Fail loud here.
if [[ ! -d "${FEED_DIR}/packages" ]]; then
  echo "ERROR: feed dir must contain packages/ subdir: ${FEED_DIR}/packages" >&2
  echo "       feed_dir should be the lime-packages source ROOT, not the" >&2
  echo "       packages/ subdir nor the build-feed IPK artifact dir." >&2
  exit 1
fi
if [[ ! -f "${FEED_DIR}/libremesh.mk" ]]; then
  echo "ERROR: feed dir is missing libremesh.mk: ${FEED_DIR}/libremesh.mk" >&2
  echo "       Most lime-* package Makefiles include ../../libremesh.mk." >&2
  echo "       Without it, those packages are silently dropped from the" >&2
  echo "       feed (no error from feeds update, package just disappears)." >&2
  exit 1
fi
if ! compgen -G "${FEED_DIR}/packages/*/Makefile" >/dev/null; then
  echo "ERROR: ${FEED_DIR}/packages contains no <pkg>/Makefile entries." >&2
  echo "       build_image_source.sh expects a SOURCE feed (src-link). The" >&2
  echo "       build-feed IPK artifact is incompatible — point feed_dir" >&2
  echo "       at the pi-lime-packages checkout root instead." >&2
  ls -la "${FEED_DIR}/packages" >&2 | head -10 || true
  exit 1
fi

# ---------------------------------------------------------------------
# Translate the IB-style PACKAGES string into kconfig fragments. Same
# convention as build_image.sh / build_image_sdk.sh: positive entries
# become `CONFIG_PACKAGE_<name>=y`, leading-`-` entries become
# `# CONFIG_PACKAGE_<name> is not set` (kconfig "remove default").
# ---------------------------------------------------------------------
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

CONFIG_SEED="${WORK_DIR}/config.seed"
{
  echo "# --- target / device ---"
  # OpenWrt source tree kconfig names (verified against v24.10.6
  # checkout, April 2026):
  #
  #   * CONFIG_TARGET_<sub>=y                 → selects the subtarget
  #     (e.g. ath79_generic). Required to expose the per-device toggles.
  #
  #   * CONFIG_TARGET_<sub>_DEVICE_<profile>=y is the per-device
  #     toggle in the FULL SOURCE BUILD. Unlike the SDK (where
  #     `Config-build.in` forces `CONFIG_TARGET_MULTI_PROFILE=y` as
  #     a hidden bool default y, forcing the `_DEVICE_` namespacing
  #     prefix), the source tree exposes `MULTI_PROFILE` as a normal
  #     bool that `make defconfig` leaves OFF unless we set it. With
  #     MULTI_PROFILE off, the active per-device toggle is the simple
  #     `CONFIG_TARGET_<sub>_DEVICE_<profile>=y` form.
  #
  #     We seed only that simple form here. We DO NOT seed
  #     MULTI_PROFILE=y (we don`t need multi-device builds — every CI
  #     run targets one device). We DO NOT seed the `_DEVICE_<sub>_
  #     DEVICE_<profile>` MULTI_PROFILE-form name (it`d be silently
  #     dropped because MULTI_PROFILE=n).
  #
  #     If a future OpenWrt release flips MULTI_PROFILE`s default,
  #     the post-defconfig sanity block below will catch the dropped
  #     `=y` and fail loud, and we`ll add the second form here then.
  echo "CONFIG_TARGET_${PROFILE_TARGET}=y"
  echo "CONFIG_TARGET_${PROFILE_TARGET}_DEVICE_${PROFILE}=y"
  echo
  echo "# --- initramfs (RAM-bootable kernel with embedded CPIO) ---"
  echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y"
  # Compression: lzma. Rationale:
  #
  #   * The ath79 kernel build always links lzma decompression in
  #     (target/linux/ath79/Makefile selects KERNEL_INITRAMFS_DECOMP
  #     LZMA). Other algorithms (lz4, zstd) are not guaranteed to be
  #     present and would silently fall through to "no decompression
  #     possible" → kernel panic on boot.
  #
  #   * NONE (raw CPIO) would inflate the uImage past the 8 MiB SPI
  #     NOR sysupgrade partition that the build also emits as a side
  #     product. We don`t flash that artefact, but the build refuses
  #     to assemble images larger than the device`s rootfs capacity
  #     (`Image too big!` from check-size in image-commands.mk),
  #     aborting the whole build.
  #
  #   * GZIP is fine but gives a ~25 % larger uImage than LZMA for the
  #     same content (typical for shell-script-heavy LibreMesh rootfs).
  echo "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y"
  # Side artefact: keep the squashfs sysupgrade build path enabled so
  # bin/targets/ ships *-squashfs-sysupgrade.bin alongside the
  # initramfs-kernel.bin. Useful for on-flash recovery via `mtd write`
  # if the testbed Belkin / OpenWrtOne paradigm ever becomes available
  # for LibreRouter, and also doubles as a manifest sanity reference
  # (sysupgrade .manifest is identical to initramfs .manifest).
  echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
  echo "# CONFIG_TARGET_ROOTFS_EXT4FS is not set"
  echo "# CONFIG_TARGET_ROOTFS_TARGZ is not set"
  echo
  echo "# --- build env (CI-friendly) ---"
  # CCACHE under DEVEL gates: caches the cross-compiler`s object
  # output between runs on the same staging_dir cache. Cuts kernel
  # rebuild time roughly in half on a warm cache.
  echo "CONFIG_DEVEL=y"
  echo "CONFIG_CCACHE=y"
  # AUTOREMOVE drops package source trees after `make package/<pkg>/install`
  # to save disk between runs. Important: the build_dir/target-* tree on
  # ath79 with our package list peaks at ~6 GB without this. GHA
  # runners have ~14 GB free disk; AUTOREMOVE keeps us comfortably
  # below the limit.
  echo "CONFIG_AUTOREMOVE=y"
  # BUILD_LOG drops per-package compile logs under logs/ for failure
  # debugging. Cheap (~few MB) and invaluable when a package compile
  # blows up six hours into the build.
  echo "CONFIG_BUILD_LOG=y"
  echo
  echo "# --- packages (PACKAGES env, IB-style) ---"
  for entry in ${PACKAGES}; do
    case "${entry}" in
      -*)
        echo "# CONFIG_PACKAGE_${entry#-} is not set"
        ;;
      *)
        echo "CONFIG_PACKAGE_${entry}=y"
        ;;
    esac
  done
} > "${CONFIG_SEED}"

echo "=== .config seed for ${PROFILE} (target=${PROFILE_TARGET}) ==="
cat "${CONFIG_SEED}"
echo "=== end seed ==="

# ---------------------------------------------------------------------
# Stage the in-container driver script. We ship it as a file so the
# heredoc-vs-quoting hell of build_image.sh doesn't repeat here. The
# container has bash, so we can use proper quoting / arrays.
# ---------------------------------------------------------------------
DRIVER="${WORK_DIR}/source_drive.sh"
cat > "${DRIVER}" <<'CONTAINER_SH'
#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:?}"
PROFILE_TARGET="${PROFILE_TARGET:?}"
OPENWRT_RELEASE="${OPENWRT_RELEASE:?}"
OPENWRT_GIT_URL="${OPENWRT_GIT_URL:?}"
MAKE_JOBS="${MAKE_JOBS:?}"

# /openwrt is bind-mounted from the host (cached or mktemp). On first
# run the directory is empty; subsequent (cache-restored) runs find the
# clone already present and we skip the clone.
cd /openwrt

if [[ ! -d .git ]]; then
  echo "::group::clone OpenWrt v${OPENWRT_RELEASE} (cold cache)"
  # --depth 1 + --single-branch keeps the clone ~250 MB instead of
  # ~3 GB for the full history. We never need history — only the tree
  # at the pinned tag. --branch v<release> resolves to a tag; git
  # clone treats tags identically to branches for shallow clones.
  git clone --depth 1 --single-branch --branch "v${OPENWRT_RELEASE}" \
    "${OPENWRT_GIT_URL}" .
  echo "::endgroup::"
else
  # Sanity: the cache may hold an older release. Detect a tag mismatch
  # and re-clone. We compare the worktree`s `git describe --tags
  # --exact-match HEAD` against the desired tag.
  cur_tag="$(git -C /openwrt describe --tags --exact-match HEAD 2>/dev/null || echo none)"
  if [[ "${cur_tag}" != "v${OPENWRT_RELEASE}" ]]; then
    echo "::group::cache holds OpenWrt ${cur_tag}; re-cloning v${OPENWRT_RELEASE}"
    # Wipe everything (including dl/, staging_dir/) — they`re ABI-
    # specific and a release bump invalidates them anyway.
    cd /
    rm -rf /openwrt/* /openwrt/.[!.]* 2>/dev/null || true
    cd /openwrt
    git clone --depth 1 --single-branch --branch "v${OPENWRT_RELEASE}" \
      "${OPENWRT_GIT_URL}" .
    echo "::endgroup::"
  else
    echo ">>> OpenWrt cache hit: v${OPENWRT_RELEASE} already present"
    echo "    dl/ size:           $(du -sh dl/ 2>/dev/null | cut -f1 || echo 0)"
    echo "    staging_dir/ size:  $(du -sh staging_dir/ 2>/dev/null | cut -f1 || echo 0)"
    echo "    build_dir/ size:    $(du -sh build_dir/ 2>/dev/null | cut -f1 || echo 0)"
    # Wipe any stale .config from a previous run — we always seed a
    # fresh one. Don`t wipe build_dir/ or staging_dir/, those are the
    # cache content we want to reuse.
    rm -f .config
  fi
fi

# ----------------------------------------------------------------
# feeds.conf: keep the upstream OpenWrt feeds (base/packages/luci/
# routing/telephony) so lime-* dependencies (firewall4, lua, jq, …)
# resolve, then append our lime_packages source feed.
#
# Mirror the gh-action-sdk substitution from git.openwrt.org → github
# so feed updates don`t trip on intermittent OpenWrt git server
# flakiness (we already burned an hour to that in earlier iterations).
# ----------------------------------------------------------------
sed \
  -e 's,https://git.openwrt.org/feed/,https://github.com/openwrt/,' \
  -e 's,https://git.openwrt.org/openwrt/,https://github.com/openwrt/,' \
  -e 's,https://git.openwrt.org/project/,https://github.com/openwrt/,' \
  feeds.conf.default > feeds.conf

# Drop any prior lime_packages line (cache restore from a previous
# run will have one) and point at the bind-mounted source tree.
#
# The host bind-mounts the lime-packages SOURCE ROOT at /lime_pkg
# (containing both `packages/` and `libremesh.mk`). The src-link
# entry targets the `packages/` subdir, which is what `scripts/feeds`
# expects (one dir per package).
sed -i '/^src-[a-z]* lime_packages /d' feeds.conf
echo "src-link lime_packages /lime_pkg/packages" >> feeds.conf

echo "::group::feeds.conf"
cat feeds.conf
echo "::endgroup::"

echo "::group::feeds update -a"
./scripts/feeds update -a
echo "::endgroup::"

echo "::group::feeds install (lime_packages first, then upstream deps)"
./scripts/feeds install -p lime_packages -f -a
./scripts/feeds install -a
echo "::endgroup::"

# ----------------------------------------------------------------
# Wire libremesh.mk into the installed-feeds dir.
#
# Most lime-* package Makefiles start with:
#
#     include ../../libremesh.mk
#
# In the source tree this resolves to <root>/libremesh.mk because
# the source layout is <root>/{libremesh.mk, packages/<pkg>/Makefile}.
# After `feeds install`, the per-package symlinks live at
# `package/feeds/lime_packages/<pkg>` and the relative include
# resolves to `package/feeds/lime_packages/libremesh.mk` — which
# does NOT exist (feeds install never copies non-package files from
# the feed root). Without this fix, every lime-* package that uses
# the helper is silently dropped from the kconfig (lime-proto-batadv,
# lime-proto-anygw, lime-hwd-*, batman-adv-auto-gw-mode, etc.) and
# the resulting LibreMesh image has no protocol stack.
# ----------------------------------------------------------------
echo "::group::wire libremesh.mk symlink"
mkdir -p package/feeds/lime_packages
ln -sfn /lime_pkg/libremesh.mk package/feeds/lime_packages/libremesh.mk
ls -la package/feeds/lime_packages/libremesh.mk
echo "::endgroup::"

echo "::group::feeds update lime_packages (after libremesh.mk symlink)"
./scripts/feeds update lime_packages
./scripts/feeds install -p lime_packages -f -a
echo "::endgroup::"

# ----------------------------------------------------------------
# .config: write the seed produced by the host wrapper, then run
# `make defconfig` to fill in transitive deps and resolve choice
# groups (e.g. CONFIG_BUSYBOX_*, CONFIG_OPENSSL_*).
# ----------------------------------------------------------------
echo "::group::.config seed (from host)"
cat /work/config.seed
echo "::endgroup::"
cp /work/config.seed .config

echo "::group::make defconfig"
make defconfig
echo "::endgroup::"

# Sanity: verify the device + initramfs survived defconfig. A typo in
# PROFILE_TARGET / PROFILE silently drops the `=y` lines and the build
# falls back to the source tree`s default device (often x86/64), wasting
# the ~50 min compile on the wrong target. Detect early and fail loud.
echo "::group::post-defconfig sanity"
required_yes=(
  "CONFIG_TARGET_${PROFILE_TARGET}=y"
  "CONFIG_TARGET_ROOTFS_INITRAMFS=y"
  "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y"
)
missing=()
for line in "${required_yes[@]}"; do
  if ! grep -qxF "${line}" .config; then
    missing+=("${line}")
  fi
done
# In the source tree we want the simple per-device kconfig name (no
# `_DEVICE_` MULTI_PROFILE prefix). If a future OpenWrt release
# flips MULTI_PROFILE`s default to y, accept the longer form too —
# this matches what build_image_sdk.sh used to do.
device_kconfigs=(
  "CONFIG_TARGET_${PROFILE_TARGET}_DEVICE_${PROFILE}=y"
  "CONFIG_TARGET_DEVICE_${PROFILE_TARGET}_DEVICE_${PROFILE}=y"
)
device_ok=0
for line in "${device_kconfigs[@]}"; do
  if grep -qxF "${line}" .config; then
    echo "post-defconfig sanity: device toggle = ${line}"
    device_ok=1
    break
  fi
done
if (( device_ok == 0 )); then
  missing+=("(device) one of: ${device_kconfigs[*]}")
fi
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: defconfig dropped required CONFIG lines:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo >&2
  echo "Diagnostic — all CONFIG_TARGET_*DEVICE* lines after defconfig:" >&2
  grep -E '^(CONFIG_TARGET_.*DEVICE|# CONFIG_TARGET_.*DEVICE)' .config | head -20 >&2 || true
  echo >&2
  echo "Diagnostic — INITRAMFS state:" >&2
  grep -E '^(CONFIG_TARGET_(ROOTFS_)?INITRAMFS|# CONFIG_TARGET_(ROOTFS_)?INITRAMFS)' .config >&2 || true
  exit 1
fi

# Sentinel package validation: same pattern as build_image_sdk.sh.
#   * lime-system uses `include $(TOPDIR)/rules.mk` directly — does
#     NOT rely on libremesh.mk. If THIS is missing, the src-link
#     feed itself failed to load (missing bind mount).
#   * lime-proto-batadv uses `include ../../libremesh.mk`. If
#     lime-system is OK but lime-proto-batadv is missing, the
#     libremesh.mk symlink fix above did not take effect.
# Catching both regressions here saves ~50 min of doomed compilation.
if ! grep -q '^CONFIG_PACKAGE_lime-system=y' .config; then
  echo "ERROR: CONFIG_PACKAGE_lime-system=y missing from .config after defconfig" >&2
  echo "       The lime_packages feed is either not linked or the package" >&2
  echo "       was renamed. ./scripts/feeds list -r lime_packages output:" >&2
  ./scripts/feeds list -r lime_packages 2>&1 | head -20 >&2 || true
  exit 1
fi
if ! grep -q '^CONFIG_PACKAGE_lime-proto-batadv=y' .config; then
  echo "ERROR: CONFIG_PACKAGE_lime-proto-batadv=y missing from .config after defconfig" >&2
  echo "       lime-system survived but lime-proto-batadv did not. This means" >&2
  echo "       the libremesh.mk include is not resolving inside the feed." >&2
  echo "       Symlink state:" >&2
  ls -la package/feeds/lime_packages/libremesh.mk >&2 || echo "  (link missing)" >&2
  echo "       lime-proto-* packages currently registered:" >&2
  ./scripts/feeds list -r lime_packages 2>&1 | grep '^lime-proto' >&2 || echo "  (none)" >&2
  exit 1
fi
echo "post-defconfig sanity: OK"
echo "::endgroup::"

# ----------------------------------------------------------------
# Pre-fetch every package source archive into dl/. Catches network
# flakiness BEFORE the multi-hour compile chain so a transient
# kernel.org / sourceforge hiccup fails fast instead of after 20 min
# of toolchain build. dl/ is the cached path so subsequent runs skip
# almost all of these downloads.
# ----------------------------------------------------------------
echo "::group::make download -j${MAKE_JOBS}"
make download -j"${MAKE_JOBS}"
echo "::endgroup::"

# ----------------------------------------------------------------
# Build the world. `world` is the default top-level target — it
# pulls in tools/, toolchain/, package/, target/, and finally the
# `image` rule that produces `bin/targets/<target>/<sub>/*.bin`.
#
# We pass V=s for verbose stderr so a CI failure shows the actual
# compile error (without V=s, the make output is heavily summarised
# and a typical failure shows just `make: *** [world] Error 1`).
# `tail -n 5000` keeps the artifact upload sane (typical successful
# build is ~80k lines of output, 50 MB raw — too big for a useful
# artifact upload).
# ----------------------------------------------------------------
echo "::group::make -j${MAKE_JOBS} world (this is the long one, ~10–60 min)"
mkdir -p logs
make -j"${MAKE_JOBS}" world V=s 2>&1 | tail -n 5000 || {
  rc=${PIPESTATUS[0]}
  echo "::error::make world failed (exit ${rc})" >&2
  echo "Last 200 lines of build output (see above; full log truncated to 5000 lines):" >&2
  exit "${rc}"
}
echo "::endgroup::"

# ----------------------------------------------------------------
# Locate the artifacts. ath79 / mediatek / filogic etc. all drop
# `*-initramfs-kernel.bin` next to the regular sysupgrade image
# under `bin/targets/<target>/<sub>/`. Resolve via shell glob so we
# don`t hardcode the release-arch-target naming convention (it has
# changed between 22.x / 23.x / 24.x).
# ----------------------------------------------------------------
echo "::group::bin/targets contents"
find bin/targets -type f -printf '  %p (%s bytes)\n' | sort
echo "::endgroup::"

init_img="$(find bin/targets -type f -name "*-${PROFILE}-initramfs-kernel.bin" | head -n 1)"
if [[ -z "${init_img}" ]]; then
  echo "ERROR: no *-${PROFILE}-initramfs-kernel.bin under bin/targets/" >&2
  echo "       The build did not produce an initramfs image. Verify" >&2
  echo "       CONFIG_TARGET_ROOTFS_INITRAMFS=y survived defconfig and" >&2
  echo "       that the device profile defines a KERNEL_INITRAMFS recipe" >&2
  echo "       in target/linux/<target>/image/<sub>.mk." >&2
  exit 1
fi

manifest="$(find bin/targets -type f -name "*-${PROFILE}.manifest" | head -n 1)"
if [[ -z "${manifest}" ]]; then
  echo "ERROR: no *-${PROFILE}.manifest under bin/targets/" >&2
  exit 1
fi

mkdir -p /work/out
cp -v "${init_img}" /work/out/
cp -v "${manifest}" /work/out/

echo "=== Final /work/out/ ==="
ls -la /work/out/
CONTAINER_SH
chmod 0755 "${DRIVER}"

mkdir -p "${WORK_DIR}/out" "${OUTPUT_DIR}"
chmod -R a+rX "${WORK_DIR}" "${FEED_DIR}"
chmod a+w "${WORK_DIR}/out"

echo ">>> Pulling build env image: ${BUILD_IMAGE}"
docker pull "${BUILD_IMAGE}"

# ---------------------------------------------------------------------
# Persistent OpenWrt source-build cache.
#
# Unlike the SDK path (where the SDK image ships a pre-built toolchain
# we MUST NOT mask), the source build clones a fresh OpenWrt tree and
# builds everything itself. So we cache the WHOLE openwrt directory:
# the clone, dl/, staging_dir/, build_dir/, .ccache/.
#
# Cache content topology (verified against v24.10.6, ath79-generic,
# librerouter profile, full LibreMesh package list):
#   * openwrt/.git                    ~250 MB  (shallow clone)
#   * openwrt/dl/                     ~500 MB  (source tarballs)
#   * openwrt/staging_dir/host        ~500 MB  (build host tools)
#   * openwrt/staging_dir/toolchain-* ~1   GB  (cross compiler)
#   * openwrt/build_dir/host          ~300 MB
#   * openwrt/build_dir/toolchain-*   ~2   GB  (toolchain build artefacts)
#   * openwrt/build_dir/target-*      ~3   GB  (NOT cached — always rebuilt)
#   * openwrt/.ccache                 ~500 MB
#   * openwrt/bin/                    ~10  MB  (NOT cached — output)
#
# The actions/cache step on the workflow side decides what to actually
# include in the cache key (build_dir/target-* and bin/ are excluded
# there via path patterns). This script just bind-mounts the host dir
# at /openwrt — whatever the host has, the container sees.
#
# When OPENWRT_SRC_CACHE_DIR is empty we fall back to a per-invocation
# mktemp dir (cold build, no persistence).
# ---------------------------------------------------------------------
if [[ -n "${OPENWRT_SRC_CACHE_DIR}" ]]; then
  OPENWRT_SRC_CACHE_DIR="$(realpath -m "${OPENWRT_SRC_CACHE_DIR}")"
  mkdir -p "${OPENWRT_SRC_CACHE_DIR}"
  OPENWRT_HOST_DIR="${OPENWRT_SRC_CACHE_DIR}"
  echo ">>> Using persistent OpenWrt source cache: ${OPENWRT_SRC_CACHE_DIR}"
  if [[ -d "${OPENWRT_SRC_CACHE_DIR}/.git" ]]; then
    echo "    cache appears warm: $(du -sh "${OPENWRT_SRC_CACHE_DIR}" 2>/dev/null | cut -f1 || echo "?") total"
  else
    echo "    cache empty / cold (first run for this key)"
  fi
else
  OPENWRT_HOST_DIR="${WORK_DIR}/openwrt"
  mkdir -p "${OPENWRT_HOST_DIR}"
  echo ">>> No OPENWRT_SRC_CACHE_DIR set; using ephemeral ${OPENWRT_HOST_DIR}"
  echo "    Expect a cold ~50 min build."
fi

# Export everything the in-container script consumes (Docker -e VAR
# without a value reads from the wrapper`s env, not from the lexical
# scope of the script).
export PROFILE PROFILE_TARGET OPENWRT_RELEASE OPENWRT_GIT_URL MAKE_JOBS

echo ">>> Running source build for ${PROFILE} (target=${PROFILE_TARGET}, MAKE_JOBS=${MAKE_JOBS})"
# Bind-mounts:
#   /work     → host wrapper`s work dir (config.seed, source_drive.sh, out/)
#   /openwrt  → OpenWrt source cache dir (persisted across runs)
#   /lime_pkg → lime-packages SOURCE ROOT (for src-link feed +
#               libremesh.mk symlink target)
#
# --user root: the SDK base image runs as user `buildbot` by default
# via the buildbot entrypoint. We override the entrypoint and run as
# root so we can write to /openwrt and /work without permissions
# dancing. The OpenWrt build itself dislikes running as root and
# checks for it; we work around that by setting FORCE_UNSAFE_CONFIGURE=1
# (env propagated through the docker run -e flag below) which is the
# documented escape hatch and what the gh-action-sdk does too.
docker run --rm \
  --user root \
  -e PROFILE \
  -e PROFILE_TARGET \
  -e OPENWRT_RELEASE \
  -e OPENWRT_GIT_URL \
  -e MAKE_JOBS \
  -e FORCE_UNSAFE_CONFIGURE=1 \
  -v "${WORK_DIR}:/work" \
  -v "${OPENWRT_HOST_DIR}:/openwrt" \
  -v "${FEED_DIR}:/lime_pkg:ro" \
  --entrypoint /bin/bash \
  "${BUILD_IMAGE}" \
  /work/source_drive.sh

# ---------------------------------------------------------------------
# Pick up artifacts. The in-container script has dropped:
#   * <stuff>-<profile>-initramfs-kernel.bin
#   * <stuff>-<profile>.manifest
# under /work/out. Rename to the firmware-<DEVICE>.{uimage,manifest}
# convention the workflow / labgrid YAML expect.
# ---------------------------------------------------------------------
echo "=== Selecting firmware artifact for ${PROFILE} (source build) ==="
ls -la "${WORK_DIR}/out/"

init_src="$(compgen -G "${WORK_DIR}/out/*-${PROFILE}-initramfs-kernel.bin" | head -n 1 || true)"
if [[ -z "${init_src}" ]]; then
  echo "::error::source build produced no *-${PROFILE}-initramfs-kernel.bin in /work/out/" >&2
  find "${WORK_DIR}/out" -type f -printf '  %p (%s bytes)\n' >&2 || true
  exit 1
fi

manifest_src="$(compgen -G "${WORK_DIR}/out/*-${PROFILE}.manifest" | head -n 1 || true)"
if [[ -z "${manifest_src}" ]]; then
  echo "::error::source build produced no *-${PROFILE}.manifest in /work/out/" >&2
  exit 1
fi

# Sanity: an ath79 initramfs-kernel.bin is a uImage. Magic must be
# 27 05 19 56 (legacy uImage). On other targets the wrapper differs
# (e.g. mediatek/filogic produces a FIT for `*-initramfs.itb`), so we
# only enforce the uImage magic when the file looks ath79-shaped.
init_magic=$(od -An -tx1 -N4 "${init_src}" | tr -d ' ')
case "${init_magic}" in
  27051956)
    echo ">>> ${init_src##*/} is a legacy uImage (magic 27051956) — OK for ath79 bootm"
    ;;
  *)
    echo "::warning::${init_src##*/} has magic ${init_magic} (not a legacy uImage)."
    echo "   build_image_source.sh has been used and tested on ath79 only."
    echo "   For other targets, double-check the labgrid YAML knows how to load this format."
    ;;
esac

# Hard-fail if the manifest is missing the LibreMesh core packages — same
# safety net as build_image.sh / the deleted build_image_sdk.sh. Catches
# the case where the local lime_packages feed silently failed to compile
# and the source build shipped a vanilla OpenWrt image.
echo "=== Manifest: ${manifest_src##*/} ($(wc -l < "${manifest_src}") packages) ==="
required_pkgs=(lime-system lime-proto-batadv lime-proto-anygw batctl-default)
missing_pkgs=()
for pkg in "${required_pkgs[@]}"; do
  if ! grep -qE "^${pkg} " "${manifest_src}"; then
    missing_pkgs+=("${pkg}")
  fi
done
if (( ${#missing_pkgs[@]} > 0 )); then
  echo "::error::source build manifest missing required LibreMesh packages: ${missing_pkgs[*]}" >&2
  echo "  This means the source build did not install the LibreMesh stack." >&2
  echo "  Manifest entries that look LibreMesh-related (none expected if broken):" >&2
  grep -E '^(lime|shared-state|babeld|firewall|batctl)' "${manifest_src}" >&2 || true
  exit 1
fi
echo ">>> Manifest validation OK"
grep -E '^(lime-|shared-state-|batctl|babeld|firewall4)' "${manifest_src}" || true

# Match the build_image.sh artifact naming convention: the bootable
# image gets the `.uimage` extension (so the test-firmware staging
# step picks it as the LG image, not the .manifest sidecar).
TARGET_FILE="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.uimage"
MANIFEST_TARGET="${OUTPUT_DIR}/firmware-${DEVICE_NAME}.manifest"
cp "${init_src}" "${TARGET_FILE}"
cp "${manifest_src}" "${MANIFEST_TARGET}"

echo ">>> Firmware output: ${TARGET_FILE} ($(stat -c%s "${TARGET_FILE}") bytes)"
echo ">>> Manifest output: ${MANIFEST_TARGET} ($(wc -l < "${MANIFEST_TARGET}") packages)"
echo ">>> Firmware sha256: $(sha256sum "${TARGET_FILE}" | cut -d' ' -f1)"
