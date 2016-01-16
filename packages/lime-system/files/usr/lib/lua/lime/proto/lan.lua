#!/usr/bin/lua

lan = {}

local network = require("lime.network")
local libuci = require("uci")

lan.configured = false

function lan.configure(args)
	if lan.configured then return end
	lan.configured = true

	local ipv4, ipv6 = network.primary_address()
	local uci = libuci:cursor()
	uci:set("network", "lan", "ip6addr", ipv6:string())
	uci:set("network", "lan", "ipaddr", ipv4:host():string())
	uci:set("network", "lan", "netmask", ipv4:mask():string())
	uci:set("network", "lan", "proto", "static")
	uci:set("network", "lan", "mtu", "1500")
	uci:delete("network", "lan", "ifname")
	uci:save("network")
end

function lan.setup_interface(ifname, args)
	if args and args["nobridge"] then return end
	if ifname:match("^wlan") then return end
	if ifname:match(network.protoVlanSeparator.."%d+$") then return end

	local uci = libuci:cursor()
	local bridgedIfs = {}
	local oldIfs = uci:get("network", "lan", "ifname") or {}
	if type(oldIfs) == "string" then oldIfs = utils.split(oldIfs, " ") end
	for _,iface in pairs(oldIfs) do
		if iface ~= ifname then
			table.insert(bridgedIfs, iface)
		end
	end
	table.insert(bridgedIfs, ifname)
	uci:set("network", "lan", "ifname", bridgedIfs)
	uci:save("network")
end

function lan.bgp_conf(templateVarsIPv4, templateVarsIPv6)
	local base_conf = [[
protocol direct {
	interface "br-lan";
}
]]
	return base_conf
end

return lan
