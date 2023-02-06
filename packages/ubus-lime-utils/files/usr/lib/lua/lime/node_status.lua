local limewireless = require 'lime.wireless'
local iwinfo = require 'iwinfo'
local utils = require 'lime.utils'

-- Functions used by get_node_status
local node_status = {}

function node_status.get_ips()
    local res = {}
    local ips = utils.unsafe_shell(
                    "ip a s br-lan | grep inet | awk '{ print $1, $2 }'")
    for line in ips:gmatch("[^\n]+") do
        local words = {}
        for w in line:gmatch("%S+") do
            if w ~= "" then table.insert(words, w) end
        end
        local version = words[1]
        local address = words[2]
        if version == "inet6" then
            table.insert(res, {version = "6", address = address})
        else
            table.insert(res, {version = "4", address = address})
        end
    end
    return res
end

function node_status.get_stations()
    local res = {}
    local ifaces = limewireless.mesh_ifaces()
    for _, iface in ipairs(ifaces) do
        local iface_type = iwinfo.type(iface)
        local iface_stations = iface_type and iwinfo[iface_type].assoclist(iface)
        if iface_stations then
            for mac, station in pairs(iface_stations) do
                station['iface'] = iface
                station.station_mac = mac
                table.insert(res, station)
            end
        end
    end
    return res
end

function node_status.get_station_stats(station)
    local iface = station.iface
    local mac = station.station_mac
    local iw_result = utils.unsafe_shell(
                                "iw " .. iface .. " station get " .. mac)
    station.rx_bytes = tonumber(
        string.match(iw_result, "rx bytes:%s+(.-)\n"), 10)
    station.tx_bytes = tonumber(
        string.match(iw_result, "tx bytes:%s+(.-)\n"), 10)
    station.signal = string.match(iw_result, "signal:%s+(.-)\n")
    return station
end

function node_status.get_most_active()
    local res = {}
    local stations = node_status.get_stations()
    if next(stations) ~= nil then
        local most_active = {}
        most_active.rx_bytes = 0
        for _, station in ipairs(stations) do
            local station_stats = node_status.get_station_stats(station)
            if station_stats.rx_bytes > most_active.rx_bytes then
                most_active = station
            end
        end
        res = most_active
    end
    return res
end

function node_status.switch_status()
    local response_ports = node_status.boardjson_get_ports()
    node_status.swconfig_get_link_status(response_ports)
    return response_ports
end

function node_status.boardjson_get_ports()
    local response_ports = {}
    local board = utils.getBoardAsTable()
    for _, role in ipairs(board['switch']['switch0']['roles']) do
        for port_number in string.gmatch(role['ports'], "%S+") do
            if not tonumber(port_number) then
                local n = tonumber(string.match(port_number, "^%d+"))
                table.insert(response_ports, { num = n, role = "cpu", device = role['device']})
            else
                table.insert(response_ports, { num = tonumber(port_number), role = role['role'], device = role['device']})
            end
        end

    end
    return response_ports
end

function node_status.swconfig_get_link_status(ports)
    local function add_link_status(port_number, status)
        for x, obj in pairs(ports) do
            if obj.num == port_number then
               obj["link"] = status
            end
        end
    end

    local swconfig = utils.unsafe_shell("swconfig dev switch0 show")
    local lines = {}
    for line in swconfig:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local port_number
    for i, line in ipairs(lines) do
        if line:match("Port %d:") then
            port_number = tonumber(line:match("Port (%d):"))
        end
        if string.find(line, "link:up") then
            add_link_status(port_number, "up")
        elseif string.find(line, "link:down") then
            add_link_status(port_number, "down")
        end
    end
    return ports
end

return node_status

