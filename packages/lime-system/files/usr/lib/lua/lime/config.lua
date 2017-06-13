#!/usr/bin/lua

--! LibreMesh is modular but this doesn't mean parallel, modules are executed
--! sequencially, so we don't need to worry about transactionality and all other
--! stuff that affects parrallels database, at moment we don't need parallelism
--! as this is just some configuration stuff and is not performance critical.

local libuci = require("uci")

config = {}

config.uci = libuci:cursor()

function config.get(sectionname, option)
	local limeconf = config.uci:get("lime", sectionname, option)
	if limeconf then return limeconf end

	local defcnf = config.uci:get("lime-defaults", sectionname, option)
	if ( defcnf ~= nil ) then
		config.set(sectionname, option, defcnf)
	else
		local cfn = sectionname.."."..option
		print("WARNING: Attempt to access undeclared default for: "..cfn)
		print(debug.traceback())
	end
	return defcnf
end

--! Execute +callback+ for each config of type +configtype+ found in
--! +/etc/config/lime+.
--! beware this function doesn't look in +/etc/config/lime-default+ for default
--! values as it is designed for use with specific sections only
function config.foreach(configtype, callback)
	return config.uci:foreach("lime", configtype, callback)
end

function config.get_all(sectionname)
	local lime_section = config.uci:get_all("lime", sectionname)
	local lime_def_section = config.uci:get_all("lime-defaults", sectionname)

	if lime_section or lime_def_section then
		local ret = lime_section or {}

		if lime_def_section then
			for key,value in pairs(lime_def_section) do
				if (ret[key] == nil) then
					config.set(sectionname, key, value)
					ret[key] = value
				end
			end
		end

		return ret
	end

	return nil
end

function config.get_bool(sectionname, option)
	local val = config.get(sectionname, option)
	return (val and ((val == '1') or (val == 'on') or (val == 'true') or (val == 'enabled')))
end

config.batched = false

function config.init_batch()
	config.batched = true
end

function config.set(...)
	config.uci:set("lime", unpack(arg))
	if(not config.batched) then config.uci:save("lime") end
end

function config.delete(...)
	config.uci:delete("lime", unpack(arg))
	if(not config.batched) then config.uci:save("lime") end
end

function config.end_batch()
	if(config.batched) then
		config.uci:save("lime")
		config.batched = false
	end
end

function config.autogenerable(section_name)
	return ( (not config.get_all(section_name)) or config.get_bool(section_name, "autogenerated") )
end


return config
