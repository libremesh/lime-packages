#!/usr/bin/lua

local fs = require("nixio.fs")

local config = require("lime.config")
local network = require("lime.network")
local utils = require("lime.utils")


system = {}

function system.get_hostname()
        local system_hostname = utils.applyMacTemplate16(config.get("system", "hostname"), network.primary_mac())
        return utils.sanitize_hostname(system_hostname)
end

function system.set_hostname()
	local hostname = system.get_hostname()
	local uci = config.get_uci_cursor()
	uci:foreach("system", "system", function(s) uci:set("system", s[".name"], "hostname", hostname) end)
	uci:save("system")
end

function system.setup_root_password()

	local policy = config.get("system", "root_password_policy")

	if policy == "DO_NOTHING" then
		--! nothing...
	elseif policy == "SET_SECRET" then
		local secret = config.get("system", "root_password_secret")
		local current_secret = utils.get_root_secret()
		if current_secret == nil then
			error("Can't get root password")
		end
		if current_secret ~= secret then
			utils.set_root_secret(secret)
		end
	elseif policy == "RANDOM" then
		--! Not having a password can be specified by the secret being empty
		--! or also being '*' or '!'. So we asume there is no password set
		--! in both cases.
		if #utils.get_root_secret() <= 1 then
			utils.set_password('root', utils.random_string(30))
		end
	else
		error('Invalid root_password_policy: ' .. policy)
	end
end

function system.clean()
    -- nothing to clean
end

function system.configure()
    utils.log("Configuring system...")
    system.set_hostname()

    system.setup_root_password()

    utils.log("Let uhttpd listen on IPv4/IPv6")
    local uci = config.get_uci_cursor()
    uci:set("uhttpd", "main", "listen_http", "80")
    uci:set("uhttpd", "main", "listen_https", "443")
    uci:set("uhttpd", "main", "max_requests", "6")
    uci:set("uhttpd", "main", "script_timeout", "15")
    uci:save("uhttpd")
end

function system.apply()
    -- apply hostname
    local hostname
    local uci = config.get_uci_cursor()
    uci:foreach("system", "system", function(s)
        hostname = uci:get("system", s[".name"], "hostname") -- FIXME Doesn't we already have hostaname in s["hostname"] without executing the get ?
    end)
    fs.writefile("/proc/sys/kernel/hostname", hostname)

    -- apply uhttpd settings
    os.execute("/etc/init.d/uhttpd reload")
end

return system
