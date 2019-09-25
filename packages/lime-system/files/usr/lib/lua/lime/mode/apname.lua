#!/usr/bin/lua

local apname = {}

apname.wifi_mode="ap"

function apname.setup_radio(radio, args)
--!	checks("table", "?table")

	args["network"] = "lan"
	return wireless.createBaseWirelessIface(radio, apname.wifi_mode, "name", args)
end

return apname
