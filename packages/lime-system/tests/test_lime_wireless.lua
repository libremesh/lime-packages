local wireless = require 'lime.wireless'
local test_utils = require 'tests.utils'
local system = require("lime.system")
local iwinfo = require('iwinfo')

local uci = nil

describe('LiMe Wireless tests #wireless', function()

    it('test is5Ghz(phy) with single freq radios', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'band', '2g')
        uci:set('wireless', 'radio1', 'wifi-device')
        uci:set('wireless', 'radio1', 'band', '5g')

        local devices = wireless.scandevices()

        assert.is_false(devices["radio0"].is5Ghz('phy0'))
        assert.is_true(devices["radio1"].is5Ghz('phy0'))
    end)

    it('test scandevices() no wireless', function()
		local devices = wireless.scandevices()
		assert.is.equal(0, utils.tableLength(devices))
    end)

    it('test scandevices() one dev', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

		local devices = wireless.scandevices()
		assert.is.equal(1, utils.tableLength(devices))
		assert.is.equal(0, devices['radio0']['.index'])
		assert.is.equal('radio0', devices['radio0']['.name'])
		assert.is.equal(0, devices['radio0'].per_band_index)
    end)

    it('test scandevices() two devs same band', function()
		uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
		uci:set('wireless', 'radio1', 'wifi-device')
        uci:set('wireless', 'radio1', 'hwmode', '11a')

        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

		local devices = wireless.scandevices()
		assert.is.equal(2, utils.tableLength(devices))
		assert.is.equal(0, devices['radio0']['.index'])
		assert.is.equal(1, devices['radio1']['.index'])
		assert.is.equal(0, devices['radio0'].per_band_index)
		assert.is.equal(1, devices['radio1'].per_band_index)
    end)

    it('test scandevices() two devs same band inverted order', function()
		uci:set('wireless', 'radio1', 'wifi-device')
        uci:set('wireless', 'radio1', 'hwmode', '11a')
		uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')

        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

		local devices = wireless.scandevices()
		assert.is.equal(2, utils.tableLength(devices))
		assert.is.equal(1, devices['radio0']['.index'])
		assert.is.equal(0, devices['radio1']['.index'])
		assert.is.equal(0, devices['radio0'].per_band_index)
		assert.is.equal(1, devices['radio1'].per_band_index)
    end)

    it('test scandevices() tho devs 5ghz, 1 dev 2ghz', function()
		uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11g')
		uci:set('wireless', 'radio1', 'wifi-device')
        uci:set('wireless', 'radio1', 'hwmode', '11a')
		uci:set('wireless', 'radio2', 'wifi-device')
        uci:set('wireless', 'radio2', 'hwmode', '11a')

        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

		local devices = wireless.scandevices()
		assert.is.equal(3, utils.tableLength(devices))
		assert.is.equal(0, devices['radio0']['.index'])
		assert.is.equal(0, devices['radio0'].per_band_index)

		assert.is.equal(1, devices['radio1']['.index'])
		assert.is.equal(2, devices['radio2']['.index'])
		assert.is.equal(0, devices['radio1'].per_band_index)
		assert.is.equal(1, devices['radio2'].per_band_index)

    end)

    it('test mesh_ifaces() tho devs 5ghz, 1 dev 2ghz', function()
        uci:set('wireless', 'wlan0_mesh_foo', 'wifi-iface')
        uci:set('wireless', 'wlan0_mesh_foo', 'mode', 'mesh')
        uci:set('wireless', 'wlan0_mesh_foo', 'ifname', 'wlan0-mesh')

        uci:set('wireless', 'wlan1_mesh_foo', 'wifi-iface')
        uci:set('wireless', 'wlan1_mesh_foo', 'mode', 'adhoc')
        uci:set('wireless', 'wlan1_mesh_foo', 'ifname', 'wlan1-adhoc')
        uci:set('wireless', 'wlan1_mesh_foo', 'disabled', '0')

        uci:set('wireless', 'wlan2_mesh_foo', 'wifi-iface')
        uci:set('wireless', 'wlan2_mesh_foo', 'mode', 'adhoc')
        uci:set('wireless', 'wlan2_mesh_foo', 'ifname', 'wlan2-adhoc')
        uci:set('wireless', 'wlan2_mesh_foo', 'disabled', '1')

        uci:set('wireless', 'wlan2_ap_foo', 'wifi-iface')
        uci:set('wireless', 'wlan2_ap_foo', 'mode', 'ap')
        uci:set('wireless', 'wlan2_ap_foo', 'ifname', 'wlan2-ap')
        uci:set('wireless', 'wlan2_ap_foo', 'disabled', '1')

        local ifaces = wireless.mesh_ifaces()
        assert.is.equal(#ifaces, 2)

    end)

    it('test configure() with distance', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

        config.set("wifi", "lime")
        config.set("wifi", "distance", '123')
        config.set("wifi", "channel", '48')
        config.set("5ghz", "lime-wifi-band")
        config.set("5ghz", "modes", {'ieee80211s'})
        wireless.configure()
        assert.is.equal('123', uci:get('wireless', 'radio0', 'distance'))

        -- distance of lime-wifi-band has priority over general distance
        config.set("5ghz", "distance", '444')
        wireless.configure()
        assert.is.equal('444', uci:get('wireless', 'radio0', 'distance'))

        config.delete("wifi", "distance")
        config.delete("5ghz", "distance")
    end)

    it('test configure() with distance and a specific radio', function()
        -- a specific radio config has precedence over the non specifc radio configs
        -- specific radio distance_5ghz > specific radio distance > generic distance_5ghz > generic distance
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

        config.set("radio0", "wifi")
        config.set("radio0", "distance", "999")

        config.set("wifi", "lime")
        config.set("wifi", "distance", '123')
        config.set("wifi", "channel", '48')
        config.set("5ghz", "lime-wifi-band" )
        config.set("5ghz", "modes", {'ieee80211s'})
        config.set("5ghz", "distance", '444')

        wireless.configure()
        assert.is.equal('999', uci:get('wireless', 'radio0', 'distance'))
    end)

    it('test configure() some options', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:set('wireless', 'radio1', 'wifi-device')
        uci:set('wireless', 'radio1', 'hwmode', '11a')
        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

        config.set("wifi", "lime")
        config.set("wifi", "txpower", '100')
        config.set("wifi", "country", 'FOO')
        config.set("wifi", "channel", {'48', '157'})
        config.set("wifi", "distance", '123')
        config.set("wifi", "ieee80211s_mesh_param_foo", 'bar') -- mode specific parameter
        config.set("5ghz", "lime-wifi-band")
        config.set("5ghz", "modes", {'ieee80211s'})
        wireless.configure()
        assert.is.equal('100', uci:get('wireless', 'radio0', 'txpower'))
        assert.is.equal('FOO', uci:get('wireless', 'radio0', 'country'))
        assert.is.equal('48', uci:get('wireless', 'radio0', 'channel'))
        assert.is.equal('157', uci:get('wireless', 'radio1', 'channel'))
        assert.is.equal('bar', uci:get('wireless', 'lm_wlan0_mesh_radio0', 'mesh_param_foo'))
    end)

    it('test configure() specific radio as client', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)

        config.set("wifi", "lime")
        config.set("radio0", "wifi")
        config.set("radio0", "distance", "999")
        config.set("radio0", "client_ssid", "MyCommunity")
        config.set("radio0", "modes", {"client"})
        config.set("5ghz", "lime-wifi-band")
        config.set("5ghz", "modes", {"ap"})
        stub(system, "get_hostname", function () return 'host' end)
        stub(network, "primary_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)
        wireless.configure()
        assert.is.equal('auto', uci:get('wireless', 'radio0', 'channel'))
        assert.is.equal('MyCommunity', uci:get('wireless', 'lm_wlan0_sta_radio0', 'ssid'))
        system.get_hostname:revert()
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
