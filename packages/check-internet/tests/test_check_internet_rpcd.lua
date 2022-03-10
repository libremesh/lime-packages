local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'

local test_file_name = "packages/check-internet/files/usr/libexec/rpcd/check-internet"
local check_internet = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local snapshot -- to revert luassert stubs and spies

describe('check-internet tests #checkinternet', function()
    it('test list methods', function()
        local response  = rpcd_call(check_internet, {'list'})
        assert.is.equal(0, response.is_connected.no_params)
    end)

    it('test is_connected', function()
        stub(os, "execute", function () return 1 end)

        local response  = rpcd_call(check_internet, {'call', 'is_connected'}, '')
        assert.is.equal("ok", response.status)
        assert.is_false(response.connected)
    end)

    it('test is_connected', function()
        stub(os, "execute", function () return 0 end)

        local response  = rpcd_call(check_internet, {'call', 'is_connected'}, '')
        assert.is.equal("ok", response.status)
        assert.is_true(response.connected)
    end)

    before_each('', function()
        snapshot = assert:snapshot()
    end)

    after_each('', function()
        snapshot:revert()
    end)
end)
