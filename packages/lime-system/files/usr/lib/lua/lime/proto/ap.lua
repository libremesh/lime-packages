#!/usr/bin/lua

local ap_mode = require("lime.mode.ap")

local ap = {}

ap.configured = false

function ap.configure(args)
	ap.configured = true
end

function ap.setup_interface(ifname, args)
	if ifname:match("^wlan%d+."..ap_mode.wifi_mode.."$") then
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

return ap
