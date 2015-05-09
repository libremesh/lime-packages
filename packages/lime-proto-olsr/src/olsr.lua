#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
--local fs = require("nixio.fs")
local libuci = require("uci")
local wireless = require("lime.wireless")

olsr = {}

olsr.configured = false

function olsr.configure(args)
	if olsr.configured then return end
	olsr.configured = true

	local uci = libuci:cursor()
	local ipv4, ipv6 = network.primary_address()

	fs.writefile("/etc/config/olsr", "")

	--generate olsr conf
	-- ipv4
	uci:set("olsrd", "lime", "olsrd")
	uci:set("olsrd", "lime", "LinkQualityAlgorithm", "etx_ff")
	uci:set("olsrd", "lime", "IpVersion", "4")

	-- load jsonplugin on 9090
	uci:set("olsrd", "limejson", "LoadPlugin")
	uci:set("olsrd", "limejson", "library", "olsrd_jsoninfo.so.0.0")
	uci:set("olsrd", "limejson", "port", "9090")
	uci:set("olsrd", "limejson", "accept", "0.0.0.0")


	uci:set("olsrd", "limehna", "Hna4")
	uci:set("olsrd", "limehna", "netaddr", ipv4:network():string())
	uci:set("olsrd", "limehna", "netmask", ipv4:mask():string())

	uci:save("olsrd")

	-- ipv6
	uci:set("olsrd6", "lime", "olsrd")
	uci:set("olsrd6", "lime", "LinkQualityAlgorithm", "etx_ff")
	uci:set("olsrd6", "lime", "IpVersion", "6")

	-- load jsonplugin on 9090
	uci:set("olsrd6", "limejson", "LoadPlugin")
	uci:set("olsrd6", "limejson", "library", "olsrd_jsoninfo.so.0.0")
	uci:set("olsrd6", "limejson", "port", "9090")
	uci:set("olsrd6", "limejson", "accept", "0::0")


	uci:set("olsrd6", "limehna", "Hna6")
	uci:set("olsrd6", "limehna", "netaddr", ipv6:network():string())
	uci:set("olsrd6", "limehna", "netmask", ipv6:prefix())

	uci:save("olsrd6")


end

function olsr.setup_interface(ifname, args)
	if ifname:match("^wlan%d+_ap") then return end
	vlanId = args[2] or 23
	vlanProto = args[3] or "8021ad"
	nameSuffix = args[4] or "_olsr"

	local uci = libuci:cursor()
	local owrtInterfaceName, linux802adIfName, owrtDeviceName
	owrtInterfaceName = ifname

	if vlanId ~= 0 then
		owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)
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

	else


	uci:set("olsr", owrtInterfaceName, "Interface")
	uci:set("olsr", owrtInterfaceName, "interface", owrtInterfaceName)
	uci:set("olsr", owrtInterfaceName, "interface", owrtInterfaceName)

	uci:set("olsr6", owrtInterfaceName, "Interface")
	uci:set("olsr6", owrtInterfaceName, "interface", owrtInterfaceName)
	uci:set("olsr6", owrtInterfaceName, "interface", owrtInterfaceName)




	end
	uci:save("olsr")
	uci:save("olsr6")


end



function olsr.apply()
		os.execute("/etc/init.d/olsrd restart")
end

return olsr
