#!/usr/bin/lua

anygw = {}

function anygw.configure()
	local network = require("lime.network")
	local libuci = require "uci"
	local uci = libuci:cursor()
	
	local ipv4, ipv6 = network.primary_address()
	
	-- anygw macvlan interface
	print("Adding macvlan interface to uci network...")
	local n1, n2, n3 = network_id()
	local anygw_mac = string.format("aa:aa:aa:%02x:%02x:%02x", n1, n2, n3)
	local anygw_ipv6 = ipv6:minhost()
	local anygw_ipv4 = ipv4:minhost()
	anygw_ipv6[3] = 64 -- SLAAC only works with a /64, per RFC
	anygw_ipv4[3] = ipv4:prefix()

	local pfr = network.limeIfNamePrefix
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

	local content = { insert = table.insert, concat = table.concat }
	for line in io.lines("/etc/firewall.user") do
		if not line:match("^ebtables ") then content:insert(line) end
	end
	content:insert("ebtables -A FORWARD -j DROP -d " .. anygw_mac)
	content:insert("ebtables -t nat -A POSTROUTING -o bat0 -j DROP -s " .. anygw_mac)
	fs.writefile("/etc/firewall.user", content:concat("\n").."\n")

	-- IPv6 router advertisement for anygw interface
	print("Enabling RA in dnsmasq...")
	local content = { }
	table.insert(content,               "enable-ra")
	table.insert(content, string.format("dhcp-range=tag:anygw, %s, ra-names", anygw_ipv6:network(64):string()))
	table.insert(content,               "dhcp-option=tag:anygw, option6:domain-search, lan")
	table.insert(content, string.format("address=/anygw/%s", anygw_ipv6:host():string()))
	table.insert(content, string.format("dhcp-option=tag:anygw, option:router, %s", anygw_ipv4:host():string()))
	table.insert(content, string.format("dhcp-option=tag:anygw, option:dns-server, %s", anygw_ipv4:host():string()))
	table.insert(content,               "dhcp-broadcast=tag:anygw")
	table.insert(content,               "no-dhcp-interface=br-lan")
	fs.writefile("/etc/dnsmasq.conf", table.concat(content, "\n").."\n")

	-- and disable 6relayd
	print("Disabling 6relayd...")
	fs.writefile("/etc/config/6relayd", "")
end

function anygw.setup_interface(ifname, args) end

return anygw
