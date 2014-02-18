#!/usr/bin/lua

local config = require("lime.config")
local network = require("lime.network")

wireless = {}

wireless.limeIfNamePrefix="lm_"

function wireless.generate_ssid()
	local m4, m5, m6 = node_id()
	return string.format("%02x%02x%02x.lime", m4, m5, m6)
end

function wireless.clean()
	print("Clearing wireless config...")
	uci:foreach("wireless", "wifi-iface", function(s) uci:delete("wireless", s[".name"]) end)
end

function wireless.scandevices()
	local devices = {}
	uci:foreach("wireless", "wifi-device", function(dev) devices[dev[".name"]] = dev end)
	return devices
end

function wireless.is5Ghz(radio)
	local hwmode = uci:get("wireless", radio, "hwmode") or "11ng"
	if hwmode:find("a") then
		return true
	end
	return false
end

wireless.availableModes = { adhoc=true, ap=true }
function wireless.isMode(m)
	return wireless.availableModes[m]
end

function wireless.configure()

	wireless.clean()

	local specificRadios = {}
	config.foreach("wifi", function(radio) specificRadios[radio[".name"]] = radio end)

	local allRadios = wireless.scandevices()
	for _,radio in pairs(allRadios) do
		local radioName = radio[".name"] 
		local phyIndex = radioName:match("%d+")
		local freqSuffix = "_2ghz"; if wireless.is5Ghz(radioName) then freqSuffix = "_5ghz" end
		local modes = config.get("wifi", "modes")
		local options = config.get_all("wifi")

		local specRadio = specificRadios[radioName]
		if specRadio then
			modes = specRadio['modes']
			options = specRadio
		end

		uci:set("wireless", radioName, "disabled", 0)

		for _,mode in pairs(modes) do
			if mode == "manual" then break end
			
			local ifname = "wlan"..phyIndex.."_"..mode
			local wirelessInterfaceName = wireless.limeIfNamePrefix..ifname.."_"..radioName
			local networkInterfaceName = network.limeIfNamePrefix..ifname
			if mode == "ap" then networkInterfaceName = "lan" end

			uci:set("wireless", wirelessInterfaceName, "wifi-iface")
			uci:set("wireless", wirelessInterfaceName, "mode", mode)
			uci:set("wireless", wirelessInterfaceName, "device", radioName)
			uci:set("wireless", wirelessInterfaceName, "network", networkInterfaceName)
			uci:set("wireless", wirelessInterfaceName, "ifname", ifname)

			for key,value in pairs(options) do
				local keyPrefix = utils.split(key, "_")[1]
				local isGoodOption = ( (key ~= "modes") and (not key:match("^%.")) and (not key:match("channel")) and (not (wireless.isMode(keyPrefix) and keyPrefix ~= mode)) )
				if isGoodOption then
					local nk = key:gsub("^"..mode.."_", ""):gsub(freqSuffix.."$", "")
					uci:set("wireless", wirelessInterfaceName, nk, value)
				end
			end
		end
	end

	uci:save("wireless")
end

return wireless
