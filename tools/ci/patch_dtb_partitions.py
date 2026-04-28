#!/usr/bin/env python3
"""Rewrite the linksys_e8450-ubi DTB partitioning to use the legacy 23.05
layout (separate `bl2`, `fip`, `factory`, `ubi` MTD partitions) instead
of the OpenWrt 24.10 all-UBI layout (only `bl2` + `ubi`, with `fip` and
`factory` living as static volumes inside UBI).

Background
==========

In February 2024 OpenWrt mainline merged "mediatek: mt7622: modernize
Linksys E8450 / Belkin RT3200 UBI build" (DEVICE_COMPAT_VERSION 1.0 →
2.0). The new mt7622-linksys-e8450-ubi.dts shipped in 24.10 declares
exactly two MTD partitions:

    bl2      0x000000  size 0x80000   (read-only)
    ubi      0x080000  size 0x7f80000 (compatible = "linux,ubi";
                                       declares fip / factory / ubootenv
                                       / fit volumes inline)

That layout is correct on a device that has been migrated by
`owrt-ubi-installer v1.1.3+`, which physically reflashes BL2 + FIP and
re-creates the UBI from scratch with `fip` and `factory` as static
volumes.

It is catastrophically wrong on a device that is still on the legacy
23.05 layout, where:

    bl2      0x000000  size 0x80000   (read-only)
    fip      0x080000  size 0x140000  (read-only)
    factory  0x1c0000  size 0x100000  (read-only)
    ubi      0x300000  size 0x7d00000

When the kernel-side UBI driver attaches the 24.10 `ubi` MTD
(0x080000-0x8000000), its scan walks every PEB-sized block. The bytes
that on a layout-1.0 device hold BL31+u-boot (0x080000-0x1c0000) and
the WiFi/MAC factory data (0x1c0000-0x2c0000) carry no valid UBI EC
header, so UBI marks those blocks as candidate empty PEBs and over
time writes its volume table on top of them. The next power cycle then
KODs because BL2 cannot read BL31 from the now-overwritten `fip`
region (`ERROR: BL2: Failed to load image id 3 (-2)`).

The lab observed exactly this: every Belkin RT3200 unit passed the
first CI run after recovery and entered KOD on the next power-cycle,
and `hexdump /dev/mtd2` (factory) on the device showed `UBI#` magic
where calibration data should sit.

Why we patch the FIT-shipped DTB instead of migrating the hardware
=================================================================

The proper fix is `owrt-ubi-installer v1.1.4` (Linksys E8450 / Belkin
RT3200, OpenWrt 24.10.0): it reflashes BL2, rebuilds the UBI as
layout 2.0, and migrates the factory volume into UBI. We tried to run
it on the lab Belkins (see chat transcript 2026-04-27) and it aborts
with:

    INSTALLER: cannot find Wi-Fi EEPROM data
    sysrq: Trigger a crash

because earlier 24.10 CI runs already wrote UBI metadata over the
on-flash `factory` MTD partition: there is no calibration data left to
back up, so the installer refuses to migrate. Recovering it would
require a backup taken before the corruption (which we do not have)
plus serial-console reflashing. Patching the FIT-shipped DTB avoids
the recovery entirely: we ship a DTB that tells the kernel the device
is on layout 1.0, the kernel attaches UBI strictly to 0x300000+, and
the on-flash BL31/FIP that we just put back with `mtk_uartboot` stays
untouched forever. CI runs are RAM-booted initramfs anyway, so the
device never sysupgrades and never sees DEVICE_COMPAT_VERSION
enforcement.

The patch is one-sided: it only matters for the kernel that runs
during a CI test run. The installed-on-flash bootchain (BL2 + FIP +
recovery) stays at 23.05.5 (what `mtk_uartboot` and the
`openwrt-mediatek-mt7622-linksys_e8450-ubi-bl31-uboot.fip` recovery
images write).

What this patches
=================

Round-tripping the FIT-shipped DTB through dtc -I dtb -O dts gives us
a free-standing DTS where:

* the `&snand { partitions { ... } }` block lists exactly two
  partitions (`bl2`, `ubi`) with the 24.10 offsets, and the `ubi`
  child node carries `compatible = "linux,ubi"` plus a `volumes {}`
  subtree declaring `ubi-volume-fit`, `ubi-volume-factory`,
  `ubi-volume-ubootenv` etc.;

* the `wmac`, `wmac1`, `gmac0`, and `wan` nodes reference
  `<&eeprom_factory_0>`, `<&eeprom_factory_5000>`,
  `<&macaddr_factory_7fff4>`, `<&macaddr_factory_7fffa>` for their
  `nvmem-cells` properties (those four labels are emitted by dtc
  whenever the source DTB carries a `__symbols__` node — which the
  OpenWrt build always does).

We replace the entire `partitions { ... }` block with the layout 1.0
shape:

    bl2      partition@0
    fip      partition@80000      (read-only)
    factory  partition@1c0000     (read-only) — also the parent node
                                    for the eeprom_factory_* and
                                    macaddr_factory_* nvmem-cells
    ubi      partition@300000

The `factory` MTD partition declares `eeprom_factory_0`,
`eeprom_factory_5000`, `macaddr_factory_7fff4`, `macaddr_factory_7fffa`
as child nodes with the same labels the original `&ubi_factory`
nvmem-layout used. Because dtc preserves labels round-trip, the
existing `nvmem-cells = <&macaddr_factory_7fff4>;` references in
wmac/gmac0/wan/wmac1 keep resolving — but now to the new MTD-backed
cells, which the kernel reads directly from the SPI-NAND
`factory` partition (no UBI attach required).

Idempotency and safety
======================

* The patcher refuses to run if the partitioning block it expects to
  rewrite (a `partitions { ... }` block whose body contains
  `compatible = "linux,ubi"`) is not found exactly once. That guards
  against future kernel revs that move the UBI declaration somewhere
  else, or against accidentally running this on an already-patched
  DTB (which has no `linux,ubi` block left).

* We require the four `eeprom_factory_*` / `macaddr_factory_*` labels
  to exist in the input DTS. If they are missing, dtc decompiled a
  DTB without `__symbols__` (which would mean references downstream
  are numeric phandles instead of `&labels`), and our textual rewrite
  cannot guarantee correctness. Hard-fail with a clear message.

CLI
===

    patch_dtb_partitions.py [--in <dts>] [--out <dts>]

stdin/stdout when `--in`/`--out` are omitted; matches the
`patch_dtb_local_mac.py` convention used elsewhere in
tools/ci/build_image.sh.
"""

