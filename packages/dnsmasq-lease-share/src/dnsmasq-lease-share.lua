#!/usr/bin/lua

--[[

Copyright (C) 2013 Gioacchino Mazzurco <gio@eigenlab.org>

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


--! dhcp lease file lines format
--! <Time of lease expiry, in epoch time (seconds since 1970)> <Client MAC Address> <Client IP> <Client unqualified hostname if provided, * if not provided> <Client-ID, if known. The client-ID is used as the computer's unique-ID in preference to the MAC address, if it's available>

--! root at OpenWrt:~# cat /var/dhcp.leases
--! 946689575 00:00:00:00:00:05 192.168.1.155 wdt 01:00:00:00:00:00:05
--! 946689351 00:0f:b0:3a:b5:0b 192.168.1.208 colinux *
--! 946689493 02:0f:b0:3a:b5:0b 192.168.1.199 * 01:02:0f:b0:3a:b5:0b

require("uci");

local local_lease_file = "/tmp/dnsmasq-lease-share-local-lease"
local alfred_shared_lease_num = "65"
local own_lease_lifetime = "600" -- in seconds

local command = arg[1];
local client_mac = arg[2];

--! Tell alfred local dhcp lease changed
function update_alfred()
	local lease_file = io.open(local_lease_file, "r+");
	local stdin = io.popen("alfred -s " .. alfred_shared_lease_num,"w");
	stdin:write(lease_file:read("*all"));
	lease_file:close();
	stdin:close();
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


if command == "add" then
	local lease_expiration = os.getenv("DNSMASQ_LEASE_EXPIRES");
	local client_ip = arg[3];
	local client_hostname;
	if (arg[4] and (arg[4]:len() > 0)) then client_hostname = arg[4] else client_hostname = "*" end;
	local client_id = os.getenv("DNSMASQ_CLIENT_ID");
	if ((not client_id) or (client_id:len() <= 0)) then client_id = client_mac end; 

	local lease_line = lease_expiration .. " " .. client_mac .. " " .. client_ip .. " " .. client_hostname .. " " .. client_id .. "\n";

	local lease_file = io.open(local_lease_file, "a");
	lease_file:write(lease_line);
	lease_file:close();

	update_alfred()

elseif command == "del" then
	local leases = "";
	local lease_file = io.open(local_lease_file, "r");
	while lease_file:read(0) do
		local lease_line = lease_file:read();
		if not string.find(lease_line, client_mac) then leases = leases .. lease_line .. "\n" end 
	end
	lease_file:close()
	lease_file = io.open(local_lease_file, "w");
	lease_file:write(leases);
	lease_file:close();
	update_alfred();

elseif command == "init" then
	local stdout = io.popen("alfred -r " .. alfred_shared_lease_num,"r");
	local raw_output = stdout:read("*a");
	stdout:close();

	local uci_conf = uci.cursor();

	local own_hostname = get_hostname();
	local own_ipv4 = uci_conf:get("network", "lan", "ipaddr");
	local disposable_mac = get_if_mac("br-lan");

	print(os.time()+own_lease_lifetime .. " " ..  disposable_mac .. " " .. own_ipv4 .. " " .. own_hostname .. " " .. disposable_mac);

	if (not raw_output) then exit(0); end

	json_output = {};
	local lease_table = {};
	-------------------------------- { added because alfred doesn't output valid json yet }
	assert(loadstring("json_output = {" .. raw_output .. "}"))()

	for _, row in ipairs(json_output) do
		local node_mac, value = unpack(row)
		table.insert(lease_table, value:gsub("\x0a", "\n") .. "\n")
	end

	print(table.concat(lease_table));

end
