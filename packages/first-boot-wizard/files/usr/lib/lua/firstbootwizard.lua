#!/usr/bin/lua

-- FIRSTBOOTWIZARD
-- get_all_networks: Perform scan and fetch configurations
-- apply_file_config: Set lime-community and apply configurations
-- apply_user_configs: Set a new mesh network
-- check_scan_file: Return /tmp/scanning status
-- is_configured: returns true if FBW has already configured the node
-- mark_as_configured: save the status of FBW as configured (is_configured will return true)
-- read_configs: Return scan results

local json = require 'luci.jsonc'
local ft = require('firstbootwizard.functools')
local utils = require('firstbootwizard.utils')
local iwinfo = require("iwinfo")
local wireless = require("lime.wireless")
local fs = require("nixio.fs")
local config = require("lime.config")
local lutils = require("lime.utils")
local nixio = require "nixio"
local uci = require "uci"

local fbw = {}



fbw.WORKDIR = '/tmp/fbw/'
fbw.HOST_CONFIG_PREFIX = 'lime-community__host__'

utils.execute('mkdir -p ' .. fbw.WORKDIR)

function fbw.log(text)
    nixio.syslog('info', '[FBW] ' .. text)
end

-- Write lock file at begin
function fbw.start_scan_file()
    local file = io.open("/tmp/scanning", "w")
    file:write("true")
    file:close()
end

-- Remove old results
function fbw.clean_tmp()
    utils.execute('rm -f ' .. fbw.WORKDIR .. fbw.HOST_CONFIG_PREFIX .. '*')
end

-- Save working copy of wireless
function fbw.backup_wifi_config()
    utils.execute("cp /etc/config/wireless /tmp/wireless-temp")
end

-- Get networks in 5ghz radios
function fbw.get_networks()
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
    -- Sort by channel and mode
    networks = utils.sort_by_channel_and_mode(networks)
    -- Remove dupicated results in multiradios devices
    networks = utils.only_best(networks)
    return networks
end

-- Get macs from 5ghz radios
function fbw.get_own_macs()
    local radios = ft.map(utils.extract_prop(".name"), wireless.scandevices())
    local radios_5ghz = ft.filter(wireless.is5Ghz,  radios)
    local phys = ft.map(utils.extract_phys_from_radios, radios_5ghz)
    return ft.map(function(phy) return table.concat(wireless.get_phy_mac(phy),":") end, phys)
end

-- Calc link local address and download lime-community
function fbw.get_config(results, mesh_network)
    fbw.log('Calc link local address and download lime-community - '.. json.stringify(mesh_network))
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local dev_id = 'wlan'..mesh_network['phy_idx']..'-'..mode
    local stations = {}
    local linksLocalIpv6 = {}
    -- Setup wireless interface
    fbw.setup_wireless(mesh_network)
    -- Check if connected if not sleep some more until connected or ignore if 10s passed
    utils.is_connected(dev_id)
    -- Get associated stations
    stations = utils.get_stations_macs(dev_id)
    -- Remove own wifi networks
    local own_macs = fbw.get_own_macs()
    stations = ft.filter(utils.not_own_network(own_macs), stations)
    -- Calc ipv6
    local linksLocalIpv6 = ft.map(utils.eui64, stations)
    local hosts = ft.map(utils.append_network(dev_id), linksLocalIpv6)
    -- Add aditional info
    local data = ft.map(function(host)
        return { host = host, signal = mesh_network.signal, ssid = mesh_network.ssid }
    end, hosts)
    data = utils.filter_alredy_scanned(data, results)
    -- Try to fetch remote config file
    local configs = ft.map(fbw.fetch_config, data)
    -- Return only valid configs
    for _, config in pairs(configs) do
        results[config.host] = config
    end
    return results
end

-- Setup wireless 
function fbw.setup_wireless(mesh_network)
    local phy_idx = mesh_network["phy_idx"]
    local mode = mesh_network.mode == "Mesh Point" and 'mesh' or 'adhoc'
    local device_name = "lm_wlan"..phy_idx.."_"..mode.."_radio"..phy_idx
    local uci_cursor = config.get_uci_cursor()
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
function fbw.fetch_config(data)
    fbw.log('Fetch config from '.. json.stringify(data))
    local host = data.host

    local hostname = utils.execute("wget --no-check-certificate http://["..data.host.."]/cgi-bin/hostname -qO - "):gsub("\n", "")
    fbw.log('Hostname found: '.. hostname)
    if (hostname == '') then hostname = host end
    local signal = data.signal
    local ssid = data.ssid
    local filename = fbw.WORKDIR .. fbw.HOST_CONFIG_PREFIX .. hostname

    utils.execute("wget --no-check-certificate http://[" .. data.host .. "]/cgi-bin/lime/lime-community -O " .. filename)
    if not utils.file_exists(filename) then
        -- For backwards compatibility
        utils.execute("wget --no-check-certificate http://[" .. data.host .. "]/lime-community -O " .. filename)
    end

    -- Remove lime-community files that are not yet configured.
    -- For this we asume that no ap_ssid options equals not configured.
    if utils.file_exists(filename) then
        local f = io.open(filename)
        local content = f:read("*a")
        f:close()
        if not content:match("ap_ssid") then
            utils.execute("rm " .. filename)
        end
    end
    return { host = host, filename = filename, success = utils.file_exists(filename) }
