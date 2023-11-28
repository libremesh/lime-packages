#!/usr/bin/env lua

local eupgrade = require 'eupgrade'
local upgrade = require 'upgrade'
local config = require "lime.config"
local utils = require "lime.utils"
local network = require("lime.network")

local mesh_upgrade = {
    -- posible tranactin states
    transaction_states = {
        NO_TRANSACTION = "no_transaction",
        STARTED = "started", -- there is a transaction in progress
        ABORTED = "aborted",
        FINISHED = "finished"
    },
    -- psible upgrade states enumeration
    upgrade_states = {
        DEFAULT = "not upgrading",
        STARTING = "starting",
        DOWNLOADING = "downloading",
        READY_FOR_UPGRADE = "ready_for_upgrade",
        UPGRADE_SCHEDULED = "upgrade_scheluded",
        CONFIRMATION_PENDING = "confirmation_pending",
        CONFIRMED = "confirmed",
        UPDATED = "updated",
        ERROR = "error"
    },
    -- list of possible errors
    errors = {
        DOWNLOAD_FAILED = "download failed",
        CONFIRMATION_TIME_OUT = "confirmation timeout"
    },
    fw_path = "",
    su_timeout = 600,
    MASTERNODE_ENDPOINT = "/lros/api/v1/"
}

-- shoud epgrade be disabled ?
eupgrade.set_workdir("/tmp/mesh_upgrade")

-- This function will download latest librerouter os firmware and expose it as
-- a local repository in order to be used for other nodes
function mesh_upgrade.set_up_firmware_repository()
    -- 1. Check if new version is available and download it demonized using eupgrade
    local cached_only = false
    local latest_data = eupgrade.is_new_version_available(cached_only)
    if latest_data then
        utils.execute_daemonized("eupgrade-download")
    else
        ret = {
            status = 'error',
            message = 'New version is not availabe'
        }
    end

    -- 2. Create local repository json data
    -- latest_data = json.parse(latest_json)
    local upgrade_url = eupgrade.get_upgrade_api_url()
    for _, im in pairs(latest_data['images']) do
        im['download-urls'] = string.gsub(im['download-urls'], upgrade_url, "test")
    end
    -- todo(kon): implement create signature
    utils.write_file(mesh_upgrade.FIRMWARE_LATEST_JSON, latest_data)
end

-- Shared state functions --
----------------------------

-- function to be called by nodes to start download from master.
function mesh_upgrade.start_node_download(url)
    local uci = config.get_uci_cursor()
    eupgrade.set_upgrade_api_url(url)
    status = uci:set('eupgrade', 'main', 'api_url',url)
    uci:save('eupgrade')
    uci:commit('eupgrade')
    local cached_only = false
    --download new firmware if necessary
    config.log("is_new_version_available ")

    local latest_data = eupgrade.is_new_version_available(cached_only)
    if latest_data then
        config.log("start_node_download ")
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.DOWNLOADING)
        config.log("downloading")

        local image = eupgrade.download_firmware(latest_data)

        local image = {}
        image, mesh_upgrade.fw_path = eupgrade.download_firmware(latest_data)
        uci:set('mesh-upgrade', 'main', 'eup_STATUS', eupgrade.get_download_status())
        if eupgrade.get_download_status() == eupgrade.STATUS_DOWNLOADED then
            mesh_upgrade.change_state(mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        else
            mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ERROR)
            -- todo: how to handle this error
        end
    else
        mesh_upgrade.change_state(mesh_upgrade.upgrade_states.ERROR)
    end
    mesh_upgrade.trigger_sheredstate_publish()
end

-- this function will be called by the master node to inform that the firmware is available
-- also will force shared state data refresh
-- curl -6 'http://[fe80::a8aa:aaff:fe0d:feaa%lime_br0]/fw/resolv.conf'
-- curl -6 'http://[fd0d:fe46:8ce8::1]/lros/api/v1/'

