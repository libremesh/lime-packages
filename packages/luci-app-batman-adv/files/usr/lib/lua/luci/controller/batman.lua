--[[
LuCI - Lua Configuration Interface

Copyright 2012 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.batman", package.seeall)

function index()
	local root, page

	root = node()
	if not root.target then
		root.target = alias("batman")
		root.index = true
	end

	page = node("batman")
	page.target = template("batman")
	page.title  = _("B.A.T.M.A.N. Advanced")
	page.order  = 1

	page = node("batman", "json")
	page.target = call("act_json")

	page = node("batman", "vis")
	page.target = call("act_vis")
	page.leaf   = true

	page = node("batman", "topo")
	page.target = call("act_topo")
	page.leaf   = true

	page = node("batman", "graph")
	page.target = template("batman_graph")
	page.leaf   = true

	page = node("batman", "gw")
	page.target = call("act_gw")
	page.leaf   = true
end

function act_vis(mode)
	if mode == "server" or mode == "client" or mode == "off" then
		luci.sys.call("batctl vm %q >/dev/null" % mode)
		luci.http.prepare_content("application/json")
		luci.http.write_json(mode)
	else
		luci.http.status(500, "Bad mode")
	end
end

function act_topo(mode)
	if not mode or mode == "dot" or mode == "json" then
		local fd = io.popen("batctl vd %s" %( mode or "dot" ))
		if fd then
			if mode == "json" then
				luci.http.prepare_content("application/json")
				luci.http.write("[")
				local ln
				repeat
					ln = fd:read("*l")
					if ln then
						luci.http.write(ln)
						luci.http.write(", ")
					end
				until not ln
				luci.http.write("{ } ]")
			else
				luci.http.prepare_content("text/vnd.graphviz")
				luci.http.header("Content-Disposition",
					"attachment; filename=topo-%s-%s.vd"
						%{ luci.sys.hostname(), os.date("%Y%m%d-%H%M%S") })
				luci.http.write(fd:read("*a"))
			end
			fd:close()
		else
			luci.http.status(500, "No data")
		end
	else
		luci.http.status(500, "Bad mode")
	end
end

function act_gw(mode, down, up)
	local s = down and (up and #up and down .. "/" .. up or down) or ""
	if mode == "client" or mode == "server" or mode == "off" then
		luci.sys.call("batctl gw %s %s >/dev/null" %{ mode, s })
		luci.http.prepare_content("application/json")
		luci.http.write_json((luci.sys.exec("batctl gw"):match("%(.+: (%S+)%)")))
	else
		luci.http.status(500, "Bad mode")
	end
end

function act_json()
	local v, l, fd
	local rv = {
		interfaces  = { },
		originators = { },
		gateways    = { }
	}

	--
	-- interfaces
	--
	fd = io.popen("batctl if")
	if fd then
		repeat
			l = fd:read("*l")
			v = l and l:match("^(.-):")
			if v then
				rv.interfaces[#rv.interfaces+1] = v
			end
		until not l
		fd:close()
	end

	--
	-- originators
	--
	fd = io.popen("batctl o")
	if fd then
		-- skip header lines
		fd:read("*l")
		fd:read("*l")

		repeat
			l = fd:read("*l")
			if l then
				local m, s, q = l:match("^ *([^ ]+) +([%d%.]+)s +%( *(%d+)%)")
				if m and s and q then
					rv.originators[#rv.originators+1] = {
						m,
						tonumber(s) * 1000,
						tonumber(q)
					}
				end
			end
		until not l
		fd:close()
	end

	--
	-- gateways
	--
	fd = io.popen("batctl gwl")
	if fd then
		-- skip header line
		fd:read("*l")

		repeat
			l = fd:read("*l")
			if l then
				local a, m, q, n, i, c, r = l:match("^(%S*) +([^ ]+) +%( *(%d+)%) +([^ ]+) +%[ *(%S+)%]: +(%d+) +- +(%S+)")
				if a and m and q and n and i and c and r then
					rv.gateways[#rv.gateways+1] = {
						#a > 0,
						m,
						tonumber(q),
						n,
						i,
						tonumber(c),
						r
					}
				end
			end
		until not l
		fd:close()
	end


	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
