#!/usr/bin/lua

local fs = require("nixio.fs")
local network = require("lime.network")
local config = require("lime.config")
local system = require("lime.system")
local utils = require("lime.utils")


anygw = {}

anygw.configured = false

anygw.SAFE_CLIENT_MTU = 1350
anygw.FQDN = {"thisnode.info", "minodo.info", "meuno.info"}

function anygw.configure(args)
	if anygw.configured then return end
	anygw.configured = true

	local cloudDomain = config.get("system", "domain")
	if not utils.has_value(anygw.FQDN, cloudDomain) then
		table.insert(anygw.FQDN, cloudDomain)
	end

	local ipv4, ipv6 = network.primary_address()
	local anygw_mac = config.get("network", "anygw_mac")
	anygw_mac = utils.applyNetTemplate16(anygw_mac)
	--! bytes 4 & 5 vary depending on %N1 and %N2 by default
	local anygw_mac_mask = "ff:ff:ff:00:00:00"
	local anygw_ipv6 = ipv6:minhost()
	local anygw_ipv4 = ipv4:minhost()
	anygw_ipv6:prefix(64) -- SLAAC only works with a /64, per RFC
	anygw_ipv4:prefix(ipv4:prefix())
	local baseIfname = "br-lan"
	local argsDev = { macaddr = anygw_mac }
	local argsIf = { proto = "static" }
	argsIf.ip6addr = anygw_ipv6:string()
	argsIf.ipaddr = anygw_ipv4:host():string()
	argsIf.netmask = anygw_ipv4:mask():string()

	local owrtInterfaceName, _, _ = network.createMacvlanIface( baseIfname,
		"anygw", argsDev, argsIf )

	local uci = config.get_uci_cursor()
	local pfr = network.limeIfNamePrefix.."anygw_"

	uci:set("network", pfr.."rule6", "rule6")
	uci:set("network", pfr.."rule6", "src", anygw_ipv6:host():string().."/128")
	uci:set("network", pfr.."rule6", "lookup", "170") -- 0xaa in decimal

	uci:set("network", pfr.."route6", "route6")
	uci:set("network", pfr.."route6", "interface", owrtInterfaceName)
	uci:set("network", pfr.."route6", "target", anygw_ipv6:network():string().."/"..anygw_ipv6:prefix())
	uci:set("network", pfr.."route6", "table", "170")

	uci:set("network", pfr.."rule4", "rule")
	uci:set("network", pfr.."rule4", "src", anygw_ipv4:host():string().."/32")
	uci:set("network", pfr.."rule4", "lookup", "170")

	uci:set("network", pfr.."route4", "route")
	uci:set("network", pfr.."route4", "interface", owrtInterfaceName)
	uci:set("network", pfr.."route4", "target", anygw_ipv4:network():string())
	uci:set("network", pfr.."route4", "netmask", anygw_ipv4:mask():string())
	uci:set("network", pfr.."route4", "table", "170")

	uci:save("network")

	uci:set("dhcp", "lan", "ignore", "1")
	uci:set("dhcp", owrtInterfaceName.."_dhcp", "dhcp")
	uci:set("dhcp", owrtInterfaceName.."_dhcp", "interface", owrtInterfaceName)
	anygw_dhcp_start = config.get("network", "anygw_dhcp_start")
	uci:set("dhcp", owrtInterfaceName.."_dhcp", "start", anygw_dhcp_start)
	anygw_dhcp_limit = config.get("network", "anygw_dhcp_limit")
	if tonumber(anygw_dhcp_limit) > 0 then
		uci:set("dhcp", owrtInterfaceName.."_dhcp", "limit", anygw_dhcp_limit)
	else
		uci:set("dhcp", owrtInterfaceName.."_dhcp", "limit", (2 ^ (32 - anygw_ipv4:prefix())) - anygw_dhcp_start - 1)
	end
	uci:set("dhcp", owrtInterfaceName.."_dhcp", "leasetime", "1h")
	uci:set("dhcp", owrtInterfaceName.."_dhcp", "force", "1")

	uci:set("dhcp", owrtInterfaceName, "tag")
	uci:set("dhcp", owrtInterfaceName, "dhcp_option", { "option:mtu,"..anygw.SAFE_CLIENT_MTU } )
	uci:set("dhcp", owrtInterfaceName, "force", "1")

	--! Avoid node hostname being resolved to anygw IP
	uci:foreach("dhcp", "dnsmasq",
		function(s)
			uci:set("dhcp", s[".name"], "add_local_fqdn", "0")
			uci:set("dhcp", s[".name"], "add_local_hostname", "0")
		end
	)

	--! Now define host records with proper node IPs
	local hostname = system.get_hostname()
	uci:set("dhcp", "node_name_dns", "hostrecord")
	uci:set("dhcp", "node_name_dns", "name", {hostname, hostname.."."..cloudDomain})
	uci:set("dhcp", "node_name_dns", "ip", ipv4:host():string() .. "," .. ipv6:host():string())

	--! Use host-record to declare own DNS entries (and not dnsmasq address as
	--! it wildcards subdomains)
	uci:set("dhcp", "anygw_dns", "hostrecord")
	uci:set("dhcp", "anygw_dns", "name", {"anygw", unpack(anygw.FQDN)})
	uci:set("dhcp", "anygw_dns", "ip", ipv4:host():string() .. "," .. ipv6:host():string())

	uci:save("dhcp")

	local content = { }
	table.insert(content, "enable-ra")
	table.insert(content, "ra-param=anygw,mtu:"..anygw.SAFE_CLIENT_MTU..",120")
	table.insert(content, "dhcp-range=tag:anygw,"..ipv6:network():string()..",ra-names,24h")
	table.insert(content, "dhcp-option=tag:anygw,option6:domain-search,"..cloudDomain)
	fs.writefile("/etc/dnsmasq.d/lime-proto-anygw-20-ipv6.conf", table.concat(content, "\n").."\n")

	utils.unsafe_shell("/etc/init.d/dnsmasq enable || true")
	utils.unsafe_shell("/etc/init.d/lime-anygw-ebtables enable || true")
end

function anygw.setup_interface(ifname, args) end

function anygw.bgp_conf(templateVarsIPv4, templateVarsIPv6)
	local base_conf = [[
protocol direct {
	interface "anygw";
}
]]
	return base_conf
end

return anygw
