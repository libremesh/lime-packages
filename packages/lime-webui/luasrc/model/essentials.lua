--[[
    Copyright (C) 2016 LibreMesh.org

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

-- LibreMesh.org config

require("luci.sys")
local lime = Map("lime", "LibreMesh")
local config = require("lime.config")
local bmx6json = require("luci.model.bmx6json") or nil

-- Create sections
local system = lime:section(NamedSection, "system", "lime","System","System")
system.addremove = false
local network = lime:section(NamedSection, "network", "lime","Network","Network")
network.addremove = false
local wifi = lime:section(NamedSection, "wifi","WiFi","WiFi")
wifi.addremove = false

-- hostname
local hostname = system:option(Value,"hostname",translate("Hostname"),
  translate("Name for this node"))
hostname.default = config.get("system","hostname")

-- network
local ipv4 = network:option(Value,"main_ipv4_address",translate("Main IPv4"),
  translate("The main IPv4 configured for this node, with slash notation (for ex. 1.2.3.4/24)"))
ipv4.default = config.get("network","main_ipv4_address")
ipv4.optional = true
local ipv6 = network:option(Value,"main_ipv6_address",translate("Main IPv6"),
  translate("The main IPv6 configured for this node, with slash notation (for ex. 2001:db8::1/64)"))
ipv6.default = config.get("network","main_ipv6_address")
ipv6.optional = true

-- bmx6 prefered gateway
if bmx6json then
	local bmx6_pref_gw = network:option(ListValue,"bmx6_pref_gw",translate("Internet Priorized Gateway (bmx6)"),
	  translate("You can choose a Gateway to priorize your traffic to go through this node."))

	bmx6_pref_gw:value('')
	local tunoptions = bmx6json.get("tunnels") or nil
	if tunoptions then
		local _,o
		for _,o in pairs(tunoptions.tunnels) do
    			if o.advNet == "0.0.0.0/0" then
        			bmx6_pref_gw:value(o.remoteName)
    			end
		end
	end
	bmx6_pref_gw.default = config.get("network","bmx6_pref_gw")
	bmx6_pref_gw.optional = true
end

-- wifi
local ap_ssid = wifi:option(Value,"ap_ssid",translate("Network SSID"),
  translate("Access Point ESSID (usually name of your network)"))
ap_ssid.default = config.get("wifi","ap_ssid")
ap_ssid.optional = true
local ch_2 = wifi:option(Value,"channel_2ghz",translate("Channel 2.4 GHz"),
  translate("Default channel used for 2.4 GHz radios"))
ch_2.default = config.get("wifi","channel_2ghz")
ch_2.optional = true
local ch_5 = wifi:option(Value,"channel_5ghz",translate("Channel 5 GHz"),
  translate("Default channel used for 5 GHz radios"))
ch_5.default = config.get("wifi","channel_5ghz")
ch_5.optional = true
local country = wifi:option(Value,"country",translate("Country code"),
  translate("Country code used for WiFi radios"))
country.default = config.get("wifi","country")
country.optional = true
local distance = wifi:option(Value,"distance",translate("Distance"),
  translate("Max distance for the links in meters (big impact on performance)"))
distance.default = config.get("wifi","distance")
distance.optional = true
local bssid = wifi:option(Value,"adhoc_bssid",translate("Mesh BSSID"),
  translate("The BSSID (WiFi network identifier) used for the mesh network"))
bssid.default = config.get("wifi","adhoc_bssid")
bssid.optional = true

-- commit
function lime.on_commit(self,map)
  luci.sys.call('(/usr/bin/lime-config > /tmp/lime-config.log 2>&1 && /usr/bin/lime-apply) &')
end

-- LibreMap.org config

limap = Map("libremap", "Libre-Map")

-- main settings
local settings = limap:section(NamedSection, "settings", "libremap",translate("General"),translate("General"))
settings.addremove = false
local com = settings:option(Value,"community",translate("Community name"),
  translate("The name of your network community"))
com.default = config.get("wifi","ap_ssid")

-- location
local loc = limap:section(NamedSection, "location", "plugin",translate("Location"),translate("Map location"))
loc:option(Value,"latitude",translate("Latitude"),
  translate("Latitude (this can be also configured in location tab)"))
loc:option(Value,"longitude",translate("Longitude"),
  translate("Longitude (this can be also configured in location tab)"))

  -- contact
local contact = limap:section(NamedSection, "contact", "plugin",translate("Contact"),translate("Contact information"))
contact:option(Value,"name",translate("Name"),
  translate("Your name or alias (not required)"))
contact:option(Value,"email",translate("Email"),
  translate("Your email (not required)"))

-- commit
function limap.on_commit(self,map)
	luci.sys.call('/usr/sbin/libremap-agent &')
end

return lime,limap
