local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'
local hotspot_wwan = require "lime.hotspot_wwan"
local iwinfo = require "iwinfo"

local uci

stub(hotspot_wwan, "_apply_change", function () return '' end)

function config_uci_hotspot_radio()
    uci:set('wireless', 'radio0', 'wifi-device')
    uci:set('wireless', 'radio0', 'type', 'mac80211')
    uci:set('wireless', 'radio0', 'channel', '4')
    uci:set('wireless', 'radio0', 'hwmode', '11a')
    uci:set('wireless', 'radio0', 'macaddr', '01:23:45:67:89:AB')
    uci:set('wireless', 'radio0', 'disabled', '0')

    uci:set('wireless', 'lm_client_wwan', 'wifi-iface')
    uci:set('wireless', 'lm_client_wwan', 'device', 'radio0')
    uci:set('wireless', 'lm_client_wwan', 'network', 'lm_client_wwan')
    uci:set('wireless', 'lm_client_wwan', 'mode', 'sta')
    uci:set('wireless', 'lm_client_wwan', 'ifname', 'client-wan')
    uci:commit('wireless')
end


describe('hotspot_wwan tests #hotspot_wwan', function()
    local snapshot -- to revert luassert stubs and spies

    it('test enable default args', function()
        local status = hotspot_wwan.status('radio1')
        assert.is_false(status.enabled)

        hotspot_wwan.enable()
        uci:load('wireless')
        local expected = {
            'wireless.radio0.disabled=0',
            'wireless.radio0.channel=auto',
            'wireless.lm_client_wwan=wifi-iface',
            'wireless.lm_client_wwan.device=radio0',
            'wireless.lm_client_wwan.network=lm_client_wwan',
            'wireless.lm_client_wwan.mode=sta',
            'wireless.lm_client_wwan.ifname=client-wwan',
            'wireless.lm_client_wwan.ssid=internet',
            'wireless.lm_client_wwan.encryption=psk2',
            'wireless.lm_client_wwan.key=internet',
            'network.lm_client_wwan=interface',
            'network.lm_client_wwan.proto=dhcp',
        }
        assert.is.equal("generic_uci_config", uci:get(config.UCI_NODE_NAME, 'hotspot_wwan'))
        assert.are.same(expected, uci:get(config.UCI_NODE_NAME, 'hotspot_wwan', 'uci_set'))

        hotspot_wwan.disable()
        assert.is_nil(uci:get(config.UCI_NODE_NAME, 'hotspot_wwan'))
    end)

    it('test hotspot_wwan_enable with args', function()
        local status
        local retval = hotspot_wwan.enable(nil, 'mypass', nil, 'radio1')
        assert.is_true(retval)
        assert.is.equal("generic_uci_config", uci:get(config.UCI_NODE_NAME, 'hotspot_wwan'))

        status = hotspot_wwan.status('radio1')
        assert.is_true(status.enabled)

        retval = hotspot_wwan.disable('radio1')
        assert.is_true(retval)
        assert.is_nil(uci:get(config.UCI_NODE_NAME, 'hotspot_wwan'))

        status = hotspot_wwan.status('radio1')
        assert.is_false(status.enabled)

    end)

    it('test hotspot_wwan_get_status when not connected', function()
        local status = hotspot_wwan.status('radio1')
        assert.is_false(status.connected)
    end)

    it('test hotspot_wwan_is_connected when connected', function()
        local sta = iwinfo.fake.gen_assoc_station("HT20", "HT40", -66, 50, 10000, 300, 120)
        local assoclist = {['AA:BB:CC:DD:EE:FF'] = sta}
        iwinfo.fake.set_assoclist(hotspot_wwan.IFACE_NAME, assoclist)

        local status = hotspot_wwan.status('radio1')
        assert.is_true(status.connected)
        assert.is.equal(-66, status.signal)
    end)

    it('test is_safe is true when no mesh ifaces configured', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'type', 'mac80211')
        uci:set('wireless', 'radio0', 'channel', '4')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:set('wireless', 'radio0', 'macaddr', '01:23:45:67:89:AB')
        uci:set('wireless', 'radio0', 'disabled', '0')
        uci:commit('wireless')

        local is_safe = hotspot_wwan._is_safe('internet', 'psk2', 'radio0')
        assert.is_true(is_safe)
    end)

    it('test is_safe is false when mesh ifaces configured', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'type', 'mac80211')
        uci:set('wireless', 'radio0', 'channel', '4')
        uci:set('wireless', 'radio0', 'hwmode', '11a')
        uci:set('wireless', 'radio0', 'macaddr', '01:23:45:67:89:AB')
        uci:set('wireless', 'radio0', 'disabled', '0')

        uci:set('wireless', 'lm_wlan0_mesh_radio', 'wifi-iface')
        uci:set('wireless', 'lm_wlan0_mesh_radio', 'device', 'radio0')
        uci:set('wireless', 'lm_wlan0_mesh_radio', 'network', 'lm_net_wlan0_mesh')
        uci:set('wireless', 'lm_wlan0_mesh_radio', 'mode', 'mesh')
        uci:set('wireless', 'lm_wlan0_mesh_radio', 'ifname', 'wlan0-mesh')
        uci:set('wireless', 'lm_wlan0_mesh_radio', 'mesh_id', 'LiMe')
        uci:commit('wireless')
            local is_safe = hotspot_wwan._is_safe('internet', 'psk2', 'radio0')
            assert.is_false(is_safe)
    end)

    it('test is_safe', function()
        config_uci_hotspot_radio()
        local ap = {
            ["encryption"] = {["enabled"] = true, ["wpa"] = 2},
            ["ssid"] = 'internet',
            ["mode"] = "Master",
        }
        iwinfo.fake.set_scanlist('client-wan', {ap})
        local is_safe = hotspot_wwan._is_safe('internet', 'psk2', 'radio0')
        assert.is_true(is_safe)
    end)

    it('test is_safe is false when encryption does not match', function()

        config_uci_hotspot_radio()
        local ap = {
            ["encryption"] = {["enabled"] = false, ["wpa"] = 0},
            ["ssid"] = 'internet',
            ["mode"] = "Master",
        }
        iwinfo.fake.set_scanlist('client-wan', {ap})
        local is_safe = hotspot_wwan._is_safe('internet', 'psk2', 'radio0')
        assert.is_false(is_safe)
    end)

    it('test hotspot_wwan_is_safe when no ifaces configured', function()
        local is_safe = hotspot_wwan._is_safe('internet', 'internet', 'psk2')
        assert.is_true(is_safe)
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)
end)
