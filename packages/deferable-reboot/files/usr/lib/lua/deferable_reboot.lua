local utils = require "lime.utils"
local config = require "lime.config"

local defreboot = {}

defreboot.DEFAULT_REBOOT_UPTIME = 60*60*27
defreboot.SLEEP_BEFORE_REBOOT_S = 30

defreboot.POSTPONE_FILE_PATH = '/tmp/deferable-reboot.defer'

function defreboot.config(min_uptime)
	if min_uptime == nil then
		local uci = config.get_uci_cursor()
		local lime_min_uptime = config.get("system", "deferable_reboot_uptime_s", false)
		local general_min_uptime = uci:get("deferable-reboot", "options", "deferable_reboot_uptime_s")
		min_uptime = tonumber(lime_min_uptime or general_min_uptime or defreboot.DEFAULT_REBOOT_UPTIME)
	end
	assert(type(min_uptime) == "number", "min_uptime must be a number")
	defreboot.min_uptime = min_uptime
end

function defreboot.should_reboot()
	local uptime_s = utils.uptime_s()
	local postpone_until_s = defreboot.read_postpone_file()
	local min_uptime = defreboot.min_uptime

	if (postpone_until_s ~= nil) and (postpone_until_s > min_uptime) then
		min_uptime = postpone_until_s
	end
	return uptime_s > min_uptime
end

function defreboot.postpone_util_s(uptime)
	assert(type(uptime) == "number", "uptime must be a number")
	local f = io.open(defreboot.POSTPONE_FILE_PATH, 'w')
	f:write(tostring(uptime))
	f:close()
end


--! use this function to postpone the reboot, also the following command can be used
--! replacing SECONDS: # awk '{print $1 + SECONDS}' /proc/uptime > /tmp/deferable-reboot.defer
function defreboot.read_postpone_file()
	local f = io.open(defreboot.POSTPONE_FILE_PATH)
	if f ~= nil then
		return tonumber(f:read("*l"))
	end
	return nil
end

function defreboot.reboot()
	--! give time to sysupgrade to kill us
	nixio.nanosleep(defreboot.SLEEP_BEFORE_REBOOT_S)
	os.execute("reboot")
end

return defreboot
