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

	-- Avoid redistributing extra local addesses
	uci:set("babeld", "localdeny", "filter")
	uci:set("babeld", "localdeny", "type", "redistribute")
	uci:set("babeld", "localdeny", "local", "true")
	uci:set("babeld", "localdeny", "action", "deny")

	-- Avoid redistributing enything else
	uci:set("babeld", "denyany", "filter")
	uci:set("babeld", "denyany", "type", "redistribute")
	uci:set("babeld", "denyany", "action", "deny")

	uci:set("babeld", "br_lan_interface", "interface") 
	uci:set("babeld", "br_lan_interface", "ifname", "br-lan")
	uci:set("babeld", "br_lan_interface", "type", "wired")

	uci:save("babeld")

	if utils.is_installed("kmod-batman-adv") then
		if not fs.stat("/etc/nft-lime") then fs.mkdir("/etc/nft-lime") end
		if not fs.stat("/etc/nft-lime/20-lime-babel-filter.nft") then
			fs.writefile("/etc/nft-lime/20-lime-babel-filter.nft", [[
table netdev lime_babel_filter {
  chain prevent_babel_leak_from_bat0 {
    type filter hook ingress device "bat0" priority 0; policy accept;
    ether daddr 33:33:00:00:01:06 counter drop
    ether daddr 01:00:5e:00:00:6f counter drop
    ip6 nexthdr udp udp dport 6696 counter drop
    ip  protocol udp udp dport 6696 counter drop
  }
}
]])

			uci:set("firewall", "lime_babel_filter_include", "include")
			uci:set("firewall", "lime_babel_filter_include", "path", "/etc/nft-lime/20-lime-babel-filter.nft")
			uci:set("firewall", "lime_babel_filter_include", "type", "nftables")
			uci:set("firewall", "lime_babel_filter_include", "position", "ruleset-post")
			uci:set("firewall", "lime_babel_filter_include", "enabled", "1")

			uci:save("firewall")
		end
	end
end

function babeld.setup_interface(ifname, args)
	if not args["specific"] and ifname:match("^wlan%d+.ap") then
		utils.log("lime.proto.babeld.setup_interface(%s, ...) ignored", ifname)
		return
	end

	utils.log("lime.proto.babeld.setup_interface(%s, ...)", ifname)

	local owrtInterfaceName, linuxVlanIfName, owrtDeviceName =
	  network.createVlanIface(ifname, vlanId, nameSuffix, vlanProto) --revisar

	local ipv4, _ = network.primary_address()

	local uci = config.get_uci_cursor()

  local section_name = "babeld_" .. ifname:gsub("[.-]", "_")

  uci:set("babeld", section_name, "interface")
  uci:set("babeld", section_name, "ifname", ifname)

  if ifname:match("^wlan") then
      uci:set("babeld", section_name, "type", "wireless")
  else
      uci:set("babeld", section_name, "type", "wired")
  end

	uci:save("babeld")
end

function babeld.runOnDevice(linuxDev, args)
	utils.log("lime.proto.babeld.runOnDevice(%s, ...)", linuxDev)
	local libubus = require("ubus")
	local ubus = libubus.connect()
	ubus:call('babeld', 'add_interface', { ifname = linuxDev })
end
return babeld
