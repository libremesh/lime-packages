local uci = require("uci")
local pirania_config = 'pirania'

local ucicursor = uci.cursor()

local config = {
    db = ucicursor:get(pirania_config, 'base_config', 'db_path'),
    uploadlimit = ucicursor:get(pirania_config, 'base_config', 'uploadlimit'),
    downloadlimit = ucicursor:get(pirania_config, 'base_config', 'downloadlimit'),
    hooksDir = ucicursor:get(pirania_config, 'base_config', 'hooks_path')
}

return config
