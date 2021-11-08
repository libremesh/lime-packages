#!/usr/bin/lua

local config = require("lime.config")
local network = require("lime.network")
local utils = require("lime.utils")
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
	utils.log("Clearing wireless config...")
	local uci = config.get_uci_cursor()
	uci:foreach("wireless", "wifi-iface", function(s) uci:delete("wireless", s[".name"]) end)
	uci:save("wireless")
end

function wireless.scandevices()
	local devices = {}
	local uci = config.get_uci_cursor()
	uci:foreach("wireless", "wifi-device", function(dev) devices[dev[".name"]] = dev end)

	local sorted_devices = {}
	for _, dev in pairs(devices) do
		table.insert(sorted_devices, utils.indexFromName(dev[".name"])+1, dev)
	end

	local band_2ghz_index = 0
	local band_5ghz_index = 0

	for _, dev in pairs(sorted_devices) do
		if wireless.is5Ghz(dev[".name"]) then
			dev.per_band_index = band_5ghz_index
			band_5ghz_index = band_5ghz_index + 1
		else
			dev.per_band_index = band_2ghz_index
			band_2ghz_index = band_2ghz_index + 1
		end
	end
	return devices
end

function wireless.is5Ghz(radio)
	local devModes = iwinfo.nl80211.hwmodelist(radio)
	return devModes.a or devModes.ac
end

wireless.availableModes = { adhoc=true, ap=true, apname=true, apbb=true, ieee80211s=true }
function wireless.isMode(m)
	return wireless.availableModes[m]
end

function wireless.mesh_ifaces()
	local uci = config.get_uci_cursor()
	local ifaces = {}

	uci:foreach("wireless", "wifi-iface", function(entry)
			if entry.disabled ~= '1' and (entry.mode == 'mesh' or entry.mode == 'adhoc') then
				table.insert(ifaces, entry.ifname)
			end
		end)
	return ifaces
end

function wireless.createBaseWirelessIface(radio, mode, nameSuffix, extras)
--! checks("table", "string", "?string", "?table")
--! checks(...) come from http://lua-users.org/wiki/LuaTypeChecking -> https://github.com/fab13n/checks
	nameSuffix = nameSuffix or ""
	local radioName = radio[".name"]
	local phyIndex = tostring(utils.indexFromName(radioName))
	local ifname = "wlan"..phyIndex..wireless.wifiModeSeparator..mode..nameSuffix
	--! sanitize generated ifname for constructing uci section name
	--! because only alphanumeric and underscores are allowed
	local wirelessInterfaceName = wireless.limeIfNamePrefix..ifname:gsub("[^%w_]", "_").."_"..radioName
	local networkInterfaceName = network.limeIfNamePrefix..ifname:gsub("[^%w_]", "_")

	local uci = config.get_uci_cursor()

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

function wireless.resolve_ssid(ssid)
	local result = utils.applyHostnameTemplate(ssid)
	result = utils.applyMacTemplate16(result, network.primary_mac())
	result = string.sub(result, 1, 32)
	return result
end

