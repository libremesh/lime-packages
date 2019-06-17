local su = require "safe-upgrade"

describe("safe-upgrade tests", function()

    it("test get current partition", function()

        proc_mtd = [[#!
        dev:    size   erasesize  name
        mtd0: 00020000 00010000 "factory-uboot"
        mtd1: 00020000 00010000 "u-boot"
        mtd2: 00180000 00010000 "kernel"
        mtd3: 00d40000 00010000 "rootfs"
        mtd4: 00b10000 00010000 "rootfs_data"
        mtd5: 000f0000 00010000 "config"
        mtd6: 00010000 00010000 "firmware"
        mtd7: 00ec0000 00010000 "fw2"
        mtd8: 00ec0000 00010000 "ART"
        ]]
        assert.is.equal(su.get_current_partition(proc_mtd), 1)

        proc_mtd = [[#!
        dev:    size   erasesize  name
        mtd0: 00020000 00010000 "factory-uboot"
        mtd1: 00020000 00010000 "u-boot"
        mtd2: 00180000 00010000 "kernel"
        mtd3: 00d40000 00010000 "rootfs"
        mtd4: 00b10000 00010000 "rootfs_data"
        mtd5: 000f0000 00010000 "config"
        mtd6: 00010000 00010000 "fw1"
        mtd7: 00ec0000 00010000 "firmware"
        mtd8: 00ec0000 00010000 "ART"
        ]]
        assert.is.equal(su.get_current_partition(proc_mtd), 2)

    end)
end)
