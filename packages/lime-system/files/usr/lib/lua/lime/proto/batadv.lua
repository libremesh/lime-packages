#!/usr/bin/lua

batadv = {}

function batadv.setup_interface(ifname, args)
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

	uci:set("network", interface, "interface")
	uci:set("network", interface, "ifname", owrtFullIfname)
	uci:set("network", interface, "proto", "batadv")
	uci:set("network", interface, "mesh", "bat0")
	uci:set("network", interface, "mtu", mtu)
	uci:save("network")
end

function batadv.clean()
	print("Clearing batman-adv config...")
	uci:delete("batman-adv", "bat0")
	if not fs.lstat("/etc/config/batman-adv") then fs.writefile("/etc/config/batman-adv", "") end
end


function batadv.configure()
	batadv.clean()

	uci:set("batman-adv", "bat0", "mesh")
	uci:set("batman-adv", "bat0", "bridge_loop_avoidance", "1")

	-- if anygw enabled disable DAT that doesn't play well with it
	for _,proto in pairs(config.get("network", "protocols")) do
		if proto == "anygw" then uci:set("batman-adv", "bat0", "distributed_arp_table", "0") end
	end
	
	uci:save("batman-adv")
end


return batadv
