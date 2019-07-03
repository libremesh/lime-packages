local libuci = require 'uci'
local config = require 'lime.config'

-- disable logging in config module
config.log = function() end

uci = libuci:cursor()

describe('LiMe Config tests', function()

    it('test empty get', function()
        assert.is_nil(config.get('section_foo', 'option_bar'))
    end)

    it('test simple get', function()
        uci:set('lime', 'section_foo', 'option_bar', 'value')
        assert.is.equal('value', config.get('section_foo', 'option_bar'))
    end)

    it('test get with fallback', function()
        assert.is.equal('fallback', config.get('section_foo', 'option_bar', 'fallback'))
    end)

    it('test get with lime-default', function()

        uci:set('lime-defaults', 'section_foo', 'option_bar', 'default_value')
        assert.is.equal('default_value', config.get('section_foo', 'option_bar'))
    end)

    it('test get precedence of fallback and lime-default', function()
        -- lime-default wins over fallback
        uci:set('lime-defaults', 'section_foo', 'option_bar', 'default_value')
        assert.is.equal('default_value', config.get('section_foo', 'option_bar', 'fallback'))
    end)

    it('test get with false value', function()
        uci:set('lime', 'section_foo', 'option_bar', false)
        assert.is_false(config.get('section_foo', 'option_bar'))
    end)

    it('test get_bool', function()

        for _, value in pairs({1, 'on', 'true', 'enabled', true}) do
            uci:set('lime', 'foo', 'bar', value)
            assert.is_true(config.get_bool('foo', 'bar'))
        end

        for _, value in pairs({0, 'off', 'anything', false}) do
            uci:set('lime', 'foo', 'bar', value)
            assert.is_false(config.get_bool('foo', 'bar'))
        end
    end)

    it('test set', function()
        config.set('wlan0', 'htmode', 'HT20')
        assert.is.equal('HT20', config.get('wlan0', 'htmode'))
        assert.is.equal('HT20', uci:get('lime', 'wlan0', 'htmode'))

        config.set('wlan0', 'htmode', nil)
        assert.is_nil(config.get('wlan0', 'htmode'))

    end)

    it('test set nonstrings', function()
        -- convert integers to strings
        config.set('wifi', 'foo', 1)
        assert.is.equal('1', config.get('wifi', 'foo'))

        -- convert floats to strings
        config.set('wifi', 'foo', 1.9)
        assert.is.equal('1.9', config.get('wifi', 'foo'))

        -- convert booleans to strings
        config.set('wifi', 'foo', false)
        assert.is.equal('false', config.get('wifi', 'foo'))

        config.set('wifi', 'foo', true)
        assert.is.equal('true', config.get('wifi', 'foo'))
    end)

    it('test get_all', function()
        config.set('wifi', 'wlan0', '0')
        config.set('wifi', 'wlan1', '1')
        assert.is.equal('0', config.get_all('wifi').wlan0)
        assert.is.equal('1', config.get_all('wifi').wlan1)
    end)

    after_each('reset uci shared store', function()
        libuci:reset()
    end)
end)
