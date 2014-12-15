#!/usr/bin/lua

utils = {}

local config = require("lime.config")


function utils.split(string, sep)
    local ret = {}
    for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
    return ret
end

function utils.stringStarts(string, start)
   return (string.sub(string, 1, string.len(start)) == start)
end

function utils.stringEnds(string, _end)
   return ( _end == '' or string.sub( string, -string.len(_end) ) == _end)
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

function utils.applyHostnameTemplate(template)
	local system = require("lime.system")
	return template:gsub("%%H", system.get_hostname())
end

function utils.network_id()
    local network_essid = config.get("wifi", "ap_ssid")
    local netid = {}
    local fd = io.popen('echo "' .. network_essid .. '" | md5sum')
    if fd then
        local md5 = fd:read("*a")
        netid[1] = md5:match("^(..)")
        netid[2] = md5:match("^..(..)")
        netid[3] = md5:match("^....(..)")
        fd:close()
    end
    return netid
end

function utils.applyNetTemplate16(template)
	local netid = utils.network_id()
	for i=1,3,1 do template = template:gsub("%%N"..i, netid[i]) end
	return template
end

function utils.applyNetTemplate10(template)
	local netid = utils.network_id()
	for i=1,3,1 do template = template:gsub("%%N"..i, tonumber(netid[i], 16)) end
	return template
end

return utils
