#!/usr/bin/lua

local libuci = require("uci")

wan = {}

function wan.setup_interface(ifname, args)
	local uci = libuci:cursor()
	uci:set("network", "wan", "ifname", ifname)
	uci:save("network")
end

function wan.configure(args)
	local uci = libuci:cursor()
	uci:set("network", "wan", "interface")
	uci:set("network", "wan", "proto", "dhcp")
	uci:save("network")
end

function wan.apply()
end

return wan
