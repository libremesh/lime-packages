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
	local uci = libuci:cursor()
	if #args > 1 then
		local ipaddr = args[2]
		-- workaround to support ipv6
		for i,v in ipairs(args) do if i > 2 then ipaddr=ipaddr..':'..v end end
		network.createStaticIface(ifname, '_static', ipaddr)
	end
end

return static
