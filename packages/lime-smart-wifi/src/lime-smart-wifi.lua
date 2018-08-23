#!/usr/bin/lua

local config = require("lime.config")
local wireless = require("lime.wireless")
local utils = require("lime.utils")

local all_radios = wireless.scandevices()

smart_wifi = {}

function smart_wifi.get_modes(dev)
    local modes = {}
    local iw = iwinfo[iwinfo.type(dev)]
    if iw ~= nil then modes = iw.hwmodelist(dev) end
        return modes
end

function smart_wifi.get_channels(dev)
    local clist = {} -- output channel list
    local iw = iwinfo[iwinfo.type(dev)]
    local ch = {}

    -- if there are not wireless cards, returning a dummy value
    if iw == nil then
        ch.channel=0
        ch.adhoc=false
        ch.ht40p=false
        ch.ht40m=false
        table.insert(clist,ch)
        return clist
    end

    local freqs = iw.freqlist(dev) --freqs list
    local c -- current channel
    local nc = 0 -- next channel
    local pc = 0 -- previous channel
    local adhoc
    local ht40_support = smart_wifi.get_modes(dev).n

    for i,f in ipairs(freqs) do
        c = f.channel
        ch = {}
        ch.channel = c
        ch.ht40p = false
        ch.ht40m = false

        if not f.restricted then ch.adhoc = true
            else ch.adhoc = false end

        -- 2.4Ghz band
        if c < 15 then
            if c < 4 then
                ch.ht40p = true
            elseif c < 10 then
                ch.ht40m = true
                ch.ht40p = true
            else
                ch.ht40m = true
            end

        -- 5Ghz band
        elseif c > 14 then
            if #freqs == i then
                nc = nil
            else
                nc = freqs[i+1].channel
            end

            -- Channels 36 to 140
            if c <= 140 then
                if c % 8 == 0 then
                    ch.ht40m = true
                elseif nc ~= nil and nc-c == 4 then
                    ch.ht40p = true
            end

            -- Channels 149 to 165
            elseif c >=149 then
                if (c-1) % 8 == 0 then
                    ch.ht40m = true
                elseif nc ~= nil and nc-c == 4 then
                    ch.ht40p = true
                end
            end
        end

        -- If the device does not support ht40, both vars (+/-) are false
        if not ht40_support then
            ch.ht40p = false
            ch.ht40m = false
        end
        table.insert(clist,ch)
    end
    return clist
end

function smart_wifi.get_txpower(dev)
    local iw = iwinfo[iwinfo.type(dev)]
    local txpower_supported = {}
    if iw ~= nil then
        local txp = iw.txpwrlist(dev) or {}
        for _,v in ipairs(txp) do
            table.insert(txpower_supported,v.dbm)
        end
    end
    return txpower_supported
end

function smart_wifi.add_mesh(modes_radio)
    if utils.has_value(smart_wifi.modes, "ieee80211s") then
        table.insert(modes_radio, "ieee80211s")
    end
    if utils.has_value(smart_wifi.modes, "adhoc") then
        table.insert(modes_radio, "adhoc")
    end
    return modes_radio
end

function smart_wifi.add_ap(modes_radio)
    table.insert(modes_radio, "ap")
    if utils.has_value(smart_wifi.modes, "apname") then
        table.insert(modes_radio, "apname")
    end
    return modes_radio
end

function smart_wifi.run()
    local channels = {}
    channels["2ghz"] = config.get("smart_wifi", "channels_2ghz", { 1, 11, 6 })
    channels["5ghz"] = config.get("smart_wifi", "channels_5ghz", { 36, 48, 40, 44})
    channels_active = {}
    channels_active["2ghz"] = 0
    channels_active["5ghz"] = 0
    has2ghz = false
    has5ghz = false

    smart_wifi.modes = config.get("wifi", "modes", {})
    if #smart_wifi.modes == 0 then
        print("No wifi modes defined - skipping")
        return
    end

    config.init_batch()

    for _, radio in pairs(all_radios) do
        local radioName = radio[".name"]
        local is5ghz = wireless.is5Ghz(radioName)
        config.set(radioName, "wifi")

        if is5ghz then
            freq = "5ghz"
            has5ghz = true
            config.set(radioName, "htmode", "HT40")

            for _,d in ipairs(smart_wifi.get_channels(radioName)) do
                if d.channel == 100 and d.adhoc ~= nil then
                    channels["5ghz"] = { 100, 112, 124, 136 }
                    break
                end
            end
        else
            freq = "2ghz"
            config.set(radioName, "htmode", "HT20")
            has2ghz = true
        end

        if channels_active[freq] == table.getn(channels[freq]) then
            channels_active[freq] = 0
        end

        channels_active[freq] = channels_active[freq] + 1

        config.set(radioName, "channel",
            channels[freq][channels_active[freq]])

        txpowers = smart_wifi.get_txpower(radioName)
        config.set(radioName, "txpower", txpowers[table.getn(txpowers)])
    end

    local multiBand = has2ghz and has5ghz
    local added_2ghz_ap = false

    if multiBand then
        for _, radio in pairs(all_radios) do
            local radioName = radio[".name"]
            local is5ghz = wireless.is5Ghz(radioName)
            local modes_radio = {}
            if is5ghz then
                if config.get_bool("smart_wifi", "mesh_5ghz", 1)
                        or config.get_bool("smart_wifi", "all_to_mesh", 0) then
                    print("set 5Ghz radio "..radioName.." to mesh")
                    modes_radio = smart_wifi.add_mesh(modes_radio)
                end
                if config.get_bool("smart_wifi", "ap_5ghz", 0)
                        or config.get_bool("smart_wifi", "all_to_ap", 0) then
                    print("set 5Ghz radio "..radioName.." to ap")
                    modes_radio = smart_wifi.add_ap(modes_radio)
                end
            else
                if (config.get_bool("smart_wifi", "ap_2ghz", 1) and not added_2ghz_ap)
                        or config.get_bool("smart_wifi", "all_to_ap", 0) then
                    print("set 2.4Ghz radio "..radioName.." to ap")
                    modes_radio = smart_wifi.add_ap(modes_radio)
                    added_2ghz_ap = true
                end
                if config.get_bool("smart_wifi", "mesh_2ghz", 0)
                        or config.get_bool("smart_wifi", "all_to_mesh", 0) then
                    print("set 2.4Ghz radio "..radioName.." to mesh")
                    modes_radio = smart_wifi.add_mesh(modes_radio)
                end
            end
            config.set(radioName, "modes", modes_radio)
        end
    end
    config.end_batch()
end

smart_wifi.run()
