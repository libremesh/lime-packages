#!/usr/bin/env lua

--! Used on lime-utils ubus script
local limewireless = require 'lime.wireless'
local utils = require 'lime.utils'
local upgrade = require 'lime.upgrade'
local node_status = require 'lime.node_status'
local hotspot_wwan = require "lime.hotspot_wwan"
local ubus = require "ubus"

local conn = ubus.connect()
if not conn then error("Failed to connect to ubus") end

local limeutils = {}

function limeutils.get_cloud_nodes()
    local nodes = utils.unsafe_shell(
                      "cat /tmp/bat-hosts | grep bat0 | cut -d' ' -f2 | sed 's/_bat0//' | sed 's/_/-/g' | sort | uniq")
    local result = {}
    result.nodes = {}
    for line in nodes:gmatch("[^\n]*") do
        if line ~= "" then table.insert(result.nodes, line) end
    end
    result.status = "ok"
    return result
end


function limeutils.get_mesh_ifaces()
    local result = {}
    result.ifaces = limewireless.mesh_ifaces()
    return result
end

function limeutils.get_node_status()
    local result = {}
    result.hostname = utils.hostname()
    result.ips = node_status.get_ips()
    result.most_active = node_status.get_most_active()
    result.switch_status = node_status.switch_status()
    result.uptime = tostring(utils.uptime_s())
    result.status = "ok"
    return result
end

function limeutils.get_notes()
    local result = {}
    result.notes = utils.read_file('/etc/banner.notes') or ''
    result.status = "ok"
    return result
end

function limeutils.set_notes(msg)
    local banner = utils.write_file('/etc/banner.notes', msg.text)
    return limeutils.get_notes()
end

function limeutils.get_community_settings()
    local config = conn:call("uci", "get", {config = "lime-app"}).values
    if config ~= nil then
        for name, value in pairs(config) do
            --! TODO: Find a best way to remove uci keys
            function table.removekey(table, key)
                local element = table[key]
                table[key] = nil
                return element
            end
            table.removekey(value, ".name")
            table.removekey(value, ".index")
            table.removekey(value, ".anonymous")
            table.removekey(value, ".type")
            return value
        end
    else
        return {error = "config not found"}
    end
end

--! todo(kon): move to utility class?? 
function limeutils.get_channels()
    local devices = limewireless.scandevices()
    local phys = {}
    for k, radio in pairs(devices) do
        local phyIndex = radio[".name"].sub(radio[".name"], -1)
        phys[k] = {phy = "phy" .. phyIndex}
        if limewireless.is5Ghz(radio[".name"]) then
            phys[k].freq = '5ghz'
        else
            phys[k].freq = '2.4ghz'
        end
    end
    local frequencies = {}
    for _, phy in pairs(phys) do
        local info = utils.unsafe_shell("iw " .. phy.phy ..
                                            " info | sed -n '/Frequencies:/,/valid/p' | sed '1d;$d' | grep -v radar | grep -v disabled | sed -e 's/.*\\[\\(.*\\)\\].*/\\1/'")
        frequencies[phy.freq] = utils.split(info, '\n')
    end
    return frequencies
end

function limeutils.get_config()
    local result = conn:call("uci", "get",
                             {config = "lime-autogen", section = "wifi"})
    result.channels = limeutils.get_channels()
    return result
end

function limeutils.get_upgrade_info()
    local result = upgrade.get_upgrade_info()
    if not result then return {status = "error"} end
    result.status = 'ok'
    return result
end


function limeutils.hotspot_wwan_get_status(msg)
    local msg = msg or {}
    local status, errmsg = hotspot_wwan.status(msg.radio)
    if status then
        return {
            status = 'ok',
            enabled = status.enabled,
            connected = status.connected,
            signal = status.signal
        }
    else
        return {status = 'error', message = errmsg}
    end
end

return limeutils
