local utils = require "lime.utils"
local test_utils = require "tests.utils"
local lib = require "lime.upgrade"

local uci
local snapshot -- to revert luassert stubs and spies

describe('ubus-lime-utils tests #ubuslimeutils', function()
    it('test get_upgrade_info', function()

        local info = lib.get_upgrade_info()
        assert.is_false(info.is_upgrade_confirm_supported)
        assert.are.same(-1, info.safe_upgrade_confirm_remaining_s)

        os.execute("rm -f /tmp/upgrade_info_cache")

        stub(lib, "is_upgrade_confirm_supported", function () return true end)
        stub(lib, "safe_upgrade_confirm_remaining_s", function () return 101 end)
        info = lib.get_upgrade_info()
        assert.are.same(101, info.safe_upgrade_confirm_remaining_s)
        os.execute("rm -f /tmp/upgrade_info_cache")
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)
end)
