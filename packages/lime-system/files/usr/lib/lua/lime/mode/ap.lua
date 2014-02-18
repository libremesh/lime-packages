#!/usr/bin/lua

local ap = {}

ap.modename="ap"

function ap.setup_radio(radio, args)
--!	checks("table", "?table")

	local extras = { network = "lan" }
	local wifi_iface = wireless.createBaseWirelessIface(radio, ap.wifi_mode, extras)
end

return ap
