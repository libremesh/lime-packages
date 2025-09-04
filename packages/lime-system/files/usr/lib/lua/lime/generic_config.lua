#!/usr/bin/lua

local config = require("lime.config")
local utils = require("lime.utils")

gen_cfg = {}

gen_cfg.ASSET_BASE_DIR = '/etc/lime-assets/'
gen_cfg.NODE_ASSET_DIRNAME = 'node/'
gen_cfg.COMMUNITY_ASSET_DIRNAME = 'community/'
gen_cfg.CONFIG_FIRST_BOOT_SIGNAL_FILE = '/etc/.cfg_first_boot_already_run'
gen_cfg.RUN_ASSET_AT_FIRSTBOOT = 'ATFIRSTBOOT'
gen_cfg.RUN_ASSET_AT_CONFIG = 'ATCONFIG'

function gen_cfg.clean()
    --! nothing to clean, but needs to be declared to comply with the API
end

function gen_cfg.configure()
    gen_cfg.do_generic_uci_configs()
    gen_cfg.do_copy_assets()
    if not utils.file_exists(gen_cfg.CONFIG_FIRST_BOOT_SIGNAL_FILE) then
        gen_cfg.do_run_assets(gen_cfg.RUN_ASSET_AT_FIRSTBOOT)
        utils.write_file(gen_cfg.CONFIG_FIRST_BOOT_SIGNAL_FILE, '')
    end
    gen_cfg.do_run_assets(gen_cfg.RUN_ASSET_AT_CONFIG)
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
                utils.log(" Error on generic config uci_set: %s", v)
                ok = false
            end
        end
    end)
    config.uci_commit_all()
    utils.log("Done applying generic configs.")
    return ok
end

function gen_cfg.get_asset(asset)
    if (utils.stringStarts(asset, gen_cfg.NODE_ASSET_DIRNAME) or
        utils.stringStarts(asset, gen_cfg.COMMUNITY_ASSET_DIRNAME)) then
        local asset = gen_cfg.ASSET_BASE_DIR .. asset
        if utils.file_exists(asset) then
            return asset
        end
    end
end

--! copy_asset copy an file from the assets directory into a specified path.
--! The node asset directories are /etc/lime-assets/node and /etc/lime-assets/community.
--! The community directory should contain the same files in all the community nodes.
--!
--! config copy_asset collectd
--!    option asset 'community/collectd.conf' # or 'node/collectd.conf' or 'community/mynode_collectd.conf'
--!    option dst '/etc/collectd.conf'
--!

function gen_cfg.do_copy_assets()
    local uci = config.get_uci_cursor()
    local ok = true
    utils.log("Copying assets:")
    config.foreach("copy_asset", function(copy_asset)
        local asset = copy_asset["asset"]
        utils.log("  %s (%s)", copy_asset[".name"], asset)
        local dst = copy_asset["dst"]
        local src = gen_cfg.get_asset(asset)
        if src ~= nil then
            local dst_dirname = dst:match("(.*/)")
            if not utils.file_exists(dst_dirname) then
                os.execute("mkdir -p " .. utils.shell_quote(dst_dirname))
            end

            src = utils.shell_quote(src)
            dst = utils.shell_quote(dst)
            os.execute('cp -dpf ' .. src .. ' ' .. dst)
        else
            utils.log(" Error copying asset '%s': file not found.", asset)
            ok = false
        end
    end)
    utils.log("Done copying assets.")
    return ok
end

--! Executes a file from the assets directory scheme explained in copy_asset.
--!
--! config run_asset dropbear
--!     option asset 'community/dropbear.sh'
--!     option when 'ATFIRSTBOOT' # ATFIRSTBOOT, ATCONFIG
--!
function gen_cfg.do_run_assets(when)
    local uci = config.get_uci_cursor()
    local ok = true
    utils.log("Running assets on " .. when .. " :")
    config.foreach("run_asset", function(run_asset)
        local asset = run_asset["asset"]
        if run_asset["when"] == when then
            utils.log("  %s (%s)", run_asset[".name"], asset)
            local src = gen_cfg.get_asset(asset)
            if src ~= nil then
                local retval = os.execute("chmod +x " .. src .. "; " .. src)
                if retval ~= 0 then
                    utils.log(" Warning: the asset '%s': returnen non zero status.", src)
                    ok = false
                end
            else
                utils.log(" Error running asset '%s': file not found .", asset)
                ok = false
            end
        end
    end)
    utils.log("Done running assets.")
    return ok
end


return gen_cfg
