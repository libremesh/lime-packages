local config = require 'lime.config'
local network = require 'lime.network'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

utils.disable_logging()
local uci

local BOARD = {
    ["model"] = {
        ["id"] = "test",
        ["name"] = "test machine",
    },
    ["network"] = {
        ["lan"] = {
            ["ifname"] = "lo",
            ["protocol"] = "static",
        },
        ["wan"] = {
            ["ifname"] = "eth0",
            ["protocol"] = "dhcp",
        },
    }
}

describe('LiMe Network tests', function()

    it('test get_mac for loopback', function()
        assert.are.same({'00', '00', '00', '00', '00', '00'}, network.get_mac('lo'))
    end)

    it('test primary_interface configured interface', function()
        -- disable assertions beacause there is a check to validate
        -- that the interface really exists in the system
        test_utils.disable_asserts()
        config.set('network', 'lime')
        config.set('network', 'primary_interface', 'test0')
        uci:commit('lime')
        stub(utils, "getBoardAsTable", function () return BOARD end)

        assert.is.equal('test0', network.primary_interface())
        test_utils.enable_asserts()
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
        config.set('network', 'main_ipv6_address', '2a00:1508:0a%N1:%N200::/64')
        config.set('network', 'protocols', {'lan'})
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        uci:commit('lime')

        stub(network, "get_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)
        test_utils.disable_asserts()
        local ipv4, ipv6 = network.primary_address()
        test_utils.enable_asserts()
        assert.is.equal('10.13.0.0', ipv4:network():string())
        assert.is.equal(16, ipv4:prefix())
        -- as 'lo' interface MAC address is 00:00:00:00:00 then
        -- the current algorithm should asign 10.13.0.0 but as it is
        -- the same as the network address then it uses the max ip
        -- address available
        assert.is.equal('10.13.255.254', ipv4:host():string())

        assert.is.equal('2a00:1508:a0d:fe00::', ipv6:network():string())
        assert.is.equal(64, ipv6:prefix())
        assert.is.equal('2a00:1508:a0d:fe00::', ipv6:host():string())
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

        test_utils.disable_asserts()
        network.configure()
        test_utils.enable_asserts()

        assert.is.equal("1500", uci:get("network", "lan", "mtu"))
        assert.is.equal("static", uci:get("network", "lan", "proto"))
        assert.is.equal(ifname, uci:get("network", "lan", "ifname")[1])
        network.get_mac:revert()
        network.scandevices:revert()
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
