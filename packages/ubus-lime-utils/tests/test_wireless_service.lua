local utils = require "lime.utils"
local test_utils = require "tests.utils"
local wireless_service = require "lime.wireless_service"
local wireless = require "lime.wireless"
local config = require "lime.config"
local network = require "lime.network"
local system = require "lime.system"

local snapshot -- to revert luassert stubs and spies
local uci = nil

local function mock_wifi_config()
    local defaults = [[
        config lime wifi
            option apname_ssid 'LibreMesh.org/%H'
            option ap_ssid 'LibreMesh.org'
        
        config lime-wifi-band '2ghz'
            list modes 'ap'
            list modes 'apname'
    ]]
        
    local community = [[
        config lime wifi
            option apname_ssid 'OurCommunity.org/%H'
            option ap_ssid 'OurCommunity.org'
    ]]
    
    local node = [[
        config lime wifi
            option apname_encryption 'psk2'
            option apname_key 'testpassword'
        
        config lime-wifi-band '2ghz'
            list modes 'apname'
    ]]

    test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, defaults)
    test_utils.write_uci_file(uci, config.UCI_COMMUNITY_NAME, community)
    test_utils.write_uci_file(uci, config.UCI_NODE_NAME, node)
    config.uci_autogen()
end

describe('wireless-service #wireless_service', function()
    describe('get_access_points_data', function()
        it('returns privileged node_ap settings when is_admin', function()
            mock_wifi_config()
            local result = wireless_service.get_access_points_data(true)
            local expected = {
                enabled = true, has_password = true,
                password = 'testpassword', ssid = 'OurCommunity.org/host'
            }
            assert.are.same(expected, result.node_ap)
        end)
        
        it('returns unprivileged node_ap settings when not is_admin', function()
            mock_wifi_config()
            local result = wireless_service.get_access_points_data()
            local expected = {
                enabled = true, has_password = true, ssid = 'OurCommunity.org/host'
            }
            assert.are.same(expected, result.node_ap)
        end)

        it('returns community_ap settings', function()
            mock_wifi_config()
            local result = wireless_service.get_access_points_data()
            local expected = {
                enabled = false, ssid = 'OurCommunity.org',
                community = {
                    enabled = true
                }
            }
            assert.are.same(expected, result.community_ap)
        end)
    end)

    describe('set_node_ap', function()
        it('changes apname password in node config', function()
            mock_wifi_config()
            wireless_service.set_node_ap(true, 'testpassword2')
            local password = uci:get(config.UCI_NODE_NAME, '2ghz', 'apname_key')
            local encryption = uci:get(config.UCI_NODE_NAME, '2ghz', 'apname_encryption')
            assert.is_equal('testpassword2', password)
            assert.is_equal('psk2', encryption)
            local node_ap = wireless_service.get_access_points_data(true).node_ap
            assert.is_true(node_ap.has_password)
            assert.is_equal('testpassword2', node_ap.password)
        end)

        it('removes apname password in node config', function()
            mock_wifi_config()
            wireless_service.set_node_ap(false)
            local encryption = uci:get(config.UCI_NODE_NAME, '2ghz', 'apname_encryption')
            assert.is_equal('none', encryption)
            local node_ap = wireless_service.get_access_points_data().node_ap
            assert.is_false(node_ap.has_password)
        end)
    end)

    describe('set_community_ap', function()
        local function mock_community_ap_disabled()
            local defaults = [[
                config lime wifi
                    list modes 'ap'
                    list modes 'apname'
            ]]
            
            local community = [[
                config lime wifi
            ]]

            local node = [[
                config lime wifi
                    list modes 'apname'
            ]]
        
            test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, defaults)
            test_utils.write_uci_file(uci, config.UCI_COMMUNITY_NAME, community)
            test_utils.write_uci_file(uci, config.UCI_NODE_NAME, node)
            config.uci_autogen()
        end

        local function mock_community_ap_enabled()
            local defaults = [[
                config lime wifi
                    list modes 'ap'
                    list modes 'apname'
            ]]
            local community = [[
                config lime wifi
            ]]

            local node = [[
                config lime wifi
            ]]
                
            test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, defaults)
            test_utils.write_uci_file(uci, config.UCI_COMMUNITY_NAME, community)
            test_utils.write_uci_file(uci, config.UCI_NODE_NAME, node)
            config.uci_autogen()
        end

        it('enables community ap', function()
            mock_community_ap_disabled()
            wireless_service.set_community_ap(true)
            local modes = uci:get(config.UCI_NODE_NAME, '2ghz', 'modes')
            local all = uci:get_all(config.UCI_NODE_NAME, '2ghz')
            assert.is_true(utils.has_value(modes, 'ap'))
        end)

        it('disables community ap', function()
            mock_community_ap_enabled()
            wireless_service.set_community_ap(false)
            local modes = uci:get(config.UCI_NODE_NAME, '2ghz', 'modes')
            assert.are.same({'apname'}, modes)
        end)
    end)

    before_each('', function()
        stub(system, "get_hostname", function () return 'host' end)
        stub(network, "primary_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)
        stub(utils, "unsafe_shell", function () config.uci_autogen() end)
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)
end)
