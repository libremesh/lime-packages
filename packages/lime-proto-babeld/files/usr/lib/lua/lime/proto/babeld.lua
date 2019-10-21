#!/usr/bin/lua

--! LiMe Proto Babeld
--! Copyright (C) 2018  Gioacchino Mazzurco <gio@altermundi.net>
--!
--! This program is free software: you can redistribute it and/or modify
--! it under the terms of the GNU Affero General Public License as
--! published by the Free Software Foundation, either version 3 of the
--! License, or (at your option) any later version.
--!
--! This program is distributed in the hope that it will be useful,
--! but WITHOUT ANY WARRANTY; without even the implied warranty of
--! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--! GNU Affero General Public License for more details.
--!
--! You should have received a copy of the GNU Affero General Public License
--! along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

	-- Avoid redistributing extra local addesses
	uci:set("babeld", "localdeny", "filter")
	uci:set("babeld", "localdeny", "type", "redistribute")
	uci:set("babeld", "localdeny", "local", "true")
	uci:set("babeld", "localdeny", "action", "deny")

	-- Avoid redistributing enything else
	uci:set("babeld", "dany", "filter")
	uci:set("babeld", "dany", "type", "redistribute")
	uci:set("babeld", "dany", "action", "deny")

	uci:save("babeld")


	uci:set("libremap", "babeld", "plugin")
	uci:set("libremap", "babeld", "enabled", "true")

	uci:save("libremap")

	--! If Babeld's Hello packets run over Batman-adv (whose bat0 is also
	--! included in br-lan), all the Babeld nodes would appear as being direct
	--! neighbors, so these Hello packets on bat0 have to be filtered
	if utils.is_installed("kmod-batman-adv") then
		fs.mkdir("/etc/firewall.lime.d")
		fs.writefile("/etc/firewall.lime.d/21-babeld-not-over-bat0-ebtables",
		  "ebtables -t nat -A POSTROUTING -o bat0 -p ipv6"..
		  " --ip6-proto udp --ip6-sport 6696 --ip6-dport 6696 -j DROP\n")
	else
		fs.remove("/etc/firewall.lime.d/21-babeld-not-over-bat0-ebtables")
	end
end

function babeld.setup_interface(ifname, args)
	if not args["specific"] and ifname:match("^wlan%d+.ap") then
		utils.log("lime.proto.babeld.setup_interface(...)", ifname, "ignored")
		return
	end

	utils.log("lime.proto.babeld.setup_interface(...)", ifname)

	local vlanId = tonumber(args[2]) or 17
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_babeld"


	--! If Babeld is without VLAN (vlanId is 0) it should run directly on plain
	--! ethernet interfaces, but the ones which are inside of the LAN bridge
	--! (e.g. eth0 or eth0.1) cannot have an IPv6 Link-Local and Babeld needs it.
	--! So Babeld has to run on the bridge interface br-lan
	local isIntoLAN = false
	local addIPtoIf = true
	for _,v in pairs(args["deviceProtos"]) do
		if v == "lan" then
			isIntoLAN = true
		--! would be weird to add a static IP to the WAN interface
		elseif v == "wan" then
			addIPtoIf = false
		end
	end

	if ifname:match("^wlan") then
		--! currently (2019-10-12) mode-ap and mode-apname have an hardcoded
		--! "option network lan" so they are always in the br-lan bridge
		if ifname:match("^wlan.*ap$") or ifname:match("^wlan.*apname$") then
			isIntoLAN = true

		--! all the WLAN interfaces are ignored by proto-lan
		--! so they are not in the bridge even if proto-lan is present
		--! (except mode-ap and mode-apname as mentioned above)
		else
			isIntoLAN = false
		end
	end

	if vlanId == 0 and isIntoLAN then
		utils.log("Rather than "..ifname..
		  ", adding br-lan into Babeld interfaces")
		ifname = "br-lan"
		--! br-lan has already an IPv4, no need to add it
		addIPtoIf = false
	end

	local owrtInterfaceName, linuxVlanIfName, owrtDeviceName =
	  network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local uci = config.get_uci_cursor()

	if(vlanId ~= 0 and ifname:match("^eth")) then
		uci:set("network", owrtDeviceName, "mtu", tostring(network.MTU_ETH_WITH_VLAN))
	end

	if addIPtoIf then
		local ipv4, _ = network.primary_address()
		--! the "else" way should always work but it fails in a weird way
		--! with some wireless interfaces without VLAN
		--! (e.g. works with wlan0-mesh and fails with wlan1-mesh)
		--! so for these cases, the first way is used
		--! (which indeed fails for most of the other cases)
		if ifname:match("^wlan") and tonumber(vlanId) == 0 then
			uci:set("network", owrtInterfaceName, "ifname", "@"..owrtDeviceName)
		else
			uci:set("network", owrtInterfaceName, "ifname", linuxVlanIfName)
		end
		uci:set("network", owrtInterfaceName, "proto", "static")
		uci:set("network", owrtInterfaceName, "ipaddr", ipv4:host():string())
		uci:set("network", owrtInterfaceName, "netmask", "255.255.255.255")
		uci:save("network")
	end

	uci:set("babeld", owrtInterfaceName, "interface")
	uci:set("babeld", owrtInterfaceName, "ifname", linuxVlanIfName)
	--! It is quite common to have dummy radio device attached via ethernet so
	--! disable wired optimization always as it would consider the link down at
	--! first packet lost
	uci:set("babeld", owrtInterfaceName, "wired", "false")

	uci:save("babeld")
end

return babeld
