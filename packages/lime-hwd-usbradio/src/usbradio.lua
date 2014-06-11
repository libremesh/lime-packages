#!/usr/bin/lua

local utils = require("lime.utils")
local libuci = require("uci")
local fs = require("nixio.fs")

usbradio = {}

function usbradio.clean()
	local uci = libuci:cursor()

	local function test_and_clean_device(s)
		if s["path"]:match("usb") then
			local phyIndex = (s[".name"]):match("%d$")
			local _, numberOfMatches = fs.glob("/sys/devices/"..s["path"].."/ieee80211/phy"..phyIndex)
			if numberOfMatches < 1 then uci:delete("wireless", s[".name"]) end
		end
	end

	uci:foreach("wireless", "wifi-device", test_and_clean_device)
	uci:save("wireless")
end

function usbradio.detect_hardware()
	local stdOutput = io.popen("find /sys/devices | grep usb | grep ieee80211 | grep 'phy[0-9]*$'")

	for _,path in pairs(utils.split(stdOutput:read("*a"), "\n")) do
		local endBasePath, phyEnd = string.find(path, "/ieee80211/phy")
		local phyPath = string.sub(path, 14, endBasePath-1)
		local phyIndex = string.sub(path, phyEnd+1)
		local radioName = "radio"..phyIndex

		local uci = libuci:cursor()

		uci:delete("wireless", radioName)
		uci:set("wireless", radioName, "wifi-device")
		uci:set("wireless", radioName, "type", "mac80211")
		uci:set("wireless", radioName, "channel", "11") --TODO: working on all 802.11bgn devices; find a general way for working in different devices
		uci:set("wireless", radioName, "hwmode", "11ng") --TODO: working on all 802.11gn devices; find a general way for working in different devices
		uci:set("wireless", radioName, "path", phyPath)
		uci:set("wireless", radioName, "htmode", "HT20")
		uci:set("wireless", radioName, "disabled", "0")
		uci:set("wireless", radioName, "ht_capab", { "LDPC", "SHORT-GI-20", "SHORT-GI-40", "TX-STBC", "RX-STBC1", "DSSS_CCK-40" }) --TODO: capabilities working on TP-WN722N; find a general way to detect capabilities on different usb devices

		uci:save("wireless")
	end
end

if hotplug_hook_args then
	usbradio.clean()
	usbradio.detect_hardware()
end

return usbradio
