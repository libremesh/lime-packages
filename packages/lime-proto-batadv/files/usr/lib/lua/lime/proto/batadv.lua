#!/usr/bin/lua

local fs = require("nixio.fs")
local lan = require("lime.proto.lan")
local utils = require("lime.utils")
local network = require("lime.network")
local config = require("lime.config")

batadv = {}

batadv.configured = false
batadv.old_cfg_api = false
batadv.type_option = 'master'
batadv.ifc_proto = 'batadv_hardif'

function batadv.detect_old_cfg_api()
    return not fs.lstat("/lib/netifd/proto/batadv_hardif.sh")
end

function batadv.configure(args)
	if batadv.configured then return end
	batadv.configured = true

	--! Detect batman config API until 2019.0-2/OpenWrt 18.06.x
	local cfg_file = 'network'
	if batadv.detect_old_cfg_api() then
		batadv.old_cfg_api = true
		cfg_file = 'batman-adv'
		batadv.ifc_proto = 'batadv'
		batadv.type_option = 'mesh'
	end

	local uci = config.get_uci_cursor()

	if not batadv.old_cfg_api then
		uci:set(cfg_file, "bat0", "interface")
		uci:set(cfg_file, "bat0", "proto", "batadv")
	else
		uci:set(cfg_file, "bat0", "mesh")
	end

	uci:set(cfg_file, "bat0", "bridge_loop_avoidance", "1")
	uci:set(cfg_file, "bat0", "multicast_mode", "0")

	-- if anygw enabled disable DAT that doesn't play well with it
	-- and set gw_mode=client everywhere. Since there's no gw_mode=server, this makes bat0 never forward requests
	-- so a rogue DHCP server doesn't affect whole network (DHCP requests are always answered locally)
	for _,proto in pairs(config.get("network", "protocols")) do
		if proto == "anygw" then
			uci:set(cfg_file, "bat0", "distributed_arp_table", "0")
			uci:set(cfg_file, "bat0", "gw_mode", "client")
		end
	end
	uci:save(cfg_file)
	lan.setup_interface("bat0", nil)

	-- enable alfred on bat0 if installed
	if utils.is_installed("alfred") then
		uci:set("alfred", "alfred", "batmanif", "bat0")
		uci:save("alfred")
	end
end

function batadv.setup_interface(ifname, args)
	if not args["specific"] then
		if ifname:match("^wlan%d+.ap") then return end
	end

	local vlanId = args[2] or "%N1"
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_batadv"
	local mtu = 1532
	if ifname:match("^eth") then mtu = 1496 end

	--! Unless a specific integer is passed, parse network_id (%N1) template
	--! and use that number to get a vlanId between 29 and 284 for batadv
	--! (to avoid overlapping with other protocols,
	--! complex definition is for keeping retrocompatibility)
	if not tonumber(vlanId) then vlanId = 29 + (utils.applyNetTemplate10(vlanId) - 13) % 256 end

	local owrtInterfaceName, _, owrtDeviceName = network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	--! Avoid dmesg flooding caused by BLA with messages like "br-lan:
	--! received packet on bat0 with own address as source address".
	--! Randomize MAC address for each of the interfaces included in Batman-adv.
	local id = utils.get_id(ifname)
	local randomMac = network.primary_mac();
	randomMac[1] = id[1]
	randomMac[2] = id[2]
	randomMac[3] = id[3]

	local uci = config.get_uci_cursor()
	uci:set("network", owrtInterfaceName, "proto", batadv.ifc_proto)
	uci:set("network", owrtInterfaceName, batadv.type_option, "bat0")

	if ifname:match("^eth") then
		--! TODO: Use DSA to check if ethernet device is capable of bigger MTU
		--! reducing it
		mtu = 1496
		
		--! Avoid dmesg flooding caused by BLA with messages like "br-lan:
		--! received packet on bat0 with own address as source address".
		--! Tweak MAC address for each of the interfaces used by Batman-adv
		--! 00 + Locally administered unicast .. 2 bytes from interface name
		--! .. 3 bytes from main interface
		local id = utils.get_id(ifname)
		local vMacaddr = network.primary_mac();
		vMacaddr[1] = "02"
		vMacaddr[2] = id[2]
		vMacaddr[3] = id[3]
		uci:set("network", owrtDeviceName, "macaddr", table.concat(vMacaddr, ":"))
	end

	uci:set("network", owrtDeviceName, "mtu", mtu)
	uci:save("network")
end


return batadv
