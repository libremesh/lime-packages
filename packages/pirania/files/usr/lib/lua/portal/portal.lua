local utils = require('lime.utils')
local config = require('lime.config')
local shared_state = require("shared-state")
local read_for_access = require("read_for_access.read_for_access")

local portal = {}

portal.PAGE_CONTENT_OBJ_PATH = '/etc/pirania/portal.json'

function portal.get_config()
    local uci = config.get_uci_cursor()
    local activated = uci:get("pirania", "base_config", "enabled") == '1'
    local with_vouchers = uci:get("pirania", "base_config", "with_vouchers") == '1'
    return {activated = activated, with_vouchers = with_vouchers}
end

function portal.set_config(activated, with_vouchers)
    local uci = config.get_uci_cursor()

    uci:set("pirania", "base_config", "with_vouchers",
            with_vouchers and "1" or "0")
    if activated then
        uci:set("pirania", "base_config", "enabled", "1")
        uci:commit("pirania")
        utils.unsafe_shell("captive-portal start")
    else
        uci:set("pirania", "base_config", "enabled", "0")
        uci:commit("pirania")
        utils.unsafe_shell("captive-portal stop")
    end
    return true
end

function portal.get_page_content()
    local db = shared_state.SharedStateMultiWriter:new('pirania_persistent'):get()
    if db.portal then
        return db.portal.data
    else
        return utils.read_obj_store(portal.PAGE_CONTENT_OBJ_PATH)
    end
end


function portal.set_page_content(title, main_text, logo, link_title, link_url, background_color)
    local data = {title=title, main_text=main_text, logo=logo, link_title=link_title, link_url=link_url, background_color=background_color}
    local db = shared_state.SharedStateMultiWriter:new('pirania_persistent')
    return db:insert({portal=data})
end

function portal.get_authorized_macs()
    local auth_macs = {}
    local with_vouchers = portal.get_config().with_vouchers
    if with_vouchers then
        local vouchera = require("voucher.vouchera")
        vouchera.init()
        auth_macs = vouchera.get_authorized_macs()
    else
        auth_macs = read_for_access.get_authorized_macs()
    end
    return auth_macs
end

function portal.get_authorized_ips()
    local auth_ips = {}
    local with_vouchers = portal.get_config().with_vouchers
    if with_vouchers then
        local vouchera = require("voucher.vouchera")
        vouchera.init()
        auth_ips = vouchera.get_authorized_ips()
    else
        auth_ips = read_for_access.get_authorized_ips()
    end
    return auth_ips
end

function portal.update_captive_portal(daemonized)
    if daemonized then
        utils.execute_daemonized('captive-portal update')
    else
	    -- redirects stdout and stderr to /dev/null to not trigger 502 Bad Gateway after voucher portal auth
        os.execute('captive-portal update > /dev/null 2>&1')
    end
end

return portal
