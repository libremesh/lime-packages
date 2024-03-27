#!/usr/bin/env lua

local eupgrade = require 'eupgrade'
local config = require "lime.config"
local utils = require "lime.utils"
local network = require("lime.network")
local fs = require("nixio.fs")
local json = require 'luci.jsonc'

local mesh_upgrade = {
    -- posible transaction states are derived from upgrade states
    transaction_states = {
        NO_TRANSACTION = "NO_TRANSACTION",
        STARTED = "STARTED", -- there is a transaction in progress
        ABORTED = "ABORTED",
        FINISHED = "FINISHED"
    },
    -- posible upgrade states enumeration
    upgrade_states = {
        DEFAULT = "DEFAULT", -- When no upgrade has started, after reboot
        DOWNLOADING = "DOWNLOADING",
        READY_FOR_UPGRADE = "READY_FOR_UPGRADE",
        UPGRADE_SCHEDULED = "UPGRADE_SCHEDULED",
        CONFIRMATION_PENDING = "CONFIRMATION_PENDING",
        CONFIRMED = "CONFIRMED",
        ERROR = "ERROR",
        ABORTED = "ABORTED"
    },
    -- Master node specific states
    main_node_states = {
        NO = "NO",
        STARTING = "STARTING",
        MAIN_NODE = "MAIN_NODE"
    },
    -- list of possible errors
    errors = {
        DOWNLOAD_FAILED = "download_failed",
        NO_LATEST_AVAILABLE = "no_latest_data_available",
        CONFIRMATION_TIME_OUT = "confirmation_timeout",
        --        ABORTED = "aborted",
        FW_FILE_NOT_FOUND = "firmware_file_not_found"

    },
    fw_path = "",
    su_confirm_timeout = 600,
    su_start_time_out = 60,
    max_retry_conunt = 4,
    safeupgrade_start_mark=0
}

-- should epgrade be disabled ?
-- eupgrade.set_workdir("/tmp/mesh_upgrade")

-- Get the base url for the firmware repository in this node
function mesh_upgrade.get_repo_base_url()
    local ipv4, ipv6 = network.primary_address()
    return "http://" .. ipv4:host():string() .. mesh_upgrade.FIRMWARE_REPO_PATH
end

-- Create a work directory if doesn't exist
function mesh_upgrade._create_workdir(workdir)
    if not utils.file_exists(workdir) then
        os.execute('mkdir -p ' .. workdir .. " >/dev/null")
    end
    if fs.stat(workdir, "type") ~= "dir" then
        error("Can't configure workdir " .. workdir)
    end
end

-- Gets local downloaded firmware's path
function mesh_upgrade.get_fw_path()
    local uci = config.get_uci_cursor()
    local path = uci:get('mesh-upgrade', 'main', 'fw_path')
    if path ~= nil and utils.file_exists(path) then
        return path
    else
        return " "
    end
end

function mesh_upgrade.set_fw_path(image)
    mesh_upgrade.fw_path = eupgrade.WORKDIR .. "/" .. image['name']
    local uci = config.get_uci_cursor()
    uci:set('mesh-upgrade', 'main', 'fw_path', mesh_upgrade.fw_path)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
end

function mesh_upgrade.set_workdir(workdir)
    mesh_upgrade._create_workdir(workdir)
    mesh_upgrade.WORKDIR = workdir
    mesh_upgrade.LATEST_JSON_FILE_NAME = utils.slugify(eupgrade._get_board_name()) ..
        ".json" -- latest json with local lan url file name
    mesh_upgrade.LATEST_JSON_PATH = mesh_upgrade.WORKDIR ..
        "/" ..
        mesh_upgrade.LATEST_JSON_FILE_NAME -- latest json full path
    mesh_upgrade.FIRMWARE_REPO_PATH =
    '/lros/'                               -- path url for firmwares
    mesh_upgrade.FIRMWARE_SHARED_FOLDER = '/www/' .. mesh_upgrade.FIRMWARE_REPO_PATH
end

mesh_upgrade.set_workdir("/tmp/mesh_upgrade")

