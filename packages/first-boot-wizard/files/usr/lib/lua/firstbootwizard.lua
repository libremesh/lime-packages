#!/usr/bin/lua

require "ubus"
local json = require 'luci.json'
local ft = require('firstbootwizard.functools')
local iwinfo = require("iwinfo")
local wireless = require("lime.wireless")
local fs = require("nixio.fs")
local uci = require("uci")
local nixio = require "nixio"

local conn = ubus.connect()
if not conn then
    error("Failed to connect to ubus")
end

local function execute(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    return s
end

local function eui64(mac)
    local cmd = [[
    function eui64 {
        mac="$(echo "$1" | tr -d : | tr A-Z a-z)"
        mac="$(echo "$mac" | head -c 6)fffe$(echo "$mac" | tail -c +7)"
        let "b = 0x$(echo "$mac" | head -c 2)"
        let "b ^= 2"
        printf "%02x" "$b"
        echo "$mac" | tail -c +3 | head -c 2
        echo -n :
        echo "$mac" | tail -c +5 | head -c 4
        echo -n :
        echo "$mac" | tail -c +9 | head -c 4
        echo -n :
        echo "$mac" | tail -c +13
    }
    echo -n `eui64 ]]..mac..'`'
    return 'fe80::'..execute(cmd)
end

function file_exists(filename)
    return fs.stat(filename, "type") == "reg"
end

local function check_file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end  

local function split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- splits a multiline string in a list of strings, one per line
local function lsplit(mlstring)
    return split(mlstring, "\n")
end

local function phy_to_idx(phy)
    local substr = string.gsub(phy, "phy", "")
    return tonumber(substr)
end

function get_networks()
    local thisBssids = {}
    local wirelessConfig = conn:call("network.wireless", "status", {})
    local allRadios = wireless.scandevices()
    -- nixio.syslog("crit", "FBW radios "..json.encode(allRadios))
    local all_networks = {}
    local phys = {}
    for _, radio in pairs (allRadios) do
        if wireless.is5Ghz(radio[".name"]) then
            local phyIndex = radio[".name"].sub(radio[".name"], -1)
            phys[#phys+1] = "phy"..phyIndex
            -- nixio.syslog("crit", "FBW thisBssids"..json.encode(wirelessConfig["radio"..phyIndex]))
            table.insert(thisBssids, wirelessConfig["radio"..phyIndex].interfaces[1].config.bssid)
        end
    end
    -- -- nixio.syslog("crit", "FBW thisBssids"..json.encode(thisBssids))
    -- -- nixio.syslog("crit", "FBW phys"..json.encode(phys))
    for idx, phy in pairs(phys) do
        networks = iwinfo.nl80211.scanlist(phy)
        -- nixio.syslog("crit", "FBW networs"..json.encode(networks))
        for k,network in pairs(networks) do
            if network.signal ~= -256 then
                network["phy"] = phy
                network["phy_idx"] = phy_to_idx(phy)
                all_networks[#all_networks+1] = network
            end
        end
    end
    return all_networks
end

function backup_wifi_config()
    execute("cp /etc/config/wireless /tmp/wireless-temp")
end

function restore_wifi_config()
    execute("cp /tmp/wireless-temp /etc/config/wireless")
    local allRadios = wireless.scandevices()
    for _, radio in pairs (allRadios) do
        if wireless.is5Ghz(radio[".name"]) then
            local phyIndex = radio[".name"].sub(radio[".name"], -1)
            execute("wifi down radio"..phyIndex.."; wifi up radio"..phyIndex)
        end
    end
end

function connect(mesh_network)
    local phy_idx = mesh_network["phy_idx"]
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local device_name = "lm_wlan"..phy_idx.."_"..mode.."_radio"..phy_idx

    -- nixio.syslog("crit", "FBW Connection to "..mesh_network.ssid)
    -- nixio.syslog("crit", "FBW in "..device_name)

    local uci_cursor = uci.cursor()

    local current_channel = uci_cursor:get("wireless", 'radio'..phy_idx, "channel")
    local current_mode = uci_cursor:get("wireless", device_name, "mode")

    -- Avoid unnecessary configuration changes
    if(current_channel == mesh_network.channel or current_mode == mode) then
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

    -- nixio.syslog("crit", "FBW applying WIFI ")
    -- apply wifi config
    execute("wifi down radio"..phy_idx.."; wifi up radio"..phy_idx)
end

function fetch_config(data)
    print(json.encode(data))
    local host = data.host
    local signal = data.signal
    local ssid = data.ssid
    local filename = "/tmp/lime-defaults__signal__"..(signal * -1).."__ssid__"..ssid.."__host__"..host
    -- nixio.syslog("crit", "FBW fetching "..host)
    os.execute("sleep 5s")
    os.execute("/bin/wget http://["..host.."]/lime-defaults -O "..filename.." &")
    return file_exists(filename) and filename or nil
end

function get_stations_macs(network)
    -- nixio.syslog("crit", "FBW get_stations_macs "..network)
    return lsplit(execute('iw dev '..network..' station dump | grep ^Station | cut -d\\  -f 2'))
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
	    print(file)
            table.insert(result, {
                ap = string.gsub(ap, "\"", ""),
                file = file
            })
        end
    end
    return result
end

function read_file(file)
    local lines = lines_from("/tmp/"..file)
    -- for k,v in pairs(lines) do
    --     -- nixio.syslog("crit", 'line[' .. k .. ']'..v)
    -- end
    return lines
end

local function tableEmpty(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function get_config(mesh_network)
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local dev_id = 'wlan'..mesh_network['phy_idx']..'-'..mode
    -- nixio.syslog("crit", "FBW MESH_NETWORK "..json.encode(mesh_network))
    connect(mesh_network)
    -- check if connected if not sleep some more until connected or ignore if 10s passed
    local isAssociated = iwinfo.nl80211.assoclist(dev_id)
    local i = 0
    while (tableEmpty(isAssociated)) and i < 5 do
        isAssociated = iwinfo.nl80211.assoclist(dev_id)
        -- nixio.syslog("crit", "FBW trying to associate "..json.encode(isAssociated)..i)
        i = i + 1
        os.execute("sleep 5s")
    end
    local stations = get_stations_macs(dev_id)
    
    local append_network = ft.curry(function (s1, s2) return s2..'%'..s1 end, 2) (dev_id)
    local linksLocalIpv6 = ft.map(eui64, stations)
    local hosts = ft.map(append_network, linksLocalIpv6)
    -- nixio.syslog("crit", "FBW DEV ID "..json.encode(dev_id))
    -- nixio.syslog("crit", "FBW LINKS LOCALS "..json.encode(linksLocalIpv6))
    -- nixio.syslog("crit", "FBW HOSTS "..json.encode(hosts))
    
    local function addData (host)
    	return {host = host, signal = mesh_network.signal, ssid = mesh_network.ssid }
    end

    local data = ft.map(addData, hosts)

    configs = ft.map(fetch_config, data)
    return ft.filter(function(el) return el ~= nil end, configs)
end

function unpack_table(t)
    local unpacked = {}
    for k,v in ipairs(t) do
        for sk, sv in ipairs(v) do
            unpacked[#unpacked+1] = sv
        end
    end
    return unpacked
end

function hash_file(file)
    return execute("md5sum "..file.." | awk '{print $1}'")
end

function are_files_different(file1, file2)
    return hash_file(file1) ~= hash_file(file2)
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
    check_file_exists(filePath)
    -- nixio.syslog("crit", "FBW FILE EXISTS ")
    execute("rm /etc/config/lime")
    execute("cp "..filePath.." /etc/config/lime-defaults")
    -- nixio.syslog("crit", "FBW FILE COPIED ")
    clean_lime_config()
    -- nixio.syslog("crit", "FBW LIME CONFIG CLEANED ")
    execute("/rom/etc/uci-defaults/91_lime-config")
    execute("rm /etc/first_run")
    -- nixio.syslog("crit", "APPLY CONFIGS ")
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
    execute("rm /etc/first_run")
end

function apply_user_configs(configs)
    local name = configs.ssid
    local uci_cursor = uci.cursor()
    -- nixio.syslog("crit", "FBW apply_user_configs ssid "..ssid)
    uci_cursor:set("lime-defaults", 'wifi', 'ap_ssid', name)
    uci_cursor:set("lime-defaults", 'wifi', 'apname_ssid', name..'/%H')
    uci_cursor:set("lime-defaults", 'wifi', 'adhoc_ssid', 'LiMe.'..name..'/%H')
    uci_cursor:set("lime-defaults", 'wifi', 'ieee80211s_mesh_id', 'LiMe.'..name..'/%H')
    uci_cursor:commit("lime-defaults")

    -- Apply config and reboot
    execute("rm /etc/config/lime")
    clean_lime_config()
    execute("/rom/etc/uci-defaults/91_lime-config")
    execute("rm /etc/first_run")
    os.execute("(( /usr/bin/lime-config && /usr/bin/lime-apply && reboot 0<&- &>/dev/null &) &)")

    return { configs = configs }
end

local function printParam(text,campo) 
    return function(objeto) 
        -- nixio.syslog("crit", text..': '..objeto[campo])
    end
end

function sortNetworks(networks)
    networks = ft.splitBy('mode')(networks)
    networks = ft.map(ft.sortBy('channel'), networks)
    networks = ft.reduce(ft.flatTable,networks, {})
    return networks
end

function clearTmp()
    execute('rm /tmp/lime-defaults__*')
end

function get_all_networks()
    -- Add lock file
    start_scan_file()
    -- Clear previus scans
    clearTmp()
    -- Set wireless backup
    backup_wifi_config()
    -- Get all networks
    local networks = get_networks()
    -- Filter only mesh and ad-hoc
    local all_mesh = ft.filter(filter_mesh, networks)
    -- Sort by channel and mode
    all_mesh = sortNetworks(all_mesh)
    -- Get configs files
    local configs = unpack_table(ft.map(get_config, all_mesh))
    -- Restore previus wireless configuration
    restore_wifi_config()
    -- Remove lock file
    stop_scan()
    -- Return configs files names
    return configs
end