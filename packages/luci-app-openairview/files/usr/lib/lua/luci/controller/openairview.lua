--[[
LuCI - Lua Configuration Interface

Copyright 2013 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.openairview", package.seeall)

function index()
   local page
   page = entry({"admin", "openairview"}, alias({"admin", "openairview", "stations"}), _("OpenAirView"), 50)
   page.index = true

   page = entry({"admin", "openairview", "stations"}, template("openairview/stations"), _("Stations"), 1)
   page.leaf = true

   page = entry({"admin", "openairview", "spectral_scan"}, template("openairview/spectral_scan"), _("Spectral Scan"), 2)
   page.leaf = true

   node("openairview")
   node("openairview", "json")

   page = node("openairview", "json", "stations")
   page.target = call("action_json_stations")
   page.leaf = true

   page = node("openairview", "json", "spectral_scan")
   page.target = call("action_json_spectral_scan")
   page.leaf = true

end


function action_json_stations(device)

   local netm = require "luci.model.network"

   local function lines(str)
      -- split a string into lines separated by line endings
      local t = {}
      local function helper(line) table.insert(t, line) return "" end
      helper((str:gsub("(.-)\r?\n", helper)))
      return t
   end

   local function file_exists(file)
      -- check if the file exists
      local f = io.open(file, "rb")
      if f then f:close() end
      return f ~= nil
   end

   local function dict_from_file(file)
      -- get all lines from a file with two values per line and return a dict type table
      -- return an empty table if the file does not exist
      if not file_exists(file) then return {} end
      dict = {}
      for line in io.lines(file) do
         words = {}
         for w in line:gmatch("%S+") do table.insert(words, w) end
         if #words == 2 and type(words[1]) == "string" and type(words[1]) == "string" then
            dict[string.lower(words[1])] = words[2]
         end
      end
      return dict
   end

   local function network_links(ntm, net)
      local station_links = {}
      local macaddr = ntm:get_interface(net.iwdata.ifname):mac()
      local channel = net:channel()
      local assoclist = net.iwinfo.assoclist
      local bat_hosts = dict_from_file("/etc/bat-hosts")
      for station_mac, link_data in pairs(assoclist) do
         local wifilink = {
            type = "wifi",
            station = station_mac,
            hostname = station_hostname,
            station_hostname = bat_hosts[string.lower(station_mac)] or station_mac,
            attributes = { signal = link_data.signal, channel = channel, inactive= link_data.inactive }
         }
         table.insert(station_links, wifilink)
      end
      return station_links
   end   

   local ntm = netm.init()
   local net = ntm:get_wifinet(device)
   local net_links = network_links(ntm, net)

   luci.http.prepare_content("application/json")
   luci.http.write_json(net_links)
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
