#!/usr/bin/lua

local apname_mode = require("lime.mode.apname")

local apname = {}

function apname.configure(args)
end

function apname.setup_interface(ifname, args)
	if ifname:match("^wlan%d+."..apname_mode.wifi_mode.."name$") then
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

return apname
