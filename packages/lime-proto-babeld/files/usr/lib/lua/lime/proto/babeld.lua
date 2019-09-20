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

	print("lime.proto.babeld.configure(...)")

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

end

function babeld.setup_interface(ifname, args)
	if not args["specific"] and ifname:match("^wlan%d+.ap") then
		print("lime.proto.babeld.setup_interface(...)", ifname, "ignored")
		return
	end

	print("lime.proto.babeld.setup_interface(...)", ifname)

	local vlanId = args[2] or 17
	local vlanProto = args[3] or "8021ad"
	local nameSuffix = args[4] or "_babeld"

	local addIPtoIf = true

	--! If Babeld is without VLAN (vlanId is 0) it cannot run directly
	--! on ethernet interfaces which are inside of a bridge (e.g. eth0 or eth0.1)
	--! because they cannot have an IPv6 Link-Local, so Babeld has to run on 
	--! the bridge interface br-lan
	--! If Babeld's Hello packets run over Batman-adv (whose bat0 is also 
	--! included in br-lan), the links will have a wrong quality metric,
	--! so these hello on bat0 have to be filtered
	if tonumber(vlanId) == 0 then
		local hasBatman = false
		local babeldOverBatman = config.get_bool("network", "babeld_over_batman")
		local hasLan = false
		for _,protoArgs in pairs(config.get("network", "protocols")) do
			local proto =  utils.split(protoArgs, network.protoParamsSeparator)[1]
			if(proto == "lan") then hasLan = true
			elseif(proto == "batadv") then hasBatman = true end
		end
	
		if hasLan and ifname:match("^eth%d") then
			ifname = "br-lan"
			addIPtoIf = false
			if hasBatman and not babeldOverBatman then
				ifname = "br-lan"
				fs.mkdir("/etc/firewall.lime.d")
				fs.writefile("/etc/firewall.lime.d/21-babeld-not-over-bat0-ebtables",
					"ebtables -t nat -A POSTROUTING -o bat0 -p ipv6"..
					" --ip6-proto udp --ip6-sport 6696 --ip6-dport 6696 -j DROP\n")
			else
				fs.remove("/etc/firewall.lime.d/21-babeld-not-over-bat0-ebtables")
			end
		end
	end

	local owrtInterfaceName, linuxVlanIfName, owrtDeviceName =
	  network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto)

	local uci = config.get_uci_cursor()

	if addIPtoIf then
		local ipv4, _ = network.primary_address()
	
		uci:set("network", owrtInterfaceName, "ifname", "@"..owrtDeviceName)
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
