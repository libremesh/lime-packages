--[[
LuCI - Lua Configuration Interface

Copyright 2013 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.luci.survey", package.seeall)

function index()
	entry({"luci", "survey"}, alias("luci", "survey", "index"), _("Survey"), 50).index = true
	entry({"luci", "survey", "index"}, call("action_survey", {autoapply=true}), _("General"), 1)
	entry({"luci", "survey", "spectral_scan"}, call("action_spectral_scan"), _("Spectral Scan"), 1)
end

function action_survey()
	luci.template.render("luci/survey")
end

function action_spectral_scan()
	luci.template.render("luci/spectral_scan")
end
