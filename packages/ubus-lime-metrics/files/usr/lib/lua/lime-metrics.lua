#!/usr/bin/lua

local utils = require('lime-metrics.utils')
local lutils = require("lime.utils")
local json = require 'luci.jsonc'

local metrics = {}

function metrics.get_last_internet_path_filename()
    return "/etc/last_internet_path"
end

function metrics.get_metrics(target)
    local result = {}
    local node = target
    local loss = nil
    local shell_output = ""

    if lutils.is_installed("lime-proto-babeld") then
        loss = utils.get_loss(node)
        shell_output = lutils.unsafe_shell("netperf -l 10 -H "..node.."| tail -n1| awk '{ print $5 }'")
    else
        return {status="error", error={msg="No lime-proto-babeld found", code="1"}}
    end
    local bw = 0
    if shell_output ~= "" and shell_output ~= nil then
        bw = shell_output:match("[%d.]+")
    end
    result.loss = loss
    result.bandwidth = bw
    result.status = "ok"
    return result
end

function metrics.get_loss(target)
    local result = {}
    local node = target
    local loss = nil

    loss = utils.get_loss(node)
    result.loss = loss
    result.status = "ok"
    return result
end


function metrics.get_gateway()
    local result = {}
    local gw = nil

    local internet_path_file = io.open(metrics.get_last_internet_path_filename(), "r")
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
    local internet_path_file = io.open(metrics.get_last_internet_path_filename(), "r")
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

    local lossV6 = utils.get_loss("2600::")
    if lossV6 ~= "100" then
        result.IPv6 = { working=true }
    else
      result.IPv6 = { working=false }
    end
    local lookup_output = utils.is_nslookup_working()
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
    local traffic = lutils.unsafe_shell("iw "..iface.." station get "..mac.." | grep bytes | awk '{ print $3}'")
    if traffic == "" or traffic == nil then
        return {status="error", error={msg="No interface found.", code="1"}}
    end
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
