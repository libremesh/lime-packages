local su = require 'safe-upgrade'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'


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

end)
