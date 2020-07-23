local config = require 'lime.config'
local gen_cfg = require 'lime.generic_config'
local test_utils = require 'tests.utils'

local uci = nil

describe('LiMe Generic config tests #genericconfig', function()

    it('test config.do_generic_uci_configs', function()

        local content = [[
        config generic_uci_config libremap
            list uci_set "libremap.settings=libremap"
            list uci_set "libremap.settings.community=our.libre.org"
            list uci_set "libremap.settings.community_lat=-200.123"
            list uci_set "libremap.settings.community_lon=500.9"
        ]]

        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)
        assert.is_true(gen_cfg.do_generic_uci_configs())

        -- check that everything is commited
        uci:load('libremap')
        assert.is.equal('our.libre.org', uci:get("libremap.settings.community"))
        assert.is.equal('-200.123', uci:get("libremap.settings.community_lat"))
        assert.is.equal('-200.123', uci:get("libremap.settings.community_lat"))
        assert.are.same({}, uci:changes())
    end)

    it('test config.do_copy_assets file not found', function()
        local content = [[
        config copy_asset collectd
            option asset 'collectd.conf'
            option dst '/tmp/lime_test/collectd.conf'
        ]]

        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)
        assert.is_false(gen_cfg.do_copy_assets())
    end)

    it('test config.do_copy_assets', function()
        local content = [[
        config copy_asset collectd
            option asset 'collectd.conf'
            option dst '/tmp/lime_test/collectd.conf'
        ]]
        gen_cfg.NODE_ASSET_DIR = '/tmp/lime-assets/node/'
        os.execute('mkdir -p /tmp/lime-assets/node/')
        os.execute('printf "foo" > /tmp/lime-assets/node/collectd.conf')
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        gen_cfg.do_copy_asset()

        assert.is.equal('foo', utils.read_file('/tmp/lime_test/collectd.conf'))
        os.execute("rm -r /tmp/lime-assets /tmp/lime_test")
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
