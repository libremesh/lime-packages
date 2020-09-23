local iwinfo = require 'iwinfo'
local test_utils = require 'tests.utils'

local uci

local scanlist_result = {
[1] = {
    ["encryption"] = {
        ["enabled"] = true,
        ["auth_algs"] = { },
        ["description"] = "WPA2 PSK (CCMP)",
        ["wep"] = false,
        ["auth_suites"] = { {"PSK"}} ,
        ["wpa"] = 2,
        ["pair_ciphers"] = {"CCMP"} ,
        ["group_ciphers"] = {"CCMP"} ,
        } ,
    ["quality_max"] = 70,
    ["ssid"] = "foo_ssid",
    ["channel"] = 1,
    ["signal"] = -53,
    ["bssid"] = "38:AB:C0:C1:D6:70",
    ["mode"] = "Master",
    ["quality"] = 57,
  } ,
  [2] = {
    ["encryption"] = {
        ["enabled"] = false,
        ["auth_algs"] = { } ,
        ["description"] = "None",
        ["wep"] = false,
        ["auth_suites"] = { } ,
        ["wpa"] = 0,
        ["pair_ciphers"] = { } ,
        ["group_ciphers"] = { } ,
    } ,
    ["quality_max"] = 70,
    ["ssid"] = "bar_ssid",
    ["channel"] = 11,
    ["signal"] = -67,
    ["bssid"] = "C2:4A:00:BE:7B:B7",
    ["mode"] = "Master",
    ["quality"] = 43,
    } ,
}


describe('iwinfo fake tests #iwinfo', function()
    it('test scanlist returning a single station', function()
        iwinfo.fake.set_scanlist('phy0', scanlist_result)
        local scanlist = iwinfo.nl80211.scanlist('phy0')
        assert.are.equal(scanlist, scanlist_result)

        local station = iwinfo.fake.scanlist_gen_station('LibreMesh.org', 7, -47,
                                                        "aa:bb:cc:dd:ee:ff", "Ad-Hoc", 37)

        assert.is.equal('Ad-Hoc', station['mode'])
        iwinfo.fake.set_scanlist('phy1', {station})
        scanlist = iwinfo.nl80211.scanlist('phy1')
        assert.are.same({station}, scanlist)
    end)


    it('test channel(phy) in a device with two phys', function()
        iwinfo.fake.set_channel('phy0', 1)
        iwinfo.fake.set_channel('phy1', 48)

        assert.is.equal(1, iwinfo.nl80211.channel('phy0'))
        assert.is.equal(48, iwinfo.nl80211.channel('phy1'))
        assert.is.equal(nil, iwinfo.nl80211.channel('phy2'))
    end)

    it('test assoclist(radio) with one station associated', function()
        assert.are.same({}, iwinfo.nl80211.assoclist('wlan-foo'))

        iwinfo.fake.set_assoclist('wlan1-apname', {})

        assert.are.same({}, iwinfo.nl80211.assoclist('wlan1-apname'))

        local sta = iwinfo.fake.gen_assoc_station("HT20", "HT40", -66, 50, 10000,
                                                  300, 120)

        assert.is_false(sta.rx_vht)
        assert.is_false(sta.tx_vht)
        assert.is_false(sta.rx_ht)
        assert.is_true(sta.tx_ht)
        assert.is.equal(10000, sta.inactive)
        assert.is.equal(20, sta.rx_mhz)
        assert.is.equal(40, sta.tx_mhz)
        local assoclist = {['AA:BB:CC:DD:EE:FF'] = sta}
        iwinfo.fake.set_assoclist('wlan1-apname', assoclist)
        assert.are.same(assoclist, iwinfo.nl80211.assoclist('wlan1-apname'))

    end)

    it('test hwmodelist(radio_or_phy) with single freq radios', function()
        local hwmodelist_n_2ghz = { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = true, ["n"] = true,}
        local hwmodelist_n_5ghz = { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = true,}

        assert.are.same(hwmodelist_n_2ghz, iwinfo.fake.HWMODE.HW_2GHZ_N)
        assert.are.same(hwmodelist_n_5ghz, iwinfo.fake.HWMODE.HW_5GHZ_N)

        -- hwmodelist returns the same for the radios or the phys
        iwinfo.fake.set_hwmodelist('wlan0-apname', hwmodelist_n_2ghz)
        iwinfo.fake.set_hwmodelist('phy0', hwmodelist_n_2ghz)
        iwinfo.fake.set_hwmodelist('wlan1-apname', hwmodelist_n_5ghz)
        iwinfo.fake.set_hwmodelist('phy1', hwmodelist_n_5ghz)

        assert.are.same(hwmodelist_n_2ghz, iwinfo.nl80211.hwmodelist('phy0'))
        assert.are.same(hwmodelist_n_2ghz, iwinfo.nl80211.hwmodelist('wlan0-apname'))

        assert.are.same(hwmodelist_n_5ghz, iwinfo.nl80211.hwmodelist('phy1'))
        assert.are.same(hwmodelist_n_5ghz, iwinfo.nl80211.hwmodelist('wlan1-apname'))
    end)

    it('test load_from_uci for a single radio device', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'type', 'mac80211')
        uci:set('wireless', 'radio0', 'channel', '4')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:set('wireless', 'radio0', 'macaddr', '01:23:45:67:89:AB')
        uci:set('wireless', 'radio0', 'htmpde', 'HT40')
        uci:set('wireless', 'radio0', 'disabled', '0')

        uci:set('wireless', 'wlan0', 'wifi-iface')
        uci:set('wireless', 'wlan0', 'device', 'radio0')
        uci:set('wireless', 'wlan0', 'network', 'lan')
        uci:set('wireless', 'wlan0', 'mode', 'ap')
        uci:set('wireless', 'wlan0', 'ssid', 'OpenWrt')
        uci:set('wireless', 'wlan0', 'encryption', 'none')

        uci:commit('wireless')
        iwinfo.fake.load_from_uci(uci)
        assert.are.same(iwinfo.fake.HWMODE.HW_5GHZ_N,
                        iwinfo.nl80211.hwmodelist('radio0'))
        assert.are.same('4', iwinfo.nl80211.channel('radio0'))
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
