#!/bin/lua
local nixio = require('nixio')

local utils = {}

function utils.log(...)
    nixio.syslog(...)
end

--! Pure Lua URL encoding/decoding utilities
--! Replaces lucihttp dependency for OpenWrt compatibility

--! Convert a character to its percent-encoded hex representation
local function char_to_hex(c)
    return string.format("%%%02X", string.byte(c))
end

--! Convert a percent-encoded hex pair back to its character
local function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

local function checkIfIpv4(ip)
    if ip == nil or type(ip) ~= "string" then
        return 0
    end
    --! check for format 1.11.111.111 for ipv4
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
        local ipv6macCommand = "ip neigh | grep "..ip_address.." | awk -F ' ' '{print $5}' | head -n 1"
        fd6 = io.popen(ipv6macCommand, 'r')
        ipv6mac = fd6:read('*l')
        fd6:close()
        local ipv4cCommand = "cat /proc/net/arp | grep "..ipv6mac.." | awk -F ' ' '{print $1}' | head -n 1"
        fd4 = io.popen(ipv4cCommand, 'r')
        ipv4 = fd4:read('*l')
        fd4:close()
        local res = {}
        res.ip = ipv4
        res.mac = ipv6mac
        return res
    end
end

--! URL-encode a string value
--! Encodes all characters except alphanumeric, hyphen, underscore, period, and tilde
--! Spaces are encoded as %20 (not +) for broader compatibility
function utils.urlencode(value)
    if value == nil then
        return nil
    end
    local str = tostring(value)
    --! Encode all characters except unreserved ones (RFC 3986)
    --! Unreserved: A-Z a-z 0-9 - _ . ~
    str = str:gsub("([^%w%-_%.~])", char_to_hex)
    return str
end

--! URL-decode a string value
--! Decodes percent-encoded sequences and optionally converts + to space
function utils.urldecode(value)
    if value == nil then
        return nil
    end
    local str = tostring(value)
    --! Convert + to space (common in query strings)
    str = str:gsub("+", " ")
    --! Decode percent-encoded sequences
    str = str:gsub("%%(%x%x)", hex_to_char)
    return str
end

--! Parse URL-encoded query string into a table
--! From given url or string. Returns a table with urldecoded values.
--! Simple parameters are stored as string values associated with the parameter
--! name within the table. Parameters with multiple values are stored as array
--! containing the corresponding values.
function utils.urldecode_params(url, tbl)
    local params = tbl or {}

    if url == nil then
        return params
    end

    --! Extract query string part (after ?)
    local query = url:match("[^?]*$") or ""

    --! Parse key=value pairs separated by & or ;
    for pair in query:gmatch("[^&;]+") do
        local key, value = pair:match("^([^=]+)=?(.*)")
        if key then
            key = utils.urldecode(key)
            value = utils.urldecode(value) or ""

            --! Handle multiple values for same key
            if params[key] then
                --! Convert to array if not already
                if type(params[key]) ~= "table" then
                    params[key] = { params[key] }
                end
                table.insert(params[key], value)
            else
                params[key] = value
            end
        end
    end

    return params
end

return utils
