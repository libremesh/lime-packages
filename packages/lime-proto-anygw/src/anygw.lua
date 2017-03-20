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
	local anygw_mac = "aa:aa:aa:aa:aa:aa"
	local anygw_ipv6 = ipv6:minhost()
	local anygw_ipv4 = ipv4:minhost()
	anygw_ipv6:prefix(64) -- SLAAC only works with a /64, per RFC
	anygw_ipv4:prefix(ipv4:prefix())
	local baseIfname = "br-lan"
	local argsDev = { macaddr = anygw_mac }
	local argsIf = { proto = "static" }
	argsIf.ip6addr = anygw_ipv6:string()
	argsIf.ipaddr = anygw_ipv4:host():string()
	argsIf.netmask = anygw_ipv4:mask():string()

	local owrtInterfaceName, _, _ = network.createMacvlanIface( baseIfname,
		"anygw", argsDev, argsIf )

	local uci = libuci:cursor()
	local pfr = network.limeIfNamePrefix.."anygw_"

	uci:set("network", pfr.."rule6", "rule6")
	uci:set("network", pfr.."rule6", "src", anygw_ipv6:host():string().."/128")
	uci:set("network", pfr.."rule6", "lookup", "170") -- 0xaa in decimal

	uci:set("network", pfr.."route6", "route6")
	uci:set("network", pfr.."route6", "interface", owrtInterfaceName)
	uci:set("network", pfr.."route6", "target", anygw_ipv6:network():string().."/"..anygw_ipv6:prefix())
	uci:set("network", pfr.."route6", "table", "170")

	uci:set("network", pfr.."rule4", "rule")
	uci:set("network", pfr.."rule4", "src", anygw_ipv4:host():string().."/32")
	uci:set("network", pfr.."rule4", "lookup", "170")

	uci:set("network", pfr.."route4", "route")
	uci:set("network", pfr.."route4", "interface", owrtInterfaceName)
	uci:set("network", pfr.."route4", "target", anygw_ipv4:network():string())
	uci:set("network", pfr.."route4", "netmask", anygw_ipv4:mask():string())
	uci:set("network", pfr.."route4", "table", "170")

	uci:save("network")

	fs.mkdir("/etc/firewall.lime.d")
	fs.writefile(
		"/etc/firewall.lime.d/20-anygw-ebtables",
		"\n" ..
		"ebtables -D FORWARD -j DROP -d " .. anygw_mac .. "\n" ..
		"ebtables -A FORWARD -j DROP -d " .. anygw_mac .. "\n" ..
		"ebtables -t nat -D POSTROUTING -o bat0 -j DROP -s " .. anygw_mac .. "\n" ..
		"ebtables -t nat -A POSTROUTING -o bat0 -j DROP -s " .. anygw_mac .. "\n"
	)

	uci:set("dhcp", "lan", "ignore", "1")

	uci:set("dhcp", "lm_net_br_lan_anygw_dhcp", "dhcp")
	uci:set("dhcp", "lm_net_br_lan_anygw_dhcp", "interface", "lm_net_br_lan_anygw_if")
	uci:set("dhcp", "lm_net_br_lan_anygw_dhcp", "start", "2")
	uci:set("dhcp", "lm_net_br_lan_anygw_dhcp", "limit", (2 ^ (32 - anygw_ipv4:prefix()))) -- use whole network
	uci:set("dhcp", "lm_net_br_lan_anygw_dhcp", "leasetime", "1h")

	uci:set("dhcp", "lm_net_br_lan_anygw_if", "tag")
	uci:set("dhcp", "lm_net_br_lan_anygw_if", "dhcp_option", { "option:mtu,1350" } )
	uci:set("dhcp", "lm_net_br_lan_anygw_if", "force", "1")

	uci:foreach("dhcp", "dnsmasq",
		function(s)
			uci:set("dhcp", s[".name"], "address", {
						"/anygw/"..anygw_ipv4:host():string(),
						"/thisnode.info/"..anygw_ipv4:host():string()
			})
		end
	)

	uci:save("dhcp")

	local content = { }
	table.insert(content, "enable-ra")
	table.insert(content, "dhcp-range=tag:anygw,"..ipv6:network():string()..",ra-names,24h")
	table.insert(content, "dhcp-option=tag:anygw,option6:domain-search,lan")
	table.insert(content, "dhcp-option=tag:anygw,option6:dns-server,"..anygw_ipv6:host():string())
	table.insert(content, "address=/anygw/"..anygw_ipv6:host():string())
	table.insert(content, "address=/thisnode.info/"..anygw_ipv6:host():string())
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
