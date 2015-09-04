#!/usr/bin/lua

local fs = require("nixio.fs")
local network = require("lime.network")
local libuci = require "uci"

anygw = {}

anygw.configured = false

function anygw.configure(args)
	if anygw.configured then return end
	anygw.configured = true

	local ipv4, ipv6 = network.primary_address()
	
	-- anygw macvlan interface
	print("Adding macvlan interface to uci network...")
	local anygw_mac = "aa:aa:aa:aa:aa:aa"
	local anygw_ipv6 = ipv6:minhost()
	local anygw_ipv4 = ipv4:minhost()
	anygw_ipv6[3] = 64 -- SLAAC only works with a /64, per RFC
	anygw_ipv4[3] = ipv4:prefix()

	local pfr = network.limeIfNamePrefix
	
	local uci = libuci:cursor()
	uci:set("network", pfr.."anygw_dev", "device")
	uci:set("network", pfr.."anygw_dev", "type", "macvlan")
	uci:set("network", pfr.."anygw_dev", "name", "anygw")
	uci:set("network", pfr.."anygw_dev", "ifname", "@lan")
	uci:set("network", pfr.."anygw_dev", "macaddr", anygw_mac)

	uci:set("network", pfr.."anygw_if", "interface")
	uci:set("network", pfr.."anygw_if", "proto", "static")
	uci:set("network", pfr.."anygw_if", "ifname", "anygw")
	uci:set("network", pfr.."anygw_if", "ip6addr", anygw_ipv6:string())
	uci:set("network", pfr.."anygw_if", "ipaddr", anygw_ipv4:host():string())
	uci:set("network", pfr.."anygw_if", "netmask", anygw_ipv4:mask():string())

	uci:set("network", pfr.."anygw_rule6", "rule6")
	uci:set("network", pfr.."anygw_rule6", "src", anygw_ipv6:host():string().."/128")
	uci:set("network", pfr.."anygw_rule6", "lookup", "170") -- 0xaa in decimal

	uci:set("network", pfr.."anygw_route6", "route6")
	uci:set("network", pfr.."anygw_route6", "interface", pfr.."anygw_if")
	uci:set("network", pfr.."anygw_route6", "target", anygw_ipv6:network():string().."/"..anygw_ipv6:prefix())
	uci:set("network", pfr.."anygw_route6", "table", "170")

	uci:set("network", pfr.."anygw_rule4", "rule")
	uci:set("network", pfr.."anygw_rule4", "src", anygw_ipv4:host():string().."/32")
	uci:set("network", pfr.."anygw_rule4", "lookup", "170")

	uci:set("network", pfr.."anygw_route4", "route")
	uci:set("network", pfr.."anygw_route4", "interface", pfr.."anygw_if")
	uci:set("network", pfr.."anygw_route4", "target", anygw_ipv4:network():string())
	uci:set("network", pfr.."anygw_route4", "netmask", anygw_ipv4:mask():string())
	uci:set("network", pfr.."anygw_route4", "table", "170")
	uci:save("network")

	fs.mkdir("/etc/firewall.user.d")
	fs.writefile(
		"/etc/firewall.user.d/20-anygw-ebtables",
		"\n" ..
		"ebtables -D FORWARD -j DROP -d " .. anygw_mac .. "\n" ..
		"ebtables -A FORWARD -j DROP -d " .. anygw_mac .. "\n" ..
		"ebtables -t nat -D POSTROUTING -o bat0 -j DROP -s " .. anygw_mac .. "\n" ..
		"ebtables -t nat -A POSTROUTING -o bat0 -j DROP -s " .. anygw_mac .. "\n"
	)

	local content = { }
	table.insert(content, "interface=anygw")
	table.insert(content, "except-interface=br-lan")
	fs.writefile("/etc/dnsmasq.d/lime-proto-anygw-00-interfaces.conf", table.concat(content, "\n").."\n")

	content = { }
	table.insert(content, "dhcp-range=tag:anygw,"..anygw_ipv4:add(1):host():string()..","..ipv4:maxhost():string())
	table.insert(content, "dhcp-option=tag:anygw,option:router,"..anygw_ipv4:host():string())
	table.insert(content, "dhcp-option=tag:anygw,option:dns-server,"..anygw_ipv4:host():string())
	table.insert(content, "dhcp-option=tag:anygw,option:domain-name,lan")
	table.insert(content, "dhcp-option=tag:anygw,option:domain-search,lan")
	table.insert(content, "dhcp-option-force=tag:anygw,option:mtu,1350")
	table.insert(content, "dhcp-broadcast=tag:anygw")
	table.insert(content, "address=/anygw/"..anygw_ipv4:host():string())
	fs.writefile("/etc/dnsmasq.d/lime-proto-anygw-10-ipv4.conf", table.concat(content, "\n").."\n")

	content = { }
	table.insert(content, "enable-ra")
	table.insert(content, "dhcp-range=tag:anygw,"..ipv6:network():string()..",ra-names")
	table.insert(content, "dhcp-option=tag:anygw,option6:domain-search,lan")
	table.insert(content, "dhcp-option=tag:anygw,option6:dns-server,"..anygw_ipv6:host():string())
	table.insert(content, "address=/anygw/"..anygw_ipv6:host():string())
	fs.writefile("/etc/dnsmasq.d/lime-proto-anygw-20-ipv6.conf", table.concat(content, "\n").."\n")

	io.popen("/etc/init.d/dnsmasq enable || true"):close()
end

function anygw.setup_interface(ifname, args) end

function anygw.bgp_conf(templateVarsIPv4, templateVarsIPv6)
	local base_conf = [[
protocol direct {
	interface "anygw";
}
]]
	return base_conf
end

return anygw
