#!/usr/bin/lua

utils = {}

-- Avoid this function as soon as you don't need a table
function utils.split(string, sep)
    local ret = {}
    for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
    return ret
end

function utils.hex(x)
    return string.format("%02x", x)
end

function utils.printf(fmt, ...)
    print(string.format(fmt, ...))
end

return utils
