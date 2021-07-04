local uci = require("uci")
local pirania_config = 'pirania'

local ucicursor = uci.cursor()

local config = {
    db_path = ucicursor:get(pirania_config, 'base_config', 'db_path'),
    hooksDir = ucicursor:get(pirania_config, 'base_config', 'hooks_path'),
    prune_expired_for_days = ucicursor:get(pirania_config, 'base_config', 'prune_expired_for_days')
}

return config
