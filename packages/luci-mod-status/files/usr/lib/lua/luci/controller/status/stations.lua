--[[
LuCI - Lua Configuration Interface

Copyright 2013 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.status.stations", package.seeall)

function index()
   local page

   node("status")

   page = entry({"status", "stations"}, template("status/stations"), _("Stations"), 2)
   page.leaf = true

   node("status", "json")

   page = node("status", "json", "stations")
   page.target = call("action_json_stations")
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
      local macaddr = ntm:get_interface(net:ifname()):mac()
      local channel = net:channel()
      local assoclist = net:assoclist()
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

   local ntm = require "luci.model.network".init()
   local net = ntm:get_wifinet(device)
   local net_links = network_links(ntm, net)

   luci.http.prepare_content("application/json")
   luci.http.write_json(net_links)
end
