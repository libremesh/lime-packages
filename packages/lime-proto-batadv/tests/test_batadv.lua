local config = require 'lime.config'
local network = require 'lime.network'
local wireless = require 'lime.wireless'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local proto = require 'lime.proto.batadv'

-- disable logging in config module
config.log = function() end

local uci

describe('LiMe proto Batman-adv #protobatadv', function()
    it('test config', function()
        config.set('network', 'lime')
        config.set('network', 'protocols', {'lan'})
        stub(network, "primary_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)

        batadv.configured = false
        proto.configure()

        assert.is.equal('batadv', uci:get('network', 'bat0', 'proto'))
        assert.is.equal('1', uci:get('network', 'bat0', 'bridge_loop_avoidance'))
        assert.is.equal('0', uci:get('network', 'bat0', 'multicast_mode'))
        assert.is.equal('2000', uci:get('network', 'bat0', 'orig_interval'))

        -- anygw is disabled
        assert.is_nil(uci:get('network', 'bat0', 'distributed_arp_table'))
        assert.is_nil(uci:get('network', 'bat0', 'gw_mode'))
    end)

    it('test config 2', function()
        config.set('network', 'lime')
        config.set('network', 'protocols', {'lan', 'anygw'})
        stub(network, "primary_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)

        batadv.configured = false
        proto.configure()

        -- anygw is enabled
        assert.is.equal('0', uci:get('network', 'bat0', 'distributed_arp_table'))
        assert.is.equal('client', uci:get('network', 'bat0', 'gw_mode'))
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
