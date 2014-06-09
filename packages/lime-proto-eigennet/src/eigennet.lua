#!/usr/bin/lua

local network = require("lime.network")
local batadv = require("lime.proto.batadv")
local libuci = require("uci")

eigennet = {}

function eigennet.setup_interface(ifname, args)
	if ifname:match("^wlan%d_ap") then return end

	if ifname:match("^eth%d$") then
		args[2] = args[2] or 10
		args[3] = args[3] or "8021q"
		args[4] = args[4] or "_eigennet"

		batadv.setup_interface(ifname, args)
		return
	end

	if ifname:match("^wlan%d_adhoc$") then
		local owrtInterfaceName = network.limeIfNamePrefix..ifname

		local uci = libuci:cursor()

		uci:set("network", owrtInterfaceName, "interface")
		uci:set("network", owrtInterfaceName, "mtu", 1532)
		uci:set("network", owrtInterfaceName, "proto", "batadv")
		uci:set("network", owrtInterfaceName, "mesh", "bat0")
		uci:set("network", owrtInterfaceName, "eigennet", "1")

		uci:save("network")
	end
end

function eigennet.clean()
	batadv.clean()
end

function eigennet.configure(args)
	batadv.configure(args)
end


return eigennet
