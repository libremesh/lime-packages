#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local libuci = require("uci")
local wireless = require("lime.wireless")
local utils = require("lime.utils")
local ip = require("luci.ip")
olsr2 = {}

olsr2.configured = false

function olsr2.configure(args)
	if olsr2.configured then return end
	olsr2.configured = true

	local uci = libuci:cursor()
	local ipv4, ipv6 = network.primary_address()
	local origInterfaceName = network.limeIfNamePrefix.."olsr_originator_lo"

	fs.writefile("/etc/config/olsrd2", "")
	uci:set("olsrd2", "lime", "global")
	uci:set("olsrd2", "lime", "failfast", "no")
	uci:set("olsrd2", "lime", "pidfile", "/var/run/olsrd2.pid")
	uci:set("olsrd2", "lime", "lockfile", "/var/lock/olsrd2")
	uci:set("olsrd2", "lime", "olsrv2")
	uci:set("olsrd2", "lime", "lan", {ipv4:string(), ipv6:string()})
	uci:set("olsrd2", "limelog", "log")
	uci:set("olsrd2", "limejson", "syslog", "true")
	uci:set("olsrd2", "limejson", "info", "all")
	uci:set("olsrd2", "limetelnet", "telnet")
	uci:set("olsrd2", "limetelnet", "port", "2009")
	uci:set("olsrd2", origInterfaceName, "interface")
	uci:set("olsrd2", origInterfaceName, "ifname", "loopback")
	uci:save("olsrd2")

	uci:set("network", origInterfaceName, "interface")
	uci:set("network", origInterfaceName, "ifname", "@loopback")
	uci:set("network", origInterfaceName, "proto", "static")
	uci:set("network", origInterfaceName, "ipaddr", ipv4:host():string())
	uci:set("network", origInterfaceName, "netmask", "255.255.255.255")
	uci:set("network", origInterfaceName, "ip6addr", ipv6:host():string().."/128")
	uci:save("network")
end

function olsr2.setup_interface(ifname, args)
	if not args["specific"] then
		if ifname:match("^wlan%d+.ap") then return end
	end
	local vlanId = tonumber(args[2]) or 16
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_olsr"
	local owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)
	local uci = libuci:cursor()

	uci:set("olsrd2", owrtInterfaceName, "interface")
	uci:set("olsrd2", owrtInterfaceName, "ifname", owrtInterfaceName)
	uci:save("olsrd2")

end


return olsr2
