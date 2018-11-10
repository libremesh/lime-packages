#!/usr/bin/lua

local client_mode = require("lime.mode.client")

local client = {}

client.configured = false

function client.configure(args)
	client.configured = true
end

function client.setup_interface(ifname, args)
	if ifname:match("^wlan%d+."..client_mode.wifi_mode) then
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

return client
