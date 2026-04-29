# Follow-up: Belkin RT3200 layout 1.0 KOD on OpenWrt 24.10 CI runs

## Status

Worked around in CI by `dtb_force_legacy_partitions: true` (added to
`linksys_e8450` in `.github/ci/targets.yml`). The patch rewrites the
SPI-NAND partitioning of the FIT-shipped DTB at build time so a 24.10
kernel running off TFTP keeps its hands off the on-flash BL31/FIP and
factory regions of devices that are still on
`DEVICE_COMPAT_VERSION 1.0`. Without the patch every CI run with a
24.10 kernel KODs the Belkin on its next power cycle.

The fix is one-sided: it only modifies the kernel that runs during a
CI test boot. The persistent BL2 + FIP + recovery installed on the
device flash stays at OpenWrt 23.05.5 — exactly what
`mtk_uartboot` plus the `openwrt-23.05.5-mediatek-mt7622-linksys_e8450-ubi-bl31-uboot.fip`
recovery image writes when a unit is being rescued from KOD.

This page is the diagnosis log and the user-facing pointer to the
patcher (`tools/ci/patch_dtb_partitions.py`); the script itself
documents its internals in detail.

## Symptom

> Belkins enter KOD after one CI run.
> After `mtk_uartboot` + U-Boot menu options 8 (write BL2) + 7
> (write FIP) the unit boots once, passes its `test-firmware` job,
> and is dead by the next power cycle. BL2 then fails on serial with:
>
>     ERROR: BL2: Failed to load image id 3 (-2)
>
> (image id 3 = BL31; -2 = -ENOENT).

OpenWrt 23.05.x firmware did NOT cause this. The regression appeared
when CI moved to OpenWrt 24.10 (`openwrt_release: "24.10.6"` in
`targets.yml`). The pattern is reproducible with every Belkin unit in
the lab.

## Root cause

Mainline OpenWrt rebuilt the SPI-NAND partitioning of the
linksys_e8450 / Belkin RT3200 between 23.05 and 24.10 in commits
that bumped `DEVICE_COMPAT_VERSION` from 1.0 to 2.0:

* `target/linux/mediatek/dts/mt7622-linksys-e8450-ubi.dts`
  (24.10): two MTD partitions only —
  * `bl2`     `0x000000  size 0x80000   (read-only)`
  * `ubi`     `0x080000  size 0x7f80000  (compatible = "linux,ubi")`,
                                          declares `fip`,
                                          `factory`, `ubootenv`,
                                          `fit` as static UBI
                                          volumes inline.

* same DTS in 23.05.5: four MTD partitions —
  * `bl2`     `0x000000  size 0x80000   (read-only)`
  * `fip`     `0x080000  size 0x140000  (read-only)`
  * `factory` `0x1c0000  size 0x100000  (read-only)`
  * `ubi`     `0x300000  size 0x7d00000`

A device that has been migrated to layout 2.0 (via
`owrt-ubi-installer v1.1.3+`) is on a fresh UBI created over the full
`0x080000-0x8000000` range, with `fip` and `factory` materialized
as UBI static volumes. The 24.10 DTS describes exactly that
on-flash topology. Everything works.

A device that is still on layout 1.0 (the lab Belkins, recovered with
`mtk_uartboot` + 23.05.5 FIPs every time they are rescued from KOD)
has BL31 + U-Boot living at the SPI-NAND bytes 0x080000-0x1c0000 and
WiFi/MAC calibration at 0x1c0000-0x2c0000, with the `ubi` MTD only
covering 0x300000+. When the 24.10 kernel boots from our TFTP-served
FIT and attaches UBI, the kernel-side UBI driver scans every
PEB-sized block within the `0x80000-0x8000000` range it was told
about. Bytes that on layout-1.0 hold BL31+u-boot and factory data
carry no valid UBI EC header, so the scan classifies them as
candidate empty PEBs. Over the run, UBI's wear-levelling allocator
writes its volume table and one or more new EBs over the BL31/FIP and
factory regions.

