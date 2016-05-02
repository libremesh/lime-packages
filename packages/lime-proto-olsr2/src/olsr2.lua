#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local libuci = require("uci")
local wireless = require("lime.wireless")
local utils = require("lime.utils")

olsr2 = {}

olsr2.configured = false

function olsr2.configure(args)
	if olsr2.configured then return end
	olsr2.configured = true

	local uci = libuci:cursor()
	local ipv4, ipv6 = network.primary_address()


	fs.writefile("/etc/config/olsrd2", "")

	uci:set("olsrd2", "lime", "global")
	uci:set("olsrd2", "lime", "failfast", "no")
	uci:set("olsrd2", "lime", "pidfile", "/var/run/olsrd2.pid")
	uci:set("olsrd2", "lime", "lockfile", "/var/lock/olsrd2")



	uci:set("olsrd2", "limelog", "log")
	uci:set("olsrd2", "limejson", "syslog", "true")
	uci:set("olsrd2", "limejson", "info", "all")

	uci:set("olsrd2", "limetelnet", "telnet")
	uci:set("olsrd2", "limetelnet", "port", "2009")

	uci:save("olsrd2")

	uci:set("network", "loopback", "ipaddr", ipv4)
	uci:set("network", "loopback", "ipaddr", ipv6)


end

function olsr2.setup_interface(ifname, args)
	if not args["specific"] then
		if ifname:match("^wlan%d+.ap") then return end
	end
	local vlanId = args[2] or 14
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_olsr"
	--!local ipPrefixTemplate = args[5] or "169.254.%M5.%M6/16"
	local owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)
	local macAddr = network.get_mac(utils.split(ifname, ".")[1])
	local ipAddr = ip.IPv4(utils.applyMacTemplate10(ipPrefixTemplate, macAddr))

	local uci = libuci:cursor()
	uci:set("network", owrtInterfaceName, "proto", "static")
	uci:save("network")

	uci:set("olsrd2", owrtInterfaceName, "interface")
	uci:set("olsrd2", owrtInterfaceName, "interface", owrtInterfaceName)
	uci:save("olsrd2")

end


return olsr2
