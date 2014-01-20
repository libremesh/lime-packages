#!/usr/bin/lua

lan = {}

local network = require "lime.network"

function lan.configure()
	lan.clear()
	
	local ipv4, ipv6 = network.primary_address()
	uci:set("network", "lan", "ip6addr", ipv6:string())
	uci:set("network", "lan", "ipaddr", ipv4:host():string())
	uci:set("network", "lan", "netmask", ipv4:mask():string())
	uci:save("network")
end

function lan.setup_interface(ifname, args)
	if ifname:match("adhoc") then return end

	local bridgedIfs = {}
	local oldIfs = uci:get("network", "lan", "ifname") or {}
	if type(oldIfs) == "string" then oldIfs = utils.split(oldIfs, " ") end
	for _,iface in pairs(oldIfs) do
		table.insert(bridgedIfs, iface)
	end
	table.insert(bridgedIfs, ifname)
	uci:set("network", "lan", "ifname", bridgedIfs)
	uci:save("network")
end

function lan.clear()
	uci:delete("network", "lan", "ifname")
end

return lan
