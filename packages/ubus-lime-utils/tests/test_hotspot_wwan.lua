local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'
local hotspot_wwan = require "lime.hotspot_wwan"
local iwinfo = require "iwinfo"

local uci

stub(hotspot_wwan, "_apply_change", function () return '' end)

describe('hotspot_wwan tests #hotspot_wwan', function()
    local snapshot -- to revert luassert stubs and spies

    it('test enable default args', function()
        local status = hotspot_wwan.status('radio1')
        assert.is_false(status.enabled)

        hotspot_wwan.enable()
        uci:load('wireless')
        local expected = {
            'wireless.radio0.disabled=0',
            'wireless.lm_client_wwan_radio0=wifi-iface',
            'wireless.lm_client_wwan_radio0.device=radio0',
            'wireless.lm_client_wwan_radio0.network=lm_client_wwan_radio0',
            'wireless.lm_client_wwan_radio0.mode=sta',
            'wireless.lm_client_wwan_radio0.ifname=client-wwan-0',
            'wireless.lm_client_wwan_radio0.ssid=internet',
            'wireless.lm_client_wwan_radio0.encryption=psk2',
            'wireless.lm_client_wwan_radio0.key=internet',
            'network.lm_client_wwan_radio0=interface',
            'network.lm_client_wwan_radio0.proto=dhcp',
        }
        assert.is.equal("generic_uci_config", uci:get(config.UCI_NODE_NAME, 'hotspot_wwan_radio0'))
        assert.are.same(expected, uci:get(config.UCI_NODE_NAME, 'hotspot_wwan_radio0', 'uci_set'))

        hotspot_wwan.disable()
        assert.is_nil(uci:get(config.UCI_NODE_NAME, 'hotspot_wwan_radio0'))
    end)

    it('test hotspot_wwan_enable with args', function()
        local status
        local retval = hotspot_wwan.enable(nil, 'mypass', nil, 'radio1')
        assert.is_true(retval)
        assert.is.equal("generic_uci_config", uci:get(config.UCI_NODE_NAME, 'hotspot_wwan_radio1'))

        status = hotspot_wwan.status('radio1')
        assert.is_true(status.enabled)

        retval = hotspot_wwan.disable('radio1')
        assert.is_true(retval)
        assert.is_nil(uci:get(config.UCI_NODE_NAME, 'hotspot_wwan_radio1'))

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
        iwinfo.fake.set_assoclist(hotspot_wwan.iface_name('radio1'), assoclist)

        local status = hotspot_wwan.status('radio1')
        assert.is_true(status.connected)
        assert.is.equal(-66, status.signal)
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
