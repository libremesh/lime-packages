local test_utils = require "tests.utils"
local json = require 'luci.jsonc'

local test_file_name = "packages/lime-eth-config/files/usr/libexec/rpcd/lime-eth-config"
local ubus_eth_config = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call

local COMPLETE_BOARD = 
{
    ["model"] = {
        ["id"] = "librerouter,librerouter-v1",
        ["name"] = "LibreRouter v1",
    },
    ["switch"] = {
        ["switch0"] = {
            ["enable"] = true,
            ["reset"] = true,
            ["ports"] = {
                {
                    ["num"] = 0,
                    ["device"] = "eth0",
                    ["need_tag"] = false,
                    ["want_untag"] = false,
                },
                {
                    ["num"] = 5,
                    ["role"] = "wan",
                },
                {
                    ["num"] = 6,
                    ["device"] = "eth1",
                    ["need_tag"] = false,
                    ["want_untag"] = false,
                },
                {
                    ["num"] = 4,
                    ["role"] = "lan",
                },
            },
            ["roles"] = {
                {
                    ["role"] = "wan",
                    ["ports"] = "5 0t",
                    ["device"] = "eth0.1",
                },
                {
                    ["role"] = "lan",
                    ["ports"] = "4 6t",
                    ["device"] = "eth1.2",
                },
            },
        },
    },
    ["network"] = {
        ["wan"] = {
            ["device"] = "eth0.1",
            ["protocol"] = "dhcp",
        },
        ["lan"] = {
            ["device"] = "eth1.2",
            ["protocol"] = "static",
        },
    },
    ["gpioswitch"] = {
        ["poe_passthrough"] = {
            ["name"] = "PoE Passthrough",
            ["pin"] = "1",
            ["default"] = 0,
        },
    },
}
    
describe('ubus-eth-config tests #eth-config', function()
    it('test get_config ', function()
        stub(utils, "getBoardAsTable", function () return COMPLETE_BOARD end)

        local response  = rpcd_call(ubus_eth_config, {'call', 'get_eth_config'}, '{}')
        utils.printJson(response)
        assert.is.equal("ok", response.status)
        assert.is_not_nil(response.interfaces)
        assert.is.equal(4, #response.interfaces)

        local expected_interfaces = {
            {num = 5, device = "eth0.1", role = "wan", eth_role = "default"},
            {num = 0, device = "eth0.1", role = "cpu", eth_role = "default"},
            {num = 4, device = "eth1.2", role = "lan", eth_role = "default"},
            {num = 6, device = "eth1.2", role = "cpu", eth_role = "default"},
        }

        for _, expected in ipairs(expected_interfaces) do
            local found = false
            for _, actual in ipairs(response.interfaces) do
            if actual.num == expected.num and
               actual.device == expected.device and
               actual.role == expected.role and
               actual.eth_role == expected.eth_role then
                found = true
                break
            end
            end
            assert.is_true(found, "Expected interface not found: " .. json.stringify(expected))
        end
    end)

    it('test delete_eth_config', function()
        stub(utils, "getBoardAsTable", function () return COMPLETE_BOARD end)

        -- Set eth config
        local set_payload = json.stringify({device = "eth1.2", role = "wan"})
        local set_response = rpcd_call(ubus_eth_config, {'call', 'set_eth_config'}, set_payload)
        utils.printJson(set_response)
        assert.is.equal("ok", set_response.status)

        -- Delete eth config
        local delete_payload = json.stringify({device = "eth1.2",role = "default"})
        local delete_response = rpcd_call(ubus_eth_config, {'call', 'set_eth_config'}, delete_payload)
        utils.printJson(delete_response)
        assert.is.equal("ok", delete_response.status)

        -- Verify deletion
        local get_response = rpcd_call(ubus_eth_config, {'call', 'get_eth_config'}, '{}')
        utils.printJson(get_response)
        assert.is.equal("ok", get_response.status)
        assert.is_not_nil(get_response.interfaces)

        local found = false
        for _, interface in ipairs(get_response.interfaces) do
            if interface.device == "eth1.2" and interface.role == "wan" then
                found = true
                break
            end
        end
        assert.is_false(found, "Expected interface with device 'eth1.2' and role 'wan' still exists after deletion")
    end)

    it('test set_eth_config and get_eth_config', function()
        stub(utils, "getBoardAsTable", function () return COMPLETE_BOARD end)

        -- Set eth config
        local set_payload = json.stringify({device = "eth1.2", role = "mesh"})
        local set_response = rpcd_call(ubus_eth_config, {'call', 'set_eth_config'}, set_payload)
        utils.printJson(set_response)
        assert.is.equal("ok", set_response.status)

        -- Get eth config and verify
        local get_response = rpcd_call(ubus_eth_config, {'call', 'get_eth_config'}, json.stringify({device = "eth1.2", role = "default"}))
        utils.printJson(get_response)
        assert.is.equal("ok", get_response.status)
        assert.is_not_nil(get_response.interfaces)

        local found = false
        for _, interface in ipairs(get_response.interfaces) do
            if interface.device == "eth1.2" and interface.role == "mesh" then
                found = true
                break
            end
        end
        assert.is_false(found, "Expected interface with device 'eth1.2' and role 'mesh' not found")
    end)

end)
