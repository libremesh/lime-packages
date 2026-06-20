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

* the `wmac`, `wmac1`, `gmac0`, and `wan` nodes reference the
  factory cells through their `nvmem-cells` properties, either as
  symbolic labels (`<&eeprom_factory_0>` etc.) when the DTB carries
  `__symbols__` (built with `dtc -@`), OR as numeric phandles
  (`<0x44>` etc.) when it does not. OpenWrt 24.10 builds normal
  kernel DTBs WITHOUT `-@`, so the references in the FIT-shipped
  DTB this patcher receives are the numeric form. Empirical
  evidence from CI run 25059904061: `dtc -I dtb -O dts` on
  `image-mt7622-linksys-e8450-ubi.dtb` produced a DTS where every
  `eeprom_factory_*` / `macaddr_factory_*` label was missing
  while the corresponding `eeprom@<addr>` / `macaddr@<addr>` nodes
  carried `phandle = <0xNN>;` properties.

We replace the entire `partitions { ... }` block with the layout 1.0
shape:

    bl2      partition@0
    fip      partition@80000      (read-only)
    factory  partition@1c0000     (read-only) - also the parent node
                                    for the eeprom_factory_* and
                                    macaddr_factory_* nvmem-cells
    ubi      partition@300000

The `factory` MTD partition declares the four nvmem-cells with
their original node names (`eeprom@0`, `eeprom@5000`,
`macaddr@7fff4`, `macaddr@7fffa`) and copies each cell's
`phandle = <0xNN>;` value verbatim from the original
`ubi-volume-factory > nvmem-layout` children. Re-using the same
phandle integers means the numeric references in
`wmac`/`wmac1`/`gmac0`/`wan` keep pointing at the right node after
recompile, no symbol table needed. We also keep the upstream
labels (`eeprom_factory_0:` etc.) for human readability and so the
patch is also correct against a DTB that DOES carry symbols (for a
future OpenWrt rev that flips on `-@` for kernel DTBs).

Idempotency and safety
======================

* The patcher refuses to run if the partitioning block it expects to
  rewrite (a `partitions { ... }` block whose body contains
  `compatible = "linux,ubi"`) is not found exactly once. That guards
  against future kernel revs that move the UBI declaration somewhere
  else, or against accidentally running this on an already-patched
  DTB (which has no `linux,ubi` block left).

* For each of the four expected factory cells the patcher reads the
  cell's phandle from the original block (if a `phandle` property
  exists; missing-phandle cells just emit the new node without one,
  trusting that nothing references them). If the input DTS has
  zero matches for a given cell name (e.g. `eeprom@0` vanished
  entirely), the patcher hard-fails - that would mean the upstream
  DTS shape changed in an incompatible way and the script needs
  updating.

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
# `&factory` nvmem cell declarations from the same file.
#
# Why these exact reg ranges:
#   bl2      0x000000-0x080000 - fixed by mt7622 boot ROM (the BootROM
#                                pulls BL2 from offset 0).
#   fip      0x080000-0x1c0000 - BL2 v2.4 looks for the FIP at 0x80000
#                                and reads up to 1.25 MiB; matches the
#                                23.05.5 OpenWrt FIP size.
#   factory  0x1c0000-0x2c0000 - vendor-supplied calibration EEPROM
#                                + dual MAC; OEM stores it here and the
#                                23.05 DTS expects it here.
#   ubi      0x300000-0x8000000 - leaves a 0x40000 gap (256 KiB) before
#                                ubi for the U-Boot environment, which
#                                23.05 stores in flash but does NOT
#                                expose as an MTD partition (legacy
#                                layout matches OpenWrt mainline).
#
# Placeholders `__PHANDLE_<name>_<addr>__` are replaced at rewrite
# time with the literal phandle property line copied from the
# original DTS. Each placeholder is at the END of the cell's reg
# line so a missing phandle (cell had no upstream reference)
# resolves to an empty string with no spurious whitespace artefact.
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
\t\t\t\t\treg = <0x00 0x4da8>;__PHANDLE_eeprom_0__
\t\t\t\t};

\t\t\t\teeprom_factory_5000: eeprom@5000 {
\t\t\t\t\treg = <0x5000 0xe00>;__PHANDLE_eeprom_5000__
\t\t\t\t};

\t\t\t\tmacaddr_factory_7fff4: macaddr@7fff4 {
\t\t\t\t\treg = <0x7fff4 0x06>;__PHANDLE_macaddr_7fff4__
\t\t\t\t};

