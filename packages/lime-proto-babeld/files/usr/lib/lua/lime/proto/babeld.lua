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

	uci:set("babeld", "br_lan_interface", "interface") 
	uci:set("babeld", "br_lan_interface", "ifname", "br-lan")
	uci:set("babeld", "br_lan_interface", "type", "wired")

	uci:save("babeld")

  if utils.is_installed("kmod-batman-adv") then
    local dir  = "/usr/share/nftables.d/ruleset-post"
    local path = dir .. "/20-lime-babel-filter.nft"

    if not fs.stat(dir) then fs.mkdir(dir) end

    if not fs.stat(path) then
      fs.writefile(path, [[
#!/usr/sbin/nft -f
add table inet lime_babel_filter
add chain inet lime_babel_filter prevent_babel_leak_from_bat0
delete chain inet lime_babel_filter prevent_babel_leak_from_bat0

table inet lime_babel_filter {
  chain prevent_babel_leak_from_bat0 {
    type filter hook ingress device "bat0" priority 0; policy accept;

    ip6 daddr ff02::1:6   udp dport 6696 counter drop   
    ip  daddr 224.0.0.111 udp dport 6696 counter drop   

    ip6 nexthdr udp udp dport 6696 counter drop
    ip  protocol udp udp dport 6696 counter drop
  }
}
]])
    end
  end
end

function babeld.setup_interface(ifname, args)
	if not args["specific"] and ifname:match("^wlan%d+.ap") then
		utils.log("lime.proto.babeld.setup_interface(%s, ...) ignored", ifname)
		return
	end

	utils.log("lime.proto.babeld.setup_interface(%s, ...)", ifname)

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
