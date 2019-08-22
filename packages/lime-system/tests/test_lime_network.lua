local config = require 'lime.config'
local network = require 'lime.network'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

local uci

describe('LiMe Network tests', function()

    it('test get_mac for loopback', function()
        assert.are.same({'00', '00', '00', '00', '00', '00'}, network.get_mac('lo'))
    end)

    it('test primary_interface', function()
        -- disable assertions beacause there is a check to validate
        -- that the interface really exists in the system
        test_utils.disable_asserts()
        config.set('network', 'lime')
        config.set('network', 'primary_interface', 'test0')
        uci:commit('lime')

        assert.is.equal('test0', network.primary_interface())
        test_utils.enable_asserts()
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
