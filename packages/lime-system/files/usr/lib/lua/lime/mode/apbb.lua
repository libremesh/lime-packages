#!/usr/bin/lua

local apbb = {}

apbb.wifi_mode="ap"

function apbb.setup_radio(radio, args)
--!	checks("table", "?table")

	return wireless.createBaseWirelessIface(radio, apbb.wifi_mode, "bb", args)
end

return apbb
