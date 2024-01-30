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
        STARTING = "STARTING",
        DOWNLOADING = "DOWNLOADING",
        READY_FOR_UPGRADE = "READY_FOR_UPGRADE",
        UPGRADE_SCHEDULED = "UPGRADE_SCHEDULED",
        CONFIRMATION_PENDING = "CONFIRMATION_PENDING",
        CONFIRMED = "CONFIRMED",
        ERROR = "ERROR"
    },

    -- list of possible errors
    errors = {
        DOWNLOAD_FAILED = "download failed",
        NO_LATEST_AVAILABLE = "no latest data available",
        CONFIRMATION_TIME_OUT = "confirmation timeout",
        ABORTED = "aborted"

    },
    fw_path = "",
    su_timeout = 600,
}

-- should epgrade be disabled ?
-- eupgrade.set_workdir("/tmp/mesh_upgrade")

-- Get the base url for the firmware repository in this node
function mesh_upgrade.get_repo_base_url()
    local ipv4, ipv6 = network.primary_address()
    return "http://" .. ipv4:host():string() .. mesh_upgrade.FIRMWARE_REPO_PATH
end

-- Create a work directory if nor exist
function mesh_upgrade._create_workdir(workdir)
    if not utils.file_exists(workdir) then
        os.execute('mkdir -p ' .. workdir  .. " >/dev/null")
    end
    if fs.stat(workdir, "type") ~= "dir" then
        error("Can't configure workdir " .. workdir)
    end
end

function mesh_upgrade.set_workdir(workdir)
    mesh_upgrade._create_workdir(workdir)
    mesh_upgrade.WORKDIR = workdir
    mesh_upgrade.LATEST_JSON_FILE_NAME = utils.slugify(eupgrade._get_board_name()) .. ".json" -- latest json with local lan url file name
    mesh_upgrade.LATEST_JSON_PATH = mesh_upgrade.WORKDIR .. "/" .. mesh_upgrade.LATEST_JSON_FILE_NAME -- latest json full path
    mesh_upgrade.FIRMWARE_REPO_PATH = '/lros/' -- path url for firmwares
    mesh_upgrade.FIRMWARE_SHARED_FOLDER = '/www/' .. mesh_upgrade.FIRMWARE_REPO_PATH
end

mesh_upgrade.set_workdir("/tmp/mesh_upgrade")

function mesh_upgrade.create_local_latest_json(latest_data)
    for _, im in pairs(latest_data['images']) do
        -- im['download-urls'] = string.gsub(im['download-urls'], upgrade_url, "test")
        im['download-urls'] = {mesh_upgrade.get_repo_base_url() .. im['name']}
    end
    
    utils.write_file(mesh_upgrade.LATEST_JSON_PATH, json.stringify(latest_data))
    -- For the moment mesh upgrade will ignore the latest json signature on de main nodes
    -- todo: add signature file with a valid signature... or review the signing process. 
end

function mesh_upgrade.share_firmware_packages(dest)
    if dest == nil then
        dest = "/www" .. mesh_upgrade.FIRMWARE_REPO_PATH
    end
    local images_folder = eupgrade.WORKDIR
    mesh_upgrade._create_workdir(dest)
    -- json file has to be placed in a url that ends with latest
    mesh_upgrade._create_workdir(dest .. "/latest")
    os.execute("ln -s " .. images_folder .. "/* " .. dest.. " >/dev/null")
    --utils.unsafe_shell("ln -s " .. images_folder .. "/* " .. dest .. " >/dev/null")
    os.execute("ln -s " .. mesh_upgrade.LATEST_JSON_PATH .. " " .. dest .. "/latest >/dev/null")
    os.execute("chmod -R 664 "..  dest .." >/dev/null")
    os.execute("chmod -R 664 "..  mesh_upgrade.WORKDIR  .." >/dev/null")
    os.execute("chmod -R 664 "..  images_folder  .." >/dev/null")

end

-- This function will download latest firmware and expose it as
-- a local repository in order to be used for other nodes
function mesh_upgrade.start_main_node_repository(latest_data)
    -- Create local repository json data
    mesh_upgrade.create_local_latest_json(latest_data)
    utils.execute_daemonized("eupgrade-download >/dev/null")
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
    --mesh_upgrade.change_state(mesh_upgrade.upgrade_states.STARTING)
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
    mesh_upgrade.change_state(mesh_upgrade.upgrade_states.STARTING)
    return {
        code = "SUCCESS",
        error = ""
    }
end

-- Return eupgrade status for this node and update mesh upgrade status accordingly
function mesh_upgrade.get_main_node_status()
    local download_status = eupgrade.get_download_status()

    -- Check download is completed
    if download_status == eupgrade.STATUS_DEFAULT then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DEFAULT)
    elseif download_status == eupgrade.STATUS_DOWNLOADING then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.STARTING)
    elseif download_status == eupgrade.STATUS_DOWNLOADED then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.STARTING)
    elseif download_status == eupgrade.STATUS_DOWNLOAD_FAILED then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ERROR, mesh_upgrade.errors.DOWNLOAD_FAILED)
    end
    return {
        code = download_status,
    }
