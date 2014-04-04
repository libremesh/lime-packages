#!/usr/bin/lua

utils = {}

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

function utils.applyMacTemplate(template, mac)
	for i=1,6,1 do
		template = template:gsub("\\M"..i.."\\", mac[i])
	end

	return template
end

return utils
