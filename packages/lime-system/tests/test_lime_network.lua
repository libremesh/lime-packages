local config = require 'lime.config'
local network = require 'lime.network'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

local uci

local BOARD = {
    ["model"] = {
        ["id"] = "test",
        ["name"] = "test machine",
    },
    ["network"] = {
        ["lan"] = {
            ["device"] = "lo",
            ["protocol"] = "static",
        },
        ["wan"] = {
            ["device"] = "wan",
            ["protocol"] = "dhcp",
        },
    }
}

describe('LiMe Network tests', function()

    it('test get_mac for loopback', function()
        assert.are.same({'00', '00', '00', '00', '00', '00'}, network.get_mac('lo'))
    end)

    it('test get_mac for ethernet', function()
        assert.is_nil (network.get_mac('nonexistent-interface'))
    end)

    it('test primary_interface configured interface', function()
        config.set('network', 'lime')
        config.set('network', 'primary_interface', 'test0')
        uci:commit('lime')
        stub(utils, "getBoardAsTable", function () return BOARD end)
        stub(network, "assert_interface_exists", function () return true end)

        assert.is.equal('test0', network.primary_interface())
    end)

    it('test primary_interface auto config', function()
        config.set('network', 'lime')
        config.set('network', 'primary_interface', 'auto')
        uci:commit('lime')
        assert.is.equal('lo', network.primary_interface())
    end)

    it('test primary_address(offset) ipv4 and ipv6 from config templates', function()
        config.set('network', 'lime')
        config.set('network', 'primary_interface', 'eth99')
        config.set('network', 'main_ipv4_address', '10.%N1.0.0/16')
        config.set('network', 'main_ipv6_address', 'fd%N1:%N2%N3:%N4%N5::/64')
        config.set('network', 'protocols', {'lan'})
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        uci:commit('lime')

        stub(network, "get_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)
        stub(network, "assert_interface_exists", function () return true end)

        local ipv4, ipv6 = network.primary_address()

        assert.is.equal('10.13.0.0', ipv4:network():string())
        assert.is.equal(16, ipv4:prefix())
        -- as 'lo' interface MAC address is 00:00:00:00:00 then
        -- the current algorithm should asign 10.13.0.0 but as it is
        -- the same as the network address then it uses the max ip
        -- address available
        assert.is.equal('10.13.255.254', ipv4:host():string())

        assert.is.equal('fd0d:fe46:8ce8::', ipv6:network():string())
        assert.is.equal(64, ipv6:prefix())
        assert.is.equal('fd0d:fe46:8ce8::', ipv6:host():string())
        network.get_mac:revert()
    end)

    it('test network.configure() with only lime.proto.lan', function()
        local ifname = 'eth99'
        config.set('system', 'lime')
        config.set('system', 'domain', 'lan')
        config.set('network', 'lime')
        config.set('network', 'primary_interface', ifname)
        config.set('network', 'main_ipv4_address', '10.%N1.0.0/16')
        config.set('network', 'main_ipv6_address', '2a00:1508:0a%N1:%N200::/64')
        config.set('network', 'protocols', {'lan'})
        config.set('network', 'resolvers', {'4.2.2.2'})
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        uci:commit('lime')

        stub(network, "get_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)
        stub(network, "scandevices", function () return  {eth99={}} end)
        stub(utils, "getBoardAsTable", function () return BOARD end)
        stub(network, "assert_interface_exists", function () return true end)

        bridge_section = uci:add("network", "device")
        uci:set("network", bridge_section, "type", "bridge")
        uci:set("network", bridge_section, "name", "br-lan")
        uci:commit("network")

        network.configure()

        assert.is.equal("1500", uci:get("network", "lan", "mtu"))
        assert.is.equal("static", uci:get("network", "lan", "proto"))
        assert.is.equal(ifname, uci:get("network", "@device[0]", "ports")[1])
        network.get_mac:revert()
        network.scandevices:revert()
    end)

    it('test createVlanIface() for ethernet address #vlan', function()
        local vid = 15
        network.createVlanIface('eth99', vid, '_fooproto')

        -- a device is created for the vlan
        assert.is.equal('eth99_15', uci:get("network", "lm_net_eth99_fooproto_dev", "name"))
        assert.is.equal('8021ad', uci:get("network", "lm_net_eth99_fooproto_dev", "type"))
        assert.is.equal('eth99', uci:get("network", "lm_net_eth99_fooproto_dev", "ifname"))
        assert.is.equal(tostring(vid), uci:get("network", "lm_net_eth99_fooproto_dev", "vid"))

        -- the interface
        assert.is.equal('eth99_15', uci:get("network", "lm_net_eth99_fooproto_if", "device"))
        assert.is.equal('1', uci:get("network", "lm_net_eth99_fooproto_if", "auto"))
        assert.is.equal('none', uci:get("network", "lm_net_eth99_fooproto_if", "proto"))
    end)

    it('test createVlanIface() for ethernet with vlan=0 #vlan', function()
        local vid = 0

        network.createVlanIface('eth99', vid, '_fooproto')

        -- a device is not created for the vlan
        assert.is_nil(uci:get("network", "lm_net_eth99_fooproto_dev", "name"))

        -- the interface uses static protocol
        assert.is.equal('eth99', uci:get("network", "lm_net_eth99_fooproto_if", "device"))
        assert.is.equal('1', uci:get("network", "lm_net_eth99_fooproto_if", "auto"))
        assert.is.equal('static', uci:get("network", "lm_net_eth99_fooproto_if", "proto"))
    end)

    it('test createVlanIface() for wireless #vlan', function()
        local vid = 15

        network.createVlanIface('wlan85', vid, '_fooproto')

        -- a device is created for the vlan
        assert.is.equal('wlan85_15', uci:get("network", "lm_net_wlan85_fooproto_dev", "name"))
        assert.is.equal('8021ad', uci:get("network", "lm_net_wlan85_fooproto_dev", "type"))
        assert.is.equal(tostring(vid), uci:get("network", "lm_net_wlan85_fooproto_dev", "vid"))
        assert.is.equal('@lm_net_wlan85', uci:get("network", "lm_net_wlan85_fooproto_dev", "ifname"))

        -- the interface
        assert.is.equal('wlan85_15', uci:get("network", "lm_net_wlan85_fooproto_if", "device"))
        assert.is.equal('1', uci:get("network", "lm_net_wlan85_fooproto_if", "auto"))
        assert.is.equal('none', uci:get("network", "lm_net_wlan85_fooproto_if", "proto"))
    end)

    it('test get_own_macs', function()
        assert.are.same({"00:00:00:00:00:00"}, network.get_own_macs("lo"))
        assert.are.same(network.get_own_macs(), network.get_own_macs("*"))
        assert.are.Not.same(network.get_own_macs("wlan0"), network.get_own_macs("*"))
        assert.are.Not.same(network.get_own_macs("wlan0"), network.get_own_macs("lo"))
    end)

    it('test device_exists returns true for existing device', function()
        assert.is_true(network.device_exists('lo'))
    end)

    it('test device_exists returns false for non-existing device', function()
        assert.is_false(network.device_exists('definitelynotadevicename'))
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
