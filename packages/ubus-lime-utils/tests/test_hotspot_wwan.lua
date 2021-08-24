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
        assert.is.equal("radio0", uci:get('wireless', 'radio0_client_wwan', 'device'))
        assert.is.equal("internet", uci:get('wireless', 'radio0_client_wwan', 'key'))
        assert.is.equal("internet", uci:get('wireless', 'radio0_client_wwan', 'ssid'))
        assert.is.equal("dhcp", uci:get('network', 'client_wwan', 'proto'))

        hotspot_wwan.disable()
        assert.is_nil(uci:get('wireless', 'radio0_client_wwan', 'device'))
        assert.is_nil(uci:get('network', 'client_wwan', 'proto'))
    end)

    it('test hotspot_wwan_enable with args #fooo', function()
        local status
        local retval = hotspot_wwan.enable(nil, 'mypass', nil, 'radio1')
        assert.is_true(retval)
        assert.is.equal("radio1", uci:get('wireless', 'radio1_client_wwan', 'device'))
        assert.is.equal("mypass", uci:get('wireless', 'radio1_client_wwan', 'key'))
        assert.is.equal("internet", uci:get('wireless', 'radio1_client_wwan', 'ssid'))
        
        
        status = hotspot_wwan.status('radio1')
        assert.is_true(status.enabled)

        retval = hotspot_wwan.disable('radio1')        
        assert.is_true(retval)
        assert.is_nil(uci:get('wireless', 'radio1_client_wwan', 'device'))
        assert.is_nil(uci:get('network', 'client_wwan', 'proto'))
        
        hotspot_wwan.disable('radio1') 
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
        iwinfo.fake.set_assoclist('client-wwan', assoclist)

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
