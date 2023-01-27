local utils = require "lime.utils"
local test_utils = require "tests.utils"
local hotspot_wwan = require 'lime.hotspot_wwan'
local limeutils = require "lime-utils"
local json = require 'luci.jsonc'
local node_status = require 'lime.node_status'

local uci
local snapshot -- to revert luassert stubs and spies

local mocks = {}

describe('ubus-lime-utils tests #ubuslimeutils', function()

    it('test get_notes', function()
        stub(utils, "read_file", function () return 'a note' end)

        local response  = limeutils.get_notes()
        assert.is.equal("ok", response.status)
        assert.is.equal("a note", response.notes)
        assert.stub(utils.read_file).was.called_with('/etc/banner.notes')
    end)

    it('test get_notes when there are no notes', function()
        local response  = limeutils.get_notes()
        assert.is.equal("ok", response.status)
        assert.is.equal("", response.notes)
    end)

    it('test set_notes', function()
        stub(utils, "read_file", function () return 'a note' end)
        stub(utils, "write_file", function ()  end)
        local response  = limeutils.set_notes(json.parse('{"text": "a new note"}'))
        assert.is.equal("ok", response.status)
        assert.is.equal("a note", response.notes)
        assert.stub(utils.read_file).was.called_with('/etc/banner.notes')
    end)

    it('test get_cloud_nodes', function()
        stub(utils, "unsafe_shell", function () return 'lm-node1\nlm-node2\n' end)
        local response  = limeutils.get_cloud_nodes()
        assert.is.equal("ok", response.status)
        assert.are.same({"lm-node1", "lm-node2"}, response.nodes)
    end)

    it('test get_node_status', function()
        stub(utils, "unsafe_shell", function () return '' end)
        stub(utils, "uptime_s", function () return '123' end)

        local response  = limeutils.get_node_status()
        assert.is.equal("ok", response.status)
        assert.is.equal(utils.hostname(), response.hostname)
        assert.are.same({}, response.ips)
        assert.is.equal("123", response.uptime)
    end)


    it('test get_most_active return most active iface with stats from iw', function()
        stub(utils, "unsafe_shell", function (cmd) 
            if string.match(cmd, "wlan0") then 
                return mocks.iw_station_get_result_wlan0
            end
            return mocks.iw_station_get_result_wlan1
        end
        )
        stub(node_status, "get_stations", function () return mocks.get_stations end)
        local most_active = node_status.get_most_active()
        assert.is.equal("wlan0-mesh", most_active["iface"])
        assert.is.equal("13 [10, 11] dBm", most_active["signal"])
        assert.is.equal(3116498, most_active["rx_bytes"])
        assert.is.equal(1166333, most_active["tx_bytes"])
    end)

    it('test get_upgrade_info', function()
        stub(utils, "unsafe_shell", function () return '-1' end)
        stub(os, "execute", function () return '0' end)

        local response  = limeutils.get_upgrade_info()
        assert.is.equal("ok", response.status)
        assert.is_false(response.is_upgrade_confirm_supported)
        assert.are.same(-1, response.safe_upgrade_confirm_remaining_s)

        os.execute:revert()
        os.execute("rm -f /tmp/upgrade_info_cache")
    end)

    it('test hotspot_wwan_get_status', function()
        stub(hotspot_wwan, "status", function () return {connected = false} end)

        local response  = limeutils.hotspot_wwan_get_status()
        assert.is.equal("ok", response.status)
        assert.is_false(response.connected)
        assert.stub(hotspot_wwan.status).was.called()

        local response  = limeutils.hotspot_wwan_get_status(json.parse('{"radio":"radio1"}'))
        assert.stub(hotspot_wwan.status).was.called_with('radio1')
    end)

    it('test hotspot_wwan_is_connected when connected', function()
        stub(hotspot_wwan, "status", function () return {connected = true, signal = -66} end)
        local response  = limeutils.hotspot_wwan_get_status()
        assert.is.equal("ok", response.status)
        assert.is_true(response.connected)
        assert.is.equal(-66, response.signal)
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


mocks.iw_station_get_result_wlan1 = [[
Station c0:4a:00:be:7b:0a (on wlan1-mesh)
    inactive time:  50 ms
    rx bytes:  503044
    rx packets:  3976
    tx bytes:  545116
    tx packets:  1237
    tx retries:  9
    tx failed:  0
    rx drop misc:  3
    signal:    -14 [-17, -16] dBm
    signal avg:  -12 [-14, -15] dBm
    Toffset:  46408315 us
    tx bitrate:  300.0 MBit/s MCS 15 40MHz short GI
    rx bitrate:  300.0 MBit/s MCS 15 40MHz short GI
    rx duration:  0 us
    expected throughput:  58.43Mbps
    mesh llid:  5944
    mesh plid:  1241
    mesh plink:  ESTAB
    mesh local PS mode:  ACTIVE
    mesh peer PS mode:  ACTIVE
    mesh non-peer PS mode:  ACTIVE
    authorized:  yes
    authenticated:  yes
    associated:  yes
    preamble:  long
    WMM/WME:  yes
    MFP:    no
    TDLS peer:  no
    DTIM period:  2
    beacon interval:100
    short slot time:yes
    connected time:  139 seconds
]]


mocks.iw_station_get_result_wlan0 = [[
    Station c0:4a:00:be:7b:09 (on wlan0-mesh)
	inactive time:	140 ms
	rx bytes:	3116498
	rx packets:	31613
	tx bytes:	1166333
	tx packets:	4462
	tx retries:	2448
	tx failed:	15
	rx drop misc:	938
	signal:  	13 [10, 11] dBm
	signal avg:	25 [-28, -15] dBm
	Toffset:	18446744073577465064 us
	tx bitrate:	6.5 MBit/s MCS 0
	rx bitrate:	39.0 MBit/s MCS 10
	rx duration:	0 us
	expected throughput:	2.197Mbps
	mesh llid:	63041
	mesh plid:	61249
	mesh plink:	ESTAB
	mesh local PS mode:	ACTIVE
	mesh peer PS mode:	ACTIVE
	mesh non-peer PS mode:	ACTIVE
	authorized:	yes
	authenticated:	yes
	associated:	yes
	preamble:	long
	WMM/WME:	yes
	MFP:		no
	TDLS peer:	no
	DTIM period:	2
	beacon interval:100
	short slot time:yes
	connected time:	5070 seconds
]]



mocks.get_stations = {
    [1] = {
        ["rx_short_gi"] = false,
        ["station_mac"] = "C0:4A:00:BE:7B:09",
        ["rx_vht"] = false,
        ["rx_mhz"] = 20,
        ["rx_40mhz"] = false,
        ["tx_packets"] = 1574,
        ["tx_mhz"] = 20,
        ["rx_packets"] = 16879,
        ["rx_ht"] = true,
        ["tx_mcs"] = 9,
        ["noise"] = -95,
        ["rx_mcs"] = 1,
        ["tx_ht"] = true,
        ["iface"] = "wlan0-mesh",
        ["tx_rate"] = 26000,
        ["inactive"] = 1390,
        ["tx_short_gi"] = false,
        ["tx_40mhz"] = false,
        ["expected_throughput"] = 11437,
        ["tx_vht"] = false,
        ["rx_rate"] = 13000,
        ["signal"] = 13
      },
    [2] = {
        ["rx_short_gi"] = true,
        ["station_mac"] = "C0:4A:00:BE:7B:0A",
        ["rx_vht"] = false,
        ["rx_mhz"] = 40,
        ["rx_40mhz"] = true,
        ["tx_packets"] = 7078,
        ["tx_mhz"] = 40,
        ["rx_packets"] = 54294,
        ["rx_ht"] = true,
        ["tx_mcs"] = 15,
        ["noise"] = -91,
        ["rx_mcs"] = 15,
        ["tx_ht"] = true,
        ["iface"] = "wlan1-mesh",
        ["tx_rate"] = 300000,
        ["inactive"] = 70,
        ["tx_short_gi"] = true,
        ["tx_40mhz"] = true,
        ["expected_throughput"] = 59437,
        ["tx_vht"] = false,
        ["rx_rate"] = 300000,
        ["signal"] = -13
      }
}
