#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local libuci = require("uci")
local wireless = require("lime.wireless")

bmx6 = {}

bmx6.configured = false

function bmx6.configure(args)
	if bmx6.configured then return end
	bmx6.configured = true

	local uci = libuci:cursor()
	local ipv4, ipv6 = network.primary_address()

	fs.writefile("/etc/config/bmx6", "")

	uci:set("bmx6", "general", "bmx6")
	uci:set("bmx6", "general", "dbgMuteTimeout", "1000000")

	uci:set("bmx6", "main", "tunDev")
	uci:set("bmx6", "main", "tunDev", "main")
	uci:set("bmx6", "main", "tun4Address", ipv4:host():string().."/32")
	uci:set("bmx6", "main", "tun6Address", ipv6:host():string().."/128")

	-- Enable bmx6 uci config plugin
	uci:set("bmx6", "config", "plugin")
	uci:set("bmx6", "config", "plugin", "bmx6_config.so")

	-- Enable JSON plugin to get bmx6 information in json format
	uci:set("bmx6", "json", "plugin")
	uci:set("bmx6", "json", "plugin", "bmx6_json.so")

	-- Enable Routing Table Redistribution plugin
	uci:set("bmx6", "table", "plugin")
	uci:set("bmx6", "table", "plugin", "bmx6_table.so")

	-- Disable ThrowRules because they are broken in IPv6 with current Linux Kernel
	uci:set("bmx6", "ipVersion", "ipVersion")
	uci:set("bmx6", "ipVersion", "ipVersion", "6")

	-- Search for networks in 172.16.0.0/12
	uci:set("bmx6", "nodes", "tunOut")
	uci:set("bmx6", "nodes", "tunOut", "nodes")
	uci:set("bmx6", "nodes", "network", "172.16.0.0/12")

	-- Search for networks in 172.16.0.0/12
	uci:set("bmx6", "nodes", "tunOut")
	uci:set("bmx6", "nodes", "tunOut", "dummynodes")
	uci:set("bmx6", "nodes", "network", "192.0.2.0/24")

	-- Search for networks in 10.0.0.0/8
	uci:set("bmx6", "clouds", "tunOut")
	uci:set("bmx6", "clouds", "tunOut", "clouds")
	uci:set("bmx6", "clouds", "network", "10.0.0.0/8")

	-- Search for internet in the mesh cloud
	uci:set("bmx6", "inet4", "tunOut")
	uci:set("bmx6", "inet4", "tunOut", "inet4")
	uci:set("bmx6", "inet4", "network", "0.0.0.0/0")
	uci:set("bmx6", "inet4", "maxPrefixLen", "0")

	-- Search for internet IPv6 gateways in the mesh cloud
	uci:set("bmx6", "inet6", "tunOut")
	uci:set("bmx6", "inet6", "tunOut", "inet6")
	uci:set("bmx6", "inet6", "network", "::/0")
	uci:set("bmx6", "inet6", "maxPrefixLen", "0")

	-- Search for other mesh cloud announcements that have public ipv6
	uci:set("bmx6", "publicv6", "tunOut")
	uci:set("bmx6", "publicv6", "tunOut", "publicv6")
	uci:set("bmx6", "publicv6", "network", "2000::/3")
	uci:set("bmx6", "publicv6", "maxPrefixLen", "64")

	-- Announce local ipv4 cloud
	uci:set("bmx6", "local4", "tunIn")
	uci:set("bmx6", "local4", "tunIn", "local4")
	uci:set("bmx6", "local4", "network", ipv4:network():string().."/"..ipv4:prefix())

	-- Announce local ipv6 cloud
	uci:set("bmx6", "local6", "tunIn")
	uci:set("bmx6", "local6", "tunIn", "local6")
	uci:set("bmx6", "local6", "network", ipv6:network():string().."/"..ipv6:prefix())

	if config.get_bool("network", "bmx6_over_batman") then
		for _,protoArgs in pairs(config.get("network", "protocols")) do
			if(utils.split(protoArgs, network.protoParamsSeparator)[1] == "batadv") then bmx6.setup_interface("bat0", args) end
		end
	end

	for _,proto in pairs(config.get("network", "protocols")) do
		if proto:match("^bgp") then
			uci:set("bmx6", "fromBird", "redistTable")
			uci:set("bmx6", "fromBird", "redistTable", "fromBird")
			uci:set("bmx6", "fromBird", "table", "200")
			uci:set("bmx6", "fromBird", "bandwidth", "100")
			uci:set("bmx6", "fromBird", "all", "1")
			uci:set("bmx6", "fromBird", "sys", "12")
		end
	end

	uci:save("bmx6")


	uci:delete("firewall", "bmxtun")

	uci:set("firewall", "bmxtun", "zone")
	uci:set("firewall", "bmxtun", "name", "bmxtun")
	uci:set("firewall", "bmxtun", "input", "ACCEPT")
	uci:set("firewall", "bmxtun", "output", "ACCEPT")
	uci:set("firewall", "bmxtun", "forward", "ACCEPT")
	uci:set("firewall", "bmxtun", "mtu_fix", "1")
	uci:set("firewall", "bmxtun", "device", "bmx+")
	uci:set("firewall", "bmxtun", "family", "ipv4")

	uci:save("firewall")
end

function bmx6.setup_interface(ifname, args)
	if ifname:match("^wlan%d+_ap") then return end
	vlanId = args[2] or 13
	vlanProto = args[3] or "8021ad"
	nameSuffix = args[4] or "_bmx6"

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

	uci:set("bmx6", owrtInterfaceName, "dev")
	uci:set("bmx6", owrtInterfaceName, "dev", linux802adIfName)
	uci:save("bmx6")
end

function bmx6.apply()
    os.execute("killall bmx6 ; sleep 2 ; killall -9 bmx6")
    os.execute("bmx6")
end

function bmx6.bgp_conf(templateVarsIPv4, templateVarsIPv6)
	local base_conf = [[
table tobmx;

protocol pipe {
	table master;
	peer table tobmx;
	import all;
	export all;
}

protocol kernel
{
	scan time 20;
	table tobmx;
	kernel table 200;
	import all;
	export all;
}

protocol direct {
	interface "bmx*";
}

]]
	return base_conf
end

return bmx6
