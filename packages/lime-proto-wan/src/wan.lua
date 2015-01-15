#!/usr/bin/lua

local libuci = require("uci")

wan = {}

wan.configured = false

function wan.configure(args)
	if wan.configured then return end
	wan.configured = true

	local uci = libuci:cursor()
	uci:set("network", "wan", "interface")
	uci:set("network", "wan", "proto", "dhcp")
	uci:save("network")
end

function wan.setup_interface(ifname, args)
	local uci = libuci:cursor()
	uci:set("network", "wan", "ifname", ifname)
	uci:save("network")
end

return wan
