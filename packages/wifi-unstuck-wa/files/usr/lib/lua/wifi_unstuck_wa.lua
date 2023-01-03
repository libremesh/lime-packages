local config = require "lime.config"
local utils = require "lime.utils"
local iwinfo = require "iwinfo"
local nixio = require 'nixio'
local wu = {}

-- so we always scan in at least one different frequency
wu.FREQ_2GHZ_LIST = "2412 2462"
wu.FREQ_5GHZ_LIST = "5180 5240"

-- if iw runs for 5 min, it is likely hanging
wu.TIMEOUT = 300

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

function wu.wait_and_kill_on_timeout(pid_time_started)
	local pid_done = {}

	for pid,time_started in pairs(pid_time_started) do
		pid_done[pid]=false
	end

	repeat
		-- wait for 100ms
		nixio.nanosleep(0,100e6)

		-- see if something changed
		while true do
			pid,state,code = nixio.waitpid(nil,"nohang")
			if not pid then break end
			pid_done[pid] = true
		end

		-- see if time is up
		now = os.time()
		for pid,time_started in pairs(pid_time_started) do
			time_is_up = now - time_started > wu.TIMEOUT
			if not pid_done[pid] and time_is_up then
				-- time is up. send SIGTERM
				nixio.kill(pid,15)
				-- we don't care any longer about processes we signaled
				pid_done[pid] = true
			end
		end

		-- see if there are remaining processes
		all_done = true
		for pid,done in pairs(pid_done) do
			all_done = all_done and done
		end
	until all_done

end

function wu.do_workaround()
	local ifaces = wu.get_stickable_ifaces()
	local pid_time_started = {}

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

			-- we can not use os.popen here, because it does not give us the
			-- pid
			pid = nixio.fork()
			if pid == 0 then
				nixio.exec('/bin/sh','-c',cmd..' >/dev/null')
				os.exit(1)
			else
				pid_time_started[pid] = os.time()
			end

			nixio.nanosleep(1)
		end
	end

	wu.wait_and_kill_on_timeout(pid_time_started)
end

return wu
