local config = require 'lime.config'
local gen_cfg = require 'lime.generic_config'
local test_utils = require 'tests.utils'

local uci = nil

gen_cfg.ASSET_BASE_DIR = '/tmp/lime-assets/'

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
            option asset 'community/collectd.conf'
            option dst '/tmp/lime-test/collectd.conf'
        ]]

        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)
        assert.is_false(gen_cfg.do_copy_assets())
    end)

    it('test config.do_copy_assets node ', function()
        local content = [[
        config copy_asset collectd
            option asset 'node/collectd.conf'
            option dst '/tmp/lime-test/collectd.conf'
        ]]

        utils.write_file("/tmp/lime-assets/node/collectd.conf", "foo")
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        gen_cfg.do_copy_assets()

        assert.is.equal('foo', utils.read_file('/tmp/lime-test/collectd.conf'))
    end)

    it('test run_assets ATCONFIG #asdf', function()
        local content = [[
        config run_asset dropbear
            option asset 'node/dropbear.sh'
            option when 'ATCONFIG'
        ]]
        utils.write_file("/tmp/lime-test/assets_testing_file", "")
        utils.write_file("/tmp/lime-assets/node/dropbear.sh", "#!/bin/sh\nrm /tmp/lime-test/assets_testing_file")
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        assert.is_true(gen_cfg.do_run_assets(gen_cfg.RUN_ASSET_AT_CONFIG))
        assert.is_false(utils.file_exists("/tmp/lime-test/assets_testing_file"))
    end)

    it('test run_assets on a script that returns non-zero status', function()
        local content = [[
        config run_asset dropbear
            option asset 'community/dropbear.sh'
            option when 'ATCONFIG'
        ]]
        utils.write_file("/tmp/lime-assets/community/dropbear.sh", "#!/bin/sh\nexit 1")
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)
        assert.is_false(gen_cfg.do_run_assets(gen_cfg.RUN_ASSET_AT_CONFIG))
    end)

    it('test run_assets with a non-existent script', function()
        local content = [[
        config run_asset dropbear
            option asset 'comunity/i_dont_exist.sh'
            option when 'ATCONFIG'
        ]]
        test_utils.write_uci_file(uci, config.UCI_CONFIG_NAME, content)

        assert.is_false(gen_cfg.do_run_assets(gen_cfg.RUN_ASSET_AT_CONFIG))
    end)

    before_each('', function()
        os.execute('mkdir -p /tmp/lime-test /tmp/lime-assets/node/ /tmp/lime-assets/community/')
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        os.execute("rm -rf /tmp/lime-assets /tmp/lime-test")
        test_utils.teardown_test_uci(uci)
    end)
end)
