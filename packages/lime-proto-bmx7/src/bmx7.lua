#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local libuci = require("uci")
local wireless = require("lime.wireless")
local utils = require("lime.utils")

bmx7 = {}

bmx7.configured = false
bmx7.f = "bmx7"

function bmx7.configure(args)
	if bmx7.configured then return end
	bmx7.configured = true

	local uci = libuci:cursor()
	local ipv4, ipv6 = network.primary_address()

	fs.writefile("/etc/config/"..bmx7.f, "")

	uci:set(bmx7.f, "general", "bmx7")
	uci:set(bmx7.f, "general", "dbgMuteTimeout", "1000000")
	uci:set(bmx7.f, "general", "tunOutTimeout", "100000")

	uci:set(bmx7.f, "main", "tunDev")
	uci:set(bmx7.f, "main", "tunDev", "main")
	uci:set(bmx7.f, "main", "tun4Address", ipv4:string())
	uci:set(bmx7.f, "main", "tun6Address", ipv6:string())

	-- Enable bmx7 uci config plugin
	uci:set(bmx7.f, "config", "plugin")
	uci:set(bmx7.f, "config", "plugin", "bmx7_config.so")

	-- Enable JSON plugin to get bmx7 information in json format
	uci:set(bmx7.f, "json", "plugin")
	uci:set(bmx7.f, "json", "plugin", "bmx7_json.so")

	-- Enable tun plugin, DISCLAIMER: this must be positioned before table plugin if used.
	uci:set(bmx7.f, "ptun", "plugin")
	uci:set(bmx7.f, "ptun", "plugin", "bmx7_tun.so")

	-- Disable ThrowRules because they are broken in IPv6 with current Linux Kernel
	uci:set(bmx7.f, "ipVersion", "ipVersion")
	uci:set(bmx7.f, "ipVersion", "ipVersion", "6")

	-- Search for networks in 172.16.0.0/12
	uci:set(bmx7.f, "nodes", "tunOut")
	uci:set(bmx7.f, "nodes", "tunOut", "nodes")
	uci:set(bmx7.f, "nodes", "network", "172.16.0.0/12")

	-- Search for networks in 10.0.0.0/8
	uci:set(bmx7.f, "clouds", "tunOut")
	uci:set(bmx7.f, "clouds", "tunOut", "clouds")
	uci:set(bmx7.f, "clouds", "network", "10.0.0.0/8")

	-- Search for internet in the mesh cloud
	uci:set(bmx7.f, "inet4", "tunOut")
	uci:set(bmx7.f, "inet4", "tunOut", "inet4")
	uci:set(bmx7.f, "inet4", "network", "0.0.0.0/0")
	uci:set(bmx7.f, "inet4", "maxPrefixLen", "0")

	-- Search for internet IPv6 gateways in the mesh cloud
	uci:set(bmx7.f, "inet6", "tunOut")
	uci:set(bmx7.f, "inet6", "tunOut", "inet6")
	uci:set(bmx7.f, "inet6", "network", "::/0")
	uci:set(bmx7.f, "inet6", "maxPrefixLen", "0")

	-- Search for other mesh cloud announcements that have public ipv6
	uci:set(bmx7.f, "publicv6", "tunOut")
	uci:set(bmx7.f, "publicv6", "tunOut", "publicv6")
	uci:set(bmx7.f, "publicv6", "network", "2000::/3")
	uci:set(bmx7.f, "publicv6", "maxPrefixLen", "64")

	if config.get_bool("network", "bmx7_over_batman") then
		for _,protoArgs in pairs(config.get("network", "protocols")) do
			if(utils.split(protoArgs, network.protoParamsSeparator)[1] == "batadv") then bmx7.setup_interface("bat0", args) end
		end
	end

	uci:save(bmx7.f)

	if utils.is_installed("firewall") then
		uci:delete("firewall", "bmxtun")

		uci:set("firewall", "bmxtun", "zone")
		uci:set("firewall", "bmxtun", "name", "bmxtun")
		uci:set("firewall", "bmxtun", "input", "ACCEPT")
		uci:set("firewall", "bmxtun", "output", "ACCEPT")
		uci:set("firewall", "bmxtun", "forward", "ACCEPT")
		uci:set("firewall", "bmxtun", "mtu_fix", "1")
		uci:set("firewall", "bmxtun", "conntrack", "1")
		uci:set("firewall", "bmxtun", "device", "bmx+")
		uci:set("firewall", "bmxtun", "family", "ipv4")

		uci:save("firewall")

		fs.remove("/etc/firewall.lime.d/20-bmxtun-mtu_fix")
	else
		fs.mkdir("/etc/firewall.lime.d")
		fs.writefile(
			"/etc/firewall.lime.d/20-bmxtun-mtu_fix",
			"\n" ..
			"iptables -t mangle -D FORWARD -o bmx+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu\n" ..
			"iptables -t mangle -A FORWARD -o bmx+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu\n"
		)
	end
