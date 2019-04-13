#!/usr/bin/lua

local json = require 'luci.json'
local ft = require('firstbootwizard.functools')
local utils = require('firstbootwizard.utils')
local iwinfo = require("iwinfo")
local wireless = require("lime.wireless")
local fs = require("nixio.fs")
local uci = require("uci")
local nixio = require "nixio"

function get_networks()
    -- Get all radios
    local radios = ft.map(utils.extract_prop(".name"), wireless.scandevices())
    -- Get only 5ghz radios
    local radios_5ghz = ft.filter(wireless.is5Ghz,  radios)
    -- Convert radios to phys
    local phys = ft.map(utils.radio_to_phy, radios_5ghz)
    -- Scan networks in phys and format result
    local networks = ft.map(
        function(phy) 
            local nets = iwinfo.nl80211.scanlist(phy)
            return ft.map(utils.add_prop("phy_idx", utils.phy_to_idx(phy)), nets)
        end, phys)
    -- Merge results
        networks = ft.reduce(ft.flatTable, networks, {})
    -- Return all networks found in 5ghz
    return networks
end

function backup_wifi_config()
    utils.execute("cp /etc/config/wireless /tmp/wireless-temp")
end

function restore_wifi_config()
    utils.execute("cp /tmp/wireless-temp /etc/config/wireless")
    local allRadios = wireless.scandevices()
    for _, radio in pairs (allRadios) do
        if wireless.is5Ghz(radio[".name"]) then
            local phyIndex = radio[".name"].sub(radio[".name"], -1)
            utils.execute("wifi down radio"..phyIndex.."; wifi up radio"..phyIndex)
        end
    end
end

function connect(mesh_network)
    local phy_idx = mesh_network["phy_idx"]
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local device_name = "lm_wlan"..phy_idx.."_"..mode.."_radio"..phy_idx

    local uci_cursor = uci.cursor()

    local current_channel = uci_cursor:get("wireless", 'radio'..phy_idx, "channel")
    local current_mode = uci_cursor:get("wireless", device_name, "mode")

    -- Avoid unnecessary configuration changes
    if(current_channel == mesh_network.channel and current_mode == mode) then
        return
    end

    -- remove networks
    uci_cursor:foreach("wireless", "wifi-iface", function(entry)
        if entry['.name'] == device_name then
            uci_cursor:delete("wireless", entry['.name']) 
        end
    end)

    -- set wifi config
    uci_cursor:set("wireless", 'radio'..phy_idx, "channel", mesh_network.channel)
    uci_cursor:set("wireless", device_name, "wifi-iface")
    uci_cursor:set("wireless", device_name, "device", 'radio'..phy_idx)
    uci_cursor:set("wireless", device_name, "ifname", 'wlan'..phy_idx..'-'..mode)
    uci_cursor:set("wireless", device_name, "network", 'lm_net_wlan'..phy_idx..'_'..mode)
    uci_cursor:set("wireless", device_name, "distance", '1000')
    uci_cursor:set("wireless", device_name, "mode", mode)
    uci_cursor:set("wireless", device_name, "mesh_id", 'LiMe')
    uci_cursor:set("wireless", device_name, "ssid", 'LiMe')
    uci_cursor:set("wireless", device_name, "mesh_fwding", '0')
    uci_cursor:set("wireless", device_name, "bssid", 'ca:fe:00:c0:ff:ee')
    uci_cursor:set("wireless", device_name, "mcast_rate", '24000')

    uci_cursor:commit("wireless")

    -- apply wifi config
    utils.execute("wifi down radio"..phy_idx.."; wifi up radio"..phy_idx)
end

function fetch_config(data)
    print(json.encode(data))
    local host = data.host
    local signal = data.signal
    local ssid = data.ssid
    local filename = "/tmp/lime-defaults__signal__"..(signal * -1).."__ssid__"..ssid.."__host__"..host
    os.execute("sleep 5s")
    os.execute("/bin/wget http://["..host.."]/lime-defaults -O "..filename.." &")
    return utils.file_exists(filename) and filename or nil
end

function get_stations_macs(network)
    return utils.lsplit(utils.execute('iw dev '..network..' station dump | grep ^Station | cut -d\\  -f 2'))
end

local function getAp(path)
    local uci_cursor = uci.cursor("/tmp")
    local ap_ssid = uci_cursor:get(path, "wifi", "ap_ssid")
    if ap_ssid ~= nil then
	return ap_ssid
    end
    return ""
end

function read_configs()
    local tempFiles = fs.dir("/tmp/")
    local result = {}
    for file in tempFiles do
        if (file ~= nil and file:sub(1, 12) == "lime-default") then
            local ap = getAp(file)
            table.insert(result, {
                ap = string.gsub(ap, "\"", ""),
                file = file
            })
        end
    end
    return result
