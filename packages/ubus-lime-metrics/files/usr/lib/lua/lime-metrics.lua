#!/usr/bin/lua

local utils = require('lime-metrics.utils')
local lutils = require("lime.utils")
local json = require 'luci.jsonc'


local metrics = {}

function metrics.get_metrics(target)
    local result = {}
    local node = target
    local loss = nil
    local shell_output = ""

    if lutils.is_installed("lime-proto-bmx6") then
        loss = utils.get_loss(node..".mesh", 6)
        shell_output = utils.shell("netperf -6 -l 10 -H "..node..".mesh| tail -n1| awk '{ print $5 }'")
    elseif lutils.is_installed("lime-proto-babeld") then
        loss = utils.get_loss(node, 4)
        shell_output = utils.shell("netperf -l 10 -H "..node.."| tail -n1| awk '{ print $5 }'")
    end
    local bw = 0
    if shell_output ~= "" then
        bw = shell_output:match("[%d.]+")
    end
    result.loss = loss
    result.bandwidth = bw
    result.status = "ok"
    return result
end

function metrics.get_gateway()
    local result = {}
    local gw = nil

    local internet_path_file = io.open("/etc/last_internet_path", "r")
    if internet_path_file then
        local path_content = assert(internet_path_file:read("*a"), nil)
        internet_path_file:close()
        path = json.parse(path_content) or nil
        if lutils.tableLength(path) > 0 then
            return { status="ok", gateway=path[lutils.tableLength(path)] }
        end
    end

    return {status="error", error={msg="Not found. No gateway available.", code="1"}}
end

function metrics.get_last_internet_path(msg)
    local internet_path_file = io.open("/etc/last_internet_path", "r")
    if internet_path_file then
        path_content = assert(internet_path_file:read("*a"), nil)
        internet_path_file:close()
        path = json.parse(path_content) or nil
        local result = {}
        if path ~= nil then
            result.path = path 
            result.status = "ok"
            return result
        end
    else
        return {status="error", error={msg="Not found. No known Internet path.", code="1"}}
    end
end

function metrics.get_internet_status( )
    local result = {}
    local lossV4 = utils.get_loss("4.2.2.2")
    if lossV4 ~= "100" then
        result.IPv4 = { working=true }
    else
      result.IPv4 = { working=false }
    end

    local lossV6 = utils.get_loss("2600::", 6)
    if lossV6 ~= "100" then
        result.IPv6 = { working=true }
    else
      result.IPv6 = { working=false }
    end
    local lookup_output = utils.nslookup_working()
    if lookup_output ~= "" then
        result.DNS = { working=true }
    else
        result.DNS = { working=false }
    end
    result.status = "ok"
    return result
end

function metrics.get_station_traffic(msg)
    local iface = msg.iface
    local mac = msg.station_mac
    local result = {}
    local traffic = utils.shell("iw "..iface.." station get "..mac.." | grep bytes | awk '{ print $3}'")
    words = {}
    for w in traffic:gmatch("[^\n]+") do table.insert(words, w) end
    rx = words[1]
    tx = words[2]
    result.station = mac
    result.rx_bytes = tonumber(rx, 10)
    result.tx_bytes = tonumber(tx, 10)
    result.status = "ok"
    return result
end


return metrics