from __future__ import annotations

import argparse
import re
import sys


# Layout 1.0 partitioning, transcribed verbatim from
# https://github.com/openwrt/openwrt/blob/v23.05.5/target/linux/mediatek/dts/mt7622-linksys-e8450-ubi.dts
# (the dtsi `&snand { partitions { ... } }` block) and merged with the
# `&factory` nvmem cell declarations from the same file. Indentation
# below intentionally uses tabs to match dtc -I dtb -O dts default
# output style; the consuming dtc -I dts -O dtb is whitespace-agnostic
# but the textual diffs in CI logs are easier to read when consistent
# with the surrounding (untouched) DTS.
#
# Why these exact reg ranges:
#   bl2      0x000000-0x080000 — fixed by mt7622 boot ROM (the BootROM
#                                pulls BL2 from offset 0).
#   fip      0x080000-0x1c0000 — BL2 v2.4 looks for the FIP at 0x80000
#                                and reads up to 1.25 MiB; matches the
#                                23.05.5 OpenWrt FIP size.
#   factory  0x1c0000-0x2c0000 — vendor-supplied calibration EEPROM
#                                + dual MAC; OEM stores it here and the
#                                23.05 DTS expects it here.
#   ubi      0x300000-0x8000000 — leaves a 0x40000 gap (256 KiB) before
#                                ubi for the U-Boot environment, which
#                                23.05 stores in flash but does NOT
#                                expose as an MTD partition (legacy
#                                layout matches OpenWrt mainline).
LAYOUT_1_0_BLOCK = """\
\t\tpartitions {
\t\t\tcompatible = "fixed-partitions";
\t\t\t#address-cells = <0x01>;
\t\t\t#size-cells = <0x01>;

\t\t\tpartition@0 {
\t\t\t\tlabel = "bl2";
\t\t\t\treg = <0x00 0x80000>;
\t\t\t\tread-only;
\t\t\t};

\t\t\tpartition@80000 {
\t\t\t\tlabel = "fip";
\t\t\t\treg = <0x80000 0x140000>;
\t\t\t\tread-only;
\t\t\t};

\t\t\tfactory: partition@1c0000 {
\t\t\t\tlabel = "factory";
\t\t\t\treg = <0x1c0000 0x100000>;
\t\t\t\tread-only;
\t\t\t\tcompatible = "nvmem-cells";
\t\t\t\t#address-cells = <0x01>;
\t\t\t\t#size-cells = <0x01>;

\t\t\t\teeprom_factory_0: eeprom@0 {
\t\t\t\t\treg = <0x00 0x4da8>;
\t\t\t\t};

\t\t\t\teeprom_factory_5000: eeprom@5000 {
\t\t\t\t\treg = <0x5000 0xe00>;
\t\t\t\t};

\t\t\t\tmacaddr_factory_7fff4: macaddr@7fff4 {
\t\t\t\t\treg = <0x7fff4 0x06>;
\t\t\t\t};

\t\t\t\tmacaddr_factory_7fffa: macaddr@7fffa {
\t\t\t\t\treg = <0x7fffa 0x06>;
\t\t\t\t};
\t\t\t};

\t\t\tpartition@300000 {
\t\t\t\tlabel = "ubi";
\t\t\t\treg = <0x300000 0x7d00000>;
\t\t\t};
\t\t};
"""


