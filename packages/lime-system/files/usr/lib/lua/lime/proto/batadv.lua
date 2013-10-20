#!/usr/bin/lua

function clean()
	print("Clearing batman-adv config...")
  x:delete("batman-adv", "bat0")
end

function init()
  -- TODO
end

function configure()
  clean()

	x:set("batman-adv", "bat0", "mesh")
	x:set("batman-adv", "bat0", "brige_loop_avoidance", "1")
}

function apply()
  -- TODO (i.e. /etc/init.d/network restart)
end

function setup_interface_batadv(interface, ifname)
  x:set("network", interface, "interface")
  x:set("network", interface, "ifname", ifname)
  x:set("network", interface, "proto", "batadv")
  x:set("network", interface, "mesh", "bat0")
  x:set("network", interface, "mtu", "1528")
end
