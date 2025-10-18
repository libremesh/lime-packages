local fs = require('nixio.fs')
local utils = require('lime.utils')
local config = require('lime.config')

local read_for_access = {}

function uptime_s()
    return math.floor(utils.uptime_s())
end

function read_for_access.set_workdir(workdir)
    if not utils.file_exists(workdir) then
        os.execute('mkdir -p ' .. workdir)
    end
    if fs.stat(workdir, "type") ~= "dir" then
        error("Can't configure workdir " .. workdir)
    end
    read_for_access.AUTH_MACS_FILE = workdir .. '/auth_macs'
    read_for_access.AUTH_IPS_FILE = workdir .. '/auth_ips'
end

read_for_access.set_workdir('/tmp/pirania/read_for_access')

function read_for_access.authorize_mac(mac, ip)
    local uci = config.get_uci_cursor()
    local duration = uci:get("pirania", "read_for_access", "duration_m")
    local timestamp = uptime_s() + tonumber(duration) * 60
    local function update_or_append(file, key, timestamp)
        if not utils.file_exists(file) or not io.open(file):read("*a"):match(key) then
            local ofile = io.open(file, 'a')
            ofile:write(key .. ' ' .. timestamp .. '\n')
            ofile:close()
        else
            local content = utils.read_file(file)
            content = content:gsub("(" .. key .. ") %d+", "%1 " .. timestamp)
            utils.write_file(file, content)
        end
    end

    update_or_append(read_for_access.AUTH_MACS_FILE, mac, timestamp)
    update_or_append(read_for_access.AUTH_IPS_FILE, ip, timestamp
    -- redirects stdout and stderr to /dev/null to not trigger 502 Bad Gateway after read for access portal
    os.execute('/usr/bin/captive-portal update > /dev/null 2>&1')
end

function read_for_access.get_authorized_macs()
    local result = {}
    local current_time = uptime_s()
    if not utils.file_exists(read_for_access.AUTH_MACS_FILE) then
        return result
    end
    for line in io.lines(read_for_access.AUTH_MACS_FILE) do
        local words = {}
        for w in line:gmatch("%S+") do table.insert(words, w) end
        if tonumber(words[2]) > current_time then
            table.insert(result, words[1])
        end
    end
    return result
end

function read_for_access.get_authorized_ips()
    local result = {}
    local current_time = uptime_s()
    if not utils.file_exists(read_for_access.AUTH_IPS_FILE) then
        return result
    end
    for line in io.lines(read_for_access.AUTH_IPS_FILE) do
        local words = {}
        for w in line:gmatch("%S+") do table.insert(words, w) end
        if tonumber(words[2]) > current_time then
            table.insert(result, words[1])
        end
    end
    return result
end

return read_for_access