end

-- Restore previus wireless configuration
function fbw.restore_wifi_config()
    utils.execute("cp /tmp/wireless-temp /etc/config/wireless")
    local allRadios = wireless.scandevices()
    for _, radio in pairs (allRadios) do
        if wireless.is5Ghz(radio[".name"]) then
            local phyIndex = radio[".name"].sub(radio[".name"], -1)
            utils.execute("wifi down radio"..phyIndex.."; wifi up radio"..phyIndex)
        end
    end
end

-- Apply configuraation permanenty
-- TODO: check if config is valid
-- TODO: use safe-reboot
function fbw.apply_file_config(file, hostname)
    fbw.log('apply_file_config(file=' .. file .. ', hostname=' .. hostname .. ')')
    local uci_cursor = config.get_uci_cursor()
    --Check if lime-community exist
    local filePath = fbw.WORKDIR .. file
    utils.file_exists(filePath)
    -- Format hostname
    hostname = hostname or config.get("system", "hostname")
    -- Clean previus lime configuration and replace lime-community
    config.reset_node_config()
    utils.execute("cp " .. filePath .. " /etc/config/" .. config.UCI_COMMUNITY_NAME)
    -- Run lime-config as first boot and  setup new hostname
    uci_cursor:set(config.UCI_NODE_NAME, "system", "hostname", hostname)
    fbw.end_config()
end

-- Remove scan lock file
function fbw.end_scan()
    local file = io.open("/tmp/scanning", "w")
    file:write("false")
    file:close()
end

-- Read scan status
function fbw.check_scan_file()
    local file = io.open("/tmp/scanning", "r")
    if(file == nil) then
        return nil
    end
    return assert(file:read("*a"), nil)
end

function fbw.is_configured()
    return config.get_bool('system', 'firstbootwizard_configured', false)
end

function fbw.mark_as_configured()
    local uci_cursor = config.get_uci_cursor()
    uci_cursor:set(config.UCI_NODE_NAME, 'system', 'firstbootwizard_configured', 'true')
end

function fbw.is_dismissed()
    return config.get_bool('system', 'firstbootwizard_dismissed', false)
end

function fbw.dismiss()
    local uci_cursor = config.get_uci_cursor()
    uci_cursor:set(config.UCI_NODE_NAME, 'system', 'firstbootwizard_dismissed', 'true')
    uci_cursor:commit(config.UCI_NODE_NAME)
    config.uci_autogen()
end

-- Get config from lime-default file
local function getConfig(path)
    local uci_cursor = uci.cursor(fbw.WORKDIR)
    local config = uci_cursor:get_all(path)
    if config ~= nil then
        return config
    end
    return {}
end

-- List downloaded lime-community
function fbw.read_configs()
    local tempFiles = fs.dir(fbw.WORKDIR)
    local result = {}
    for file in tempFiles do
        if (file ~= nil and file:match("^" .. lutils.literalize(fbw.HOST_CONFIG_PREFIX))) then
            local config = getConfig(file)
            table.insert(result, {
                config = config,
                file = file
            })
        end
    end
    return result
end

-- Apply configuration for a new network ( used in ubus daemon)
function fbw.create_network(ssid, hostname, password)
    fbw.log('apply_file_config(ssid=' .. ssid .. ', hostname=' .. hostname .. ')')
    local uci_cursor = config.get_uci_cursor()

    -- Save changes in lime-community
    if password ~= nil and password ~= '' then
        lutils.set_shared_root_password(password)
    end
    uci_cursor:set("lime-community", 'wifi', 'ap_ssid', ssid)
    uci_cursor:set("lime-community", 'wifi', 'apname_ssid', ssid..'/%H')
    uci_cursor:commit("lime-community")

    -- Apply new configuration and setup hostname
    config.reset_node_config()
    uci_cursor:set("lime-node", 'system', 'hostname', hostname or config.get("system", "hostname"))
    fbw.end_config()
end

function fbw.end_config()
    local uci_cursor = config.get_uci_cursor()
    fbw.mark_as_configured()
    fbw.log('commiting lime-node')
    uci_cursor:commit(config.UCI_NODE_NAME)
    -- Apply new configuration

    os.execute("/usr/bin/lime-config")

    os.execute("reboot")
end

-- Scan for networks and fetch configurations files
function fbw.get_all_networks()
    local networks = {}
    local configs = {}

    fbw.log('Add lock file')
    fbw.start_scan_file()
    fbw.log('Clear previus scans')
    fbw.clean_tmp()
    fbw.log('Set wireless backup')
    fbw.backup_wifi_config()
    fbw.log('Get mesh networks')
    networks = fbw.get_networks()
    fbw.log('Get configs files')
    configs = ft.reduce(fbw.get_config, networks, {})
    fbw.log('Restore previus wireless configuration')
    fbw.restore_wifi_config()
    fbw.log('Remove lock file')
    fbw.end_scan()
    fbw.log('Return configs files names')
    return configs
end

return fbw
