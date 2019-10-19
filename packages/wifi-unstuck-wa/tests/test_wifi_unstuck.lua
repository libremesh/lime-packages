local config = require 'lime.config'
local test_utils = require 'tests.utils'
local unstuck_wa = require 'wifi_unstuck_wa'
local iwinfo = require 'iwinfo'
local nixio = require 'nixio'

local uci = nil

describe('Wireless unstuck workarounds #unstuck', function()
    local snapshot -- to revert luassert stubs and spies

    it('test get stickable interfaces only mesh or adhoc', function()
        local ifaces = unstuck_wa.get_stickable_ifaces()
        assert.is.equal(2, #ifaces)
        assert.are.same({'wlan1-mesh', 'wlan2-mesh'}, ifaces)
    end)

    it('test get scan freq for iface', function()
        stub(io, 'popen', function () return true end)
        stub(nixio, 'nanosleep', function () return true end)

        local function fake_frequency(phy)
            if phy == 'wlan1-mesh' then
                return 2462
            elseif phy == 'wlan2-mesh' then
                return 5230
            end
        end
        stub(iwinfo.nl80211, 'frequency', fake_frequency)

        unstuck_wa.do_workaround()
        assert.stub(io.popen).was.called_with('iw dev wlan1-mesh scan freq 2412 2462')
        assert.stub(io.popen).was.called_with('iw dev wlan2-mesh scan freq 5180 5240')
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
        local fin = io.open('packages/wifi-unstuck-wa/tests/uci_wireless')
        local fout = io.open(uci:get_confdir() .. '/' .. 'wireless', 'w')
        fout:write(fin:read('*a'))
        fin:close()
        fout:close()
        uci:load('wireless')
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)

end)
