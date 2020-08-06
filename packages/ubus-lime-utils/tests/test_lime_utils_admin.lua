local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'

local test_file_name = "packages/ubus-lime-utils/files/usr/libexec/rpcd/lime-utils-admin"
local ubus_lime_utils = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local uci

describe('ubus-lime-utils-admin tests #ubuslimeutilsadmin', function()
    it('test list methods', function()
        local response  = rpcd_call(ubus_lime_utils, {'list'})
        assert.is.equal(nil, response.set_root_password.no_params)
    end)

    it('test set_root_password', function()
        uci:set('lime-community', 'system', 'lime')
        stub(utils, "set_password", function (user, pass) return pass end)

        local response  = rpcd_call(ubus_lime_utils, {'call', 'set_root_password'},
                                    '{"password": "foo"}')

        assert.is.equal("ok", response.status)
        assert.stub(utils.set_password).was.called_with('root', 'foo')
        assert.is.equal("SET_SECRET", uci:get("lime-community", 'system', 'root_password_policy'))
    end)

    it('test is_upgrade_confirm_supported in unsupported board', function()
        stub(os, "execute", function() return 1 end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'is_upgrade_confirm_supported'}, '')
        assert.is.equal("ok", response.status)
        assert.is_false(response.supported)
        os.execute:revert()
    end)

    it('test is_upgrade_confirm_supported in supported board', function()
        stub(os, "execute", function() return 0 end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'is_upgrade_confirm_supported'}, '')
        assert.is.equal("ok", response.status)
        assert.is_true(response.supported)
        os.execute:revert()
    end)

    it('test firmware_verify inexistent file', function()
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_verify'},
                                    '{"fw_path": "/foo"}')
        assert.is.equal("error", response.status)
        assert.is.equal("Firmware file not found", response.message)
    end)

    it('test firmware_verify with confirm method', function()
        stub(os, "execute", function() return 0 end)
        stub(utils, "file_exists", function() return true end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_verify'},
                                    '{"fw_path": "/foo"}')
        assert.is.equal("ok", response.status)
        os.execute:revert()
        utils.file_exists:revert()
    end)

    it('test firmware_upgrade', function()
        stub(os, "execute", function() return 0 end)
        stub(utils, "file_exists", function() return true end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_upgrade'},
                                    '{"fw_path": "/foo"}')
        assert.is.equal("ok", response.status)
        assert.is.not_nil("ok", response.upgrade_id)
        os.execute:revert()
        utils.file_exists:revert()
    end)

    it('test firmware_confirm', function()
        stub(os, "execute", function() return 0 end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_confirm'}, '')
        assert.is.equal("ok", response.status)
        os.execute:revert()
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