# `partitions {` line, top-level (not a member like `volumes {`). The
# leading indent is captured so the replacement keeps the same column
# level as the original block, which is required for some readers that
# rely on dtc's whitespace cues (and keeps CI diffs readable).
PARTITIONS_HEADER_RE = re.compile(
    r"^([ \t]*)partitions\s*\{",
    re.MULTILINE,
)


# Marker we use to identify "this `partitions {` block is the one
# attached to the SPI-NAND". We can't anchor on the parent node name
# because dtc decompiles `&snand` to a path-based node ID we cannot
# predict (depends on SoC dtsi); but the all-UBI partitioning is the
# only place in any mediatek/mt7622 DTS where a partition declares
# `compatible = "linux,ubi"`, so that string is a reliable selector.
LINUX_UBI_MARKER = 'compatible = "linux,ubi"'


# Labels we MUST find somewhere in the input DTS before we rewrite the
# partitioning. If any is missing, dtc decompiled a DTB without
# preserved labels (no __symbols__ node), which means the references
# from wmac/gmac0/wan/wmac1 to factory cells are numeric phandles and
# our textual rewrite would silently leave them dangling.
REQUIRED_LABELS = (
    "eeprom_factory_0",
    "eeprom_factory_5000",
    "macaddr_factory_7fff4",
    "macaddr_factory_7fffa",
)


def _find_block_end(text: str, open_brace_idx: int) -> int:
    """Return the index just past the `}` matching the `{` at
    `open_brace_idx`. -1 on unbalanced input."""
    depth = 1
    i = open_brace_idx + 1
    while i < len(text) and depth > 0:
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    if depth != 0:
        return -1
    return i


def _find_snand_partitions(dts: str) -> tuple[int, int, str] | None:
    """Locate the start..end byte range of the `partitions { ... };`
    block whose body declares `compatible = "linux,ubi";`.

    Returns `(start, end, indent)` where `indent` is the whitespace
    preceding the `partitions {` keyword (used to reapply the original
    indentation to the replacement block). Returns None when no block
    matches. Raises `RuntimeError` when more than one block matches —
    that would mean a future DTS rev has multiple UBI-on-flash
    partitionings and we no longer know which one is the SPI-NAND.
    """
    matches: list[tuple[int, int, str]] = []
    for hdr in PARTITIONS_HEADER_RE.finditer(dts):
        open_brace_idx = hdr.end() - 1
        if dts[open_brace_idx] != "{":
            continue
        end = _find_block_end(dts, open_brace_idx)
        if end < 0:
            continue
        # Walk forward to the trailing `;` so we replace the full
        # statement (`partitions { ... };`), not just the braces. dtc
        # always emits the `;` immediately after `}` (possibly with
        # intervening whitespace).
        tail_end = end
        while tail_end < len(dts) and dts[tail_end] in " \t":
            tail_end += 1
        if tail_end < len(dts) and dts[tail_end] == ";":
            tail_end += 1
        # Also consume the trailing newline if present so the splice
        # leaves the surrounding DTS clean.
        if tail_end < len(dts) and dts[tail_end] == "\n":
            tail_end += 1
        block = dts[hdr.start():tail_end]
        if LINUX_UBI_MARKER in block:
            matches.append((hdr.start(), tail_end, hdr.group(1)))
    if not matches:
        return None
    if len(matches) > 1:
        raise RuntimeError(
            f"Found {len(matches)} `partitions {{}}` blocks containing "
            f"{LINUX_UBI_MARKER!r}; expected exactly one. Refusing to "
            "guess which one is the SPI-NAND. Update this script."
        )
    return matches[0]


