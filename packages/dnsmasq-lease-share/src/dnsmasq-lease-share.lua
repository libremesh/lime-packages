#!/usr/bin/lua

--[[

Copyright (C) 2013 Gioacchino Mazzurco <gio@eigenlab.org>
Copyright (C) 2014 Gui Iribarren <gui@altermundi.net>

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

-- PLEASE USE TAB NOT SPACE JUST FOR INDENTATION

--! dhcp-hostsfile line format
--! [<hwaddr>][,id:<client_id>|*][,set:<tag>][,<ipaddr>][,<hostname>][,<lease_time>][,ignore]

require("uci")

local local_lease_file = "/tmp/dhcp.hosts_local"
local dnsmasq_dhcp_hostsfile = "/tmp/dhcp.hosts_remote"
local dnsmasq_addn_hostsfile = "/tmp/hosts/dnsmasq-lease-share"
local alfred_shared_lease_num = "66"

function split(string, sep)
    local ret = {}
    for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
    return ret
end

--! Tell alfred local dhcp lease changed
function update_alfred()
	local lease_file = io.open(local_lease_file, "r+")
	local stdin = io.popen("alfred -s " .. alfred_shared_lease_num,"w")
	stdin:write(lease_file:read("*all"))
	lease_file:close()
	stdin:close()
end

--! Tell dnsmasq to reread dhcp-hostsfile and addn-hosts
function reload_dnsmasq()
	os.execute("killall -HUP dnsmasq 2>/dev/null")
end

function get_hostname()
	local hostfile = io.open("/proc/sys/kernel/hostname", "r")
	local ret_string = hostfile:read()
	hostfile:close()
	return ret_string
end

function get_if_mac(ifname)
	local macfile = io.open("/sys/class/net/" .. ifname .. "/address")
	local ret_string = macfile:read()
	macfile:close()
	return ret_string
end

function add_lease(client_mac, client_ip, client_hostname, client_id)
	local lease_line = client_mac .. ",id:" .. client_id .. "," .. client_ip .. "," .. client_hostname .. "\n"

	local lease_file = io.open(local_lease_file, "a")
	lease_file:write(lease_line)
	lease_file:close()
end

function del_lease(client_mac, client_ip)
	local leases = ""
	local lease_file = io.open(local_lease_file, "r")
	if lease_file then
		while lease_file:read(0) do
			local lease_line = lease_file:read()
			if not (lease_line:find("^"..client_mac) and lease_line:find(client_ip, 0, true)) then leases = leases .. lease_line .. "\n" end
		end
		lease_file:close()
		lease_file = io.open(local_lease_file, "w")
		lease_file:write(leases)
		lease_file:close()
	end
end

function receive_dhcp_hosts()
	local stdout = io.popen("alfred -r " .. alfred_shared_lease_num,"r")
	local raw_output = stdout:read("*a")
	stdout:close()

	if (not raw_output) then exit(0) end

	json_output = {}
	-------------------------------- { added because alfred doesn't output valid json yet }
	assert(loadstring("json_output = {" .. raw_output .. "}"))()

	local own_mac = get_if_mac("br-lan")

	--! write down unpacked output on a tmpfile, to iterate over it later with io.lines()
	io.input(io.output(io.tmpfile()))
	for _, row in ipairs(json_output) do
		local node_mac, value = unpack(row)
		if node_mac ~= own_mac then
			io.write(value:gsub("\x0a", "\n") .. "\n")
		end
	end
	io.input():seek("set")

	local lease_table = {}
	local addnhosts = {}
	for line in io.lines() do
		client_mac, client_id, client_ip, client_hostname = unpack(split(line, ","))
		if client_ip and client_hostname then
			--! populating a table like this ensures every line is unique
			addnhosts[client_ip .. " " .. client_hostname] = 1
		end

		if client_mac and client_id and client_ip then
			--! IPv6 addresses must be enclosed in brackets
			if client_ip:find(":") then client_ip = "[" .. client_ip .. "]" end
			--! ensure client_id is prefixed with "id:" once and only once
			lease_table[client_mac .. ",id:" .. client_id:gsub("^id:", "") .. "," .. client_ip] = 1
		end
	end

	local hostsfile = io.open(dnsmasq_dhcp_hostsfile, "w")
	if hostsfile then
		for line, _ in pairs(lease_table) do
			hostsfile:write(line .. "\n")
		end
		hostsfile:close()
	end

	local addnhostsfile = io.open(dnsmasq_addn_hostsfile, "w")
	if addnhostsfile then
		for line, _ in pairs(addnhosts) do
			addnhostsfile:write(line .. "\n")
		end
		addnhostsfile:close()
	end
end

local command = arg[1]
local client_mac = arg[2]
local client_ip = arg[3]
local client_hostname
if (arg[4] and (arg[4]:len() > 0)) then client_hostname = arg[4] else client_hostname = "" end
local client_id = os.getenv("DNSMASQ_CLIENT_ID")
if ((not client_id) or (client_id:len() <= 0)) then client_id = client_mac end

if command == "add" then
	add_lease(client_mac, client_ip, client_hostname, client_id)
	update_alfred()

elseif command == "del" then
	del_lease(client_mac, client_ip)
	update_alfred()

elseif command == "old" then
	del_lease(client_mac, client_ip)
	add_lease(client_mac, client_ip, client_hostname, client_id)
	update_alfred()

elseif command == nil then
--! ran from cron as an alfred facter,
--! publish our own host details
	local uci_conf = uci.cursor()

	local own_hostname = get_hostname()
	local own_ipv4 = uci_conf:get("network", "lan", "ipaddr")
	local own_ipv6 = uci_conf:get("network", "lan", "ip6addr")
	local own_mac = get_if_mac("br-lan")

	del_lease(own_mac, own_ipv4)
	add_lease(own_mac, own_ipv4, own_hostname, own_mac)
	if own_ipv6 then
		own_ipv6 = own_ipv6:gsub("/.*$", "")
		del_lease(own_mac, own_ipv6)
		add_lease(own_mac, own_ipv6, own_hostname, own_mac)
	end
	update_alfred()

--! and populate dhcp-hostsfile with incoming data
	receive_dhcp_hosts()
	reload_dnsmasq()

end
