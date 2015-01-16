#!/usr/bin/lua

local ieee80211s_mode = require("lime.mode.ieee80211s")

local ieee80211s = {}

ieee80211s.configured = false

function ieee80211s.configure(args)
	ieee80211s.configured = true
end

function ieee80211s.setup_interface(ifname, args)
	if ifname:match("^wlan%d+_"..ieee80211s_mode.wifi_mode) then
		local libuci = require "uci"
		local uci = libuci:cursor()

		local networkInterfaceName = network.limeIfNamePrefix..ifname

		uci:set("network", networkInterfaceName, "interface")
		uci:set("network", networkInterfaceName, "proto", "none")
		uci:set("network", networkInterfaceName, "mtu", "1536")
		uci:set("network", networkInterfaceName, "auto", "1")

		uci:save("network")
	end
end

return ieee80211s
