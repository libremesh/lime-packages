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
	local bgpPeers = {{remoteIP="10.1.152.10", remoteAS=37922, localAS=97922}}

	local base_template = [[
router id $1;

protocol device {
        scan time 10;
}

protocol kernel {
	learn;
	scan time 20;
        export all;
}
]]

	local peer_template = [[
protocol bgp {
	import all;
	export all;

	local as $localAS;
	neighbor $remoteIP as $remoteAS;
}
]]

	for _,peer in pairs(bgpPeers) do
		base_template = base_template .. utils.expandVars(peer_template, peer)
	end

	for _,proto in pairs(config.get("network", "protocols")) do
		if proto == "lan" then
			base_template = base_template .. [[
protocol direct {
        interface "br-lan";
}
]]
			break
		end
	end

	fs.writefile("/etc/bird4.conf", utils.expandVars(base_template, ipv4:host():string()))
end

function proto.setup_interface(ifname, args)
end

function proto.apply()
    os.execute("/etc/init.d/bird4 restart")
    os.execute("/etc/init.d/bird6 restart")
end

return proto
