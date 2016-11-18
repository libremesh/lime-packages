#!/usr/bin/lua

local ieee80211s_mode = require("lime.mode.ieee80211s")

local ieee80211s = {}

ieee80211s.configured = false

function ieee80211s.configure(args)
	ieee80211s.configured = true
end

function ieee80211s.setup_interface(ifname, args)
	if ifname:match("^wlan%d+."..ieee80211s_mode.wifi_mode) then
		local libuci = require "uci"
		local uci = libuci:cursor()

		--! sanitize passed ifname for constructing uci section name
		--! because only alphanumeric and underscores are allowed
		local networkInterfaceName = network.limeIfNamePrefix..ifname:gsub("[^%w_]", "_")

		uci:set("network", networkInterfaceName, "interface")
		uci:set("network", networkInterfaceName, "proto", "none")
		uci:set("network", networkInterfaceName, "mtu", "1536")
		uci:set("network", networkInterfaceName, "auto", "1")

		uci:save("network")
	end
end

return ieee80211s
