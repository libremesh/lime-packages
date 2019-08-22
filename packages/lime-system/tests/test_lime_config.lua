local config = require 'lime.config'

-- disable logging in config module
config.log = function() end

local uci

describe('LiMe Config tests', function()

    it('test get/set_uci_cursor', function()
        local cursor = config.get_uci_cursor()
        assert.are.equal(config.get_uci_cursor(), cursor)
        config.set_uci_cursor('foo')
        assert.is.equal('foo', config.get_uci_cursor())
        --restore cursor
        config.set_uci_cursor(cursor)
    end)
end)
