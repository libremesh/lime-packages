#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local utils = require("lime.utils")
local wireless = require("lime.wireless")


proto = {}

proto.configured = false

function proto.configure(args)
	if proto.configured then return end
	proto.configured = true

	local ipv4, ipv6 = network.primary_address()
	local localAS = args[2] or 64496

	local base_template = [[
router id $1;

protocol device {
	scan time 10;
}

filter toBgp {
	if net ~ $4 then {
		if proto ~ "kernelFrom*" then {
			bgp_path.prepend($2);
			bgp_path.prepend($2);
			bgp_path.prepend($2);
			bgp_path.prepend($2);
			bgp_path.prepend($2);
			bgp_path.prepend($2);
			bgp_path.prepend($2);
			bgp_path.prepend($2);
		}
		accept;
	}
	reject;
}

filter fromBgp {
	if net ~ $4 then accept;
	reject;
}

protocol kernel {
	scan time 20;
	export all;
}
]]

	for _,proto in pairs(config.get("network", "protocols")) do
		if proto:match("^lan") then
			base_template = base_template .. [[
protocol direct {
	interface "br-lan";
}
]]
		elseif proto:match("^bmx") then
			base_template = base_template .. [[
table tobmx;

protocol pipe {
	table master;
	peer table tobmx;
	import all;
	export all;
}

protocol kernel
{
	scan time 20;
	table tobmx;
	kernel table 200;
	import all;
	export all;
}

filter fromBmx {
	if ifname = "$3" then accept;
	reject;
}

protocol kernel kernelFromBmx {
	learn;
	scan time 20;
	export all;
	import filter fromBmx;
}

protocol direct {
	interface "$3";
}
]]
		end
	end
	
	local bird4_config = utils.expandVars(base_template, ipv4:host():string(), localAS, "bmxC4main", "10.0.0.0/8")
	local bird6_config = utils.expandVars(base_template, ipv6:host():string(), localAS, "bmxC6main", "2000::/3")

	local peer_template = [[
protocol bgp {
	import filter fromBgp;
	export filter toBgp;

	local as $localAS;
	neighbor $remoteIP as $remoteAS;
}
]]

	local function apply_peer_template(s)
		s.localAS = localAS
		if string.find(s.remoteIP, ":", 1, true) then
			bird6_config = bird6_config .. utils.expandVars(peer_template, s)
		elseif string.find(s.remoteIP, ".", 1, true) then
			bird4_config = bird4_config .. utils.expandVars(peer_template, s)
		end
	end
	config.foreach("bgp_peer", apply_peer_template)

	fs.writefile("/etc/bird4.conf", bird4_config)
	fs.writefile("/etc/bird6.conf", bird6_config)
end

function proto.setup_interface(ifname, args)
end

function proto.apply()
    os.execute("/etc/init.d/bird4 restart")
    os.execute("/etc/init.d/bird6 restart")
end

return proto
