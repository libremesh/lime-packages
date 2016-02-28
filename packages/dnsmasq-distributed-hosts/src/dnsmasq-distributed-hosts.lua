#!/usr/bin/lua

--[[

Copyright (C) 2013 Gioacchino Mazzurco <gio@eigenlab.org>
Copyright (C) 2015 Gui Iribarren <gui@altermundi.net>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this file. If not, see <http://www.gnu.org/licenses/>.

]]--

local static_hosts_file = "/etc/hosts"
local dnsmasq_addn_hostsdir = "/tmp/hosts/d-d-h_"
local alfred_static_hosts_num = "67"

--! Tell alfred local /etc/hosts changed
function update_alfred()
	io.input(static_hosts_file)
	io.output(io.popen("alfred -s " .. alfred_static_hosts_num,"w"))
	for line in io.lines() do
		--! skip loopback addresses
		if not line:match("^%s*127\.") and not line:match("^%s*::1%s") then
			io.write(line.."\n")
		end
	end
	io.close(io.input())
	io.close(io.output())
end

--! Tell dnsmasq to reread dhcp-hostsfile and addn-hosts
function reload_dnsmasq()
	os.execute("killall -HUP dnsmasq 2>/dev/null")
end

function get_if_mac(ifname)
	local macfile = io.open("/sys/class/net/" .. ifname .. "/address")
	local ret_string = macfile:read()
	macfile:close()
	return ret_string
end

function receive_static_hosts()
	local stdout = io.popen("alfred -r " .. alfred_static_hosts_num,"r")
	local raw_output = stdout:read("*a")
	stdout:close()

	if (not raw_output) then exit(0) end

	json_output = {}
	-------------------------------- { added because alfred doesn't output valid json yet }
	assert(loadstring("json_output = {" .. raw_output .. "}"))()

	local own_mac = get_if_mac("br-lan")

	for _, row in ipairs(json_output) do
		local node_mac, value = unpack(row)
		if node_mac ~= own_mac then
			io.output(dnsmasq_addn_hostsdir..node_mac, "w")
			io.write(value:gsub("\x0a", "\n"):gsub("\x09", "\t") .. "\n")
			io.close()
		end
	end
end

--! ran from cron as an alfred facter,
--! publish our own host details
update_alfred()

--! and populate addn-hostsfile with incoming data
receive_static_hosts()
reload_dnsmasq()
