#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")
local config = require("lime.config")

static = {}

static.configured = false

function static.configure(args)
	if static.configured then return end
	static.configured = true
end

function static.setup_interface(ifname, args)
	if not args["specific"] then return end
	-- kept for back compatibility
	if #args > 1 then
		local ipaddr = args[2]
		network.createStaticIface(ifname, '_static', ipaddr)
	end
	local table = args._specific_section
	local ipAddrIPv4 = table["static_ipv4"]
	if ipAddrIPv4 then
		local gwAddrIPv4 = table["static_gateway_ipv4"]
		network.createStaticIface(ifname, '_static', ipAddrIPv4, gwAddrIPv4)
	end
	local ipAddrIPv6 = table["static_ipv6"]
	if ipAddrIPv6 then
		local gwAddrIPv6 = table["static_gateway_ipv6"]
		network.createStaticIface(ifname, '_static', ipAddrIPv6, gwAddrIPv6)
	end
end

return static
