local utils = require('lime.utils')
local config = require('lime.config')

local portal = {}

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



return portal
