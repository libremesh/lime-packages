#!/usr/bin/lua

lan = {}

local network = require "lime.network"

function lan.configure()
	local ipv4, ipv6 = network.primary_address()
	
	uci:set("network", "lan", "ip6addr", ipv6:string())
	uci:set("network", "lan", "ipaddr", ipv4:host():string())
	uci:set("network", "lan", "netmask", ipv4:mask():string())
end

function lan.setup_interface(ifname, args)
	local bridgedIfs = uci:get("network", "lan", "ifname") or {}
	bridgedIfs[#bridgedIfs+1] = ifname
	uci:set("network", "lan", "ifname", bridgedIfs)
	uci:save("network")
end

return lan
