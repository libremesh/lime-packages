#!/usr/bin/lua

local config = require("lime.config")
local network = require("lime.network")
local utils = require("lime.utils")
local libuci = require("uci")
local fs = require("nixio.fs")
local iwinfo = require("iwinfo")

wireless = {}

wireless.limeIfNamePrefix="lm_"
wireless.wifiModeSeparator="-"

function wireless.get_phy_mac(phy)
	local path = "/sys/class/ieee80211/"..phy.."/macaddress"
	local mac = assert(fs.readfile(path), "wireless.get_phy_mac(..) failed reading: "..path):gsub("\n","")
	return utils.split(mac, ":")
end

function wireless.clean()
	print("Clearing wireless config...")
	local uci = libuci:cursor()
	uci:foreach("wireless", "wifi-iface", function(s) uci:delete("wireless", s[".name"]) end)
	uci:save("wireless")
end

function wireless.scandevices()
	local devices = {}
	local uci = libuci:cursor()
	uci:foreach("wireless", "wifi-device", function(dev) devices[dev[".name"]] = dev end)
	return devices
end

function wireless.is5Ghz(radio)
	local devModes = iwinfo.nl80211.hwmodelist(radio)
	return devModes.a or devModes.ac
end

wireless.availableModes = { adhoc=true, ap=true, apname=true, ieee80211s=true }
function wireless.isMode(m)
	return wireless.availableModes[m]
end
 
function wireless.createBaseWirelessIface(radio, mode, nameSuffix, extras)
--! checks("table", "string", "?string", "?table")
--! checks(...) come from http://lua-users.org/wiki/LuaTypeChecking -> https://github.com/fab13n/checks
	nameSuffix = nameSuffix or ""
	local radioName = radio[".name"]
	local phyIndex = radioName:match("%d+")
	local ifname = "wlan"..phyIndex..wireless.wifiModeSeparator..mode..nameSuffix
	--! sanitize generated ifname for constructing uci section name
	--! because only alphanumeric and underscores are allowed
	local wirelessInterfaceName = wireless.limeIfNamePrefix..ifname:gsub("[^%w_]", "_").."_"..radioName
	local networkInterfaceName = network.limeIfNamePrefix..ifname:gsub("[^%w_]", "_")

	local uci = libuci:cursor()

	uci:set("wireless", wirelessInterfaceName, "wifi-iface")
	uci:set("wireless", wirelessInterfaceName, "mode", mode)
	uci:set("wireless", wirelessInterfaceName, "device", radioName)
	uci:set("wireless", wirelessInterfaceName, "ifname", ifname)
	uci:set("wireless", wirelessInterfaceName, "network", networkInterfaceName)

	if extras then
		for key, value in pairs(extras) do
			uci:set("wireless", wirelessInterfaceName, key, value)
		end
	end

	uci:save("wireless")

	return uci:get_all("wireless", wirelessInterfaceName)
end

function wireless.configure()
	local specificRadios = {}
	config.foreach("wifi", function(radio) specificRadios[radio[".name"]] = radio end)

	local allRadios = wireless.scandevices()
	for _,radio in pairs(allRadios) do
		local radioName = radio[".name"]
		local specRadio = specificRadios[radioName]
		local modes = config.get("wifi", "modes", {})
		local options = config.get_all("wifi")

		if specRadio then
			modes = specRadio["modes"]
			options = utils.tableMelt(options, specRadio)
		end

		--! If manual mode is used toghether with other modes it results in an
		--! unpredictable behaviour
		local freqSuffix
		local ignoredSuffix
		local distance
		local htmode
		local modeSuffix
		if modes[1] ~= "manual" then
			if wireless.is5Ghz(radioName) then
				freqSuffix = "_5ghz"
				ignoredSuffix = "_2ghz"
				distance = options["distance"..freqSuffix] or options["distance"] or 1000
				htmode = options["htmode"..freqSuffix] or options["htmode"] or "HT40"
			else
				freqSuffix = "_2ghz"
				ignoredSuffix = "_5ghz"
				distance = options["distance"..freqSuffix] or options["distance"] or 100
				htmode = options["htmode"..freqSuffix] or options["htmode"] or "HT20"
			end

			--! up to 10km links by default
			local distance = options["distance"..freqSuffix] or options["distance"] or 10000
			local htmode = options["htmode"..freqSuffix] or options["htmode"]

			--! fallback to "auto" in client mode
			local channel
			if modes[1] ~= "client" then
				channel = options["channel"..freqSuffix] or options["channel"]
				if type(channel) == "table" then
					local chanIndex = 1 + radioName:match("%d+$") % #channel
					chanIndex = chanIndex > 0 and chanIndex or 1
					channel = channel[chanIndex]
				end
			else
				channel = specRadio["channel"..freqSuffix] or specRadio["channel"] or "auto"
			end

			local uci = libuci:cursor()
			uci:set("wireless", radioName, "disabled", 0)
			uci:set("wireless", radioName, "distance", distance)
			uci:set("wireless", radioName, "noscan", 1)
			uci:set("wireless", radioName, "channel", channel)
			if options["country"] then uci:set("wireless", radioName, "country", options["country"]) end
			if htmode then uci:set("wireless", radioName, "htmode", htmode) end
			uci:save("wireless")

			for _,modeName in pairs(modes) do
				local args = {}
				modeSuffix = utils.split(modeName, "_")[2]	
				modeName = utils.split(modeName, "_")[1]	
				local mode = require("lime.mode."..modeName)

				for key,value in pairs(options) do
					local keyPrefix = utils.split(key, "_")[1]
					local isGoodOption = ( (key ~= "modes")
					                and (not key:match("^%."))
					                and (not key:match("channel"))
					                and (not key:match("country"))
					                and (not key:match("htmode"))
					                and (not (wireless.isMode(keyPrefix) and keyPrefix ~= modeName))
					                and (not key:match(ignoredSuffix)) )
					if isGoodOption then
						local nk = key:gsub("^"..modeName.."_", ""):gsub(freqSuffix.."$", "")
						if nk == "ssid" then
							value = utils.applyHostnameTemplate(value)
							value = utils.applyMacTemplate16(value, network.primary_mac())
							value = string.sub(value, 1, 32)
						end

						args[nk] = value
					end
				end

				if ( modeSuffix == nil ) or ("_"..modeSuffix == freqSuffix) then
					mode.setup_radio(radio, args)
				end

			end
		end
	end
end

return wireless
