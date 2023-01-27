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

return node_status