local config = require 'lime.config'
local libuci = require 'uci'

local utils = {}

utils.assert = assert

UCI_CONFIG_FILES = {
	"6relayd", "babeld", "batman-adv", "check-date", "dhcp", "dropbear", "fstab", "firewall",
	"libremap", "lime", "lime-app", "lime-defaults", "lime-defaults-factory",
	"luci", "network", "pirania", "rpcd", "shared-state", "system", "ucitrack",
	"uhttpd", "wireless",
}

-- Creates a custom empty uci environment to be used in unittesting.
-- Should be called in a before_each block and must be followed by a call to
-- teardown_test_uci in an after_each block.
function utils.setup_test_uci()
	local uci = libuci:cursor()
	config.set_uci_cursor(uci)
	local tmpdir = io.popen("mktemp -d"):read('*l')
	uci:set_confdir(tmpdir)
	-- If the uci files does not exists then doing uci add fails
	-- so here we create empty config files
	for _, cfgname in ipairs(UCI_CONFIG_FILES) do
		local f = io.open(tmpdir .. '/' .. cfgname, "w"):close()
	end
	return uci
end

function utils.teardown_test_uci(uci)
	local confdir = uci:get_confdir()
	if(string.find(confdir, '^/tmp') ~= nil) then
		local out = io.popen("rm -rf " .. confdir .. " " .. uci:get_savedir())
		out:read('*all') -- this allows waiting for popen completion
		out:close()
		io.popen("rm -rf " .. confdir .. " " .. uci:get_savedir())
	end
	uci:close()
end


return utils
