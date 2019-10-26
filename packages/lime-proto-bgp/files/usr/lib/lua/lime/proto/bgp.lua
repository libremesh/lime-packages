#!/usr/bin/lua

local network = require("lime.network")
local config = require("lime.config")
local fs = require("nixio.fs")
local utils = require("lime.utils")


proto = {}

proto.configured = false

function proto.configure(args)
	if proto.configured then return end
	proto.configured = true

	local ipv4, ipv6 = network.primary_address()
	local localAS = args[2] or 64496
	local bgp_exchanges = args[3]
	if bgp_exchanges then bgp_exchanges = utils.split(bgp_exchanges,",")
	else bgp_exchanges = {} end
	local meshPenalty = args[4] or 8

	local mp = "bgp_path.prepend("..localAS..");\n"
	for i=1,meshPenalty do
		mp = mp .. "\t\t\tbgp_path.prepend("..localAS..");\n"
	end

	local templateVarsIPv4 = { localIp=ipv4:host():string(),
		localAS=localAS, acceptedNet="10.0.0.0/8", meshPenalty=mp }
	local templateVarsIPv6 = { localIp=ipv6:host():string(),
		localAS=localAS, acceptedNet="2000::0/3", meshPenalty=mp }

	local base_template = [[
router id $localIp;

protocol device {
	scan time 10;
}

filter toBgp {
	if net ~ $acceptedNet then {
		if proto ~ "kernel*" then {
			$meshPenalty
		}
		accept;
	}
	reject;
}

filter fromBgp {
	if net ~ $acceptedNet then accept;
	reject;
}

protocol kernel {
	learn;
	scan time 20;
	export all;
}
]]

	for _,protocol in pairs(bgp_exchanges) do
		local protoModule = "lime.proto."..protocol
		if utils.isModuleAvailable(protoModule) then
			local proto = require(protoModule)
			local snippet = nil
			xpcall( function() snippet = proto.bgp_conf(templateVarsIPv4, templateVarsIPv6) end,
			       function(errmsg) print(errmsg) ; print(debug.traceback()) ; snippet = nil end)
			if snippet then base_template = base_template .. snippet end
		end
	end

	local bird4_config = utils.expandVars(base_template, templateVarsIPv4)
	local bird6_config = utils.expandVars(base_template, templateVarsIPv6)

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
	config.node_foreach("bgp_peer", apply_peer_template)

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
