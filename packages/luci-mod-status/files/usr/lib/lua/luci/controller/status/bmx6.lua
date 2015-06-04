--[[
    Copyright (C) 2011 Pau Escrich <pau@dabax.net>
    Contributors Jo-Philipp Wich <xm@subsignal.org>

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

local bmx6json = require("luci.model.bmx6json")

module("luci.controller.status.bmx6", package.seeall)

function index()
	local place = {}
	local ucim = require "luci.model.uci"
	local uci = ucim.cursor()

	require("nixio.fs")

	-- checking if luci-app-bmx6 is installed
	if not nixio.fs.stat(luci.util.libpath() .. "/controller/bmx6.lua") then
		return nil
	end

	-- default values
	place = {"status", "bmx6"}

	---------------------------
	-- Starting with the pages
	---------------------------

	--- status (default)
	entry(place,call("action_nodes_j"),"BMX6",11)            

	-- not visible
	table.insert(place,"nodes_nojs")
	entry(place, call("action_nodes"), nil)
	table.remove(place)

	--- nodes
	table.insert(place,"Nodes")
	entry(place,call("action_nodes_j"),"Nodes",0)
	table.remove(place)

	table.insert(place,"Status")
	entry(place,call("action_status_j"),"Status",1)
	table.remove(place)

	--- links
	table.insert(place,"Links")
	entry(place,call("action_links"),"Links",2).leaf = true
	table.remove(place)

	-- Tunnels
	table.insert(place,"Tunnels")
	entry(place,call("action_tunnels_j"), "Tunnels", 3).leaf = true
	table.remove(place)

	--- Graph
	table.insert(place,"Graph")
	entry(place, template("bmx6/graph"), "Graph",4)
	table.remove(place)

	--- Topology (hidden)
	table.insert(place,"topology")
	entry(place, call("action_topology"), nil)
	table.remove(place)

	table.remove(place)

end

function action_status()
		local status = bmx6json.get("status").status or nil
		local interfaces = bmx6json.get("interfaces").interfaces or nil

		if status == nil or interfaces == nil then
			luci.template.render("bmx6/error", {txt="Cannot fetch data from bmx6 json"})
		else
        	luci.template.render("bmx6/status", {status=status,interfaces=interfaces})
		end
end

function action_status_j()
	luci.template.render("bmx6/status_j", {})
end

function action_nodes()
		local orig_list = bmx6json
		orig_list = bmx6json.get("originators")
		luci.template.render("bmx6/error", {txt="Cannot fetch data from bmx6 json"..orig_list})
end



function action_nodesx()
		local orig_list = bmx6json
		orig_list = bmx6json.get("originators")
		luci.template.render("bmx6/error", {txt="Cannot fetch data from bmx6 json"..orig_list})
		orig_list = bmx6json.get("originators").originators or nil

		if orig_list == nil then
			luci.template.render("bmx6/error", {txt="Cannot fetch data from bmx6 json"})
			return nil
		end

		local originators = {}
		local desc = nil
		local orig = nil
		local name = ""
		local ipv4 = ""

		for _,o in ipairs(orig_list) do
			orig = bmx6json.get("originators/"..o.name) or {}
			desc = bmx6json.get("descriptions/"..o.name) or {}

			if string.find(o.name,'.') then
				name = luci.util.split(o.name,'.')[1]
			else
				name = o.name
			end

			table.insert(originators,{name=name,orig=orig,desc=desc})
		end

        luci.template.render("bmx6/nodes", {originators=originators})
end

function action_nodes_j()
	local http = require "luci.http"
	local link_non_js = "/cgi-bin/luci" .. http.getenv("PATH_INFO") .. '/nodes_nojs'

	luci.template.render("bmx6/nodes_j", {link_non_js=link_non_js})
end

function action_gateways_j()
	luci.template.render("bmx6/gateways_j", {})
end

function action_tunnels_j()
        luci.template.render("bmx6/tunnels_j", {})
end


function action_links(host)
	local links = bmx6json.get("links", host)
	local devlinks = {}
	local _,l

	if links ~= nil then
		links = links.links
		for _,l in ipairs(links) do
			devlinks[l.viaDev] = {}
		end
		for _,l in ipairs(links) do
			l.name = luci.util.split(l.name,'.')[1]
			table.insert(devlinks[l.viaDev],l)
		end
	end

	luci.template.render("bmx6/links", {links=devlinks})
end

function action_topology()
	local originators = bmx6json.get("originators/all")
	local o,i,l,i2
	local first = true
	local topology = '[ '
	local cache = '/tmp/bmx6-topology.json'
	local offset = 60

	local cachefd = io.open(cache,r)
	local update = false

	if cachefd ~= nil then
		local lastupdate = tonumber(cachefd:read("*line")) or 0
		if os.time() >= lastupdate + offset then
			update = true
		else
			topology = cachefd:read("*all")
		end
		cachefd:close()
	end

	if cachefd == nil or update then
	    	for i,o in ipairs(originators) do
	    		local links = bmx6json.get("links",o.primaryIp)
	    		if links then
	    			if first then
	    				first = false
	    			else
						topology = topology .. ', '
	    			end
	    
					topology = topology .. '{ "name": "%s", "links": [' %o.name
	    
	    			local first2 = true
	    
	    			for i2,l in ipairs(links.links) do
	    				if first2 then
	    					first2 = false
	    				else
	    					topology = topology .. ', '
						end
						name = l.name or l.llocalIp or "unknown"
						topology = topology .. '{ "name": "%s", "rxRate": %s, "txRate": %s }'
							%{ name, l.rxRate, l.txRate }
	    
	    			end
	    
	    			topology = topology .. ']}'
	    		end
	    
	    	end
		
		topology = topology .. ' ]'

		-- Upgrading the content of the cache file
	 	cachefd = io.open(cache,'w+')
		cachefd:write(os.time()..'\n')
		cachefd:write(topology)
		cachefd:close()
	end

	luci.http.prepare_content("application/json")
	luci.http.write(topology)
end