end

function bmx7.setup_interface(ifname, args)
	if not args["specific"] and ifname:match("^wlan%d+.ap") then return end
	vlanId = args[2] or 13
	vlanProto = args[3] or "8021ad"
	nameSuffix = args[4] or "_bmx7"

	local owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local uci = libuci:cursor()
	uci:set("network", owrtDeviceName, "mtu", "1398")

	-- BEGIN [Workaround issue 38]
	if ifname:match("^wlan%d+") then
		local macAddr = wireless.get_phy_mac("phy"..ifname:match("%d+"))
		local vlanIp = { 169, 254, tonumber(macAddr[5], 16), tonumber(macAddr[6], 16) }
		uci:set("network", owrtInterfaceName, "proto", "static")
		uci:set("network", owrtInterfaceName, "ipaddr", table.concat(vlanIp, "."))
		uci:set("network", owrtInterfaceName, "netmask", "255.255.255.255")
	end
	--- END [Workaround issue 38]

	uci:save("network")

	uci:set(bmx7.f, owrtInterfaceName, "dev")
	uci:set(bmx7.f, owrtInterfaceName, "dev", linux802adIfName)

	-- BEGIN [Workaround issue 40]
	if ifname:match("^wlan%d+") then
		uci:set(bmx7.f, owrtInterfaceName, "rateMax", "54000")
	end
	--- END [Workaround issue 40]

	uci:save(bmx7.f)
end

function bmx7.apply()
	os.execute("killall bmx7 ; sleep 2 ; killall -9 bmx7")
	os.execute(bmx7.f)
end

function bmx7.bgp_conf(templateVarsIPv4, templateVarsIPv6)
	local uci = libuci:cursor()

	-- Enable Routing Table Redistribution plugin
	uci:set(bmx7.f, "table", "plugin")
	uci:set(bmx7.f, "table", "plugin", "bmx7_table.so")

	-- Redistribute proto bird routes
	uci:set(bmx7.f, "fromBird", "redistTable")
	uci:set(bmx7.f, "fromBird", "redistTable", "fromBird")
	uci:set(bmx7.f, "fromBird", "table", "254")
	uci:set(bmx7.f, "fromBird", "bandwidth", "100")
	uci:set(bmx7.f, "fromBird", "proto", "12")

	-- Avoid aggregation as it use lot of CPU with huge number of routes
	uci:set(bmx7.f, "fromBird", "aggregatePrefixLen", "128")

	-- Disable proactive tunnels announcement as it use lot of CPU with
	-- huge number of routes
	uci:set(bmx7.f, "general", "proactiveTunRoutes", "0")

	-- BMX7 security features are at moment not used by LiMe, disable hop
	-- by hop links signature as it consume a lot of CPU expecially in
	-- setups with multiples interfaces  and lot of routes like LiMe
	uci:set(bmx7.f, "general", "linkSignatureLen", "0")

	uci:save(bmx7.f)

	local base_bgp_conf = [[
protocol direct {
	interface "bmx*";
}
]]

	return base_bgp_conf
end

return bmx7
