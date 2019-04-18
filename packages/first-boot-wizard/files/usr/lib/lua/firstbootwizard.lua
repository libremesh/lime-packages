#!/usr/bin/lua

-- FIRSTBOOTWIZARD
-- get_all_networks: Perform scan and fetch configurations
-- apply_config: Set lime-default and apply configurations
-- apply_user_configs: Set a new mesh network
-- check_scan_file: Return /tmp/scanning status
-- check_lock_file: Check /etc/first_run status
-- read_configs: Return scan results

local json = require 'luci.json'
local ft = require('firstbootwizard.functools')
local utils = require('firstbootwizard.utils')
local iwinfo = require("iwinfo")
local wireless = require("lime.wireless")
local fs = require("nixio.fs")
local uci = require("uci")
local nixio = require "nixio"

-- Write lock file at begin
function start_scan_file()
    local file = io.open("/tmp/scanning", "w")
    file:write("true")
    file:close()
end

-- Remove old results
function clean_tmp()
    utils.execute('rm /tmp/lime-defaults__*')
end

-- Save working copy of wireless
function backup_wifi_config()
    utils.execute("cp /etc/config/wireless /tmp/wireless-temp")
end

-- Get networks in 5ghz radios
function get_networks()
    -- Get all radios
    local radios = ft.map(utils.extract_prop(".name"), wireless.scandevices())
    -- Get only 5ghz radios
    local radios_5ghz = ft.filter(wireless.is5Ghz,  radios)
    -- Convert radios to phys (get a list of phys from radio devices)
    local phys = ft.map(utils.extract_phys_from_radios, radios_5ghz)
    -- Scan networks in phys and format result
    local networks = ft.map(
        function(phy)
            local nets = iwinfo.nl80211.scanlist(phy)
            return ft.map(utils.add_prop("phy_idx", utils.phy_to_idx(phy)), nets)
        end, phys)
    -- Merge results
    networks = ft.reduce(ft.flatTable, networks, {})
    -- Filter only remote mesh and ad-hoc networks
    networks = ft.filter(utils.filter_mesh, networks)
    networks = ft.filter(utils.not_own_network, networks)
    -- Sort by channel and mode
    networks = utils.sort_by_channel_and_mode(networks)
    return networks
end

-- Calc link local address and download lime-default
function get_config(mesh_network)
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local dev_id = 'wlan'..mesh_network['phy_idx']..'-'..mode
    local stations = {}
    local linksLocalIpv6 = {}
    -- Setup wireless interface
    setup_wireless(mesh_network)
    -- Check if connected if not sleep some more until connected or ignore if 10s passed
    utils.is_connected(dev_id)
    -- Calc ipv6
     stations = utils.get_stations_macs(dev_id)
    local linksLocalIpv6 = ft.map(utils.eui64, stations)
    local hosts = ft.map(utils.append_network(dev_id), linksLocalIpv6)
    -- Add aditional info
    local data = ft.map(function(host)
    	return { host = host, signal = mesh_network.signal, ssid = mesh_network.ssid }
    end, hosts)
    -- Try to fetch remote config file
    configs = ft.map(fetch_config, data)
    -- Return only valid configs
    return ft.filter(function(el) return el ~= nil end, configs)
end

-- Setup wireless 
function setup_wireless(mesh_network)
    local phy_idx = mesh_network["phy_idx"]
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local device_name = "lm_wlan"..phy_idx.."_"..mode.."_radio"..phy_idx
    local uci_cursor = uci.cursor()
    -- Get acutal settings
    local current_channel = uci_cursor:get("wireless", 'radio'..phy_idx, "channel")
    local current_mode = uci_cursor:get("wireless", device_name, "mode")
    -- Avoid unnecessary configuration changes
    if  ( tonumber(current_channel) == tonumber(mesh_network.channel) and current_mode == mode ) then
        return
    end
    -- Remove current wireless setup
    uci_cursor:foreach("wireless", "wifi-iface", function(entry)
        if entry['.name'] == device_name then
            uci_cursor:delete("wireless", entry['.name']) 
        end
    end)
    -- Set new wireless configuration
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
    utils.execute("wifi down radio"..phy_idx.."; wifi up radio"..phy_idx)
    os.execute("sleep 10s")
