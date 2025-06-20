#!/usr/bin/lua

local config = require("lime.config")
local ieee80211s_mode = require("lime.mode.ieee80211s")

local ieee80211s = {}

function ieee80211s.configure(args)
end

function ieee80211s.setup_interface(ifname, args)
	if ifname:match("^wlan%d+."..ieee80211s_mode.wifi_mode) then
		local uci = config.get_uci_cursor()

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

function ieee80211s.runOnDevice(linuxDev, args) end

return ieee80211s
