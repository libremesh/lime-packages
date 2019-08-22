local fs = require 'nixio.fs'
local test_utils = require "tests.utils"

describe("Test utils tests", function()
    it("test setup_test_uci check creation of empty config files", function()
        local uci = test_utils.setup_test_uci()
        local uci_confdir = uci:get_confdir()
        local f = io.open(uci_confdir .. "/wireless")
        assert.is_not_nil(f)
        assert.is.equal("", f:read("*a"))
        f:close()

        -- test that config file is not there anymore
        test_utils.teardown_test_uci(uci)
        f = io.open(uci_confdir .. "/wireless")
        assert.is_nil(f)
    end)
end)
