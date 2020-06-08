local su = require 'safe-upgrade'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local json = require 'luci.jsonc'

describe('safe-upgrade tests #safeupgrade', function()

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

end)
