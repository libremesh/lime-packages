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

	local uci = libuci:cursor()
	uci:set("network", interface, "interface")
	uci:set("network", interface, "proto", "batadv")
	uci:set("network", interface, "mesh", "bat0")

	if ifname:match("^wlan") then
		owrtFullIfname = "@"..network.limeIfNamePrefix..owrtFullIfname
		mtu = 1532
	end
	if args[2] then
		owrtFullIfname = owrtFullIfname..network.vlanSeparator..args[2]
		if ifname:match("^eth") then
			mtu = 1496

			-- BEGIN
			-- Workaround to http://www.libre-mesh.org/issues/32
			-- We create a new macaddress for ethernet vlan interface
			-- We use 000049 Unicast MAC prefix reserved by Apricot Ltd
			-- We change the 7nt bit to 1 to give it locally administered meaning
			-- Then use it as the new mac address prefix "02:00:49"
			local vlanMacAddr = utils.split(network.get_mac(ifname), ":")
			vlanMacAddr[1] = "02"
			vlanMacAddr[2] = "00"
			vlanMacAddr[3] = "49"
			uci:set("network", interface, "macaddr", table.concat(vlanMacAddr, ":"))
			--- END
		end
	end

	uci:set("network", interface, "ifname", owrtFullIfname)
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
