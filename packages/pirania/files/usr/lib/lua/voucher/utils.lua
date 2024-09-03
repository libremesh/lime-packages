#!/bin/lua
local nixio = require('nixio')
local lhttp = require('lucihttp')

local utils = {}

function utils.log(...)
    nixio.syslog(...)
end

local function checkIfIpv4(ip)
    if ip == nil or type(ip) ~= "string" then
        return 0
    end
    -- check for format 1.11.111.111 for ipv4
    local chunks = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if (#chunks == 4) then
        for _,v in pairs(chunks) do
            if (tonumber(v) < 0 or tonumber(v) > 255) then
                return 0
            end
        end
        return true
    else
        return false
    end
end

--! get ipv4 and MAC from a ip_address that could be ipv4 or ipv6
function utils.getIpv4AndMac(ip_address)
    local isIpv4 = checkIfIpv4(ip_address)
    if (isIpv4) then
        local ipv4macCommand = "cat /proc/net/arp | grep "..ip_address.." | awk -F ' ' '{print $4}' | head -n 1"
        fd = io.popen(ipv4macCommand, 'r')
        ipv4mac = fd:read('*l')
        fd:close()
        local res = {}
        res.ip = ip_address
        res.mac = ipv4mac
        return res
    else
        # change from neighbor to neigh or n
        local ipv6macCommand = "ip neigh | grep "..ip_address.." | awk -F ' ' '{print $5}' | head -n 1"
        fd6 = io.popen(ipv6macCommand, 'r')
        ipv6mac = fd6:read('*l')
        fd6:close()
        local ipv4cCommand = "cat /proc/net/arp | grep "..ipv6mac.." | awk -F ' ' '{print $1}' | head -n 1"
        fd4 = io.popen(ipv4Command, 'r')
        ipv4 = fd4:read('*l')
        fd4:close()
        local res = {}
        res.ip = ipv4
        res.mac = ipv6mac
        return res
    end
end

--! from given url or string. Returns a table with urldecoded values.
--! Simple parameters are stored as string values associated with the parameter
--! name within the table. Parameters with multiple values are stored as array
--! containing the corresponding values.
function utils.urldecode_params(url, tbl)
    local parser, name
    local params = tbl or { }

    parser = lhttp.urlencoded_parser(function (what, buffer, length)
        if what == parser.TUPLE then
            name, value = nil, nil
        elseif what == parser.NAME then
            name = lhttp.urldecode(buffer)
        elseif what == parser.VALUE and name then
            params[name] = lhttp.urldecode(buffer) or ""
        end

        return true
    end)

    if parser then
        parser:parse((url or ""):match("[^?]*$"))
        parser:parse(nil)
    end

    return params
end

function utils.urlencode(value)
    if value ~= nil then
        local str = tostring(value)
        return lhttp.urlencode(str, lhttp.ENCODE_IF_NEEDED + lhttp.ENCODE_FULL) or str
    end
    return nil
end

function utils.urldecode(value)
    if value ~= nil then
        local str = tostring(value)
        return lhttp.urldecode(str, lhttp.DECODE_IF_NEEDED) or str
    end
    return nil
end

return utils
