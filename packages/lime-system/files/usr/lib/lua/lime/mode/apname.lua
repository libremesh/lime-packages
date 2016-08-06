#!/usr/bin/lua

local ap = {}

ap.wifi_mode="ap"

function ap.setup_radio(radio, args)
--!	checks("table", "?table")

	return wireless.createBaseWirelessIface(radio, ap.wifi_mode, "name", { network = "lan" })
end

return ap
