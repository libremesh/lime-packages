#!/usr/bin/lua

--! LibreMesh community mesh networks meta-firmware
--!
--! Copyright (C) 2024  Gioacchino Mazzurco <gio@polymathes.cc>
--! Copyright (C) 2024  Asociación Civil Altermundi <info@altermundi.net>
--!
--! SPDX-License-Identifier: AGPL-3.0-only

local wireless = require("lime.wireless")

local apup = {}

function apup.WIFI_MODE()
	return "ap"
end

function apup.WIFI_MODE_SUFFIX()
	return "up"
end

function apup.PEER_SUFFIX()
	return "peer"
end

function apup.setup_radio(radio, args)
--! checks("table", "?table")

	args["network"] = "lan"
	args["apup"] = "1"
	args["apup_peer_ifname_prefix"] =
		wireless.calcIfname(radio[".name"], apup.PEER_SUFFIX(), "")

	return wireless.createBaseWirelessIface(
		radio, apup.WIFI_MODE(), apup.WIFI_MODE_SUFFIX(), args )
end

--! TODO: port all modes to .WIFI_MODE()
apup.wifi_mode="ap"

return apup
