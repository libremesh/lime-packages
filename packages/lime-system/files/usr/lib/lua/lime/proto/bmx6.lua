#!/usr/bin/lua

bmx6 = {}

function bmx6.clean()
    print("Clearing bmx6 config...")
    fs.writefile("/etc/config/bmx6", "")
end

function bmx6.init()
    -- TODO
end

function bmx6.configure(v4, v6)
    bmx6.clean()

    x:set("bmx6", "general", "bmx6")
    x:set("bmx6", "general", "dbgMuteTimeout", "1000000")

    x:set("bmx6", "main", "tunDev")
    x:set("bmx6", "main", "tunDev", "main")
    x:set("bmx6", "main", "tun4Address", v4)
    x:set("bmx6", "main", "tun6Address", v6)

    -- Enable bmx6 uci config plugin
    x:set("bmx6", "config", "plugin")
    x:set("bmx6", "config", "plugin", "bmx6_config.so")

    -- Enable JSON plugin to get bmx6 information in json format
    x:set("bmx6", "json", "plugin")
    x:set("bmx6", "json", "plugin", "bmx6_json.so")

    -- Disable ThrowRules because they are broken in IPv6 with current Linux Kernel
    x:set("bmx6", "ipVersion", "ipVersion")
    x:set("bmx6", "ipVersion", "ipVersion", "6")

    -- Search for mesh node's IP
    x:set("bmx6", "nodes", "tunOut")
    x:set("bmx6", "nodes", "tunOut", "nodes")
    x:set("bmx6", "nodes", "network", "172.16.0.0/12")

    -- Search for clouds
    x:set("bmx6", "clouds", "tunOut")
    x:set("bmx6", "clouds", "tunOut", "clouds")
    x:set("bmx6", "clouds", "network", "10.0.0.0/8")

    -- Search for internet in the mesh cloud
    x:set("bmx6", "inet4", "tunOut")
    x:set("bmx6", "inet4", "tunOut", "inet4")
    x:set("bmx6", "inet4", "network", "0.0.0.0/0")
    x:set("bmx6", "inet4", "maxPrefixLen", "0")

    -- Search for internet IPv6 gateways in the mesh cloud
    x:set("bmx6", "inet6", "tunOut")
    x:set("bmx6", "inet6", "tunOut", "inet6")
    x:set("bmx6", "inet6", "network", "::/0")
    x:set("bmx6", "inet6", "maxPrefixLen", "0")

    -- Search for other mesh cloud announcements
    x:set("bmx6", "ula", "tunOut")
    x:set("bmx6", "ula", "tunOut", "ula")
    x:set("bmx6", "ula", "network", "fddf:ca00::/24")
    x:set("bmx6", "ula", "minPrefixLen", "48")

    -- Search for other mesh cloud announcements that have public ipv6
    x:set("bmx6", "publicv6", "tunOut")
    x:set("bmx6", "publicv6", "tunOut", "publicv6")
    x:set("bmx6", "publicv6", "network", "2000::/3")
    x:set("bmx6", "publicv6", "maxPrefixLen", "64")

    x:save("bmx6")
}

function bmx6.setup_interface(interface, ifname)
    x:set("bmx6", interface, "dev")
    x:set("bmx6", interface, "dev", ifname)
    x:save("bmx6")

    x:set("network", interface, "interface")
    x:set("network", interface, "ifname", ifname)
    x:set("network", interface, "proto", "none")
    x:set("network", interface, "auto", "1")
    x:save("network")
}

function bmx6.apply()
    os.execute("killall bmx6 ; sleep 2 ; killall -9 bmx6")
    os.execute("bmx6")
end

return bmx6
