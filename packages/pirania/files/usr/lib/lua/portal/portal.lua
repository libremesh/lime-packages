local utils = require('lime.utils')
local config = require('lime.config')
local shared_state = require("shared-state")

local portal = {}

portal.PAGE_CONTENT_OBJ_PATH = '/etc/pirania/portal.json'

function portal.get_config()
    local uci = config.get_uci_cursor()
    local activated = false
    if uci:get("pirania", "base_config", "enabled") == '1' then
       activated = true
    end
    return {activated = activated, with_vouchers = true}
end

function portal.set_config(activated, with_vouchers)
    local uci = config.get_uci_cursor()

    if activated then
        uci:set("pirania", "base_config", "enabled", "1")
        utils.unsafe_shell("captive-portal start")
    else
        uci:set("pirania", "base_config", "enabled", "0")
        utils.unsafe_shell("captive-portal stop")
    end
    uci:commit("pirania")
    if not with_vouchers then
        return nil, 'with_vouchers=false is not supported yet'
    end
    return true
end

function portal.get_config()
    local uci = config.get_uci_cursor()
    local activated = false
    if uci:get("pirania", "base_config", "enabled") == '1' then
       activated = true
    end
    return {activated = activated, with_vouchers = true}
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

return portal
