#!/usr/bin/lua

local client = {}

client.wifi_mode="sta"

function client.setup_radio(radio, args)
--!	checks("table", "?table")

  args["network"] = "wan"
	return wireless.createBaseWirelessIface(radio, client.wifi_mode, nil, args)
end

return client
