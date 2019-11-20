local wireless = require 'lime.wireless'
local test_utils = require 'tests.utils'
local iwinfo = require('iwinfo')

local uci = nil

describe('LiMe Wireless tests #wireless', function()

    it('test is5Ghz(phy) with single freq radios', function()
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = true,})
        assert.is_true(wireless.is5Ghz('phy0'))
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = false,})
        assert.is_true(wireless.is5Ghz('phy0'))
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = false, ["b"] = false, ["ac"] = true, ["g"] = false, ["n"] = true,})
        assert.is_true(wireless.is5Ghz('phy0'))

        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = false, ["n"] = true,})
        assert.is_false(wireless.is5Ghz('phy0'))
        iwinfo.fake.set_hwmodelist('phy0', { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = true, ["n"] = false,})
        assert.is_false(wireless.is5Ghz('phy0'))
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


    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
