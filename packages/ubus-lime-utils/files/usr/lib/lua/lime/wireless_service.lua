local utils = require('lime.utils')
local config = require('lime.config')
local wireless = require('lime.wireless')

local wireless_service = {}
wireless_service.AP_BAND = '2ghz' -- TODO: grab from uci config


local function get_node_ap_data(is_admin)
    local result = {}
    local cfg = wireless.get_band_config(wireless_service.AP_BAND)
    result.enabled = utils.has_value(cfg.modes, 'apname')
    result.has_password = (cfg.apname_encryption and
                          cfg.apname_encryption ~= "none")
    result.password = is_admin and cfg.apname_key or nil
    result.ssid = wireless.resolve_ssid(cfg.apname_ssid)
    return result
end

local function get_community_ap_data()
    local result = {}
    local cfg = wireless.get_band_config(wireless_service.AP_BAND)
    local community_cfg = wireless.get_community_band_config(wireless_service.AP_BAND)
    result.enabled = utils.has_value(cfg.modes, 'ap')
    result.ssid = wireless.resolve_ssid(cfg.ap_ssid)
    result.community = {}
    result.community.enabled = utils.has_value(community_cfg.modes, 'ap')
    return result
end

function wireless_service.get_access_points_data(is_admin)
    local result = {}
    result.node_ap = get_node_ap_data(is_admin)
    result.community_ap = get_community_ap_data()
    return result
end

function wireless_service.set_node_ap(has_password, password)
    local config = {}
    config.apname_encryption = has_password and 'psk2' or 'none'
    config.apname_key = password or nil
    wireless.set_band_config(wireless_service.AP_BAND, config)
end

function wireless_service.set_community_ap(enabled)
    if enabled then
        wireless.add_band_mode(wireless_service.AP_BAND, 'ap')
    else
        wireless.remove_band_mode(wireless_service.AP_BAND, 'ap')
    end
end

return wireless_service