function wireless.configure()
	local specificRadios = {}
	config.foreach("wifi", function(radio)
		specificRadios[radio[".name"]] = radio
	end)

	local allRadios = wireless.scandevices()
	for _,radio in pairs(allRadios) do
		local radioName = radio[".name"]
		local radioBand = wireless.is5Ghz(radioName) and '5ghz' or '2ghz'
		local radioOptions = specificRadios[radioName] or {}
		local bandOptions = config.get_all(radioBand) or {}
		local options = config.get_all("wifi")
		
		options = utils.tableMelt(options, bandOptions)
		options = utils.tableMelt(options, radioOptions)

		--! If manual mode is used toghether with other modes it results in an
		--! unpredictable behaviour
		if options["modes"][1] ~= "manual" then
			--! fallback to "auto" in client mode
			local channel
			if options["modes"][1] ~= "client" then
				channel = options["channel"]
				if type(channel) == "table" then
					channel = channel[1 + radio.per_band_index % #channel]
				end
			else
				channel = options["channel"] or "auto"
			end

			local uci = config.get_uci_cursor()
			uci:set("wireless", radioName, "disabled", 0)
			uci:set("wireless", radioName, "distance", options["distance"])
			uci:set("wireless", radioName, "noscan", 1)
			uci:set("wireless", radioName, "channel", channel)
			if options["country"] then uci:set("wireless", radioName, "country", options["country"]) end
			if options["legacy_rates"] and not wireless.is5Ghz(radioName) then uci:set("wireless", radioName, "legacy_rates", options["legacy_rates"]) end
			if options["txpower"] then uci:set("wireless", radioName, "txpower", options["txpower"]) end
			if options["htmode"] then uci:set("wireless", radioName, "htmode", options["htmode"]) end
			uci:save("wireless")

			for _,modeName in pairs(options["modes"]) do
				local args = {}
				local mode = require("lime.mode."..modeName)

				-- gather mode specific configs (eg ieee80211s_mcast_rate_5ghz)
				for key,value in pairs(options) do
					local keyPrefix = utils.split(key, "_")[1]
					local isGoodOption = ( (key ~= "modes")
					                and (not key:match("^%."))
					                and (not key:match("channel"))
					                and (not key:match("country"))
					                and (not key:match("legacy_rates"))
					                and (not key:match("txpower"))
					                and (not key:match("htmode"))
					                and (not (wireless.isMode(keyPrefix) and keyPrefix ~= modeName)))
					if isGoodOption then
						local nk = key:gsub("^"..modeName.."_", "")
						if nk == "ssid" then
							value = wireless.resolve_ssid(value)
						end
						args[nk] = value
					end
				end

				mode.setup_radio(radio, args)
			end
		end
	end
end

function wireless.get_band_config(band)
	local general_cfg = config.get_all("wifi") or {}
	local band_cfg = config.get_all(band) or {}
	local result = general_cfg
	utils.tableMelt(result, band_cfg)
	return result
end

function wireless.get_community_band_config(band)
	local uci = config.get_uci_cursor()
	local default_general_cfg = uci:get_all(config.UCI_DEFAULTS_NAME, "wifi") or {}
	local default_band_cfg = uci:get_all(config.UCI_DEFAULTS_NAME, band) or {}
	local community_general_cfg = uci:get_all(config.UCI_COMMUNITY_NAME, "wifi") or {}
	local community_band_cfg = uci:get_all(config.UCI_COMMUNITY_NAME, band) or {}
	local result = default_general_cfg
	utils.tableMelt(result, default_band_cfg)
	utils.tableMelt(result, community_general_cfg)
	utils.tableMelt(result, community_band_cfg)
	return result
end

function wireless.add_band_mode(band, mode_name)
	local uci = config.get_uci_cursor()
	local cfg = wireless.get_band_config(band)
	if not utils.has_value(cfg.modes, mode_name) then
		local modes = uci:get(config.UCI_NODE_NAME, band, 'modes')
		if not modes or modes[1] == 'manual' then
			modes = { mode_name }
		else
			table.insert(modes, mode_name)
		end
		uci:set(config.UCI_NODE_NAME, band, 'lime-wifi-band')
		uci:set(config.UCI_NODE_NAME, band, 'modes', modes)
		uci:commit(config.UCI_NODE_NAME)
		utils.unsafe_shell('lime-config')
	end
end

function wireless.remove_band_mode(band, mode_name)
	local uci = config.get_uci_cursor()
	local cfg = wireless.get_band_config(band)
	if utils.has_value(cfg.modes, mode_name) then
		local new_modes = {}
		for _, mode in pairs(cfg.modes) do
			if mode ~= mode_name then
				table.insert(new_modes, mode)
			end
		end
		if utils.tableLength(new_modes) == 0 then
			new_modes = {'manual'}
		end
		uci:set(config.UCI_NODE_NAME, band, 'lime-wifi-band')
		uci:set(config.UCI_NODE_NAME, band, 'modes', new_modes)
		uci:commit(config.UCI_NODE_NAME)
		utils.unsafe_shell('lime-config')
	end
end

function wireless.set_band_config(band, cfg)
	local uci = config.get_uci_cursor()
	uci:set(config.UCI_NODE_NAME, band, 'lime-wifi-band')
	for key, value in pairs(cfg) do
		uci:set(config.UCI_NODE_NAME, band, key, value)
	end
	uci:commit(config.UCI_NODE_NAME)
	utils.unsafe_shell('lime-config')
end

return wireless
