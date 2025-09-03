#!/usr/bin/lua
--! SPDX-License-Identifier: AGPL-3.0-or-later
--! 
--! Copyright (C) 2018  Gioacchino Mazzurco <gio@altermundi.net>

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")

babeld = {}

babeld.configured = false

function babeld.configure(args)
	if babeld.configured then return end
	babeld.configured = true

	utils.log("lime.proto.babeld.configure(...)")

	fs.writefile("/etc/config/babeld", "")

	local uci = config.get_uci_cursor()

	if config.get("network", "babeld_over_librenet6", false) then
		uci:set("babeld", "librenet6", "interface")
		uci:set("babeld", "librenet6", "ifname", "librenet6")
		uci:set("babeld", "librenet6", "type", "tunnel")
	end

	uci:set("babeld", "general", "general")
	uci:set("babeld", "general", "local_port", "30003")
	uci:set("babeld", "general", "ubus_bindings", "true")

	uci:set("babeld", "ula6", "filter")
	uci:set("babeld", "ula6", "type", "redistribute")
	uci:set("babeld", "ula6", "ip", "fc00::/7")
	uci:set("babeld", "ula6", "action", "allow")

	uci:set("babeld", "public6", "filter")
	uci:set("babeld", "public6", "type", "redistribute")
	uci:set("babeld", "public6", "ip", "2000::0/3")
	uci:set("babeld", "public6", "action", "allow")

	uci:set("babeld", "default6", "filter")
	uci:set("babeld", "default6", "type", "redistribute")
	uci:set("babeld", "default6", "ip", "0::0/0")
	uci:set("babeld", "default6", "le", "0")
	uci:set("babeld", "default6", "action", "allow")

	uci:set("babeld", "mesh4", "filter")
	uci:set("babeld", "mesh4", "type", "redistribute")
	uci:set("babeld", "mesh4", "ip", "10.0.0.0/8")
	uci:set("babeld", "mesh4", "action", "allow")

	uci:set("babeld", "mptp4", "filter")
	uci:set("babeld", "mptp4", "type", "redistribute")
	uci:set("babeld", "mptp4", "ip", "172.16.0.0/12")
	uci:set("babeld", "mptp4", "action", "allow")

	uci:set("babeld", "default4", "filter")
	uci:set("babeld", "default4", "type", "redistribute")
	uci:set("babeld", "default4", "ip", "0.0.0.0/0")
	uci:set("babeld", "default4", "le", "0")
	uci:set("babeld", "default4", "action", "allow")

	--! Avoid redistributing extra local addesses
	uci:set("babeld", "localdeny", "filter")
	uci:set("babeld", "localdeny", "type", "redistribute")
	uci:set("babeld", "localdeny", "local", "true")
	uci:set("babeld", "localdeny", "action", "deny")

	--! Avoid redistributing enything else
	uci:set("babeld", "denyany", "filter")
	uci:set("babeld", "denyany", "type", "redistribute")
	uci:set("babeld", "denyany", "action", "deny")

	uci:save("babeld")

end

function babeld.setup_interface(ifname, args)
	if not args["specific"] and ifname:match("^wlan%d+.ap") then
		utils.log("lime.proto.babeld.setup_interface(%s, ...) ignored", ifname)
		return
	end

	utils.log("lime.proto.babeld.setup_interface(%s, ...)", ifname)

	local vlanId = args[2] or 17
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_babeld"

	local owrtInterfaceName, linuxVlanIfName, owrtDeviceName =
	  network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local ipv4, _ = network.primary_address()

	local uci = config.get_uci_cursor()

	if(vlanId ~= 0 and (ifname:match("^eth") or ifname:match("^lan"))) then
		uci:set("network", owrtDeviceName, "mtu", tostring(network.MTU_ETH_WITH_VLAN))
	end

	uci:set("network", owrtInterfaceName, "proto", "static")
	uci:set("network", owrtInterfaceName, "ipaddr", ipv4:host():string())
	uci:set("network", owrtInterfaceName, "netmask", "255.255.255.255")
	uci:save("network")

	uci:set("babeld", owrtInterfaceName, "interface")
	uci:set("babeld", owrtInterfaceName, "ifname", linuxVlanIfName)
	--! It is quite common to have dummy radio device attached via ethernet so
	--! disable wired optimization always as it would consider the link down at
	--! first packet lost
	uci:set("babeld", owrtInterfaceName, "type", "wireless")

	uci:save("babeld")
end

function babeld.runOnDevice(linuxDev, args)
	utils.log("lime.proto.babeld.runOnDevice(%s, ...)", linuxDev)

	local vlanId = args[2] or 17
	local vlanProto = args[3] or "8021ad"

	local vlanDev = network.createVlan(linuxDev, vlanId, vlanProto)
	network.createStatic(vlanDev)

	local libubus = require("ubus")
	local ubus = libubus.connect()
	ubus:call('babeld', 'add_interface', { ifname = vlanDev })
end

return babeld
