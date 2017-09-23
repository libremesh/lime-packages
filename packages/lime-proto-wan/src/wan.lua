#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")
local utils = require("lime.utils")

wan = {}

wan.configured = false

function wan.configure(args)
	if wan.configured then return end
	wan.configured = true

	local uci = libuci:cursor()
	uci:set("network", "wan", "interface")
	uci:set("network", "wan", "proto", "dhcp")
	uci:save("network")
end

function wan.setup_interface(ifname, args)
	local uci = libuci:cursor()
	uci:set("network", "wan", "ifname", ifname)
	uci:save("network")

	if utils.is_installed('firewall') then
		fs.remove("/etc/firewall.lime.d/20-wan-out-masquerade")
	else
		fs.mkdir("/etc/firewall.lime.d")
		fs.writefile(
			"/etc/firewall.lime.d/20-wan-out-masquerade",
			"iptables -t nat -D POSTROUTING -o " .. ifname .. " -j MASQUERADE\n" ..
			"iptables -t nat -A POSTROUTING -o " .. ifname .. " -j MASQUERADE\n"
		)
	end

	if utils.is_installed('firewall') then
		fs.mkdir("/etc/firewall.lime.d")
		fs.writefile(
			"/etc/firewall.lime.d/20-allow-all-fe80-traffic-over-wan",
			"# These will do nothing if fw3 is not running, since *put_wan_rule will not exist\n" ..
			"ip6tables -D input_wan_rule  -j ACCEPT -p all -s fe80::/10 -m comment --comment 'Allow all link-local traffic over WAN'\n" ..
			"ip6tables -A input_wan_rule  -j ACCEPT -p all -s fe80::/10 -m comment --comment 'Allow all link-local traffic over WAN'\n" ..
			"ip6tables -D output_wan_rule -j ACCEPT -p all -s fe80::/10 -m comment --comment 'Allow all link-local traffic over WAN'\n" ..
			"ip6tables -A output_wan_rule -j ACCEPT -p all -s fe80::/10 -m comment --comment 'Allow all link-local traffic over WAN'\n"
		)
	else
		fs.remove("/etc/firewall.lime.d/20-allow-all-fe80-traffic-over-wan")
	end

end

return wan
