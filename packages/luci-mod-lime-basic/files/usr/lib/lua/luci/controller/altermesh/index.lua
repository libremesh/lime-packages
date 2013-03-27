--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>
Copyright 2013 Santiago Piccinini <spiccinini@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.altermesh.index", package.seeall)

function index()
	local root = node()
	if not root.lock then
		root.target = alias("altermesh")
		root.index = true
	end

	local page   = entry({"altermesh"}, alias("altermesh", "index"), _("Essentials"), 10)
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.index = true

	entry({"altermesh", "index"}, alias("altermesh", "index", "index"), _("Overview"), 10).index = true
	entry({"altermesh", "index", "index"}, form("altermesh/index"), _("General"), 1).ignoreindex = true
	entry({"altermesh", "index", "settings"}, cbi("altermesh/settings", {autoapply=true}), _("Settings"), 10)
	entry({"altermesh", "index", "logout"}, call("action_logout"), _("Logout"))
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url())
end
