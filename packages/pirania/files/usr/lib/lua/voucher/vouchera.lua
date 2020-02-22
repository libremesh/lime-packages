#!/bin/lua

local dba = require('voucher.db')
local logic = require('voucher.logic')

_module = {}

function _module.init(config)
    if config == nil then
        config = require('voucher.config')
    end

    local vouchera = {}
    vouchera.config = config
    vouchera.db = dba.load(config.db)
    vouchera._initialized = true

    function vouchera.is_mac_valid(mac)
        return logic.check_mac_validity(vouchera.db, mac)
    end

    function vouchera.is_valid(secret)
        return logic.check_voucher_validity(secret, vouchera.db)
    end

	function vouchera.create_with_expiration()
        return nil
    end

    function vouchera.create_with_duration()
        return nil
    end

    function vouchera.auth(mac, voucher)
    end

    return vouchera
end


return _module
