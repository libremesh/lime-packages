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
	local ipv4 = network.primary_address()

	fs.writefile("/etc/config/olsrd", "")

	uci:set("olsrd", "lime", "olsrd")
	uci:set("olsrd", "lime", "LinkQualityAlgorithm", "etx_ff")
	uci:set("olsrd", "lime", "IpVersion", "4")

	uci:set("olsrd", "limejson", "LoadPlugin")
	uci:set("olsrd", "limejson", "library", "olsrd_jsoninfo.so.0.0")
	uci:set("olsrd", "limejson", "accept", "127.0.0.1")

	uci:set("olsrd", "limehna", "Hna4")
	uci:set("olsrd", "limehna", "netaddr", ipv4:network():string())
	uci:set("olsrd", "limehna", "netmask", ipv4:mask():string())

	uci:save("olsrd")


end

function olsr.setup_interface(ifname, args)
	if ifname:match("^wlan%d+_ap") then return end
	vlanId = args[2] or 14
	vlanProto = args[3] or "8021ad"
	nameSuffix = args[4] or "_olsr"

	local uci = libuci:cursor()
	local owrtInterfaceName, linux802adIfName, owrtDeviceName
	owrtInterfaceName = ifname

	if vlanId ~= 0 then
		owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)
	end

	local macAddr = network.get_mac(utils.split(ifname, ".")[1])
	local ipAddr = { utils.applyMacTemplate10("169.254.%M5.%M6/16", macAddr) }
	uci:set("network", owrtInterfaceName, "proto", "static")
	uci:set("network", owrtInterfaceName, "ipaddr", ipAddr)
	uci:set("network", owrtInterfaceName, "netmask", "255.255.0.0")
	uci:save("network")

	uci:set("olsrd", owrtInterfaceName, "Interface")
	uci:set("olsrd", owrtInterfaceName, "interface", owrtInterfaceName)

	uci:save("olsrd")

end


return olsr