end

function get_config(mesh_network)
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local dev_id = 'wlan'..mesh_network['phy_idx']..'-'..mode
    connect(mesh_network)
    -- check if connected if not sleep some more until connected or ignore if 10s passed
    local isAssociated = iwinfo.nl80211.assoclist(dev_id)
    local i = 0
    while (utils.tableEmpty(isAssociated)) and i < 5 do
        isAssociated = iwinfo.nl80211.assoclist(dev_id)
        i = i + 1
        os.execute("sleep 5s")
    end
    local stations = get_stations_macs(dev_id)
    
    local append_network = ft.curry(function (s1, s2) return s2..'%'..s1 end, 2) (dev_id)
    local linksLocalIpv6 = ft.map(utils.eui64, stations)
    local hosts = ft.map(append_network, linksLocalIpv6)
   
    local function addData (host)
    	return {host = host, signal = mesh_network.signal, ssid = mesh_network.ssid }
    end

    local data = ft.map(addData, hosts)

    configs = ft.map(fetch_config, data)
    return ft.filter(function(el) return el ~= nil end, configs)
end




function clean_lime_config()
    local f = io.open("/etc/config/lime", "w")
    local command = [[
        config lime system
        config lime network
        config lime wifi
    ]]
    local s = f:write(command)
    f:close()
end

function apply_config(file)
    -- TODO: check if config is valid
    local filePath = "/tmp/"..file
    check_utils.file_exists(filePath)
    utils.execute("rm /etc/config/lime")
    utils.execute("cp "..filePath.." /etc/config/lime-defaults")
    clean_lime_config()
    utils.execute("/rom/etc/uci-defaults/91_lime-config")
    utils.execute("rm /etc/first_run")
    os.execute("(( /usr/bin/lime-config && /usr/bin/lime-apply && reboot 0<&- &>/dev/null &) &)")
end

function filter_mesh(n)
    return n.mode == "Ad-Hoc" or n.mode == "Mesh Point"
end

local function start_scan_file()
    local file = io.open("/tmp/scanning", "w")
    file:write("true")
    file:close()
end

local function stop_scan()
    local file = io.open("/tmp/scanning", "w")
    file:write("false")
    file:close()
end

function check_scan_file()
    local file = io.open("/tmp/scanning", "r")
    if(file == nil) then
        return nil
    end
    return assert(file:read("*a"), nil)
end

function check_lock_file()
    local file = io.open("/etc/first_run", "r")
    if(file == nil) then
        return false
    end
    return true
end

function remove_lock_file()
    utils.execute("rm /etc/first_run")
end

function apply_user_configs(configs)
    local name = configs.ssid
    local uci_cursor = uci.cursor()
    uci_cursor:set("lime-defaults", 'wifi', 'ap_ssid', name)
    uci_cursor:set("lime-defaults", 'wifi', 'apname_ssid', name..'/%H')
    uci_cursor:set("lime-defaults", 'wifi', 'adhoc_ssid', 'LiMe.'..name..'/%H')
    uci_cursor:set("lime-defaults", 'wifi', 'ieee80211s_mesh_id', 'LiMe.'..name..'/%H')
    uci_cursor:commit("lime-defaults")

    -- Apply config and reboot
    utils.execute("rm /etc/config/lime")
    clean_lime_config()
    utils.execute("/rom/etc/uci-defaults/91_lime-config")
    utils.execute("rm /etc/first_run")
    os.execute("(( /usr/bin/lime-config && /usr/bin/lime-apply && reboot 0<&- &>/dev/null &) &)")

    return { configs = configs }
end

function sortNetworks(networks)
    networks = ft.splitBy('mode')(networks)
    networks = ft.map(ft.sortBy('channel'), networks)
    networks = ft.reduce(ft.flatTable,networks, {})
    return networks
end

function clearTmp()
    utils.execute('rm /tmp/lime-defaults__*')
end

function get_all_networks()
    local networks = {}
    local all_mesh = {}
    local configs = {}

    -- Add lock file
    start_scan_file()
    -- Clear previus scans
    clearTmp()
    -- Set wireless backup
    backup_wifi_config()
    -- Get all networks
    networks = get_networks()
    -- Filter only remote mesh and ad-hoc networks
    all_mesh = ft.filter(filter_mesh, networks)
    all_mesh = ft.filter(utils.not_own_network, all_mesh)
    -- Sort by channel and mode
    all_mesh = sortNetworks(all_mesh)
    -- Get configs files
    configs = utils.unpack_table(ft.map(get_config, all_mesh))
    -- Restore previus wireless configuration
    restore_wifi_config()
    -- Remove lock file
    stop_scan()
    -- Return configs files names
    return configs
end