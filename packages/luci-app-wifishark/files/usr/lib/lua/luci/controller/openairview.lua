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
	local e

	e = entry({"admin", "survey"}, alias("admin", "survey", "index"), _("Survey"), 50)
	e.index = true

	entry({"admin", "survey", "index"}, template("openairview/survey"), _("General"), 1)
	entry({"admin", "survey", "spectral_scan"}, template("openairview/spectral_scan"), _("Spectral Scan"), 1)
end
