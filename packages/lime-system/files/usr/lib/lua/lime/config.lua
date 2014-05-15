#!/usr/bin/lua

--! Libre-Mesh is modular but this doesn't mean parallel,
--! modules are executed sequencially, so we don't need
--! to worry about transaction and all other stuff that
--! affects parrallels database, at moment we don't need
--! parallelism as this is just some configuration stuff
--! and is not performance critical.

local libuci = require "uci"

config = {}

config.uci = libuci:cursor()

function config.get(sectionname, option, default)
	return config.uci:get("lime", sectionname, option) or config.uci:get("lime-defaults", sectionname, option, default)
end

function config.foreach(configtype, callback)
	return config.uci:foreach("lime", configtype, callback)
end

function config.get_all(sectionname)
	local ret = config.uci:get_all("lime", sectionname) or {}
	for key,value in pairs(config.uci:get_all("lime-defaults", sectionname)) do
		if (ret[key] == nil) then
			ret[key] = value
		end
	end
	return ret
end

function config.get_bool(sectionname, option, default)
	local val = config.get(sectionname, option, default)
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

return config
