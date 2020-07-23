#!/usr/bin/lua

local config = require("lime.config")
local utils = require("lime.utils")

gen_cfg = {}

gen_cfg.NODE_ASSET_DIR = '/etc/lime-assets/node/'
gen_cfg.COMMUNITY_ASSET_DIR = '/etc/lime-assets/community/'

function gen_cfg.clean()
    -- nothing to clean
end

function gen_cfg.configure()
    gen_cfg.do_generic_uci_config()
end

--! Generic UCI configuration from libremesh. Eg usage:
--!   config generic_uci_config libremap
--!     list uci_set "libremap.settings=libremap"
--!     list uci_set "libremap.settings.community=our.libre.org"
--!     list uci_set "libremap.settings.community_lat=-200.123"
--!     list uci_set "libremap.settings.community_lon=500.9"
function gen_cfg.do_generic_uci_config()
    local uci = config.get_uci_cursor()
    local ok = true
    utils.log("Applying generic configs:")
    config.foreach("generic_uci_config", function(gen_uci_cfg)
        utils.log(" " .. gen_uci_cfg[".name"])
        for _, v in pairs(gen_uci_cfg["uci_set"]) do
            if uci:set(v) ~= true then
                utils.log(" Error on generic config uci_set: " .. v)
                ok = false
            end
        end
    end)
    config.uci_commit_all()
    utils.log("Done applying generic configs.")
    return ok
end

return gen_cfg
