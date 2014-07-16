#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local libuci = require("uci")

babeld = {}

function babeld.setup_interface(ifname, args)
	vlanId = args[2] or 14
	vlanProto = args[3] or "8021ad"
	nameSuffix = args[4] or "_babeld"

	local owrtInterfaceName, linux802adIfName, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local uci = libuci:cursor()
	uci:set("babeld", owrtInterfaceName, "interface")
	uci:set("babeld", owrtInterfaceName, "ignore", "false")
	uci:save("babeld")
end

function babeld.clean()
	print("Clearing babeld config...")
	fs.writefile("/etc/config/babeld", "")
end

function babeld.configure(args)

	babeld.clean()

	local ipv4, ipv6 = network.primary_address()

	local uci = libuci:cursor()

	uci:set("babeld", "general", "babeld")
	uci:set("babeld", "general", "log_file", "/var/log/babeld.log")

	-- Don't announce anything by default
	uci:set("babeld", "default_out", "filter")
	uci:set("babeld", "default_out", "ignore", "false")
	uci:set("babeld", "default_out", "type", "redistribute")
	uci:set("babeld", "default_out", "local", "1")
	uci:set("babeld", "default_out", "action", "deny")

	-- Don't search for anything by default
	uci:set("babeld", "default_in", "filter")
	uci:set("babeld", "default_in", "ignore", "false")
	uci:set("babeld", "default_in", "type", "in")
	uci:set("babeld", "default_in", "action", "deny")

	-- Search for networks in 172.16.0.0/12
	uci:set("babeld", "nodes", "filter")
	uci:set("babeld", "nodes", "ignore", "false")
	uci:set("babeld", "nodes", "type", "in")
	uci:set("babeld", "nodes", "ip", "172.16.0.0/12")

	-- Search for networks in 10.0.0.0/8
	uci:set("babeld", "clouds", "filter")
	uci:set("babeld", "clouds", "ignore", "false")
	uci:set("babeld", "clouds", "type", "in")
	uci:set("babeld", "clouds", "ip", "10.0.0.0/8")

	-- Search for internet in the mesh cloud
	uci:set("babeld", "inet4", "filter")
	uci:set("babeld", "inet4", "ignore", "false")
	uci:set("babeld", "inet4", "type", "in")
	uci:set("babeld", "inet4", "ip", "0.0.0.0/0")
	uci:set("babeld", "inet4", "le", "0")

	-- Search for internet IPv6 gateways in the mesh cloud
	uci:set("babeld", "inet6", "filter")
	uci:set("babeld", "inet6", "ignore", "false")
	uci:set("babeld", "inet6", "type", "in")
	uci:set("babeld", "inet6", "ip", "::/0")
	uci:set("babeld", "inet6", "le", "0")

	-- Search for other mesh cloud announcements that have public ipv6
	uci:set("babeld", "publicv6", "filter")
	uci:set("babeld", "publicv6", "ignore", "false")
	uci:set("babeld", "publicv6", "type", "in")
	uci:set("babeld", "publicv6", "ip", "2000::/3")
	uci:set("babeld", "publicv6", "le", "64")

	-- Announce local ipv4 cloud
	uci:set("babeld", "local4", "filter")
	uci:set("babeld", "local4", "ignore", "false")
	uci:set("babeld", "local4", "type", "redistribute")
	uci:set("babeld", "local4", "ip", ipv4:network():string().."/"..ipv4:prefix())

	-- Announce local ipv6 cloud
	uci:set("babeld", "local6", "filter")
	uci:set("babeld", "local6", "ignore", "false")
	uci:set("babeld", "local6", "type", "redistribute")
	uci:set("babeld", "local6", "ip", ipv6:network():string().."/"..ipv6:prefix())

	uci:save("babeld")
end

function babeld.apply()
    os.execute("killall babeld ; sleep 2 ; killall -9 babeld")
    os.execute("babeld")
end

return babeld
