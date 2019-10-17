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

	uci:foreach("wireless", "wifi-iface", function(entry)
			if entry.mode == 'mesh' or entry.mode == 'adhoc' or entry.mode == 'sta' then
				table.insert(ifaces, entry.ifname)
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
