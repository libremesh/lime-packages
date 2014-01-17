#!/usr/bin/lua

local libuci = require "uci"

config = {}

config.uci = libuci:cursor()

function config.get(sectionname, option, default)
	return config.uci:get("lime", sectionname, option) or config.uci:get("lime-defaults", sectionname, option) or default 
end

function config.foreach(configtype, callback)
	config.uci:foreach("lime", configtype, callback)
end
