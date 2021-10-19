local test_utils = require('tests.utils')
local config = require('lime.config')

local uci = nil

describe('migrate-wifi-bands-cfg script #migratewifibands', function()
    it('migrate community/node modes to lime-wifi-band uci sections', function()
        local default = [[
        config lime 'wifi'
            list modes 'ap'
            list modes 'apname'
            list modes 'ieee80211s'
        ]]

        local community = [[
        config lime 'wifi'
            list modes 'ap_2ghz'
            list modes 'apname_2ghz'
            list modes 'ieee80211s'
        ]]

        local node = [[
        config lime 'wifi'
            list modes 'ap_2ghz'
            list modes 'apname_2ghz'
            list modes 'ieee80211s_5ghz'
        ]]

		test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, default)
        test_utils.write_uci_file(uci, config.UCI_COMMUNITY_NAME, community)
        test_utils.write_uci_file(uci, config.UCI_NODE_NAME, node)
		
        migration_script = test_utils.load_lua_file_as_function('packages/lime-system/files/usr/bin/migrate-wifi-bands-cfg')
        migration_script()
        local default_wifi = uci:get_all(config.UCI_DEFAULTS_NAME, 'wifi')
        assert.are.same({ 'ap', 'apname', 'ieee80211s' }, default_wifi['modes'])
        local community_5ghz = uci:get_all(config.UCI_COMMUNITY_NAME, '5ghz')
        assert.are.same({ 'ieee80211s' }, community_5ghz['modes'])
        local community_2ghz = uci:get_all(config.UCI_COMMUNITY_NAME, '2ghz')
        assert.are.same({ 'ap', 'apname', 'ieee80211s'}, community_2ghz['modes'])
        local node_5ghz = uci:get_all(config.UCI_NODE_NAME, '5ghz')
        assert.are.same({ 'ieee80211s' }, node_5ghz['modes'])
        local node_2ghz = uci:get_all(config.UCI_NODE_NAME, '2ghz')
        assert.are.same({ 'ap', 'apname' }, node_2ghz['modes'])
    end)

    it('setup band modes to { manual } when no modes are available for that band', function()
        -- If band specific modes were left undefined, then general modes would be used.
        -- The mode 'manual' is used to prevent this behaviour (missing empty list configs),
        -- and mantain consistency with previous config setup. 
        local default = [[
        config lime 'wifi'
            list modes 'ap'
            list modes 'apname'
            list modes 'ieee80211s'
        ]]

        local community = [[
        config lime 'wifi'
            list modes 'ap_2ghz'
            list modes 'apname_2ghz'
        ]]

        local node = [[
        config lime 'wifi'
        ]]

		test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, default)
        test_utils.write_uci_file(uci, config.UCI_COMMUNITY_NAME, community)
        test_utils.write_uci_file(uci, config.UCI_NODE_NAME, node)
		
        migration_script = test_utils.load_lua_file_as_function('packages/lime-system/files/usr/bin/migrate-wifi-bands-cfg')
        migration_script()
        local community_5ghz = uci:get_all(config.UCI_COMMUNITY_NAME, '5ghz')
        assert.are.same({ 'manual' }, community_5ghz['modes'])
        local community_2ghz = uci:get_all(config.UCI_COMMUNITY_NAME, '2ghz')
        assert.are.same({ 'ap', 'apname'}, community_2ghz['modes'])
        local node_5ghz = uci:get_all(config.UCI_NODE_NAME, '5ghz')
        assert.is.equal(nil, node_5ghz)
    end)

    it('migrates other configs such as channel and htmode to lime-wifi-band uci sections', function()
        local community = [[
        config lime 'wifi'
            list channel_5ghz '48'
            list channel_5ghz '157'
            option channel_2ghz '1'
            option htmode_2ghz '20'
        ]]

        local node = [[
        config lime 'wifi'
        ]]

        test_utils.write_uci_file(uci, config.UCI_COMMUNITY_NAME, community)
        test_utils.write_uci_file(uci, config.UCI_NODE_NAME, node)
		
        migration_script = test_utils.load_lua_file_as_function('packages/lime-system/files/usr/bin/migrate-wifi-bands-cfg')
        migration_script()
        local community_5ghz = uci:get_all(config.UCI_COMMUNITY_NAME, '5ghz')
        assert.are.same({ '48', '157' }, community_5ghz['channel'])
        local community_2ghz = uci:get_all(config.UCI_COMMUNITY_NAME, '2ghz')
        assert.are.same('1', community_2ghz['channel'])
        assert.are.same('20', community_2ghz['htmode'])
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
