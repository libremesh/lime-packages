local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'

local test_file_name = "packages/ubus-lime-utils/files/usr/libexec/rpcd/lime-utils-admin"
local ubus_lime_utils = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local uci

local openwrt_release = [[DISTRIB_ID='LiMe'
DISTRIB_RELEASE='96dcfa439d2757067bc73812b218aa689be9ea57'
DISTRIB_REVISION='96dcfa4'
DISTRIB_TARGET='ar71xx/generic'
DISTRIB_ARCH='mips_24kc'
DISTRIB_DESCRIPTION='LiMe 96dcfa439d27570...'
DISTRIB_TAINTS='no-all busybox'
]]

describe('ubus-lime-utils-admin tests #ubuslimeutilsadmin', function()
    local snapshot -- to revert luassert stubs and spies
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

    it('test set_hostname', function()
        stub(utils, "unsafe_shell", function () return '-1' end)
        stub(os, "execute", function () return '0' end)
        uci:set(config.UCI_NODE_NAME, 'system', 'lime')
        uci:set(config.UCI_NODE_NAME, 'system', 'hostname', 'oldname')

        local response  = rpcd_call(ubus_lime_utils, {'call', 'set_hostname'}, '{"hostname": "foo"}')
        assert.is.equal("ok", response.status)
        assert.is.equal("foo", uci:get(config.UCI_NODE_NAME, 'system', 'hostname'))

        local response  = rpcd_call(ubus_lime_utils, {'call', 'set_hostname'}, '{}')
        assert.is.equal("error", response.status)
        assert.is.equal("Hostname not provided", response.msg)
        assert.is.equal("foo", uci:get(config.UCI_NODE_NAME, 'system', 'hostname'))

        local response  = rpcd_call(ubus_lime_utils, {'call', 'set_hostname'}, '{"hostname": "inv@lid-"}')
        assert.is.equal("error", response.status)
        assert.is.equal("Invalid hostname", response.msg)
        assert.is.equal("foo", uci:get(config.UCI_NODE_NAME, 'system', 'hostname'))
    end)

    it('test is_upgrade_confirm_supported in unsupported board', function()
        stub(os, "execute", function() return 1 end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'is_upgrade_confirm_supported'}, '')
        assert.is.equal("ok", response.status)
        assert.is_false(response.supported)
    end)

    it('test is_upgrade_confirm_supported in supported board', function()
        stub(os, "execute", function() return 0 end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'is_upgrade_confirm_supported'}, '')
        assert.is.equal("ok", response.status)
        assert.is_true(response.supported)
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
    end)

    it('test firmware_upgrade without new metadata', function()

        stub(os, "execute", function() return 0 end)
        stub(utils, "file_exists", function() return true end)
        stub(utils, "read_file", function() return openwrt_release end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_upgrade'},
                                    '{"fw_path": "/foo"}')
        assert.is.equal("ok", response.status)
        assert.is.equal("LiMe 96dcfa439d27570...", response.metadata.old_release_description)
        assert.is_false(response.metadata.config_preserved)
    end)

    it('test firmware_upgrade with metadata', function()
        stub(os, "execute", function() return 0 end)
        stub(os, "time", function() return 1500 end)
        stub(utils, "file_exists", function() return true end)
        stub(utils, "read_file", function() return openwrt_release end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_upgrade'},
                                   '{"fw_path": "/foo", "preserve_config": true, "metadata": {"foo": 1}}')
        assert.is.equal("ok", response.status)
        assert.is.equal("LiMe 96dcfa439d27570...", response.metadata.old_release_description)
        assert.is_true(response.metadata.config_preserved)
        assert.is.equal(1, response.metadata.foo)
        assert.is.equal(1500, response.metadata.local_timestamp)
    end)

    it('test last_upgrade_metadata', function()
        stub(utils, "file_exists", function() return true end)
        stub(utils, "read_file", function() return '{"foo": "bar"}' end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'last_upgrade_metadata'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal("bar", response.metadata.foo)
    end)

    it('test last_upgrade_metadata but no metadata is available', function()
        local response  = rpcd_call(ubus_lime_utils, {'call', 'last_upgrade_metadata'}, '')
        assert.is.equal("error", response.status)
        assert.is.equal("No metadata available", response.message)
    end)

    it('test firmware_confirm', function()
        stub(os, "execute", function() return 0 end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'firmware_confirm'}, '')
        assert.is.equal("ok", response.status)
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