end

function mesh_upgrade.start_firmware_upgrade_transaction()
    -- todo(kon): do all needed checks also with the main node state etc..
    -- Expose eupgrade folder to uhttp (this is the best place to do it since
    --    all the files are present)
    local latest = eupgrade.is_new_version_available(true)
    if not latest then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DEFAULT)
        return {
            code = "NO_NEW_VERSION",
            error = "No new version is available"
        }
    end
    mesh_upgrade.share_firmware_packages()
    -- Check if local json file exists
    if not utils.file_exists(mesh_upgrade.LATEST_JSON_PATH) then
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ERROR, mesh_upgrade.errors.NO_LATEST_AVAILABLE)

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
    uci:set('mesh-upgrade', 'main', 'timestamp', os.time())
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    -- trigger shared state data refresh
    mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ERROR)
end

-- function to be called by nodes to start download from main.
function mesh_upgrade.start_node_download(url)
    eupgrade.set_custom_api_url(url)
    local cached_only = false
    local url2 = eupgrade.get_upgrade_api_url()
    local latest_data, message = eupgrade.is_new_version_available(cached_only)
    --utils.log("start_node_download from  " .. url2 )

    if latest_data then
        --utils.log("start_node_download ")
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DOWNLOADING)
        --utils.log("downloading")
        local image = {}
        image = eupgrade.download_firmware(latest_data)
        --utils.printJson(image)
        ----utils.log(mesh_upgrade.fw_path)
        ----utils.log(latest_data)
        if eupgrade.get_download_status() == eupgrade.STATUS_DOWNLOADED and image ~= nil then
            --utils.printJson(image)
            mesh_upgrade.change_state(mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
            mesh_upgrade.trigger_sheredstate_publish()
        else
            --utils.log("Error ... download failed")
            mesh_upgrade.report_error(mesh_upgrade.errors.DOWNLOAD_FAILED)
        end
    else
        --utils.log("Error ... no latest data available" .. message)
        mesh_upgrade.report_error(mesh_upgrade.errors.DOWNLOAD_FAILED)
    end
end

-- this function will be called by the main node to inform that the firmware is available
-- also will force shared state data refresh
-- curl -6 'http://[fe80::a8aa:aaff:fe0d:feaa%lime_br0]/fw/resolv.conf'
-- curl -6 'http://[fd0d:fe46:8ce8::1]/lros/api/v1/'
function mesh_upgrade.inform_download_location(version)
    if eupgrade.get_download_status() == eupgrade.STATUS_DOWNLOADED then
        -- TODO: setup uhttpd to serve workdir location
        mesh_upgrade.set_mesh_upgrade_info({
            candidate_fw = version,
            repo_url = mesh_upgrade.get_repo_base_url(),
            upgrde_state = mesh_upgrade.upgrade_states.READY_FOR_UPGRADE,
            error = "",
            main_node = true,
            board_name = eupgrade._get_board_name(),
            current_fw = eupgrade._get_current_fw_version()
        }, mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
    end
end

-- Validate if the upgrade has already started
function mesh_upgrade.started()
    status = mesh_upgrade.state()
    if status == mesh_upgrade.upgrade_states.STARTING or status == mesh_upgrade.upgrade_states.CONFIRMATION_PENDING or
            status == mesh_upgrade.upgrade_states.CONFIRMED or status == mesh_upgrade.upgrade_states.DOWNLOADING or status ==
            mesh_upgrade.upgrade_states.READY_FOR_UPGRADE or status == mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED then
        return true
    end
    return false
    -- todo(javi): what happens if a mesh_upgrade has started more than an hour ago ? should this node abort it ?
end

function mesh_upgrade.state()
    local uci = config.get_uci_cursor()
    return uci:get('mesh-upgrade', 'main', 'upgrade_state') or mesh_upgrade.upgrade_states.DEFAULT
end

function mesh_upgrade.mesh_upgrade_abort()
    mesh_upgrade.report_error(mesh_upgrade.errors.ABORTED)
    -- todo(javi): stop and delete everything 

end

-- This line will genereate recursive dependencies like in pirania pakcage
function mesh_upgrade.trigger_sheredstate_publish()
    utils.execute_daemonized(
            "/etc/shared-state/publishers/shared-state-publish_mesh_wide_upgrade && shared-state sync mesh_wide_upgrade")
end

-- ! changes the state of the upgrade and verifies that state transition is possible.
function mesh_upgrade.change_state(newstate)
    -- If the state is the same just return
    if newstate == mesh_upgrade.state() then return false end

    local uci = config.get_uci_cursor()
    if newstate == mesh_upgrade.upgrade_states.STARTING and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.DEFAULT and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.ERROR and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.UPDATED then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.DOWNLOADING and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.STARTING then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.READY_FOR_UPGRADE and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.DOWNLOADING and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.STARTING then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.READY_FOR_UPGRADE then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.CONFIRMATION_PENDING and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED then
        return false
    elseif newstate == mesh_upgrade.upgrade_states.UPDATED and
            mesh_upgrade.state() ~= mesh_upgrade.upgrade_states.CONFIRMATION_PENDING then
        return false
    end
    -- todo(javi): verify other states and return false if it is not possible
    -- lets allow all types of state changes.
    uci:set('mesh-upgrade', 'main', 'upgrade_state', newstate)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    return true
end

function mesh_upgrade.become_bot_node(upgrade_data)
    if mesh_upgrade.started() then
        --utils.log("already a bot node")
    else
        --utils.log("transfoming into a bot node")
        upgrade_data.main_node = false
        mesh_upgrade.set_mesh_upgrade_info(upgrade_data, mesh_upgrade.upgrade_states.STARTING)
        if (mesh_upgrade.state() == mesh_upgrade.upgrade_states.STARTING) then
            mesh_upgrade.start_node_download(upgrade_data.repo_url)
        end
    end
end

-- set download information for the new firmware from main node
-- Called by a shared state hook in bot nodes
function mesh_upgrade.set_mesh_upgrade_info(upgrade_data, upgrade_state)
    local uci = config.get_uci_cursor()
    if string.match(upgrade_data.repo_url, "https?://[%w-_%.%?%.:/%+=&]+") ~= nil -- todo (javi): perform aditional checks
    then
        --utils.log("seting up repo download info to " .. upgrade_state .. " actual " .. mesh_upgrade.state())
        if (mesh_upgrade.change_state(upgrade_state)) then
            uci:set('mesh-upgrade', 'main', "mesh-upgrade")
            uci:set('mesh-upgrade', 'main', 'repo_url', upgrade_data.repo_url)
            uci:set('mesh-upgrade', 'main', 'candidate_fw', upgrade_data.candidate_fw)
            uci:set('mesh-upgrade', 'main', 'error', "")
            uci:set('mesh-upgrade', 'main', 'timestamp', os.time())
            uci:set('mesh-upgrade', 'main', 'main_node', tostring(upgrade_data.main_node))
            uci:save('mesh-upgrade')
            uci:commit('mesh-upgrade')
            -- trigger shared state data refresh
            mesh_upgrade.trigger_sheredstate_publish()
        else
            --utils.log("invalid state change ")
        end
    else
        --utils.log("upgrade failed due input data errors")
    end
end

function mesh_upgrade.toboolean(str)
    if str == "true" then
        return true
    end
    return false
end

-- ! Read status from UCI
function mesh_upgrade.get_mesh_upgrade_status()
    local uci = config.get_uci_cursor()
    local upgrade_data = {}
    upgrade_data.candidate_fw = uci:get('mesh-upgrade', 'main', 'candidate_fw')
    upgrade_data.repo_url = uci:get('mesh-upgrade', 'main', 'repo_url')
    upgrade_data.upgrade_state = uci:get('mesh-upgrade', 'main', 'upgrade_state')
    if (upgrade_data.upgrade_state == nil) then
        uci:set('mesh-upgrade', 'main', 'transaction_state', mesh_upgrade.upgrade_states.DEFAULT)
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        upgrade_data.upgrade_state = uci:get('mesh-upgrade', 'main', 'transaction_state')
    end
    upgrade_data.error = uci:get('mesh-upgrade', 'main', 'error')
    upgrade_data.timestamp = uci:get('mesh-upgrade', 'main', 'timestamp')
    upgrade_data.main_node = mesh_upgrade.toboolean(uci:get('mesh-upgrade', 'main', 'main_node'))
    upgrade_data.board_name = eupgrade._get_board_name()
    upgrade_data.current_fw = eupgrade._get_current_fw_version()
    return upgrade_data
end

function mesh_upgrade.start_safe_upgrade()
    if mesh_upgrade.state() == mesh_upgrade.upgrade_states.READY_FOR_UPGRADE and utils.file_exists(mesh_upgrade.fw_path) then
        -- perform safe upgrade preserving config and rebooting after 600 sec if
        -- no confirmation is received
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.UPGRADE_SCHELUDED)
        mesh_upgrade.trigger_sheredstate_publish()
        utils.execute_daemonized("safe-upgrade upgrade --reboot-safety-timeout=600 " .. mesh_upgrade.fw_path)
        return {
            code = "SUCCESS"
        }
    else
        --utils.log("not able to start upgrade invalid state or firmware not found")
        return {
            code = "NOT_ABLE_TO_START_UPGRADE",
            error = "Firmware not found"
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
    if mesh_upgrade.state() == mesh_upgrade.upgrade_states.CONFIRMATION_PENDING then
        local shell_output = utils.unsafe_shell("safe-upgrade confirm")
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.UPDATED)
        --utils.log(shell_output)
        return {
            code = "SUCCESS"
        }
    end
end

return mesh_upgrade
