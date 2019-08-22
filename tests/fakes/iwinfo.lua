local iwinfo = {}
iwinfo.nl80211 = {}
iwinfo.fake = {}

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
    return iwinfo.fake._scanlists[phy_id]
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
    return iwinfo.fake._assoclists[radio]
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
        if dev.hwmode == '11a' then
            hwmode = iwinfo.fake.HWMODE.HW_5GHZ_N
        elseif dev.hwmode == '11g' then
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

