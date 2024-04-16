local test_utils = require "tests.utils"
local json = require("luci.jsonc")
local eupgrade = require 'eupgrade'
local libuci = require 'uci'
local uci


local testFileName = "packages/lime-mesh-upgrade/files/usr/libexec/rpcd/lime-mesh-upgrade"
local limeRpc
local rpcdCall = test_utils.rpcd_call

describe('general rpc testing', function()
    local snapshot -- to revert luassert stubs and spies

    before_each('', function()
        limeRpc = test_utils.load_lua_file_as_function(testFileName)

        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()

        stub(utils, 'unsafe_shell', function(command)
            if command == "safe-upgrade confirm-remaining" then
            return confirm_remaining
            elseif command == "shared-state-async get mesh_wide_upgrade" then
                return "{}"
            end
            print(command)
            return confirm_remaining
        
        end)

        local boardname = 'librerouter-v1'
        stub(eupgrade, '_get_board_name', function()
            return boardname
        end)
        lime_mesh_upgrade = require 'lime-mesh-upgrade'

        snapshot = assert:snapshot()
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', "upgrade_state", "DEFAULT")
        uci:save('mesh-upgrade')
        config.set('network', 'lime')
        config.set('network', 'main_ipv4_address', '10.%N1.0.0/16')
        config.set('network', 'main_ipv6_address', 'fd%N1:%N2%N3:%N4%N5::/64')
        config.set('network', 'protocols', { 'lan' })
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        uci:commit('lime')
        uci:commit('mesh-upgrade')
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
        test_utils.teardown_test_dir()
    end)

    it('test list methods', function()
        local response = rpcdCall(limeRpc, { 'list' })
        assert.is.equal("value", response.become_main_node.url)
        assert.is.equal(0, response.start_safe_upgrade.confirm_timeout)
        assert.is.equal(0, response.abort.no_params)
        assert.is.equal(0, response.start_firmware_upgrade_transaction.no_params)
        assert.is.equal(0, response.get_node_status.no_params)

    end)

    it('test start_safe_upgrade different timeouts', function()
        stub(utils, 'execute_daemonized', function()
        end)
        
        stub(os, 'execute', function()
            return 0
        end)

        stub(lime_mesh_upgrade, 'state', function()
            return lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE
        end)

        stub(utils, 'file_exists', function()
            return true
        end)

        stub(lime_mesh_upgrade, 'get_fw_path', function()
            return "/tmp/foo.bar"
        end)

        local response = rpcdCall(limeRpc, { 'call', 'start_safe_upgrade'}, '{}')
        assert.are.equal("SUCCESS", response.code )
        assert.are.equal(600,response.su_confirm_timeout)
        assert.are.equal(60,response.su_start_time_out)
        local response = rpcdCall(limeRpc, { 'call', 'start_safe_upgrade'}, '{"confirm_timeout":15, "start_delay":150}')
        assert.are.equal(response.code, "SUCCESS")
        assert.are.equal(response.su_confirm_timeout, 15)
        assert.are.equal(response.su_start_time_out, 150)
        local response = rpcdCall(limeRpc, { 'call', 'start_safe_upgrade'}, '{}')
        assert.are.equal(response.code, "SUCCESS")
        assert.are.equal(response.su_confirm_timeout, 15)
        assert.are.equal(response.su_start_time_out, 150)
    end)



    it('test start_safe_upgrade invalid firmware file', function()
        stub(utils, 'execute_daemonized', function()
        end)
        
        stub(lime_mesh_upgrade, 'state', function()
            return lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE
        end)

        stub(utils, 'file_exists', function()
            return true
        end)

        stub(lime_mesh_upgrade, 'get_fw_path', function()
            return "/tmp/foo.bar"
        end)

        local response = rpcdCall(limeRpc, { 'call', 'start_safe_upgrade'}, '{}')
        assert.are.equal("NOT_ABLE_TO_START_UPGRADE", response.code )
        assert.are.equal("Invalid Firmware", response.error )
    end)
end)
