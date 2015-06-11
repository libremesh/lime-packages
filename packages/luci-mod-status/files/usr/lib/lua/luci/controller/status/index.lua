--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: system.lua 9655 2013-01-27 18:43:41Z jow $
]]--

module("luci.controller.status.index", package.seeall)

function index()
	local root = node()
	if not root.lock then
		root.target = alias("status")
		root.index = true
	end

	local page
	page = entry({"status"}, firstchild(), _("Status"), 9)
	page.index = true

	page = entry({"status", "index"}, template("status/index"), _("Status"), 1)
	page.leaf = true

	require("nixio.fs")

	if nixio.fs.stat(luci.util.libpath() .. "/controller/batman.lua") then
		page = entry({"status", "batadv"}, template("status/batadv"), _("BATMAN-Adv"), 10)
		page.index = true
	end

end