function mesh_upgrade.inform_download_location(version)
    if eupgrade.get_download_status() == eupgrade.STATUS_DOWNLOADED then
        -- TODO: setup uhttpd to serve workdir location
        ipv4, ipv6 = network.primary_address()
        mesh_upgrade.set_mesh_upgrade_info({
            type = "upgrade",
            data = {
                firmware_ver = version,
                repo_url = "http://" .. ipv4 .. mesh_upgrade.MASTERNODE_ENDPOINT,
                repo_url_v6 = "http://[" .. ipv6 .. "]".. mesh_upgrade.MASTERNODE_ENDPOINT,
                upgrde_state = mesh_upgrade.upgrade_states.READY_FOR_UPGRADE,
                error = 0,
                safe_upgrade_status = "",
                eup_STATUS = eupgrade.STATUS_DOWNLOADED
            },
            timestamp = os.time(),
            id = 21, -- todo: create a unique hash
            transaction_state = mesh_upgrade.transaction_states.STARTED,
            master_node = utils.hostname()
        }, mesh_upgrade.upgrade_states.READY_FOR_UPGRADE, mesh_upgrade.transaction_states.STARTED)
    else
        config.log("eupgrade STATUS is not 'DOWNLOADED'")
    end
end

-- Validate if the upgrade has already started
function mesh_upgrade.started()
    local uci = config.get_uci_cursor()
    return uci:get('mesh-upgrade', 'main', 'transaction_state') == mesh_upgrade.transaction_states.STARTED
    -- todo: what happens if a mesh_upgrade has started more than an hour ago ? should this node abort it ?
end

function mesh_upgrade.state()
    local uci = config.get_uci_cursor()
    return uci:get('mesh-upgrade', 'main', 'upgrade_state') or mesh_upgrade.upgrade_states.DEFAULT
end

function mesh_upgrade.mesh_upgrade_abort()
    local uci = config.get_uci_cursor()
    uci:set('mesh-upgrade', 'main', 'transaction_state', mesh_upgrade.transaction_states.ABORTED)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    -- stop and delete everything
    -- trigger a shared state publish
end

-- This line will genereate recursive dependencies like in pirania pakcage
function mesh_upgrade.trigger_sheredstate_publish()
    utils.execute_daemonized(
        "/etc/shared-state/publishers/shared-state-publish_mesh_wide_upgrade && shared-state sync mesh_wide_upgrade")
end

-- ! changes the state of the upgrade and verifies that state transition is possible.
function mesh_upgrade.change_state(newstate, errortype)
    local uci = config.get_uci_cursor()
    if newstate == mesh_upgrade.upgrade_states.STARTING and
        (mesh_upgrade.state() == mesh_upgrade.upgrade_states.DEFAULT or mesh_upgrade.state() ==
            mesh_upgrade.upgrade_states.ERROR or mesh_upgrade.state() == mesh_upgrade.upgrade_states.UPDATED) then
        -- trigger firmware download from master_node url
        uci:set('mesh-upgrade', 'main', 'upgrade_state', newstate)
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        return true
    end
    -- todo: verify other states 
    -- lets allow all types of state changes. 
    uci:set('mesh-upgrade', 'main', 'upgrade_state', newstate)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    return false
end

