--[[
    Copyright (C) libre-mesh.org

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

module("luci.controller.lime", package.seeall)

function index()

	-- Making lime as default
	local root = node()
	root.target = alias("lime")
	root.index  = true

	-- Main window with auth enabled
	status = entry({"lime"}, firstchild(), _("Simple Config"), 9.5)
	status.dependent = false
	status.sysauth = "root"
	status.sysauth_authenticator = "htmlauth"

	-- Rest of entries
	entry({"lime","essentials"}, cbi("lime/essentials"), _("Advanced"), 70).dependent=false
	entry({"lime","about"}, call("action_about"), _("About"), 80).dependent=false
	entry({"lime","logout"}, call("action_logout"), _("Logout"), 90)
end

function action_about()
--	package.path = package.path .. ";/etc/lime/?.lua"
	luci.template.render("lime/about",{})
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
