local wireless = require 'lime.wireless'
local test_utils = require 'tests.utils'
local iwinfo = require('iwinfo')

local uci = nil

describe('LiMe Wireless tests', function()

    it('test get_mac for loopback', function()
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = true,})
        assert.is_true(wireless.is5Ghz('phy0'))
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = false,})
        assert.is_true(wireless.is5Ghz('phy0'))
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = false, ["b"] = false, ["ac"] = true, ["g"] = false, ["n"] = true,})
        assert.is_true(wireless.is5Ghz('phy0'))

        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = false, ["n"] = true,})
        assert.is_false(wireless.is5Ghz('phy0'))
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = true, ["n"] = false,})
        assert.is_false(wireless.is5Ghz('phy0'))
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
