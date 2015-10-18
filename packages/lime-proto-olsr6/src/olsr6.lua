#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local libuci = require("uci")
local wireless = require("lime.wireless")
local utils = require("lime.utils")

olsr = {}

olsr.configured = false

function olsr.configure(args)
	if olsr.configured then return end
	olsr.configured = true

	local uci = libuci:cursor()
	local _, ipv6 = network.primary_address()

	fs.writefile("/etc/config/olsrd6", "")

	uci:set("olsrd6", "lime", "olsrd")
	uci:set("olsrd6", "lime", "LinkQualityAlgorithm", "etx_ff")
	uci:set("olsrd6", "lime", "IpVersion", "6")

	uci:set("olsrd6", "limejson", "LoadPlugin")
	uci:set("olsrd6", "limejson", "library", "olsrd_jsoninfo.so.0.0")
	uci:set("olsrd6", "limejson", "accept", "::1")

	uci:set("olsrd6", "limehna", "Hna6")
	uci:set("olsrd6", "limehna", "netaddr", ipv6:network():string())
	uci:set("olsrd6", "limehna", "prefix", ipv6:prefix())

	uci:save("olsrd6")


end

function olsr.setup_interface(ifname, args)
	if ifname:match("^wlan%d+_ap") then return end
	vlanId = args[2] or 15
	vlanProto = args[3] or "8021ad"
	nameSuffix = args[4] or "_olsr6"

	local uci = libuci:cursor()
	local owrtInterfaceName, linux802adIfName, owrtDeviceName
	owrtInterfaceName = ifname

	if vlanId ~= '0' then
		owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)
	end

	local macAddr = network.get_mac(utils.split(ifname, ".")[1])
	local ipAddr = { utils.applyMacTemplate16("fc00::%M1:%M2:%M3:%M4:%M5:%M6/128", macAddr) }
	uci:set("network", owrtInterfaceName, "proto", "static")
	uci:set("network", owrtInterfaceName, "ip6addr", ipAddr)
	uci:save("network")

	uci:set("olsrd6", owrtInterfaceName, "Interface")
	uci:set("olsrd6", owrtInterfaceName, "interface", owrtInterfaceName)

	uci:save("olsrd6")


end


return olsr
