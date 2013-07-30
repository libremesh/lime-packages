--[[
LuCI - Lua Configuration Interface

Copyright 2013 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.openairview.survey", package.seeall)

function index()
	entry({"admin", "survey"}, alias("admin", "survey", "index"), _("Survey"), 50).index = true
	entry({"admin", "survey", "index"}, call("action_survey", {autoapply=true}), _("General"), 1)
	entry({"admin", "survey", "spectral_scan"}, call("action_spectral_scan"), _("Spectral Scan"), 1)
end

function action_survey()
	luci.template.render("openairview/survey")
end

function action_spectral_scan()
	luci.template.render("openairview/spectral_scan")
end
