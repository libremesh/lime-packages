local config = require 'lime.config'
local network = require 'lime.network'
local wireless = require 'lime.wireless'
local utils = require 'lime.utils'
local hw_detection = require 'lime.hardware_detection'
local test_utils = require 'tests.utils'


-- disable logging in config module
config.log = function() end

local uci

local librerouter_board = test_utils.get_board('librerouter-v1')

describe('LiMe Config tests', function()
    it('test lime-config for a LibreRouter device #librerouter', function()
		local defaults = io.open('./packages/lime-system/files/etc/config/lime-defaults'):read("*all")
		test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, defaults)

		stub(wireless, "get_phy_mac", utils.get_id)
        stub(network, "get_mac", utils.get_id)
        stub(network, "assert_interface_exists", function () return true end)

        -- copy openwrt first boot generated configs
		for _, config_name in ipairs({'network', 'wireless'}) do
			local fin = io.open('tests/devices/librerouter-v1/uci_config_' .. config_name, 'r')
			local fout = io.open(uci:get_confdir() .. '/' .. config_name, 'w')
			fout:write(fin:read('*a'))
			fin:close()
			fout:close()
			uci:load(config_name)
		end

        local iwinfo = require 'iwinfo'
		iwinfo.fake.load_from_uci(uci)

        stub(utils, "getBoardAsTable", function () return librerouter_board end)
        table.insert(hw_detection.search_paths, 'packages/*hwd*/files/usr/lib/lua/lime/hwd/*.lua')

        config.main()

        assert.is.equal('eth0.1', config.get('lm_hwd_openwrt_wan', 'linux_name'))
        assert.is.equal('eth0', uci:get('network', 'lm_net_eth0_babeld_dev', 'ifname'))
        assert.is.equal('17', uci:get('network', 'lm_net_eth0_babeld_dev', 'vid'))
        assert.is.equal('eth0_17', uci:get('network', 'lm_net_eth0_babeld_if', 'ifname'))

        assert.is.equal(tostring(network.MTU_ETH_WITH_VLAN),
                        uci:get('network', 'lm_net_eth0_babeld_dev', 'mtu'))

        assert.is.equal('@lm_net_wlan1_mesh', uci:get('network', 'lm_net_wlan1_mesh_babeld_dev', 'ifname'))
        assert.is.equal('17', uci:get('network', 'lm_net_wlan1_mesh_babeld_dev', 'vid'))
        assert.is_nil(uci:get('network', 'lm_net_wlan1_mesh_babeld_dev', 'mtu'))

        assert.is.equal('29', uci:get('network', 'lm_net_wlan1_mesh_batadv_dev', 'vid'))

        assert.is_nil(uci:get('network', 'globals', 'ula_prefix'))
		for _, radio in ipairs({'radio0', 'radio1', 'radio2'}) do
			assert.is.equal('0', uci:get('wireless', radio, 'disabled'))
			assert.is.equal('1', uci:get('wireless', radio, 'noscan'))
		end

		assert.is.equal('11', uci:get('wireless', 'radio0', 'channel'))
		assert.is.equal('48', uci:get('wireless', 'radio1', 'channel'))
		assert.is.equal('157', uci:get('wireless', 'radio2', 'channel'))

		assert.is.equal('HT20', uci:get('wireless', 'radio0', 'htmode'))
		assert.is.equal('HT40', uci:get('wireless', 'radio1', 'htmode'))
		assert.is.equal('HT40', uci:get('wireless', 'radio2', 'htmode'))

		assert.is.equal('1000', uci:get('wireless', 'radio0', 'distance'))
		assert.is.equal('10000', uci:get('wireless', 'radio1', 'distance'))
		assert.is.equal('10000', uci:get('wireless', 'radio2', 'distance'))
    end)

	setup('', function()
		-- fake an empty hooksDir
        config.hooksDir = io.popen("mktemp -d"):read('*l')
	end)

	teardown('', function()
		io.popen("rm -r " .. config.hooksDir)
	end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
