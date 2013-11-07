--[[
LuCI - Lua Configuration Interface

Copyright 2013 Gui Iribarren <gui@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.openairview.spectral_scan", package.seeall)

function index()
    local page
    page = node("openairview", "json", "spectral_scan")
    page.target = call("action_json_spectral_scan")
    page.leaf = true
end

function action_json_spectral_scan(device, spectrum)
    local fd = assert(io.open("/sys/class/net/" .. device .. "/phy80211/name"))
    local phy = assert(fd:read("*l"))
    fd:close()

    local path_ath9k = "/sys/kernel/debug/ieee80211/" .. phy .. "/ath9k/"

    local freqs = { }
    freqs["2ghz"] = { 2412, 2422, 2432, 2442, 2452, 2462 }
    freqs["5ghz"] = { } -- scan all possible channels

    if spectrum == "2ghz" or spectrum == "5ghz" then
        samples = sample_whole_spectrum(device, path_ath9k, freqs[spectrum])
    elseif spectrum == "current" then
        samples = sample_current_channel(path_ath9k)
    end

    luci.http.prepare_content("application/json")

    local json_reply = { }
    table.insert(json_reply, '{ "epoch": ' .. os.time() .. ', "samples":\n')
    table.insert(json_reply, samples)
    table.insert(json_reply, '}')

    luci.http.write(table.concat(json_reply))
end

function sample_current_channel(path_ath9k)
    -- sample current channel only, no freq hopping
    -- grab only one sample per trigger
    nixio.fs.writefile(path_ath9k .. "spectral_count", "1")
    -- empty buffer
    nixio.fs.readfile(path_ath9k .. "spectral_scan0")
    -- trigger sampling
    nixio.fs.writefile(path_ath9k .. "spectral_scan_ctl", "manual")
    nixio.fs.writefile(path_ath9k .. "spectral_scan_ctl", "trigger")
    local samples = luci.util.exec("fft_eval " .. path_ath9k .. "spectral_scan0")
    nixio.fs.writefile(path_ath9k .. "spectral_scan_ctl", "disable")

    return samples
end

function sample_whole_spectrum(device, path_ath9k, freqs)
    -- grab samples over the whole spectrum
    -- grab only one sample per trigger
    nixio.fs.writefile(path_ath9k .. "spectral_count", "1")
    -- empty buffer
    nixio.fs.readfile(path_ath9k .. "spectral_scan0")
    -- trigger sampling hopping channels
    nixio.fs.writefile(path_ath9k .. "spectral_scan_ctl", "chanscan")

    local cmd = "iw dev " .. device .. " scan"
    if #freqs > 0 then cmd = cmd .. " freq " .. table.concat(freqs, " ") end
    luci.util.exec(cmd)

    nixio.fs.writefile(path_ath9k .. "spectral_scan_ctl", "disable")

    local samples = luci.util.exec("fft_eval " .. path_ath9k .. "spectral_scan0")
    return samples
end
