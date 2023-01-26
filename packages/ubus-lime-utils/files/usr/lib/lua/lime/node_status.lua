local limewireless = require 'lime.wireless'
local iwinfo = require 'iwinfo'

-- Functions used by get_node_status
local node_status = {}

function node_status.get_station_traffic(params)
    local iface = params.iface
    local mac = params.station_mac
    local result = {}
    local traffic = utils.unsafe_shell(
                        "iw " .. iface .. " station get " .. mac ..
                            " | grep bytes | awk '{ print $3}'")
    local words = {}
    for w in traffic:gmatch("[^\n]+") do table.insert(words, w) end
    local rx = words[1]
    local tx = words[2]
    result.station = mac
    result.rx_bytes = tonumber(rx, 10)
    result.tx_bytes = tonumber(tx, 10)
    result.status = "ok"
    return result
end

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

function node_status.get_most_active()
    local res = {}
    local stations = node_status.get_stations()
    if next(stations) ~= nil then
        local most_active_rx = 0
        local most_active = nil
        for _, station in ipairs(stations) do
            local traffic = utils.unsafe_shell(
                                "iw " .. station.iface .. " station get " ..
                                    station.station_mac ..
                                    " | grep bytes | awk '{ print $3}'")
            local words = {}
            for w in traffic:gmatch("[^\n]+") do
                table.insert(words, w)
            end
            local rx = words[1]
            local tx = words[2]
            station.rx_bytes = tonumber(rx, 10)
            station.tx_bytes = tonumber(tx, 10)
            if station.rx_bytes > most_active_rx then
                most_active_rx = station.rx_bytes
                most_active = station
            end
        end
        local station_traffic = node_status.get_station_traffic({
            iface = most_active.iface,
            station_mac = most_active.station_mac
        })
        most_active.rx_bytes = station_traffic.rx_bytes
        most_active.tx_bytes = station_traffic.tx_bytes
        res = most_active
    end
    return res
end

return node_status