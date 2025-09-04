#!/usr/bin/env lua
--! SPDX-License-Identifier: Apache-2.0
--!
--! Copyright 2017 Marcos Gutierrez <gmarcos87@gmail.com>
--! Copyright 2020 Santiago Piccinini <spiccinini@altermundi.net>

local iwinfo = require "iwinfo"
local json = require "luci.jsonc"
local config = require "lime.config"
local wireless = require "lime.wireless"
local system = require "lime.system"

local location = {}

function location.is_valid_coordinate(value)
    return type(tonumber(value)) == "number"
end

function location.get_node()
    local uci = config.get_uci_cursor()
    local lat = uci:get("location", "settings", "node_latitude")
    local long = uci:get("location", "settings", "node_longitude")

    if location.is_valid_coordinate(lat) and location.is_valid_coordinate(long) then
        return {lat=lat, long=long}
    end
end

function location.get_community()
    local uci = config.get_uci_cursor()
    local lat = uci:get("location", "settings", "community_latitude")
    local long = uci:get("location", "settings", "community_longitude")

    if location.is_valid_coordinate(lat) and location.is_valid_coordinate(long) then
        return {lat=lat, long=long}
    end
end

function location.set(lat, long)
    local uci = config.get_uci_cursor()
    uci:set("location", "settings", "node_latitude", lat)
    uci:set("location", "settings", "node_longitude", long)
    uci:commit("location")
    local hostname = system.get_hostname()
    local data = {}
    data[hostname] = location.nodes_and_links()
    io.popen("shared-state insert nodes_and_links", "w"):write(json.stringify(data))
end

function location.nodes_and_links()
  local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")
  local macs = network.get_own_macs("wlan*")

  local coords = location.get_node() or location.get_community() or {lat="FIXME", long="FIXME"}
  local iface, currneigh, _, n

  local interfaces = wireless.mesh_ifaces()
  local links = {}
  for _, iface in pairs(interfaces) do
    currneigh = iwinfo.nl80211.assoclist(iface)
    for mac, station in pairs(currneigh) do
        table.insert(links, string.lower(mac))
    end
  end
  return {hostname=hostname, macs=macs, coordinates={lat=coords.lat, lon=coords.long}, links=links}
end

return location