def _check_required_labels(dts: str) -> list[str]:
    """Return the subset of REQUIRED_LABELS that is missing from the
    input DTS. An empty list means every label is present and the
    references downstream resolve symbolically."""
    missing = []
    for label in REQUIRED_LABELS:
        # Match `<label>:` with surrounding whitespace at the start of
        # a node header. dtc emits labels in this exact form
        # (`label: name@addr {`).
        if not re.search(rf"\b{re.escape(label)}\s*:", dts):
            missing.append(label)
    return missing


def patch_dts(dts: str) -> tuple[str, str]:
    """Apply the layout 1.0 rewrite. Returns `(patched_dts, summary)`.

    The summary string is suitable for stderr emission and lists the
    range that was rewritten. Raises `RuntimeError` on any condition
    that would result in a half-patched / silently broken DTB."""
    missing = _check_required_labels(dts)
    if missing:
        raise RuntimeError(
            "Input DTS is missing required factory-cell labels "
            f"({', '.join(missing)}). dtc -I dtb -O dts probably "
            "decompiled a DTB without a __symbols__ node, so the "
            "wmac / wmac1 / gmac0 / wan nvmem-cells references are "
            "numeric phandles. Textually rewriting the partitioning "
            "would leave them pointing at deleted nodes."
        )
    found = _find_snand_partitions(dts)
    if found is None:
        raise RuntimeError(
            "No `partitions { ... }` block containing "
            f"{LINUX_UBI_MARKER!r} found in the input DTS. The DTB "
            "either is already on layout 1.0 (so this patch is a "
            "no-op and should not have been requested), or the kernel "
            "DTS shape changed and this script needs updating."
        )
    start, end, _indent = found
    # We do NOT try to re-indent the template to match the original
    # block's column. Reasoning:
    #
    # * dtc is whitespace-agnostic. The recompiled .dtb is identical
    #   regardless of indentation depth, so functional correctness is
    #   not affected.
    # * Per-line re-indentation via a chain of `re.sub` over leading
    #   tabs caused a stacking bug (a 2-tab → 3-tab pass happened
    #   first, then the resulting 3-tab lines matched the next
    #   2-tab→2-tab clause, snowballing each level). Tracking it
    #   correctly would require parsing whitespace runs as
    #   tab-counters, which is overkill for a one-pass patch.
    # * The DTS is regenerated from the patched DTB on every CI run,
    #   so the human-readable indentation only matters when reading
    #   the intermediate `.patched.dts` artifact during debugging —
    #   and there the template's own `\t\t` baseline is perfectly
    #   legible.
    template = LAYOUT_1_0_BLOCK
    # The original block we replace ends with `;` (statement
    # terminator), so the template must do the same. Sanity-check
    # ourselves so a future template edit cannot ship a broken DTS.
    if not template.rstrip("\n").endswith("};"):
        raise RuntimeError(
            "Internal: layout 1.0 template does not end with `};` — "
            "this should be unreachable, fix the template literal."
        )
    out = dts[:start] + template + dts[end:]
    summary = (
        f"rewrote partitions block at bytes {start}..{end} "
        f"({end - start} bytes -> {len(template)} bytes)"
    )
    return out, summary


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(
        description="Rewrite linksys_e8450-ubi DTB partitioning to layout 1.0",
    )
    p.add_argument("--in", dest="in_path", default=None,
                   help="DTS input path (default: stdin)")
    p.add_argument("--out", dest="out_path", default=None,
                   help="DTS output path (default: stdout)")
    args = p.parse_args(argv)

    try:
        if args.in_path:
            with open(args.in_path, "r", encoding="utf-8") as f:
                src = f.read()
        else:
            src = sys.stdin.read()
    except OSError as exc:
        print(f"[patch_dtb_partitions] read failed: {exc}", file=sys.stderr)
        return 1

    try:
        patched, summary = patch_dts(src)
    except RuntimeError as exc:
        print(f"[patch_dtb_partitions] {exc}", file=sys.stderr)
        return 2

    print(f"[patch_dtb_partitions] {summary}", file=sys.stderr)

    try:
        if args.out_path:
            with open(args.out_path, "w", encoding="utf-8") as f:
                f.write(patched)
        else:
            sys.stdout.write(patched)
    except OSError as exc:
        print(f"[patch_dtb_partitions] write failed: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
