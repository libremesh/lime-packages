#!/usr/bin/lua

batadv = {}

function batadv.setup_interface(interface, ifname)
    x:set("network", interface, "interface")
    x:set("network", interface, "ifname", ifname)
    x:set("network", interface, "proto", "batadv")
    x:set("network", interface, "mesh", "bat0")
    x:set("network", interface, "mtu", "1528")
    x:save("network")
end

function batadv.clean()
    print("Clearing batman-adv config...")
    x:delete("batman-adv", "bat0")
end

function batadv.init()
    -- TODO
end

function batadv.configure()
    batadv.clean()

    x:set("batman-adv", "bat0", "mesh")
    x:set("batman-adv", "bat0", "brige_loop_avoidance", "1")
    x:save("batman-adv")
end

function batadv.apply()
    -- TODO (i.e. /etc/init.d/network restart)
end

return batadv
