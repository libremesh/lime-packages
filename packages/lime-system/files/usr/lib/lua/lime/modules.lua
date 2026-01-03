#!/usr/bin/lua

modules = {}

modules.NAMES = {
	"hardware_detection",
	"wireless",
	"network",
	"firewall",
	"system",
	"generic_config",
	"wifi_unstuck_wa",
}

function modules.is_available(name)
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

function modules.ensure_modules()
	if modules.modules ~= nil then
		return
	end

	modules.modules = {}
	for i, name in pairs(modules.NAMES) do
		full_name = "lime." .. name
		if modules.is_available(full_name) then
			modules.modules[i] = require(full_name)
		end
	end
end

local function module_error(errmsg)
	print(errmsg)
	print(debug.traceback())
end

function modules.execute(func)
	modules.ensure_modules()

	for _, module in pairs(modules.modules) do
		if module[func] ~= nil then
			xpcall(module[func], module_error)
		end
	end
end

return modules
