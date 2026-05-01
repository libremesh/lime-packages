#!/usr/bin/env python3
"""Inject `local-mac-address` properties into the GMAC and DSA-WAN nodes of a
flattened DTS so the kernel never queries the (UBI-backed) factory NVMEM for
the device MAC.

Background
==========
On targets whose `factory` partition lives inside a UBI volume - e.g. the
Belkin RT3200 / Linksys E8450 (`mt7622-linksys-e8450-ubi.dts`) - `gmac0`
and the WAN switch port reference NVMEM cells provided by the UBI factory
volume:

    &gmac0 {
        nvmem-cells = <&macaddr_factory_7fff4>;
        nvmem-cell-names = "mac-address";
    };

The kernel calls `of_get_mac_address()` very early during `mtk_eth_soc.probe`,
which calls into `nvmem_cell_get()` for the `mac-address` cell. UBI itself is
not yet attached at that point, so `nvmem_cell_get()` returns `-EPROBE_DEFER`.
Per OpenWrt issue [openwrt/openwrt#22858] (NVMEM core perpetual `-EPROBE_DEFER`
blocks fallback mechanisms), the deferral is never converted to `-ENODEV`
even after the underlying flash partition fails to materialise, so the
ethernet driver stays stuck forever:

    [    X.YYY] platform 1b100000.ethernet: deferred probe pending: (reason unknown)

…and the MT7915E PCIe WiFi card never finishes its DMA-side probe either
(it shares the same factory volume for its EEPROM cell), leaving LibreMesh
without LAN, WAN nor WiFi - exactly the failure mode CI run 25004392669 hit
on `belkin_rt3200_2`.

The kernel resolves MAC addresses via `of_get_mac_address()`, which checks
DT properties **before** falling back to NVMEM:

    1. mac-address      (DT property)        <- short-circuits NVMEM
    2. local-mac-address (DT property)        <- short-circuits NVMEM
    3. nvmem-cells "mac-address"             <- suffers from the bug above

So injecting a deterministic `local-mac-address` into each affected node
makes the `nvmem-cells` reference moot for MAC purposes and unblocks the
deferred probe entirely.

What this patches
=================
Two node classes are patched in-place:

* `mac@<unit>` whose `compatible = "mediatek,eth-mac"` AND whose existing
  body declares `nvmem-cell-names = "mac-address"`. Matches `gmac0` (and
  `gmac1` if present) - the SoC GMAC nodes that otherwise stall
  `mtk_eth_soc.probe`.
* `port@<unit>` (DSA switch ports) whose body declares
  `nvmem-cell-names = "mac-address"`. Matches the WAN port (`port@4` on
  the MT7531 switch in linksys_e8450-ubi).

Nodes that already carry `local-mac-address` or `mac-address` are skipped,
so re-running the patch is idempotent.

MAC generation
==============
Each patched node receives a deterministic locally-administered unicast MAC
derived from `<profile>-<role>` via SHA-256. `role` is `gmac<unit>`,
`wan-port@<unit>`, etc., so two patched nodes never collide.

* The first byte is forced to `0x02` (locally-administered, unicast) per
  IEEE 802. This guarantees the MAC will never collide with an OEM-assigned
  address space and makes lab traffic easy to filter (`02:*:*:*:*:*` is
  obviously synthetic).
* The remaining five bytes come from `sha256(seed)[2:12]` so different
  CI rebuilds of the same board profile produce the same MAC - important
  for the testbed's DHCP / DNS records that pin per-DUT addresses.

The MAC is written into the DTS as a `[xx xx xx xx xx xx]` byte array,
which is the canonical DTS encoding for `local-mac-address` (matches what
upstream board DTSes write when they hard-code a MAC).

CLI
===
    patch_dtb_local_mac.py <profile> [--in <dts>] [--out <dts>]

If `--in`/`--out` are omitted the script reads stdin / writes stdout, which
is the form `tools/ci/build_image.sh` uses inside the ImageBuilder container
(`dtc -I dtb -O dts <dtb> | python3 patch_dtb_local_mac.py <profile> | dtc
-I dts -O dtb -o <dtb>`). Diagnostics go to stderr so they are visible in
the CI job log without contaminating the patched DTS on stdout.

Exit codes
==========
0 - patch attempted; output written. `--require-patch` upgrades
    "no node matched" to a hard error (exit 2). Useful in CI to fail the
    build loudly if a future DTS rename silently drops the patch instead
    of shipping a still-broken firmware.
2 - required patch could not be applied (only with `--require-patch`).
1 - argv / I/O error.

[openwrt/openwrt#22858]: https://github.com/openwrt/openwrt/issues/22858
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys


def gen_mac(seed: str) -> str:
    """Return a deterministic locally-administered unicast MAC encoded as
    six space-separated lowercase hex bytes (DTS `[xx xx xx xx xx xx]`)."""
    digest = hashlib.sha256(seed.encode("utf-8")).digest()
    octets = bytearray(digest[:6])
    # IEEE 802: bit 1 of the first octet is U/L (1 = locally administered),
    # bit 0 is I/G (0 = unicast). Force `0b000000_10` = 0x02 in the low
    # nibble while preserving the SHA-derived high nibble for entropy.
    octets[0] = (octets[0] & 0xFC) | 0x02
    return " ".join(f"{b:02x}" for b in octets)


def _find_block_end(text: str, open_brace_idx: int) -> int:
    """Given the index of an opening `{`, return the index just past the
    matching `}`. Counts nested braces. Returns -1 if no match."""
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
    return i  # past the closing `}`


# Anchor we use both as the "patch me" marker (in classify) and as the
# insertion point inside the matched block. DTS grammar (and `dtc -I dts`)
# enforce "properties must precede subnodes" within a node, so anchoring
# on an existing property guarantees our injected `local-mac-address`
# also lands in the property zone - even when the node carries
# subnodes after its property block (e.g. `port@4` on Belkin RT3200's
# MT7531 DSA switch wraps a `fixed-link {...}` after its
# `nvmem-cell-names`, which is precisely what made the previous
# "before closing `};`" placement explode with
# `dtc: Properties must precede subnodes` (CI run 25011299098).
#
# The capturing group (`([ \t]*)`) reuses the anchor's own indentation
# for the new property, so the patched DTS keeps the source's spacing
# convention (tabs vs spaces) intact.
NVMEM_MAC_ANCHOR_RE = re.compile(
    r'^([ \t]*)nvmem-cell-names\s*=\s*"mac-address"\s*;[ \t]*\n',
    re.MULTILINE,
)


def _inject_local_mac(text: str, node_re: re.Pattern, classify,
                      label: str, *, multi: bool = True) -> tuple[str, int]:
    """Walk every node header matched by `node_re`, scope each body to its
    matching brace pair, and inject a `local-mac-address` property
    immediately after the `nvmem-cell-names = "mac-address";` line in the
    body whenever `classify(block_text, regex_match)` returns a non-empty
    seed string.

    `classify` is responsible for both filtering (return `None` to skip)
    and deciding the MAC seed; it is only called for nodes that do **not**
    already carry a `local-mac-address` or `mac-address` property, so it
    cannot leak state between siblings even on already-patched DTSes.

    Iteration runs back-to-front so insertions never shift offsets of
    earlier matches still queued for processing.

    Returns `(patched_text, count)` where `count` is the number of nodes
    that received the new property. When `multi=False` only the first
    match is patched (used for tests that need exactly-one semantics)."""
    out = text
    count = 0
    matches = list(node_re.finditer(out))
    for m in reversed(matches):
        header_start = m.start()
        # m.end() points just past the `{` we anchored on (regex includes it).
        open_brace_idx = m.end() - 1
        if open_brace_idx < 0 or out[open_brace_idx] != "{":
            continue
        end = _find_block_end(out, open_brace_idx)
        if end < 0:
            continue
        block = out[header_start:end]
        # Skip nodes that already pin a MAC via DT properties - both
        # `local-mac-address` and `mac-address` short-circuit
        # `of_get_mac_address()` ahead of any NVMEM lookup, so injecting
        # again would be redundant and (for `mac-address`) would silently
        # override an OEM-pinned address. The negative lookbehind
        # forbids `nvmem-cell-names = "mac-address"` from matching, since
        # that string carries `mac-address` as the cell *name*, not as
        # an actual MAC property.
        if re.search(r"(?<!cell-names = \")\b(?:local-mac-address|mac-address)\s*=", block):
            print(f"[patch_dtb_local_mac] {label} at offset {header_start}: "
                  "already has mac-address/local-mac-address, skipping",
                  file=sys.stderr)
            continue
        seed = classify(block, m)
        if not seed:
            continue
        anchor_m = NVMEM_MAC_ANCHOR_RE.search(block)
        if anchor_m is None:
            # classify already required the anchor string; if we get here
            # the DTS shape changed (e.g. anchor split across lines) and
            # we'd rather fail loudly than ship a half-patched DTB.
            print(f"[patch_dtb_local_mac] {label} (seed={seed}): "
                  "anchor `nvmem-cell-names = \"mac-address\";` not found "
                  "on its own line - refusing to guess insertion point",
                  file=sys.stderr)
            continue
        indent = anchor_m.group(1)
        # anchor_m.end() points just past the trailing `\n` of the anchor
        # line, so insertion lands on a fresh line at the same depth.
        insert_at = header_start + anchor_m.end()
        mac = gen_mac(seed)
        prop = f"{indent}local-mac-address = [{mac}];\n"
        out = out[:insert_at] + prop + out[insert_at:]
        count += 1
        print(f"[patch_dtb_local_mac] {label} (seed={seed}): inserted "
              f"local-mac-address = [{mac}]", file=sys.stderr)
        if not multi:
            break
    return out, count


def patch_dts(dts: str, profile: str) -> tuple[str, int]:
    """Apply both GMAC and DSA-WAN injections to the DTS source.

    Returns `(patched_dts, total_count)`."""
    total = 0

    # 1) `mac@<unit>` with `compatible = "mediatek,eth-mac"` AND
    # `nvmem-cell-names = "mac-address"` - the SoC GMAC nodes
    # `mtk_eth_soc` binds against. The unit address is the GMAC index
    # (0 or 1), folded into the seed so two GMACs on the same board
    # never collide.
    mac_re = re.compile(r"\bmac@([0-9a-f]+)\s*\{", re.IGNORECASE)

    def _classify_eth_mac(block: str, m: re.Match) -> str | None:
        if 'compatible = "mediatek,eth-mac"' not in block:
            return None
        if 'nvmem-cell-names = "mac-address"' not in block:
            return None
        return f"{profile}-gmac{m.group(1)}"

    dts, c = _inject_local_mac(dts, mac_re, _classify_eth_mac,
                               label="mediatek,eth-mac")
    total += c

    # 2) DSA switch ports (`port@<unit>`) with
    # `nvmem-cell-names = "mac-address"` - the WAN port on Belkin
    # RT3200's MT7531 (port@4) is the canonical case; other vendors may
    # ship MAC NVMEM cells on additional ports.
    port_re = re.compile(r"\bport@([0-9a-f]+)\s*\{", re.IGNORECASE)

    def _classify_mac_port(block: str, m: re.Match) -> str | None:
        if 'nvmem-cell-names = "mac-address"' not in block:
            return None
        return f"{profile}-port{m.group(1)}"

    dts, c = _inject_local_mac(dts, port_re, _classify_mac_port,
                               label="dsa-port")
    total += c

    return dts, total


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(
        description="Inject local-mac-address into MAC-bearing DTS nodes "
                    "so the kernel skips the broken UBI-NVMEM lookup.",
    )
    p.add_argument("profile", help="OpenWrt profile name; used as MAC seed")
    p.add_argument("--in", dest="in_path", default=None,
                   help="DTS input path (default: stdin)")
    p.add_argument("--out", dest="out_path", default=None,
                   help="DTS output path (default: stdout)")
    p.add_argument("--require-patch", action="store_true",
                   help="Exit 2 if no node was patched")
    args = p.parse_args(argv)

    try:
        if args.in_path:
            with open(args.in_path, "r", encoding="utf-8") as f:
                src = f.read()
        else:
            src = sys.stdin.read()
    except OSError as exc:
        print(f"[patch_dtb_local_mac] read failed: {exc}", file=sys.stderr)
        return 1

    patched, count = patch_dts(src, args.profile)
    print(f"[patch_dtb_local_mac] total nodes patched: {count}",
          file=sys.stderr)

    if count == 0 and args.require_patch:
        print("[patch_dtb_local_mac] --require-patch: no nodes matched, "
              "this means the DTS no longer contains the GMAC / WAN "
              "patterns we know how to patch. Update this script.",
              file=sys.stderr)
        return 2

    try:
        if args.out_path:
            with open(args.out_path, "w", encoding="utf-8") as f:
                f.write(patched)
        else:
            sys.stdout.write(patched)
    except OSError as exc:
        print(f"[patch_dtb_local_mac] write failed: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
