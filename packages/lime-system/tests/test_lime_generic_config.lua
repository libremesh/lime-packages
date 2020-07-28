local config = require 'lime.config'
local gen_cfg = require 'lime.generic_config'
local test_utils = require 'tests.utils'

local uci = nil

describe('LiMe Generic config tests #genericconfig', function()

    it('test do_generic_uci_configs', function()

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
        assert.is.equal('500.9', uci:get("libremap.settings.community_lon"))
        assert.are.same({}, uci:changes())
    end)

    it('test do_generic_uci_configs with an invalid or non-existent key', function()

        local content = [[
        config generic_uci_config invalid
            list uci_set "invalid.settings.foo=bar"
        ]]

        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)
        assert.is_false(gen_cfg.do_generic_uci_configs())
    end)

    it('test generic_uci_configs with invalid key and good key', function()

        local content = [[
        config generic_uci_config invalid_syntax
            list uci_set "this is bad s!ntax=='1000'"
            list uci_set "libremap.settings=libremap"
            list uci_set "libremap.settings.community=our.libre.org"
        ]]

        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        assert.is_false(gen_cfg.do_generic_uci_configs())

        uci:load('libremap')
        -- check that even having one uci_set not working it will correctly set the other
        -- keys without crashing
        assert.is.equal('our.libre.org', uci:get("libremap.settings.community"))
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

        gen_cfg.do_copy_assets()

        assert.is.equal('foo', utils.read_file('/tmp/lime_test/collectd.conf'))
        os.execute("rm -r /tmp/lime-assets /tmp/lime_test")
    end)

    it('test run_assets on RECONFIG', function()
        local content = [[
        config run_asset dropbear
            option asset 'dropbear.sh'
            option when 'RECONFIG'
        ]]
        gen_cfg.NODE_ASSET_DIR = '/tmp/lime-assets/node/'
        os.execute('mkdir -p /tmp/lime-assets/node/')
        utils.write_file("/tmp/assets_testing_file", "")
        os.execute('printf "#!/bin/sh\nrm /tmp/assets_testing_file" > /tmp/lime-assets/node/dropbear.sh')
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        assert.is_true(gen_cfg.do_run_assets('RECONFIG'))
        assert.is_false(utils.file_exists("/tmp/assets_testing_file"))
        os.execute("rm -rf /tmp/lime-assets/ /tmp/assets_testing_file")
    end)

    it('test run_assets on a script that returns non-zero status', function()
        local content = [[
        config run_asset dropbear
            option asset 'dropbear.sh'
            option when 'RECONFIG'
        ]]
        gen_cfg.COMMUNITY_ASSET_DIR = '/tmp/lime-assets/community/'
        os.execute('mkdir -p /tmp/lime-assets/community/')
        os.execute('printf "#!/bin/sh\nexit 1" > /tmp/lime-assets/community/dropbear.sh')
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        assert.is_false(gen_cfg.do_run_assets('RECONFIG'))
        os.execute("rm -rf /tmp/lime-assets/")
    end)

    it('test run_assets with a non-existent script', function()
        local content = [[
        config run_asset dropbear
            option asset 'i_dont_exist.sh'
            option when 'RECONFIG'
        ]]
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        assert.is_false(gen_cfg.do_run_assets('RECONFIG'))
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
