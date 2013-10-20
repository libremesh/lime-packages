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


--! dhcp lease file lines format
--! <Time of lease expiry, in epoch time (seconds since 1970)> <Client MAC Address> <Client IP> <Client unqualified hostname if provided, * if not provided> <Client-ID, if known. The client-ID is used as the computer's unique-ID in preference to the MAC address, if it's available>

--! root at OpenWrt:~# cat /var/dhcp.leases
--! 946689575 00:00:00:00:00:05 192.168.1.155 wdt 01:00:00:00:00:00:05
--! 946689522 00:00:00:00:00:04 192.168.1.237 * 01:00:00:00:00:00:04
--! 946689351 00:0f:b0:3a:b5:0b 192.168.1.208 colinux *
--! 946689493 02:0f:b0:3a:b5:0b 192.168.1.199 * 01:02:0f:b0:3a:b5:0b


local local_lease_file = "/tmp/dnsmasq-lease-share/local_lease"
local alfred_shared_lease_num = "65"

local command = arg[1];
local client_mac = arg[2];

--! Tell alfred local dhcp lease changed
function update_alfred()
    local lease_file = io.open(local_lease_file, "r+");
    local stdin = io.popen("afred -r " .. alfred_shared_lease_num,"w");
    stdin.write(lease_file:read("*all"));
end

if command == "add" then
    local lease_expiration = os.getenv("DNSMASQ_LEASE_EXPIRES");
    local client_ip = arg[3];
    local client_hostname;
    if arg[4]:len() > 0 then client_hostname = arg[4] else client_hostname = "*" end;
    local client_id = os.getenv("DNSMASQ_CLIENT_ID");
    if client_id:len() <= 0 then client_id = client_mac end; 

    local lease_line = lease_expiration .. " " .. client_mac .. " " .. client_ip .. " " .. client_hostname .. " " .. client_id;

    local lease_file = io.open(local_lease_file, "a");
    lease_file:write(lease_file);

    update_alfred()

elseif command == "del" then
    local leases;
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
    local stdout = io.popen("afred -r " .. alfred_shared_lease_num,"r");
    print(stdout:read("*all"));
    
end
