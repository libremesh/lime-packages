local fs = require('nixio.fs')
local utils = require('lime.utils')

local read_for_access = {}

function read_for_access.set_workdir(workdir)
    if not utils.file_exists(workdir) then
        os.execute('mkdir -p ' .. workdir)
    end
    if fs.stat(workdir, "type") ~= "dir" then
        error("Can't configure workdir " .. workdir)
    end
    read_for_access.AUTH_MACS_FILE = workdir .. '/auth_macs'   
end

read_for_access.set_workdir('/tmp/pirania/read_for_access')

function read_for_access.authorize_mac(mac)
    local uci = config.get_uci_cursor()
    local found = false
    if utils.file_exists(read_for_access.AUTH_MACS_FILE) then
        for line in io.lines(read_for_access.AUTH_MACS_FILE) do
            if line:match(mac) then
                found = true
                break
            end
        end
    end
    if not found then
        local duration = uci:get("pirania", "read_for_access", "duration_m")
        local timestamp = utils.uptime_s() + tonumber(duration) * 60
        local ofile = io.open(read_for_access.AUTH_MACS_FILE, 'a')
        ofile:write(mac .. ' ' .. timestamp .. '\n')
        ofile:close()
    end
    os.execute('/usr/bin/captive-portal update')
end

function read_for_access.get_authorized_macs()
    local result = {}
    local with_vouchers
    local current_time = utils.uptime_s()
    if not utils.file_exists(read_for_access.AUTH_MACS_FILE) then
        return result
    end
    for line in io.lines(read_for_access.AUTH_MACS_FILE) do
        words = {}
        for w in line:gmatch("%S+") do table.insert(words, w) end
        if tonumber(words[2]) > current_time then
            table.insert(result, words[1])
        end
    end
    return result
end

return read_for_access
