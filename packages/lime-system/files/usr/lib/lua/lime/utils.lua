#!/usr/bin/lua

utils = {}

local config = require("lime.config")

function utils.split(string, sep)
    local ret = {}
    for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
    return ret
end

function utils.hex(x)
    return string.format("%02x", x)
end

function utils.printf(fmt, ...)
    print(string.format(fmt, ...))
end

function utils.isModuleAvailable(name)
	if package.loaded[name] then 
		return true
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

function utils.applyMacTemplate16(template, mac)
	for i=1,6,1 do template = template:gsub("%%M"..i, mac[i]) end
	return template
end

function utils.applyMacTemplate10(template, mac)
	for i=1,6,1 do template = template:gsub("%%M"..i, tonumber(mac[i], 16)) end
	return template
end

function utils.network_id()
    local network_essid = config.get("wifi", "ap_ssid")
    local n1, n2, n3
    local fd = io.popen('echo "' .. network_essid .. '" | md5sum')
    if fd then
        local md5 = fd:read("*a")
        n1 = tonumber(md5:match("^(..)"), 16)
        n2 = tonumber(md5:match("^..(..)"), 16)
        n3 = tonumber(md5:match("^....(..)"), 16)
        fd:close()
    end
    return n1, n2, n3
end

return utils
