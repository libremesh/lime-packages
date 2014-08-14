#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")
local lan = require("lime.proto.lan")

batadv = {}

function batadv.setup_interface(ifname, args)
	if ifname:match("^wlan%d_ap") then return end
	local vlanId = args[2] or 11
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_batadv"
	local mtu = 1532
	if ifname:match("^eth") then mtu = 1496 end

	local owrtInterfaceName, _, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local uci = libuci:cursor()

	uci:set("network", owrtDeviceName, "mtu", mtu)

	-- BEGIN
	-- Workaround to http://www.libre-mesh.org/issues/32
	-- We create a new macaddress for ethernet vlan interface
	-- We change the 7nt bit to 1 to give it locally administered meaning
	-- Then use it as the new mac address prefix "02"
	if ifname:match("^eth") then
		local vlanMacAddr = network.get_mac(ifname:gsub("%..*", ""))
		vlanMacAddr[1] = "02"
		uci:set("network", owrtDeviceName, "macaddr", table.concat(vlanMacAddr, ":"))
	end
	--- END

	uci:set("network", owrtInterfaceName, "proto", "batadv")
	uci:set("network", owrtInterfaceName, "mesh", "bat0")

	uci:save("network")
end

function batadv.clean()
	if not fs.lstat("/etc/config/batman-adv") then fs.writefile("/etc/config/batman-adv", "") end
end


function batadv.configure(args)
	batadv.clean()

	local uci = libuci:cursor()
	uci:set("batman-adv", "bat0", "mesh")
	uci:set("batman-adv", "bat0", "bridge_loop_avoidance", "1")
	uci:set("batman-adv", "bat0", "multicast_mode", "0")

	-- if anygw enabled disable DAT that doesn't play well with it
	for _,proto in pairs(config.get("network", "protocols")) do
		if proto == "anygw" then uci:set("batman-adv", "bat0", "distributed_arp_table", "0") end
	end

	lan.setup_interface("bat0", nil)

	uci:save("batman-adv")
end


return batadv