The next power cycle:

1. BootROM loads BL2 from offset 0x0 (still intact — read-only MTD).
2. BL2 loads FIP from offset 0x80000 (now a UBI EC header).
3. FIP signature check fails -> BL2 prints
   `Failed to load image id 3 (-2)` and the device is bricked at the
   first stage. KOD.

`hexdump /dev/mtd2` (factory) on a freshly-recovered Belkin shows
`UBI#` magic where calibration data should sit, confirming the
overwrite happened on a previous run.

## Why we patch the FIT and not the hardware

The "proper" fix is to migrate the Belkins to layout 2.0 with
`owrt-ubi-installer v1.1.4` (the OpenWrt-supplied tool that reflashes
BL2, rebuilds the UBI as layout 2.0 and copies factory data into it
as a UBI static volume). We tried this on the lab Belkins on
2026-04-27. The installer aborts with:

    INSTALLER: cannot find Wi-Fi EEPROM data
    sysrq: Trigger a crash
    Kernel panic - not syncing: sysrq triggered crash

because earlier 24.10 CI runs already wrote UBI metadata over the
on-flash `factory` MTD partition: there is no calibration data left
to back up, so the installer refuses to migrate (and it is correct
to do so — migrating with empty factory bytes would lose the unit's
OEM MAC and WiFi calibration permanently). Recovering it would
require a backup taken before the corruption (which the lab does
not have) plus serial-console reflashing of a known-good factory
image. We do not have either, so layout-2.0 migration is not
available to us.

Patching the FIT-shipped DTB avoids the migration entirely:

* The CI test boot is RAM-only initramfs. The kernel that runs
  never sysupgrades, never enforces `DEVICE_COMPAT_VERSION`, and
  never has to match the on-flash layout exactly.
* BL2 + FIP + recovery on the device stay at 23.05.5 (what
  `mtk_uartboot` flashes). Future KOD recoveries keep working
  with the same `mtk_uartboot` procedure already documented in
  `fcefyn_testbed_utils/docs/configuracion/duts-config.md`.
* The patched DTB tells the kernel the device is on layout 1.0,
  the kernel attaches UBI strictly to MTD offset 0x300000+, and
  the BL31/FIP bytes are no longer reachable from the UBI driver.

The trade-off is that the kernel inside the CI initramfs cannot use
the layout-2.0 features (UBI-resident `ubootenv`, `factory`, and
`fit` static volumes). That has no impact on what we test —
LibreMesh boots from RAM and never reads the on-flash UBI for
anything that matters.

## What the patch does (short version)

`tools/ci/patch_dtb_partitions.py` replaces the
`&snand { partitions { ... } }` block in the FIT-shipped DTB with
the layout 1.0 shape:

    bl2      partition@0
    fip      partition@80000      (read-only)
    factory: partition@1c0000     (read-only) — also the parent node
                                                for eeprom_factory_*
                                                and macaddr_factory_*
                                                nvmem-cells children
    ubi      partition@300000

It also re-publishes `eeprom@0`, `eeprom@5000`, `macaddr@7fff4`
and `macaddr@7fffa` as nvmem-cell children of the `factory` MTD
partition. To keep references from `wmac`/`wmac1`/`gmac0`/`wan`
resolving across the rewrite, the patcher reads the
`phandle = <0xNN>;` integer of each cell from the original
`ubi-volume-factory > nvmem-layout` block and injects the SAME
integer on the new MTD-backed cell. Numeric references downstream
(`nvmem-cells = <0x44>;` etc.) then point at the new node without
needing a `__symbols__` table — which OpenWrt 24.10 does NOT
emit for kernel DTBs (`dtc` is invoked WITHOUT `-@` for normal
target builds).

