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
    gen_cfg.do_generic_uci_configs()
    gen_cfg.do_copy_assets()
end


--! Generic UCI configuration from libremesh. Eg usage:
--!   config generic_uci_config libremap
--!     list uci_set "libremap.settings=libremap"
--!     list uci_set "libremap.settings.community=our.libre.org"
--!     list uci_set "libremap.settings.community_lat=-200.123"
--!     list uci_set "libremap.settings.community_lon=500.9"
function gen_cfg.do_generic_uci_configs()
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

--! copy_asset copy an file from the assets directory into a specified path.
--! The node asset directory (/etc/lime-assets/node) has priority over the community directory when
--! both assets exists. Use this to specify a per node configuration.
--!
--! config copy_asset collectd
--!    option asset 'collectd.conf' # relative to /etc/lime-assets/node or /etc/lime-assets/community/
--!    option path '/etc/collectd.conf'
--!
function gen_cfg.do_copy_assets()
    local uci = config.get_uci_cursor()
    local ok = true
    utils.log("Copying assets:")
    config.foreach("copy_asset", function(copy_asset)
        utils.log("  " .. copy_asset[".name"])
        local asset = copy_asset["asset"]
        local dst = copy_asset["dst"]
        local node_asset = gen_cfg.NODE_ASSET_DIR .. asset
        local community_asset = gen_cfg.COMMUNITY_ASSET_DIR .. asset
        local src = nil
        if utils.file_exists(node_asset) then
            src = node_asset
        elseif utils.file_exists(community_asset) then
            src = community_asset
        else
            utils.log(" Error copying asset '" .. asset .. "': file not found")
            ok = false
        end
        if src ~= nil then
            local dst_dirname = dst:match("(.*/)")
            if not utils.file_exists(dst_dirname) then
                os.execute("mkdir -p " .. utils.shell_quote(dst_dirname))
            end

            src = utils.shell_quote(src)
            dst = utils.shell_quote(dst)
            os.execute('cp -dpf ' .. src .. ' ' .. dst)
        end
    end)
    utils.log("Done copying assets.")
    return ok
end

return gen_cfg
