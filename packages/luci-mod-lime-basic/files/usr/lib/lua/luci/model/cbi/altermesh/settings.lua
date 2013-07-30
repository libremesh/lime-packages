--[[
LuCI - Lua Configuration Interface

Copyright 2013 Santiago Piccinini <spiccinini@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

require "luci.config"
local fs = require "nixio.fs"
local uci = require "luci.model.uci".cursor()

-- Luci settings

luci_map = Map("luci", translate("Web <abbr title=\"User Interface\">UI</abbr>"))

-- force reload of global luci config namespace to reflect the changes
function luci_map.commit_handler(self)
	package.loaded["luci.config"] = nil
	require "luci.config"
end

c = luci_map:section(NamedSection, "main", "core", translate("General"))

l = c:option(ListValue, "lang", translate("Language"))
l:value("auto")

local i18ndir = luci.i18n.i18ndir .. "base."
for k, v in luci.util.kspairs(luci.config.languages) do
	local file = i18ndir .. k:gsub("_", "-")
	if k:sub(1, 1) ~= "." and fs.access(file .. ".lmo") then
		l:value(k, v)
	end
end

-- Network settings

network_map = Map("network", translate("Network"))
lan_section = network_map:section(NamedSection, "lan", "interface", translate("Local Network"))
lan_section.addremove = false

lan_section:option(Value, "ipaddr", translate("<abbr title=\"Internet Protocol Version 4\">IPv4</abbr>-Address"))

nm = lan_section:option(Value, "netmask", translate("<abbr title=\"Internet Protocol Version 4\">IPv4</abbr>-Netmask"))
nm:value("255.255.255.0")
nm:value("255.255.0.0")
nm:value("255.0.0.0")

gw = lan_section:option(Value, "gateway", translate("<abbr title=\"Internet Protocol Version 4\">IPv4</abbr>-Gateway") .. translate(" (optional)"))
gw.rmempty = true
dns = lan_section:option(Value, "dns", translate("<abbr title=\"Domain Name System\">DNS</abbr>-Server") .. translate(" (optional)"))
dns.rmempty = true

-- System settings

system_map = Map("system", translate("System"))

s = system_map:section(TypedSection, "system")
s.addremove = false

hostname = s:option(Value, "hostname", translate("Hostname"))
hostname.rmempty = false
hostname.datatype = "hostname"

-- Altermap settings

local altermap_url = uci:get("altermap", "agent", "server_url")
altermap_map = Map("altermap", translate("Altermap"), translate("Here you can access the map of your network:") .. string.format("<a href='%s'>%s</a>", altermap_url, altermap_url))

altermap_section = altermap_map:section(NamedSection, "agent", "altermap", translate("Altermap"))
altermap_section.addremove = false
altermap_section:option(Value, "server_url", translate("Map Server URL"))
altermap_section:option(Flag, "enabled", translate("Enable agent"))

return luci_map, system_map, network_map, altermap_map
