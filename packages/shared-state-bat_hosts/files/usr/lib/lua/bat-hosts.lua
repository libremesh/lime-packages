#!/usr/bin/lua

bat_hosts = {}

local shared_state = require("shared-state")
local utils = require("lime.utils")

function bat_hosts.bathost_deserialize(hostname_plus_iface)
    local partial_hostname = hostname_plus_iface
    local iface
    for _, ifname in ipairs(utils.get_ifnames()) do
        local serialized_ifname = string.gsub(ifname, "%W", "_")
        serialized_ifname = utils.literalize(serialized_ifname)
        local replaced_hostname = hostname_plus_iface:gsub("_"..serialized_ifname, "")
        -- hostname don't have underscores see utils.is_valid_hostname
        replaced_hostname = replaced_hostname:gsub("_", "-")
        if #replaced_hostname < #partial_hostname then
            partial_hostname = replaced_hostname
            iface = ifname
        end
    end
    return partial_hostname, iface
end

function bat_hosts.get_bathost(mac, outgoing_iface)
	local sharedState = shared_state.SharedState:new('bat-hosts')
	local bathosts = sharedState:get()
	local bathost = bathosts[mac:lower()]
	if bathost == nil and outgoing_iface then
		local ipv6ll = utils.mac2ipv6linklocal(mac) .. "%" .. outgoing_iface
		sharedState:sync({ ipv6ll })
		bathosts = sharedState:get()
		bathost = bathosts[mac:lower()]
	end
	if bathost == nil then
		return
	end
	local hostname, iface = bat_hosts.bathost_deserialize(bathost.data)
	return { hostname = hostname, iface = iface }
end

return bat_hosts
