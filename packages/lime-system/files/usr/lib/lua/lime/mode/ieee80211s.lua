#!/usr/bin/lua

local wireless = require("lime.wireless")

local ieee80211s = {}

ieee80211s.wifi_mode = "mesh"

function ieee80211s.setup_radio(radio, args)
	--!	checks("table", "?table")

	return wireless.createBaseWirelessIface(radio, ieee80211s.wifi_mode, nil, args)
end

return ieee80211s
