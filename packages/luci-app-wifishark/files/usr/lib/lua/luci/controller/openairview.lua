--[[
LuCI - Lua Configuration Interface

Copyright 2013 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.openairview", package.seeall)

function index()
	local page

	page = entry({"admin", "openairview"}, alias("admin", "openairview", "survey"), _("OpenAirView"), 50)
	page.index = true

	page = entry({"admin", "openairview", "survey"}, template("openairview/survey"), _("Neighbors"), 1)

	page = entry({"admin", "openairview", "spectral_scan"}, template("openairview/spectral_scan"), _("Spectral Scan"), 1)
end
