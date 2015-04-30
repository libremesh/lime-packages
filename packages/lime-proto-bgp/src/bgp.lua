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
	local localAS = 97922
	local bgpPeers = {{ip="10.1.152.10", as=37922}}

	local base_template = [[
router id $1;

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
	neighbor $1 as $2;
}
]]

	for _,peer in pairs(bgpPeers) do
		base_template = base_template .. utils.expandVars(peer_template, peer)
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
