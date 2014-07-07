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

require("uci");

local local_lease_file = "/tmp/dhcp.hosts_local"
local dnsmasq_dhcp_hostsfile = "/tmp/dhcp.hosts_remote"
local alfred_shared_lease_num = "66"

--! Tell alfred local dhcp lease changed
function update_alfred()
	local lease_file = io.open(local_lease_file, "r+");
	local stdin = io.popen("alfred -s " .. alfred_shared_lease_num,"w");
	stdin:write(lease_file:read("*all"));
	lease_file:close();
	stdin:close();
end

--! Tell dnsmasq to reread dhcp-hostsfile
function reload_dnsmasq()
	os.execute("killall -HUP dnsmasq 2>/dev/null")
end

function get_hostname()
	local hostfile = io.open("/proc/sys/kernel/hostname", "r");
	local ret_string = hostfile:read();
	hostfile:close();
	return ret_string;
end

function get_if_mac(ifname)
	local macfile = io.open("/sys/class/net/" .. ifname .. "/address");
	local ret_string = macfile:read();
	macfile:close();
	return ret_string;
end

function add_lease(client_mac, client_ip, client_hostname, client_id)
	local lease_line = client_mac .. ",id:" .. client_id .. "," .. client_ip .. "," .. client_hostname .. "\n";

	local lease_file = io.open(local_lease_file, "a");
	lease_file:write(lease_line);
	lease_file:close();
end

function del_lease(client_mac)
	local leases = "";
	local lease_file = io.open(local_lease_file, "r");
	if lease_file then
		while lease_file:read(0) do
			local lease_line = lease_file:read();
			if not string.find(lease_line, client_mac) then leases = leases .. lease_line .. "\n" end
		end
		lease_file:close()
		lease_file = io.open(local_lease_file, "w");
		lease_file:write(leases);
		lease_file:close();
	end
end

function receive_dhcp_hosts()
	local stdout = io.popen("alfred -r " .. alfred_shared_lease_num,"r");
	local raw_output = stdout:read("*a");
	stdout:close();

	if (not raw_output) then exit(0); end

	json_output = {};
	local lease_table = {};
	-------------------------------- { added because alfred doesn't output valid json yet }
	assert(loadstring("json_output = {" .. raw_output .. "}"))()

	for _, row in ipairs(json_output) do
		local node_mac, value = unpack(row)
		table.insert(lease_table, "# Node ".. node_mac .. "\n")
		table.insert(lease_table, value:gsub("\x0a", "\n") .. "\n")
	end

	local hostsfile = io.open(dnsmasq_dhcp_hostsfile, "w");
	if hostsfile then
		hostsfile:write(table.concat(lease_table));
		hostsfile:close();
	end
end

local command = arg[1];
local client_mac = arg[2];
local client_ip = arg[3];
local client_hostname;
if (arg[4] and (arg[4]:len() > 0)) then client_hostname = arg[4] else client_hostname = "" end;
local client_id = os.getenv("DNSMASQ_CLIENT_ID");
if ((not client_id) or (client_id:len() <= 0)) then client_id = client_mac end;

if command == "add" then
	add_lease(client_mac, client_ip, client_hostname, client_id)
	update_alfred()

elseif command == "del" then
	del_lease(client_mac)
	update_alfred()

elseif command == "old" then
	del_lease(client_mac)
	add_lease(client_mac, client_ip, client_hostname, client_id)
	update_alfred()

elseif command == nil then
--! ran from cron as an alfred facter,
--! publish our own host details
	local uci_conf = uci.cursor();

	local own_hostname = get_hostname();
	local own_ipv4 = uci_conf:get("network", "lan", "ipaddr");
	local own_mac = get_if_mac("br-lan");

	del_lease(own_mac)
	add_lease(own_mac, own_ipv4, own_hostname, own_mac);
	update_alfred()

--! and populate dhcp-hostsfile with incoming data
	receive_dhcp_hosts()
	reload_dnsmasq()

end
