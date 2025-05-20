local iwinfo = {}
iwinfo.nl80211 = {}
iwinfo.fake = {}
iwinfo.mocks = {}

iwinfo.mocks.iw_station_get_result_wlan1 = [[
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


iwinfo.mocks.iw_station_get_result_wlan0 = [[
    Station c0:4a:00:be:7b:09 (on wlan0-mesh)
	inactive time:	140 ms
	rx bytes:	3116498
	rx packets:	31613
	tx bytes:	1166333
	tx packets:	4462
	tx retries:	2448
	tx failed:	15
	rx drop misc:	938
	signal:  	-14 [-17, -18] dBm
	signal avg:	-14 [-17, -18] dBm
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


iwinfo.mocks.get_stations = {
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

iwinfo.mocks.wlan1_mesh_mac = {'C0', '00', '00', '01', '01', '01'}
iwinfo.mocks.wlan0_mesh_mac = {'C0', '00', '00', '00', '00', '00'}

OP_MODES = {
    "Unknown", "Master", "Ad-Hoc", "Client", "Monitor", "Master (VLAN)",
    "WDS", "Mesh Point", "P2P Client", "P2P Go"
}

HT_MODES = {"HT20", "HT40", "VHT20", "VHT40", "VHT80", "VHT80+80", "VHT160"}

iwinfo.fake._scanlists = {}
iwinfo.fake._channels = {}
iwinfo.fake._assoclists = {}
iwinfo.fake._hwmodelists = {}

function iwinfo.fake.set_scanlist(phy_id, scanlist)
    iwinfo.fake._scanlists[phy_id] = scanlist
end

function iwinfo.fake.scanlist_gen_station(ssid, channel, signal, mac, mode, quality)
    local utils = require("lime.utils")
    assert(utils.has_value(OP_MODES, mode))

    local station = {
    ["encryption"] = {
        ["enabled"] = false,
        ["auth_algs"] = { } ,
        ["description"] = None,
        ["wep"] = false,
        ["auth_suites"] = { } ,
        ["wpa"] = 0,
        ["pair_ciphers"] = { } ,
        ["group_ciphers"] = { } ,
    } ,
    ["quality_max"] = 70,
    ["ssid"] = ssid,
    ["channel"] = channel,
    ["signal"] = signal,
    ["bssid"] = bssid,
    ["mode"] = mode,
    ["quality"] = quality,
    }
    return station
end


function iwinfo.nl80211.scanlist(phy_id)
    return iwinfo.fake._scanlists[phy_id] or {}
end

function iwinfo.fake.set_channel(phy_id, channel)
    iwinfo.fake._channels[phy_id] = channel
end

function iwinfo.nl80211.channel(phy_id)
    return iwinfo.fake._channels[phy_id]
end

function iwinfo.fake.set_assoclist(radio, assoclist)
    iwinfo.fake._assoclists[radio] = assoclist
end

function iwinfo.nl80211.assoclist(radio)
    return iwinfo.fake._assoclists[radio] or {}
end

function iwinfo.type(phy_id)
    return 'nl80211'
end

function iwinfo.fake.gen_assoc_station(rx_ht_mode, tx_ht_mode, signal, quality, inactive_ms,
                                        tx_packets, rx_packets)
    local utils = require("lime.utils")

    -- VHT modes not yet supported
    assert(utils.has_value({"HT20", "HT40"}, rx_ht_mode))
    assert(utils.has_value({"HT20", "HT40"}, tx_ht_mode))

    local rx_vht = false
    local tx_vht = false
    local rx_ht = false
    local tx_ht = false
    local rx_mhz = 20
    local tx_mhz = 20
    local tx_40mhz = false

    if rx_ht_mode == "HT40" then
        rx_ht = true
        rx_mhz = 40
    end

    if tx_ht_mode == "HT40" then
        tx_ht = true
        tx_40mhz = true
        tx_mhz = 40
    end

    local r = {
        ["rx_ht"] = rx_ht,
        ["rx_vht"] = rx_vht,
        ["rx_mhz"] = rx_mhz,
        ["rx_rate"] = rx_rate,

        ["tx_ht"] = tx_ht,
        ["tx_vht"] = tx_vht,
        ["tx_40mhz"] = tx_40mhz,
        ["tx_mhz"] = tx_mhz,
        ["tx_mcs"] = tx_mcs,
        ["tx_rate"] = tx_rate,
        ["tx_short_gi"] = true,

        ["tx_packets"] = tx_packets,
        ["rx_packets"] = rx_packets,
        ["noise"] = noise,
        ["inactive"] = inactive_ms,
        ["expected_throughput"] = throughtput,
        ["signal"] = signal
    }
    return r
end

iwinfo.fake.HWMODE = {
    ["HW_2GHZ_N"] =  { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = true, ["n"] = true},
    ["HW_5GHZ_N"] = { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = true}
}

function iwinfo.fake.set_hwmodelist(radio_or_phy, hwmodelist)
    iwinfo.fake._hwmodelists[radio_or_phy] = hwmodelist
end

function iwinfo.nl80211.hwmodelist(radio_or_phy)
    return iwinfo.fake._hwmodelists[radio_or_phy]
end

function iwinfo.fake.load_from_uci(uci_cursor)
    function create_device(dev)
        local hwmode
        if dev.band == '5g' then
            hwmode = iwinfo.fake.HWMODE.HW_5GHZ_N
        elseif dev.band == '2g' then
            hwmode = iwinfo.fake.HWMODE.HW_2GHZ_N
        else
            assert(0, 'posibility not supported yet, please add support!')
        end
        iwinfo.fake.set_hwmodelist(dev[".name"], hwmode)
        iwinfo.fake.set_channel(dev[".name"], dev.channel)
    end
    uci_cursor:foreach("wireless", "wifi-device", function(dev) create_device(dev) end)
end

return iwinfo

