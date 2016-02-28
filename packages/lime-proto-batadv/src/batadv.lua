#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")
local lan = require("lime.proto.lan")
local utils = require("lime.utils")

batadv = {}

batadv.configured = false

function batadv.configure(args)
	if batadv.configured then return end
	batadv.configured = true

	if not fs.lstat("/etc/config/batman-adv") then fs.writefile("/etc/config/batman-adv", "") end

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

function batadv.setup_interface(ifname, args)
	if ifname:match("^wlan%d+_ap") then return end
	if ifname:match("^eth") then return end

	local vlanId = args[2] or "%N1"
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_batadv"
	local mtu = 1532

	--! Unless a specific integer is passed, parse network_id (%N1) template
	--! and use that number + 16 to get a vlanId between 16 and 271 for batadv
	--! (to avoid overlapping with other protocols)
	if not tonumber(vlanId) then vlanId = 16 + utils.applyNetTemplate10(vlanId) end

	local owrtInterfaceName, _, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local uci = libuci:cursor()
	uci:set("network", owrtDeviceName, "mtu", mtu)
	uci:set("network", owrtInterfaceName, "proto", "batadv")
	uci:set("network", owrtInterfaceName, "mesh", "bat0")
	uci:save("network")
end


return batadv