-- set download information for the new firmware from master node
-- Called by a shared state hook in non master nodes
function mesh_upgrade.set_mesh_upgrade_info(upgrade_data, upgrade_state, transaction_state)
    local uci = config.get_uci_cursor()
    if (type(upgrade_data.id) == "number") and string.match(upgrade_data.data.repo_url, "https?://[%w-_%.%?%.:/%+=&]+") ~=
        nil -- perform aditional checks
    then
        if (mesh_upgrade.change_state(upgrade_state)) then
            uci:get('mesh-upgrade', 'main', 'repo_url')
            uci:set('mesh-upgrade', 'main', "mesh-upgrade")
            uci:set('mesh-upgrade', 'main', 'id', upgrade_data.id)
            uci:set('mesh-upgrade', 'main', 'repo_url', upgrade_data.data.repo_url)
            uci:set('mesh-upgrade', 'main', 'firmware_ver', upgrade_data.data.firmware_ver)
            -- uci:set('mesh-upgrade', 'main', 'upgrade_state', upgrade_state) already done in change state
            uci:set('mesh-upgrade', 'main', 'error', 0)
            uci:set('mesh-upgrade', 'main', 'timestamp', os.time())
            uci:set('mesh-upgrade', 'main', 'master_node', upgrade_data.master_node)
            uci:set('mesh-upgrade', 'main', 'transaction_state',
                transaction_state or mesh_upgrade.transaction_states.STARTED)
            uci:save('mesh-upgrade')
            uci:commit('mesh-upgrade')
            -- trigger shared state data refresh
            mesh_upgrade.trigger_sheredstate_publish()
            mesh_upgrade.start_node_download(upgrade_data.data.repo_url)
        else
            config.log("invalid state change ")
        end
    else
        config.log("upgrade failed due input data errors")
    end
end

--
-- {
--     type= "upgrade",
--     data={
--       firmware_ver="xxxx",
--       repo_url="http://10.13.0.1/lros/api/v1/",
--       upgrde_state="starting,downloading|ready_for_upgrade|upgrade_scheluded|confirmation_pending|~~confirmed~~|updated|error",
--       error="CODE",
--       safe_upgrade_status="",
--       eup_STATUS="",eup.STATUS_DEFAULT = 'not-initiated' eup.STATUS_DOWNLOADING = 'downloading' eup.STATUS_DOWNLOADED = 'downloaded' eup.STATUS_DOWNLOAD_FAILED = 'download-failed'
--     },
--     timestamp=231354654,
--     id="",
--     transaction_state="started/aborted/finished",
--     master_node=""
-- }
--

-- ! Read status from UCI
function mesh_upgrade.get_mesh_upgrade_status()
    local uci = config.get_uci_cursor()
    local upgrade_data = {}
    upgrade_data.data = {}
    upgrade_data.type = "upgrade"
    upgrade_data.id = uci:get('mesh-upgrade', 'main', 'id')
    upgrade_data.data.firmware_ver = uci:get('mesh-upgrade', 'main', 'firmware_ver')
    upgrade_data.data.repo_url = uci:get('mesh-upgrade', 'main', 'repo_url')
    upgrade_data.data.upgrade_state = uci:get('mesh-upgrade', 'main', 'upgrade_state')
    upgrade_data.data.error = uci:get('mesh-upgrade', 'main', 'error')
    upgrade_data.data.safe_upgrade_status = uci:get('mesh-upgrade', 'main', 'safe_upgrade_status')
    upgrade_data.data.eup_STATUS = uci:get('mesh-upgrade', 'main', 'eup_STATUS')
    upgrade_data.timestamp = uci:get('mesh-upgrade', 'main', 'timestamp')
    upgrade_data.master_node = uci:get('mesh-upgrade', 'main', 'master_node')
    upgrade_data.transaction_state = uci:get('mesh-upgrade', 'main', 'transaction_state')
    if (upgrade_data.transaction_state == nil) then
        uci:set('mesh-upgrade', 'main', 'transaction_state', mesh_upgrade.transaction_states.NO_TRANSACTION)
        upgrade_data.transaction_state = uci:get('mesh-upgrade', 'main', 'transaction_state')
    end
    return upgrade_data
end

function mesh_upgrade.start_safe_upgrade()
    if mesh_upgrade.change_state( mesh_upgrade.upgrade_states.UPGRADE_SCHELUDED) and utils.file_exists(mesh_upgrade.fw_path) then
        upgrade.firmware_upgrade()
    else
        utils.log ("not able to start upgrade invalid state or firmware not found")
        mesh_upgrade.change_state( mesh_upgrade.upgrade_states.ERROR)
    end
end

return mesh_upgrade