function mesh_upgrade.create_local_latest_json(latest_data)
    for _, im in pairs(latest_data['images']) do
        -- im['download-urls'] = string.gsub(im['download-urls'], upgrade_url, "test")
        im['download-urls'] = { mesh_upgrade.get_repo_base_url() .. im['name'] }
    end
    utils.write_file(mesh_upgrade.LATEST_JSON_PATH, json.stringify(latest_data))
    -- For the moment mesh upgrade will ignore the latest json signature on de main nodes
    -- todo: add signature file with a valid signature... or review the signing process.
end

function mesh_upgrade.share_firmware_packages(dest)
    if dest == nil then
        dest = mesh_upgrade.FIRMWARE_SHARED_FOLDER
    end
    local images_folder = eupgrade.WORKDIR
    mesh_upgrade._create_workdir(dest)
    -- json file has to be placed in a url that ends with latest
    mesh_upgrade._create_workdir(dest .. "/latest")
    os.execute("ln -s " .. images_folder .. "/* " .. dest .. " >/dev/null")
    os.execute("ln -s " .. mesh_upgrade.LATEST_JSON_PATH .. " " .. dest .. "/latest >/dev/null")
    os.execute("chmod -R 777 " .. dest .. " >/dev/null")
    os.execute("chmod -R 777 " .. mesh_upgrade.WORKDIR .. " >/dev/null")
    os.execute("chmod -R 777 " .. images_folder .. " >/dev/null")
end

-- This function will download latest firmware and expose it as
-- a local repository in order to be used for other nodes
function mesh_upgrade.start_main_node_repository(latest_data)
    -- Create local repository json data
    mesh_upgrade.create_local_latest_json(latest_data)
    utils.execute_daemonized("eupgrade-download >/dev/null")
    mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DOWNLOADING)
end

--- Function that check if tihs node have all things needed to became a main node
--- Then, call update shared state with the proper info
-- @url optional new url to get the firmware for local repo
function mesh_upgrade.become_main_node(url)
    if url then
        eupgrade.set_custom_api_url(url)
    end
    -- todo(kon): check if main node is already set or we are on mesh_upgrade status
    -- todo(kon): dont start again if status is started and eupgrade is downloaded for example
    -- Check if there are a new version available (cached only)
    -- 1. Check if new version is available and download it demonized using eupgrade
    local latest = eupgrade.is_new_version_available(false)
    if not latest then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DEFAULT)
        return {
            code = "NO_NEW_VERSION",
            error = "No new version is available"
        }
    end
    -- 2. Start local repository and download latest firmware
    mesh_upgrade.start_main_node_repository(latest)
    mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DOWNLOADING)
    if mesh_upgrade.change_main_node_state(mesh_upgrade.main_node_states.STARTING) then
    return {
        code = "SUCCESS",
        error = ""
    }
    end
    return {
        code = "NO_ABLE_TO_BECOME_MAIN_NODE",
        error = "Not able to start main node repository or change to starting"
    }
end

-- Update the state witth an error if eupgrade download failed
-- It returns the download status
function mesh_upgrade.check_eupgrade_download_failed()
    local download_status = eupgrade.get_download_status()
    local upgrade_state = mesh_upgrade.state()

    if upgrade_state == mesh_upgrade.upgrade_states.DOWNLOADING
        and download_status == eupgrade.STATUS_DOWNLOAD_FAILED then
        mesh_upgrade.report_error(mesh_upgrade.errors.DOWNLOAD_FAILED)
    end
    return download_status
end

function mesh_upgrade.start_firmware_upgrade_transaction()
    -- todo(kon): do all needed checks also with the main node state etc..
    -- Expose eupgrade folder to uhttp (this is the best place to do it since
    --    all the files are present)
    if mesh_upgrade.main_node_state() ~= mesh_upgrade.main_node_states.STARTING then
        return {
            code = "BAD_NODE_STATE",
            error = "This node main state status is not starting"
        }
    end
    local download_status = mesh_upgrade.check_eupgrade_download_failed()
    if download_status ~= eupgrade.STATUS_DOWNLOADED then
        return {
            code = "NO_FIRMWARE_AVAILABLE",
            error = "No new firmware file downloaded"
        }
    end
    local latest = eupgrade.is_new_version_available(true)
    if not latest then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DEFAULT)
        return {
            code = "NO_NEW_VERSION",
            error = "No new version is available"
        }
    end
    mesh_upgrade.set_fw_path(latest['images'][1])
    mesh_upgrade.share_firmware_packages()
    -- Check if local json file exists
    if not utils.file_exists(mesh_upgrade.LATEST_JSON_PATH) then
        mesh_upgrade.report_error(mesh_upgrade.errors.NO_LATEST_AVAILABLE)

        return {
            code = "NO_LOCAL_JSON",
            error = "Local json file not found"
        }
    end
    -- Check firmware packages are shared properly
    -- we could check if the shared folder is empty or not and what files are present. Not needed imho
    if not utils.file_exists(mesh_upgrade.FIRMWARE_SHARED_FOLDER) then
        return {
            code = "NO_SHARED_FOLDER",
            error = "Shared folder not found"
        }
    end
    -- If we get here is supposed that everything is ready to be a main node
    mesh_upgrade.inform_download_location(latest['version'])
    mesh_upgrade.trigger_sheredstate_publish()
    return {
        code = "SUCCESS",
        error = ""
    }
