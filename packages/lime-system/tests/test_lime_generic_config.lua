local config = require 'lime.config'
local gen_cfg = require 'lime.generic_config'
local test_utils = require 'tests.utils'

local uci = nil

describe('LiMe Generic config tests #genericconfig', function()

    it('test config.do_generic_uci_config', function()

        local content = [[
        config generic_uci_config libremap
            list uci_set "libremap.settings=libremap"
            list uci_set "libremap.settings.community=our.libre.org"
            list uci_set "libremap.settings.community_lat=-200.123"
            list uci_set "libremap.settings.community_lon=500.9"
        ]]

        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)
        assert.is_true(gen_cfg.do_generic_uci_config())

        -- check that everything is commited
        uci:load('libremap')
        assert.is.equal('our.libre.org', uci:get("libremap.settings.community"))
        assert.is.equal('-200.123', uci:get("libremap.settings.community_lat"))
        assert.is.equal('-200.123', uci:get("libremap.settings.community_lat"))
        assert.are.same({}, uci:changes())
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
