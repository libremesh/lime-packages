#!/usr/bin/lua

local ap = {}

ap.modename="ap"

function ap.setup_radio(radio, args)
--!	checks("table", "?table")

	wireless.createBaseWirelessIface(radio, ap.wifi_mode, { network = "lan" })
end

return ap