end

-- Shared state functions --
----------------------------
function mesh_upgrade.report_error(error)
    local uci = config.get_uci_cursor()
    uci:set('mesh-upgrade', 'main', 'error', error)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ERROR)
end

-- function to be called by nodes to start download from main.
function mesh_upgrade.start_node_download(url)
    eupgrade.set_custom_api_url(url)
    local cached_only = false
    local url2 = eupgrade.get_upgrade_api_url()
    local latest_data, message = eupgrade.is_new_version_available(cached_only)
    --utils.log("start_node_download from  " .. url2)

    if latest_data then
        --utils.log("start_node_download ")
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DOWNLOADING)
        --utils.log("downloading")
        local image = {}
        image = eupgrade.download_firmware(latest_data)
        if eupgrade.get_download_status() == eupgrade.STATUS_DOWNLOADED and image ~= nil then
            --utils.printJson(image)
            mesh_upgrade.change_state(mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
            mesh_upgrade.trigger_sheredstate_publish()
            mesh_upgrade.set_fw_path(image)
        else
            --utils.log("Error ... download failed")
            mesh_upgrade.report_error(mesh_upgrade.errors.DOWNLOAD_FAILED)
        end
    else
        --utils.log("Error ... no latest data available" .. message)
        mesh_upgrade.report_error(mesh_upgrade.errors.NO_LATEST_AVAILABLE)
    end
end

-- this function will be called by the main node to inform that the firmware is available
-- also will force shared state data refresh
-- curl -6 'http://[fe80::a8aa:aaff:fe0d:feaa%lime_br0]/fw/resolv.conf'
-- curl -6 'http://[fd0d:fe46:8ce8::1]/lros/api/v1/'
function mesh_upgrade.inform_download_location(version)
    if eupgrade.get_download_status() == eupgrade.STATUS_DOWNLOADED
        and mesh_upgrade.main_node_state() == mesh_upgrade.main_node_states.STARTING then
        -- TODO: setup uhttpd to serve workdir location
        mesh_upgrade.set_mesh_upgrade_info({
            candidate_fw = version,
            repo_url = mesh_upgrade.get_repo_base_url(),
            upgrde_state = mesh_upgrade.upgrade_states.READY_FOR_UPGRADE,
            error = "",
            timestamp = os.time(),
            main_node = mesh_upgrade.main_node_states.MAIN_NODE,
            board_name = eupgrade._get_board_name(),
            current_fw = eupgrade._get_current_fw_version()
        }, mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        -- trigger shared state data refresh
        mesh_upgrade.trigger_sheredstate_publish()
    end
end

-- Validate if the upgrade has already started
function mesh_upgrade.started()
    status = mesh_upgrade.state()
    if status == mesh_upgrade.upgrade_states.DEFAULT or
        --if an error has ocurred then there is no transaction
        status == mesh_upgrade.upgrade_states.ERROR or
        status == mesh_upgrade.upgrade_states.ABORTED
    then
        return false
    end
    return true
    -- todo(javi): what happens if a mesh_upgrade has started more than an hour ago ? should this node abort it ?
end

function mesh_upgrade.state()
    local uci = config.get_uci_cursor()
    local upgrade_state = uci:get('mesh-upgrade', 'main', 'upgrade_state')
    if (upgrade_state == nil) then
        uci:set('mesh-upgrade', 'main', 'upgrade_state', mesh_upgrade.upgrade_states.DEFAULT)
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        return mesh_upgrade.upgrade_states.DEFAULT
    end
    return upgrade_state
end

function mesh_upgrade.main_node_state()
    local uci = config.get_uci_cursor()
    local main_node_state = uci:get('mesh-upgrade', 'main', 'main_node')
    if (main_node_state == nil) then
        uci:set('mesh-upgrade', 'main', 'main_node', mesh_upgrade.main_node_states.NO)
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        return mesh_upgrade.main_node_states.NO
    end
    return main_node_state
end

function mesh_upgrade.mesh_upgrade_abort()
    if mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ABORTED) then
        --mesh_upgrade.change_main_node_state(mesh_upgrade.main_node_states.NO)
        local uci = config.get_uci_cursor()
        uci:set('mesh-upgrade', 'main', 'retry_count', 0)
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        mesh_upgrade.trigger_sheredstate_publish()
        -- todo(javi): stop and delete everything
        -- kill posible safe upgrade command
        utils.unsafe_shell("kill $(ps| grep 'sh -c (( sleep " ..
        mesh_upgrade.su_start_time_out ..
        "; safe-upgrade upgrade'| awk '{print $1}')")
    end
    return {
        code = "SUCCESS",
        error = ""
    }
end

-- This line will genereate recursive dependencies like in pirania pakcage
function mesh_upgrade.trigger_sheredstate_publish()
    utils.execute_daemonized(
        "sleep 1; \
        shared-state bleach mesh_wide_upgrade; \
        /etc/shared-state/publishers/shared-state-publish_mesh_wide_upgrade && shared-state sync mesh_wide_upgrade")
end

function mesh_upgrade.change_main_node_state(newstate)
    local main_node_state = mesh_upgrade.main_node_state()
    --if newstate == main_node_state then return false end

    -- if newstate == mesh_upgrade.main_node_states.STARTING and
    --     main_node_state ~= mesh_upgrade.main_node_states.NO then
    --     return false
    if newstate == mesh_upgrade.main_node_states.MAIN_NODE and
        main_node_state ~= mesh_upgrade.main_node_states.STARTING then
        return false
    end

    local uci = config.get_uci_cursor()
    uci:set('mesh-upgrade', 'main', 'main_node', newstate)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    return true
end

-- ! changes the state of the upgrade and verifies that state transition is possible.
function mesh_upgrade.change_state(newstate)
    local actual_state = mesh_upgrade.state()
    -- If the state is the same just return
    if newstate == actual_state then return false end

    if newstate == mesh_upgrade.upgrade_states.DOWNLOADING and
        actual_state ~= mesh_upgrade.upgrade_states.DEFAULT and
        actual_state ~= mesh_upgrade.upgrade_states.ERROR and
        actual_state ~= mesh_upgrade.upgrade_states.UPDATED and
        actual_state ~= mesh_upgrade.upgrade_states.ABORTED then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.READY_FOR_UPGRADE and
        actual_state ~= mesh_upgrade.upgrade_states.DOWNLOADING then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED and
        actual_state ~= mesh_upgrade.upgrade_states.READY_FOR_UPGRADE then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.CONFIRMATION_PENDING and
        actual_state ~= mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.UPDATED and
        actual_state ~= mesh_upgrade.upgrade_states.CONFIRMATION_PENDING then
        return false
    end
    -- todo(javi): verify other states and return false if it is not possible
    -- lets allow all types of state changes.
    local uci = config.get_uci_cursor()
    uci:set('mesh-upgrade', 'main', 'upgrade_state', newstate)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    return true
end

--this function will retry max_retry_conunt tymes in case of error
function mesh_upgrade.become_bot_node(main_node_upgrade_data)
    if main_node_upgrade_data.upgrade_state == mesh_upgrade.upgrade_states.ABORTED then
        utils.log("main node has aborted")
        mesh_upgrade.mesh_upgrade_abort()
        return
    end
    
    if mesh_upgrade.started() then
        utils.log("node has already started")
        return
    else
        utils.log("node has not started")

        main_node_upgrade_data.main_node = mesh_upgrade.main_node_states.NO
        actual_state = mesh_upgrade.get_node_status()
        if actual_state.timestamp == main_node_upgrade_data.timestamp and
            actual_state.repo_url == main_node_upgrade_data.repo_url then
            main_node_upgrade_data.retry_count = actual_state.retry_count + 1
        else
            main_node_upgrade_data.retry_count = 0
        end

        if main_node_upgrade_data.retry_count < mesh_upgrade.max_retry_conunt then
            if (mesh_upgrade.set_mesh_upgrade_info(main_node_upgrade_data, mesh_upgrade.upgrade_states.DOWNLOADING)) then
                mesh_upgrade.start_node_download(main_node_upgrade_data.repo_url)
                -- trigger shared state data refresh
                mesh_upgrade.trigger_sheredstate_publish()
            end
        else
            utils.log("max retry_count has been reached")

        end
    end
end

-- set download information for the new firmware from main node
-- Called by a shared state hook in bot nodes
function mesh_upgrade.set_mesh_upgrade_info(upgrade_data, upgrade_state)
    local uci = config.get_uci_cursor()
    if string.match(upgrade_data.repo_url, "https?://[%w-_%.%?%.:/%+=&]+") ~= nil -- todo (javi): perform aditional checks
    then
        utils.log("seting up repo download info to " .. upgrade_state .. " actual " .. mesh_upgrade.state())
        if (mesh_upgrade.change_state(upgrade_state)) then
            uci:set('mesh-upgrade', 'main', "mesh-upgrade")
            uci:set('mesh-upgrade', 'main', 'repo_url', upgrade_data.repo_url)
            uci:set('mesh-upgrade', 'main', 'candidate_fw', upgrade_data.candidate_fw)
            uci:set('mesh-upgrade', 'main', 'error', "")
            uci:set('mesh-upgrade', 'main', 'retry_count', upgrade_data.retry_count or 0)
            --timestamp is used as id ... every node must have the same one
            uci:set('mesh-upgrade', 'main', 'timestamp', upgrade_data.timestamp)
            uci:set('mesh-upgrade', 'main', 'main_node', upgrade_data.main_node)
            uci:save('mesh-upgrade')
            uci:commit('mesh-upgrade')
            return true
        else
            --utils.log("invalid state change ")
            return false
        end
    else
        --utils.log("upgrade failed due input data errors")
        return false
    end
end

function mesh_upgrade.toboolean(str)
    if str == "true" then
        return true
    end
    return false
end

-- ! Read status from UCI
function mesh_upgrade.get_node_status()
    local uci = config.get_uci_cursor()
    local upgrade_data = {}
    upgrade_data.candidate_fw = uci:get('mesh-upgrade', 'main', 'candidate_fw')
    upgrade_data.repo_url = uci:get('mesh-upgrade', 'main', 'repo_url')
    upgrade_data.eupgradestate = mesh_upgrade.check_eupgrade_download_failed()
    upgrade_data.upgrade_state = mesh_upgrade.state()
    if (upgrade_data.upgrade_state == mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED) then
        if (tonumber(utils.unsafe_shell("safe-upgrade confirm-remaining")) > 1) then
            mesh_upgrade.change_state(mesh_upgrade.upgrade_states.CONFIRMATION_PENDING)
        elseif utils.file_exists(mesh_upgrade.get_fw_path()) == false then
            mesh_upgrade.report_error(mesh_upgrade.errors.FW_FILE_NOT_FOUND)
        end
    end
    upgrade_data.upgrade_state = uci:get('mesh-upgrade', 'main', 'upgrade_state')
    upgrade_data.error = uci:get('mesh-upgrade', 'main', 'error')
    upgrade_data.retry_count = tonumber(uci:get('mesh-upgrade', 'main', 'retry_count'))
    upgrade_data.timestamp = tonumber(uci:get('mesh-upgrade', 'main', 'timestamp'))
    upgrade_data.main_node = mesh_upgrade.main_node_state()
    upgrade_data.board_name = eupgrade._get_board_name()
    upgrade_data.current_fw = eupgrade._get_current_fw_version()
    local ipv4, ipv6 = network.primary_address()
    upgrade_data.node_ip = ipv4:host():string()
    upgrade_data.safeupgrade_start_remining= (mesh_upgrade.su_start_time_out- (utils.uptime_s()-mesh_upgrade.safeupgrade_start_mark)>0 and  mesh_upgrade.su_start_time_out- (utils.uptime_s()-mesh_upgrade.safeupgrade_start_mark) or -1)                 
    upgrade_data.confirm_remining= tonumber(utils.unsafe_shell("safe-upgrade confirm-remaining"))
    return upgrade_data
end

function mesh_upgrade.start_safe_upgrade(su_start_delay, su_confirm_timeout)
    mesh_upgrade.su_start_time_out = su_start_delay or mesh_upgrade.su_start_time_out
    mesh_upgrade.su_confirm_timeout = su_confirm_timeout or mesh_upgrade.su_confirm_timeout

    if mesh_upgrade.state() == mesh_upgrade.upgrade_states.READY_FOR_UPGRADE then
        if utils.file_exists(mesh_upgrade.get_fw_path()) then
            -- perform safe upgrade preserving config and rebooting after 600 sec if
            -- no confirmation is received
            -- todo: javier first veryfy image

            -- just preserve meshconfig
            --os.execute("tar cfz ".. mesh_upgrade.WORKDIR.."/mesh_upgrade_cfg.tgz -C / etc/config/mesh-upgrade")

            -- perform a full config backup including mesh_upgrade config file needed for the next image
            -- surprisingly this does not presrve nodename
            -- os.execute("sysupgrade -b ".. mesh_upgrade.WORKDIR.."/mesh_upgrade_cfg.tgz")

            config = require("lime.config")
            local keep = config.get("system", "keep_on_upgrade", "")
            keep = keep .. " lime-mesh-upgrade"
            config.set("system", "keep_on_upgrade", keep) --use set but not commit, so this configuration wont be preserved.

            mesh_upgrade.change_state(mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED)
            mesh_upgrade.safeupgrade_start_mark=utils.uptime_s()
            mesh_upgrade.trigger_sheredstate_publish()
            --this must be executed after a safe upgrade timeout to enable all nodes to start_safe_upgrade
            utils.execute_daemonized("sleep " ..
                mesh_upgrade.su_start_time_out ..
                "; safe-upgrade upgrade --reboot-safety-timeout=" ..
                mesh_upgrade.su_confirm_timeout .. " " .. mesh_upgrade.get_fw_path())

            return {
                code = "SUCCESS",
                error = "",
                su_start_delay = mesh_upgrade.su_start_time_out,
                su_confirm_timeout = mesh_upgrade.su_confirm_timeout

            }
        else
            ----utils.log("not able to start upgrade invalid state or firmware not found")
            mesh_upgrade.report_error(mesh_upgrade.errors.FW_FILE_NOT_FOUND)
            return {
                code = "NOT_ABLE_TO_START_UPGRADE",
                error = "Firmware not found"
            }
        end
    else
        return {
            code = "NOT_READY_FOR_UPGRADE",
            error = "Not READY FOR UPGRADE"
        }
    end
end

-- This command requires that the configuration be preserverd across upgrade,
-- maybe this change achieves this objetive

-- diff --git a/packages/lime-system/files/etc/config/lime-defaults b/packages/lime-system/files/etc/config/lime-defaults
-- index 5f5c4a31..8d55d949 100644
-- --- a/packages/lime-system/files/etc/config/lime-defaults
-- +++ b/packages/lime-system/files/etc/config/lime-defaults
-- @@ -8,7 +8,7 @@
--  config lime system
--         option hostname 'LiMe-%M4%M5%M6'
--         option domain 'thisnode.info'
-- -       option keep_on_upgrade 'libremesh dropbear minimum-essential /etc/sysupgrade.conf'
-- +       option keep_on_upgrade 'libremesh dropbear minimum-essential /etc/sysupgrade.conf /etc/config/mesh-upgrade'
--         option root_password_policy 'DO_NOTHING'
--         option root_password_secret ''
--         option deferable_reboot_uptime_s '97200'
function mesh_upgrade.confirm()
    if mesh_upgrade.get_node_status().upgrade_state == mesh_upgrade.upgrade_states.CONFIRMATION_PENDING then
        local shell_output = utils.unsafe_shell("safe-upgrade confirm")
        if mesh_upgrade.change_state(mesh_upgrade.upgrade_states.CONFIRMED) then
            return {
                code = "SUCCESS"
            }
        end
    end
    return {
        code = "NOT_READY_TO_CONFIRM",
        error = "NOT_READY_TO_CONFIRM"
    }
end

return mesh_upgrade