end

-- Fetch remote configuration and save result
function fetch_config(data)
    local host = data.host
    local signal = data.signal
    local ssid = data.ssid
    -- TODO : Fetch hostname form /cgi-bin/hostname
    local filename = "/tmp/lime-defaults__signal__"..(signal * -1).."__ssid__"..ssid.."__host__"..host
    os.execute("/bin/wget http://["..host.."]/lime-defaults -O "..filename)
    return utils.file_exists(filename) and filename or nil
end

-- Restore previus wireless configuration
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

-- Reset lime config file
function clean_lime_config()
    utils.execute("rm /etc/config/lime")
    local f = io.open("/etc/config/lime", "w")
    local command = [[
        config lime system
        config lime network
        config lime wifi
    ]]
    local s = f:write(command)
    f:close()
end

-- Apply configuraation permanenty
-- TODO: check if config is valid
-- TODO: use safe-reboot
function apply_config(file)
    local filePath = "/tmp/"..file
    check_utils.file_exists(filePath)
    -- Clean previus lime configuration and replace lime-defaults
    clean_lime_config()
    utils.execute("cp "..filePath.." /etc/config/lime-defaults")    
    -- Run lime-config as first boot
    utils.execute("/rom/etc/uci-defaults/91_lime-config")
    -- Remove FBW lock file
    utils.execute("rm /etc/first_run")
    -- Apply new configuration
    os.execute("(( /usr/bin/lime-config && /usr/bin/lime-apply && reboot 0<&- &>/dev/null &) &)")
end

-- Remove scan lock file
local function end_scan()
    local file = io.open("/tmp/scanning", "w")
    file:write("false")
    file:close()
end

-- Read scan status
function check_scan_file()
    local file = io.open("/tmp/scanning", "r")
    if(file == nil) then
        return nil
    end
    return assert(file:read("*a"), nil)
end

-- Read scan lock file
function check_lock_file()
    local file = io.open("/etc/first_run", "r")
    if(file == nil) then
        return false
    end
    return true
end

-- Remove lock file
function remove_lock_file()
    utils.execute("rm /etc/first_run")
end

-- List downloaded lime-defaults
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

-- Apply configuration for a new network ( used in ubus daemon)
function apply_user_configs(configs)
    -- Mesh network name
    local name = configs.ssid
    -- Save changes in lime-defaults
    local uci_cursor = uci.cursor()
    uci_cursor:set("lime-defaults", 'wifi', 'ap_ssid', name)
    uci_cursor:set("lime-defaults", 'wifi', 'apname_ssid', name..'/%H')
    uci_cursor:set("lime-defaults", 'wifi', 'adhoc_ssid', 'LiMe.%H')
    uci_cursor:set("lime-defaults", 'wifi', 'ieee80211s_mesh_id', 'LiMe')
    uci_cursor:commit("lime-defaults")
    -- Apply new configuration and reboot
    clean_lime_config()
    utils.execute("/rom/etc/uci-defaults/91_lime-config")
    utils.execute("rm /etc/first_run")
    os.execute("(( /usr/bin/lime-config && /usr/bin/lime-apply && reboot 0<&- &>/dev/null &) &)")
    return { configs = configs }
end

-- Scan for networks and fetch configurations files
function get_all_networks()
    local networks = {}
    local configs = {}

    -- Add lock file
    start_scan_file()
    -- Clear previus scans
    clean_tmp()
    -- Set wireless backup
    backup_wifi_config()
    -- Get mesh networks
    networks = get_networks()
    -- Get configs files
    configs = utils.unpack_table(ft.map(get_config, networks))
    -- Restore previus wireless configuration
    restore_wifi_config()
    -- Remove lock file
    end_scan()
    -- Return configs files names
    return configs
end