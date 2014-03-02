#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")
local lan = require("lime.proto.lan")

batadv = {}

function batadv.setup_interface(ifname, args)
	if ifname:match("^wlan%d_ap") then return end

	local interface = network.limeIfNamePrefix..ifname.."_batadv"
	local owrtFullIfname = ifname
	local mtu = 1500

	if ifname:match("^wlan") then
		owrtFullIfname = "@"..network.limeIfNamePrefix..owrtFullIfname
		mtu = 1532
	end
	if args[2] then
		owrtFullIfname = owrtFullIfname..network.vlanSeparator..args[2]
		if ifname:match("^eth") then mtu = 1496 end 
	end

	local uci = libuci:cursor()
	uci:set("network", interface, "interface")
	uci:set("network", interface, "ifname", owrtFullIfname)
	uci:set("network", interface, "proto", "batadv")
	uci:set("network", interface, "mesh", "bat0")
	uci:set("network", interface, "mtu", mtu)
	uci:save("network")
end

function batadv.clean()
	print("Clearing batman-adv config...")
	local uci = libuci:cursor()
	uci:delete("batman-adv", "bat0")
	uci:save("batman-adv")
	if not fs.lstat("/etc/config/batman-adv") then fs.writefile("/etc/config/batman-adv", "") end
end


function batadv.configure(args)
	batadv.clean()

	local uci = libuci:cursor()
	uci:set("batman-adv", "bat0", "mesh")
	uci:set("batman-adv", "bat0", "bridge_loop_avoidance", "1")

	-- if anygw enabled disable DAT that doesn't play well with it
	for _,proto in pairs(config.get("network", "protocols")) do
		if proto == "anygw" then uci:set("batman-adv", "bat0", "distributed_arp_table", "0") end
	end

	lan.setup_interface("bat0", nil)

	uci:save("batman-adv")
end


return batadv