\t\t\t\tmacaddr_factory_7fffa: macaddr@7fffa {
\t\t\t\t\treg = <0x7fffa 0x06>;__PHANDLE_macaddr_7fffa__
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


# Cells we must find inside the original `ubi-volume-factory >
# nvmem-layout` block, identified by their (node_name, addr_hex)
# tuple - these are deterministic across OpenWrt revs because they
# come straight from the upstream DTS source. We extract each cell's
# numeric phandle (if any) so the new MTD-backed partition can
# replicate it; numeric references downstream (`<0xNN>`) then
# resolve to the new node without depending on a `__symbols__`
# section that 24.10 does not emit.
FACTORY_CELLS: tuple[tuple[str, str], ...] = (
    ("eeprom",  "0"),
    ("eeprom",  "5000"),
    ("macaddr", "7fff4"),
    ("macaddr", "7fffa"),
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
    matches. Raises `RuntimeError` when more than one block matches -
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


def _extract_factory_phandles(
    block: str,
) -> dict[tuple[str, str], int | None]:
    """Walk `block` (typically the SPI-NAND `partitions { ... }`
    block we are about to replace) and return a mapping from
    `(node_name, addr)` to the phandle integer for each entry of
    FACTORY_CELLS.

    A `None` value means "node was found but had no `phandle`
    property"; this is legal - it means nothing references that cell
    and we can emit the new node without an explicit phandle.

    Raises `RuntimeError` when a cell node is missing entirely,
    which would mean the upstream DTS shape changed and we need to
    update FACTORY_CELLS.
    """
    out: dict[tuple[str, str], int | None] = {}
    for name, addr in FACTORY_CELLS:
        # Match `\b<name>@<addr> {` so addresses like `7fff4` cannot
        # accidentally be matched against `1c0000` etc. dtc may emit
        # the address as the bare hex digits or with a `0x` prefix in
        # rare cases - anchor to the literal upstream form, which
        # never carries the prefix on node units.
        pattern = rf"(?<![\w-]){re.escape(name)}@{re.escape(addr)}\s*\{{"
        m = re.search(pattern, block)
        if not m:
            raise RuntimeError(
                f"Cannot find `{name}@{addr}` in the original "
                "ubi-volume-factory block. The upstream DTS shape "
                "changed and patch_dtb_partitions.py needs updating "
                "(check FACTORY_CELLS against the current "
                "mt7622-linksys-e8450-ubi.dts)."
            )
        open_brace_idx = m.end() - 1
        node_end = _find_block_end(block, open_brace_idx)
        if node_end < 0:
            raise RuntimeError(
                f"Unbalanced braces while reading `{name}@{addr}` "
                "node in the original DTS."
            )
        body = block[open_brace_idx:node_end]
        pm = re.search(
            r"phandle\s*=\s*<\s*(0x[0-9a-fA-F]+|\d+)\s*>",
            body,
        )
        if pm is None:
            out[(name, addr)] = None
            continue
        raw = pm.group(1)
        out[(name, addr)] = int(raw, 16) if raw.startswith("0x") else int(raw)
    return out


def _format_phandle_line(value: int | None) -> str:
    """Render the phandle property line that follows a cell's `reg`
    declaration. Empty string when there is no phandle to copy -
    the placeholder slot in LAYOUT_1_0_BLOCK is on the same line as
    `reg = ...;` so this collapses cleanly.
    """
    if value is None:
        return ""
    # Hex form mirrors what dtc emits in -I dtb -O dts output, which
    # makes intermediate `.dts` files easier to diff against the
    # original. The exact textual form is irrelevant once dtc -I dts
    # -O dtb consumes it.
    return f"\n\t\t\t\t\tphandle = <0x{value:x}>;"


def patch_dts(dts: str) -> tuple[str, str]:
    """Apply the layout 1.0 rewrite. Returns `(patched_dts, summary)`.

    The summary string is suitable for stderr emission and lists the
    range that was rewritten and which phandles were preserved.
    Raises `RuntimeError` on any condition that would result in a
    half-patched / silently broken DTB."""
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
    original_block = dts[start:end]
    # Extract phandles from the soon-to-be-deleted block BEFORE we
    # replace it. Numeric references downstream (in wmac/gmac0/wan)
    # would otherwise dangle.
    phandles = _extract_factory_phandles(original_block)
    template = LAYOUT_1_0_BLOCK
    for (name, addr), value in phandles.items():
        placeholder = f"__PHANDLE_{name}_{addr}__"
        if placeholder not in template:
            raise RuntimeError(
                f"Internal: template is missing placeholder "
                f"{placeholder} - fix LAYOUT_1_0_BLOCK to match "
                "FACTORY_CELLS."
            )
        template = template.replace(placeholder, _format_phandle_line(value))
    # Defensive: any leftover placeholder means the FACTORY_CELLS
    # table and the template diverged.
    if "__PHANDLE_" in template:
        leftover = re.findall(r"__PHANDLE_[\w]+__", template)
        raise RuntimeError(
            "Internal: unsubstituted placeholders left in template: "
            f"{leftover}"
        )
    # The original block we replace ends with `;` (statement
    # terminator), so the template must do the same. Sanity-check
    # ourselves so a future template edit cannot ship a broken DTS.
    if not template.rstrip("\n").endswith("};"):
        raise RuntimeError(
            "Internal: layout 1.0 template does not end with `};` - "
            "this should be unreachable, fix the template literal."
        )
    # We do NOT try to re-indent the template to match the original
    # block's column. dtc is whitespace-agnostic; the recompiled
    # .dtb is identical regardless of indentation depth.
    out = dts[:start] + template + dts[end:]
    phandle_summary = ", ".join(
        f"{name}@{addr}->{('skip' if v is None else f'0x{v:x}')}"
        for (name, addr), v in phandles.items()
    )
    summary = (
        f"rewrote partitions block at bytes {start}..{end} "
        f"({end - start} bytes -> {len(template)} bytes); "
        f"factory phandles: {phandle_summary}"
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
