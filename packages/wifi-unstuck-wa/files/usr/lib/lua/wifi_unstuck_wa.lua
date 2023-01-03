local config = require "lime.config"
local utils = require "lime.utils"
local iwinfo = require "iwinfo"
local nixio = require 'nixio'
local wu = {}

-- so we always scan in at least one different frequency
wu.FREQ_2GHZ_LIST = "2412 2462"
wu.FREQ_5GHZ_LIST = "5180 5240"

function wu.get_stickable_ifaces()
	local uci = config.get_uci_cursor()
	local ifaces = {}
	local devices = {}

	uci:foreach("wireless", "wifi-iface", function(entry)
			if (entry.mode == 'mesh' or entry.mode == 'adhoc' or
				entry.mode == 'sta' or entry.mode == 'ap') then
				local device_path = uci:get("wireless", entry.device, "path")
				local device_disabled = uci:get("wireless", entry.device, "disabled")
				--! get only one interface per radio and check that the radio is not disabled
				if device_path and device_disabled == '0' and devices[device_path] == nil then
					table.insert(ifaces, entry.ifname)
					devices[device_path] = 1
				end
			end
		end)
	return ifaces
end

function wu.do_workaround()
	local ifaces = wu.get_stickable_ifaces()

	for _, iface in pairs(ifaces) do
		local cmd = "iw dev " .. iface .. " scan freq "
		local freq = iwinfo.nl80211.frequency(iface)
		if freq ~= nil then
			if freq < 3000 then
				cmd = cmd .. wu.FREQ_2GHZ_LIST
			else
				cmd = cmd .. wu.FREQ_5GHZ_LIST
			end
			utils.log(cmd)
			io.popen(cmd)
			nixio.nanosleep(1)
		end
	end
end

return wu
