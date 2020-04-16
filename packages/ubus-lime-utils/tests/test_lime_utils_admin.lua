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

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
