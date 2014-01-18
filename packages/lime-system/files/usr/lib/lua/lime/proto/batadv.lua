#!/usr/bin/lua

batadv = {}

function batadv.setup_interface(ifname, args)
	local interface = network.limeIfNamePrefix..ifname
	local linuxFullIfname = ifname; if args[2] then linuxFullIfname = linuxFullIfname..network.vlanSeparator..vlan

	uci:set("network", interface, "interface")
	uci:set("network", interface, "ifname", linuxFullIfname)
	uci:set("network", interface, "proto", "batadv")
	uci:set("network", interface, "mesh", "bat0")
	uci:set("network", interface, "mtu", "1528")
	uci:save("network")
end

function batadv.clean()
    print("Clearing batman-adv config...")
    uci:delete("batman-adv", "bat0")
    if not fs.lstat("/etc/config/batman-adv") then fs.writefile("/etc/config/batman-adv", "") end
end

function batadv.init()
    -- TODO
end

function batadv.configure()
    batadv.clean()

    uci:set("batman-adv", "bat0", "mesh")
    uci:set("batman-adv", "bat0", "bridge_loop_avoidance", "1")
    uci:save("batman-adv")
end

function batadv.apply()
    -- TODO (i.e. /etc/init.d/network restart)
end

return batadv
