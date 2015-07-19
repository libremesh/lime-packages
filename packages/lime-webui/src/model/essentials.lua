--[[
    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net

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
m = Map("lime", "Libre-Mesh")

-- Create sections
local system = m:section(NamedSection, "system", "lime","System","System")
system.addremove = true

local network = m:section(NamedSection, "network", "lime","Network","Network")
network.addremove = true

local wifi = m:section(TypedSection, "wifi","WiFi","WiFi")
wifi.addremove = true

-- hostname
system:option(Value,"hostname",translate("Hostname"),translate("Name for this node"))

-- network
network:option(Value,"main_ipv4_address",translate("Main IPv4"),translate("The main IPv4 configured for this node, with slash notation (for ex. 1.2.3.4/24)"))
network:option(Value,"main_ipv6_address",translate("Main IPv6"),translate("The main IPv6 configured for this node, with slash notation (for ex. 2001:db8::1/64)"))

-- wifi
wifi:option(Value,"public_essid",translate("Public SSID"),translate("The SSID (WiFi network name) used for this node"))
wifi:option(Value,"channel",translate("Channel"),translate("Channel used for this interface"))
wifi:option(Value,"ap_essid",translate("AP SSID"),translate("The SSID (WiFi network name) used for the access point devices"))
wifi:option(Value,"adhoc_essid",translate("Mesh SSID"),translate("The SSID (WiFi network name) used for the ad-hoc device"))
wifi:option(Value,"adhoc_bssid",translate("Mesh BSSID"),translate("The BSSID (WiFi network identifier) used for the ad-hoc network"))

-- commit
function m.on_commit(self,map)
	luci.sys.call('true')
end

return m

