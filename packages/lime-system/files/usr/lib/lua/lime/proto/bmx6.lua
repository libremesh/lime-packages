#!/usr/bin/lua

local network = require "lime.network"

bmx6 = {}

function bmx6.setup_interface(ifname, args)
	local interface = network.limeIfNamePrefix..ifname.."_bmx6"
	local owrtFullIfname = "@"..network.limeIfNamePrefix..ifname; if args[2] then owrtFullIfname = owrtFullIfname..network.vlanSeparator..vlan

	uci:set("bmx6", interface, "dev")
	uci:set("bmx6", interface, "dev", linuxFullIfname)
	uci:save("bmx6")

	uci:set("network", interface, "interface")
	uci:set("network", interface, "ifname", owrtFullIfname)
	uci:set("network", interface, "proto", "none")
	uci:set("network", interface, "auto", "1")
	uci:set("network", interface, "mtu", "1398")
	uci:save("network")
end

function bmx6.clean()
	print("Clearing bmx6 config...")
	fs.writefile("/etc/config/bmx6", "")
end

function bmx6.init()
    -- TODO
end

function bmx6.configure(ipv4, ipv6)
    bmx6.clean()

    uci:set("bmx6", "general", "bmx6")
    uci:set("bmx6", "general", "dbgMuteTimeout", "1000000")

    uci:set("bmx6", "main", "tunDev")
    uci:set("bmx6", "main", "tunDev", "main")
    uci:set("bmx6", "main", "tun4Address", ipv4:string())
    uci:set("bmx6", "main", "tun6Address", ipv6:string())

    -- Enable bmx6 uci config plugin
    uci:set("bmx6", "config", "plugin")
    uci:set("bmx6", "config", "plugin", "bmx6_config.so")

    -- Enable JSON plugin to get bmx6 information in json format
    uci:set("bmx6", "json", "plugin")
    uci:set("bmx6", "json", "plugin", "bmx6_json.so")

    -- Disable ThrowRules because they are broken in IPv6 with current Linux Kernel
    uci:set("bmx6", "ipVersion", "ipVersion")
    uci:set("bmx6", "ipVersion", "ipVersion", "6")

    -- Search for mesh node's IP
    uci:set("bmx6", "nodes", "tunOut")
    uci:set("bmx6", "nodes", "tunOut", "nodes")
    uci:set("bmx6", "nodes", "network", "172.16.0.0/12")

    -- Search for clouds
    uci:set("bmx6", "clouds", "tunOut")
    uci:set("bmx6", "clouds", "tunOut", "clouds")
    uci:set("bmx6", "clouds", "network", "10.0.0.0/8")

    -- Search for internet in the mesh cloud
    uci:set("bmx6", "inet4", "tunOut")
    uci:set("bmx6", "inet4", "tunOut", "inet4")
    uci:set("bmx6", "inet4", "network", "0.0.0.0/0")
    uci:set("bmx6", "inet4", "maxPrefixLen", "0")

    -- Search for internet IPv6 gateways in the mesh cloud
    uci:set("bmx6", "inet6", "tunOut")
    uci:set("bmx6", "inet6", "tunOut", "inet6")
    uci:set("bmx6", "inet6", "network", "::/0")
    uci:set("bmx6", "inet6", "maxPrefixLen", "0")

    -- Search for other mesh cloud announcements
    uci:set("bmx6", "ula", "tunOut")
    uci:set("bmx6", "ula", "tunOut", "ula")
    uci:set("bmx6", "ula", "network", "fddf:ca00::/24")
    uci:set("bmx6", "ula", "minPrefixLen", "48")

    -- Search for other mesh cloud announcements that have public ipv6
    uci:set("bmx6", "publicv6", "tunOut")
    uci:set("bmx6", "publicv6", "tunOut", "publicv6")
    uci:set("bmx6", "publicv6", "network", "2000::/3")
    uci:set("bmx6", "publicv6", "maxPrefixLen", "64")

    uci:save("bmx6")
end

function bmx6.apply()
    os.execute("killall bmx6 ; sleep 2 ; killall -9 bmx6")
    os.execute("bmx6")
end

return bmx6