We discovered this empirically in CI run 25059904061 (job
73410967986): the first cut of the patcher required the
`eeprom_factory_*` / `macaddr_factory_*` labels to be present in
the decompiled DTS and hard-failed when they were not. The DTS
shipped by `image-mt7622-linksys-e8450-ubi.dtb` had no labels at
all on the factory cells but kept the `eeprom@0` etc. node names
plus `phandle = <0xNN>;` properties — the references in wmac /
gmac0 / wan were already in their numeric form. The current
patcher copies those phandle integers verbatim, which is the
minimal change that makes the rewrite sound on a label-less DTB.

The patcher is a textual rewrite over the DTS produced by
`dtc -I dtb -O dts`. It hard-fails if:

* the input DTS contains zero or more than one
  `partitions { ... compatible = "linux,ubi" ... }` blocks
  (means the DTS shape changed and the script needs updating, or
  the DTB is already patched);
* any of the four expected factory cell nodes (`eeprom@0`,
  `eeprom@5000`, `macaddr@7fff4`, `macaddr@7fffa`) is missing
  from the original block (means the upstream DTS layout shifted
  and `FACTORY_CELLS` in the script needs an update). A node
  that is present but has no `phandle` property is fine — we
  emit the new node without one and trust dtc to assign one
  freely on recompile.

## What the patch does NOT do

* It does not restore factory calibration bytes that previous CI
  runs already overwrote with UBI EC headers. The MAC / EEPROM
  `factory` partition will read zeros (or UBI metadata) on units
  whose `factory` MTD region got clobbered before the patch was
  in place. `dtb_patch_nvmem_mac: true` already handles the MAC
  side by injecting `local-mac-address` properties into
  `gmac0`/`wan`/DSA ports; WiFi PHYs (mt7615 / mt7915) will fall
  back to driver defaults for missing eeprom data.
* It does not move the on-flash device to layout 2.0. Re-attempting
  the `owrt-ubi-installer` migration on a recovered (post-patch)
  unit would require restoring a known-good `factory` blob first;
  out of scope here.
* It does not protect the `factory` MTD bytes against future direct
  writes (e.g. a kernel that ignores DT partitioning and writes
  flash directly via mtdblock). Nothing in our CI does that, so the
  guarantee `factory MTD = read-only` from the DTS is sufficient.

## How to verify on a CI run

After the patch lands, a build job for `linksys_e8450` should print
in `tools/ci/build_image.sh`:

    === Patching DTB stage 1: local-mac-address (workaround openwrt#22858) ===
    [patch_dtb_local_mac] ...
    === Patching DTB stage 2: legacy 23.05 SPI-NAND partitioning ===
    [patch_dtb_partitions] rewrote partitions block at bytes ... -> ... bytes
      patched DTB    : ... bytes; original ... bytes

On the device side, after a CI test boot, `cat /proc/mtd` should
report exactly four partitions in the layout-1.0 shape:

    mtd0: 00080000 ... "bl2"
    mtd1: 00140000 ... "fip"
    mtd2: 00100000 ... "factory"
    mtd3: 07d00000 ... "ubi"

and `dmesg` should NOT show any UBI scan over offsets below
0x300000. Power-cycling the unit after a CI run should bring it back
up cleanly at the U-Boot prompt — no KOD.

## Future cleanup

When the lab is ready to give up layout-1.0 entirely, the migration
path is:

1. Reflash a known-good `factory` blob via U-Boot menu (option that
   loads via TFTP and writes to MTD), per OpenWrt's installer doc.
2. Run `owrt-ubi-installer v1.1.4` to migrate to layout 2.0.
3. Drop `dtb_force_legacy_partitions: true` from
   `targets.yml` for `linksys_e8450`. The patcher then becomes
   dead code; keep it around behind the flag for documentation
   value (and as a recovery tool for any new layout-1.0 unit added
   to the lab in the future).

Until step 1 is feasible, the CI patch is the only fix that keeps
the lab Belkins booting OpenWrt 24.10 firmware reliably.
