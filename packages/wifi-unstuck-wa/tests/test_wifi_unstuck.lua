local config = require 'lime.config'
local test_utils = require 'tests.utils'
local unstuck_wa = require 'wifi_unstuck_wa'
local iwinfo = require 'iwinfo'
local nixio = require 'nixio'

local uci = nil

describe('Wireless unstuck workarounds #unstuck', function()
    local snapshot -- to revert luassert stubs and spies

    it('test get stickable interfaces', function()
        local ifaces = unstuck_wa.get_stickable_ifaces()
        assert.is.equal(3, #ifaces)
        assert.are.same({'wlan0-ap', 'wlan1-mesh', 'wlan2-mesh'}, ifaces)
    end)

    it('test get scan freq for iface', function()
        stub(nixio, 'exec', function () return true end)
        stub(nixio, 'fork', function () return 0 end)
        stub(nixio, 'nanosleep', function () return true end)
        stub(os, 'exit', function () return true end)

        local function fake_frequency(phy)
            if phy == 'wlan1-mesh' then
                return 2462
            elseif phy == 'wlan2-mesh' then
                return 5230
            end
        end
        stub(iwinfo.nl80211, 'frequency', fake_frequency)

        unstuck_wa.do_workaround()

        assert.stub(nixio.exec).was.called_with('/bin/sh','-c','iw dev wlan1-mesh scan freq 2412 2462 >/dev/null')
        assert.stub(nixio.exec).was.called_with('/bin/sh','-c','iw dev wlan2-mesh scan freq 5180 5240 >/dev/null')
    end)

    it('test pid-timeout-table', function()
        stub(nixio, 'exec', function () return true end)
        stub(nixio, 'nanosleep', function () return true end)
        stub(os, 'time', function () return 10000 end)
        stub(os, 'exit', function () return true end)
        stub(unstuck_wa,'wait_and_kill_on_timeout', function() return true end)

        local function fake_frequency(phy)
            if phy == 'wlan1-mesh' then
                return 2462
            elseif phy == 'wlan2-mesh' then
                return 5230
            end
        end
        stub(iwinfo.nl80211, 'frequency', fake_frequency)

        local pid = 11270
        local function fake_fork()
            pid = pid + 1
            return pid
        end
        stub(nixio, 'fork', fake_fork)

        unstuck_wa.do_workaround()

        assert.stub(unstuck_wa.wait_and_kill_on_timeout).was.called_with(
            { [11271]=10000, [11272]=10000 }
        )
    end)

    it('test kill iw scan after timeout', function()
        stub(nixio, 'nanosleep', function () return true end)
        stub(nixio, 'kill', function () return true end)

        local time = 10001
        local function fake_time()
            time = time + 1
            return time
        end
        stub(os, 'time', fake_time)

        local iw_is_done = false
        local function fake_waitpid()
            if iw_is_done then return nil,nil,nil end
            if time >= 10003 then
                iw_is_done = true
                return 11271,'exited',0
            end
        end
        stub(nixio, 'waitpid', fake_waitpid)

        unstuck_wa.wait_and_kill_on_timeout({ [11271]=10000, [11272]=10000 })

        assert.stub(nixio.kill).was._not.called_with(11271,15)
        assert.stub(nixio.kill).was.called_with(11272,15)

        stub(nixio, 'waitpid', function () return nil end)
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
