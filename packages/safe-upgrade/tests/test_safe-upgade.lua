local su = require 'safe-upgrade'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local json = require 'luci.jsonc'

local test_dir = nil

describe('safe-upgrade tests #safeupgrade', function()
    it('test get_partitions()', function()
        stub(su, 'get_uboot_env',
            function(part_name)
                if part_name == su.STABLE_PARTITION_NAME then
                    return 1
                elseif part_name == su.TESTING_PARTITION_NAME then
                    return 0
                else
                    assert.is_true(false)
                end
            end)
        local mtd_file = test_dir .. 'mtd'
        local mtd = [[dev:    size   erasesize  name
mtd0: 00040000 00010000 "u-boot"
mtd1: 00010000 00010000 "u-boot-env"
mtd2: 007d0000 00010000 "firmware"
mtd3: 00160000 00010000 "kernel"
mtd4: 00670000 00010000 "rootfs"
mtd5: 00480000 00010000 "rootfs_data"
mtd6: 007d0000 00010000 "fw2"
mtd7: 00010000 00010000 "ART"
]]
        utils.write_file(mtd_file, mtd)
        su._mtd_partitions_desc = mtd_file
        local partitions = su.get_partitions()
        assert.are.equal(1, partitions.current)
        assert.are.equal(2, partitions.other)
        assert.are.equal(1, partitions.stable)
        assert.are.equal(0, partitions.testing)

        local mtd = [[dev:    size   erasesize  name
mtd0: 00040000 00010000 "u-boot"
mtd1: 00010000 00010000 "u-boot-env"
mtd2: 007c0000 00010000 "fw1"
mtd3: 007c0000 00010000 "firmware"
mtd4: 00160000 00010000 "kernel"
mtd5: 00660000 00010000 "rootfs"
mtd6: 00310000 00010000 "rootfs_data"
mtd7: 00020000 00010000 "res"
mtd8: 00010000 00010000 "ART"
]]
        utils.write_file(mtd_file, mtd)
        su._mtd_partitions_desc = mtd_file
        local partitions = su.get_partitions()
        assert.are.equal(2, partitions.current)
        assert.are.equal(1, partitions.other)
        assert.are.equal(1, partitions.stable)
        assert.are.equal(0, partitions.testing)
    end)

    it('test is_current_board_supported()', function()
        stub(su, 'get_supported_devices', function () return {'librerouter-v1', 'librerouter-v2'} end)
        stub(su, 'get_current_device', function () return 'librerouter-v1' end)
        assert.is_true(su.is_current_board_supported())
        stub(su, 'get_current_device', function () return 'librerouter-v2' end)
        assert.is_true(su.is_current_board_supported())
        stub(su, 'get_current_device', function () return '' end)
        assert.is_false(su.is_current_board_supported())
        stub(su, 'get_current_device', function () return 'qemu-standard-pc' end)
        assert.is_false(su.is_current_board_supported())
        su.get_current_device:revert()
        su.get_supported_devices:revert()
    end)

    it('test is_firmware_valid()', function()
        local meta_lros = '{  "supported_devices":["librerouter-v1"] }'
        local meta_master = '{  "supported_devices":["librerouter,librerouter-v1"]}'
        local meta_v2 = '{  "supported_devices":["other,librerouter-v2"]}'
        local meta_other = '{  "supported_devices":["other"]}'
        stub(su, 'get_current_device', function () return 'librerouter-v1' end)
        assert.is_true(su.is_firmware_valid(json.parse(meta_lros)))
        assert.is_true(su.is_firmware_valid(json.parse(meta_master)))
        assert.is_false(su.is_firmware_valid(json.parse(meta_v2)))
        assert.is_false(su.is_firmware_valid(json.parse(meta_other)))
        assert.is_false(su.is_firmware_valid(nil))
        assert.is_false(su.is_firmware_valid({}))

        stub(su, 'get_current_device', function () return 'librerouter-v2' end)
        assert.is_false(su.is_firmware_valid(json.parse(meta_lros)))
        assert.is_false(su.is_firmware_valid(json.parse(meta_master)))
        assert.is_false(su.is_firmware_valid(json.parse(meta_v2)))
        assert.is_false(su.is_firmware_valid(json.parse(meta_other)))
        assert.is_false(su.is_firmware_valid(nil))
        assert.is_false(su.is_firmware_valid({}))
        su.get_current_device:revert()
    end)

    it('test preserve_files_to_new_partition preserve some', function()
        local preserve_file = test_dir .. 'foo'
        local preserve_inexistent_file = test_dir .. 'inexistent_foo'
        utils.write_file(preserve_file, '')
        stub(utils, 'keep_on_upgrade_files', function() return {preserve_file, preserve_inexistent_file} end)
        local args = {reboot_safety_timeout=600}
        local files_preserved = su.preserve_files_to_new_partition(args)
        local expected = {
            'etc/init.d/safe_upgrade_auto_reboot',
            'etc/rc.d/S11safe_upgrade_auto_reboot',
            'etc/safe_upgrade_auto_reboot_confirm_timeout_s',
             string.sub(preserve_file, 2)
        }
        assert.are.same(expected, files_preserved)
    end)

    it('test preserve_files_to_new_partition do not preserve', function()
        local preserve_file = test_dir .. 'foo'
        local preserve_inexistent_file = test_dir .. 'inexistent_foo'
        utils.write_file(preserve_file, '')
        stub(utils, 'keep_on_upgrade_files', function() return {preserve_file, preserve_inexistent_file} end)
        local args = {reboot_safety_timeout=600, do_not_preserve_config=true}
        local files_preserved = su.preserve_files_to_new_partition(args)
        local expected = {
            'etc/init.d/safe_upgrade_auto_reboot',
            'etc/rc.d/S11safe_upgrade_auto_reboot',
            'etc/safe_upgrade_auto_reboot_confirm_timeout_s',
        }
        assert.are.same(expected, files_preserved)
    end)

    it('test preserve_files_to_new_partition with archive', function()
        local preserve_archive = test_dir .. 'backup.tar.gz'
        os.execute('tar cfz ' .. preserve_archive .. ' /proc/version 2> /dev/null')
        stub(utils, 'keep_on_upgrade_files', function() return {} end)
        local args = {reboot_safety_timeout=600, preserve_archive=preserve_archive}
        local files_preserved = su.preserve_files_to_new_partition(args)
        local expected = {
            'etc/init.d/safe_upgrade_auto_reboot',
            'etc/rc.d/S11safe_upgrade_auto_reboot',
            'etc/safe_upgrade_auto_reboot_confirm_timeout_s',
            'proc/version',
        }
        assert.are.same(expected, files_preserved)
    end)

    before_each('', function()
        test_dir = test_utils.setup_test_dir()
    end)

    after_each('', function()
        test_utils.teardown_test_dir()
    end)
end)
