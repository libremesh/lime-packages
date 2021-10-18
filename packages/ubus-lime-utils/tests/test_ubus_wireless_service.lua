local test_utils = require "tests.utils"
local config = require 'lime.config'
local wireless = require 'lime.wireless_service'

local wireless_service = test_utils.load_lua_file_as_function(
    "packages/ubus-lime-utils/files/usr/libexec/rpcd/wireless-service"
)

local wireless_service_admin = test_utils.load_lua_file_as_function(
    "packages/ubus-lime-utils/files/usr/libexec/rpcd/wireless-service-admin"
)


local rpcd_call = test_utils.rpcd_call
local uci
local snapshot -- to revert luassert stubs and spies

describe('ubus_wireless_service_admin #ubus_wireless_service', function()

    it('get_wifi_data wires to with get_access_points_data lib', function()
        local mocked_data = { some_data = "some_value" }
        stub(wireless, "get_access_points_data", function () return mocked_data end)
        local response = rpcd_call(wireless_service_admin, {'call', 'get_wifi_data'}, '')
        assert.stub(wireless.get_access_points_data).was.called_with(true)
        assert.is_equal("ok", response.status)
        assert.is_equal(mocked_data.some_data, response.some_data)
    end)

    it('set_node_ap wires to set_node_ap lib', function()
        stub(wireless, "set_node_ap", function () return end)
        local response = rpcd_call(wireless_service_admin, {'call', 'set_node_ap'},
            '{"has_password": true, "password": "some_password"}')
        assert.stub(wireless.set_node_ap).was.called_with(true, 'some_password')
        assert.is_equal("ok", response.status)
    end)

    it('set_community_ap wires to set_community_ap lib', function()
        stub(wireless, "set_community_ap", function () return end)
        local response = rpcd_call(wireless_service_admin, {'call', 'set_community_ap'},
            '{"enabled": true}')
        assert.stub(wireless.set_community_ap).was.called_with(true)
        assert.is_equal("ok", response.status)
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

describe('ubus_wireless_service #ubus_wireless_service', function()

    it('get_wifi_data wires to with get_acesss_points_data lib', function()
        local mocked_data = { some_data = "some_value" }
        stub(wireless, "get_access_points_data", function () return mocked_data end)
        local response = rpcd_call(wireless_service, {'call', 'get_wifi_data'}, '')
        assert.stub(wireless.get_access_points_data).was.called_with()
        assert.is_equal("ok", response.status)
        assert.is_equal(mocked_data.some_data, response.some_data)
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
