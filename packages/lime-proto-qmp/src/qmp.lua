#!/usr/bin/lua

local bmx6 = require("lime.proto.bmx6")

qmp = {}

qmp.configured = false

function qmp.configure(args)
	if qmp.configured then return
	qmp.configured = true

	bmx6.configure(args)
end

function qmp.setup_interface(ifname, args)
	args[2] = args[2] or 12
	args[3] = args[3] or "8021q"
	args[4] = args[4] or "_qmp"

	bmx6.setup_interface(ifname, args)
end

function qmp.configure(args)
	bmx6.configure(args)
end

return qmp
