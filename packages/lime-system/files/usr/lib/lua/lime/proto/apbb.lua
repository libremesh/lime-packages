#!/usr/bin/lua

local apbb_mode = require("lime.mode.apbb")

local apbb = {}

function apbb.configure(args)
end

function apbb.setup_interface(ifname, args)
	if ifname:match("^wlan%d+."..apbb_mode.wifi_mode.."bb$") then
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

return apbb
