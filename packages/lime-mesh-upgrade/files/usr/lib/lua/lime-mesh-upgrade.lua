#!/usr/bin/env lua

local libuci = require "uci"
local eupgrade = require 'eupgrade'
local config = require "lime.config"



local mesh_upgrade = {
    --posible tranactin states
    transaction_states = {
        NO_TRANSACTION="no_transaction",
        STARTED = "started", --ther is a transaction in progress
        ABORTED = "aborted",
        FINISHED = "finished"
    },
    --psible upgrade states enumeration
    upgrade_states = {
        DOWNLOADING= "downloading",
        READY_FOR_UPGRADE="ready_for_upgrade",
        UPGRADE_SCHELUDED="upgrade_scheluded",
        CONFIRMATION_PENDING="confirmation_pending",
        CONFIRMED="confirmed",
        UPDATED="updated",
        ERROR= "error"
    },
    -- list of possible errors
    errors =
    {
        DOWNLOAD_FAILED="download failed",
        CONFIRMATION_TIME_OUT="confirmation timeout"
    }
}

-- function mesh_upgrade.set_workdir(workdir)
--     if not utils.file_exists(workdir) then
--         os.execute('mkdir -p ' .. workdir)
--     end
--     if fs.stat(workdir, "type") ~= "dir" then
--         error("Can't configure workdir " .. workdir)
--     end
--     mesh_upgrade.WORKDIR = workdir
--     --mup.DOWNLOAD_INFO_CACHE_FILE = mup.WORKDIR .. '/download_status'
--     mesh_upgrade.FIRMWARE_LATEST_JSON = mup.WORKDIR .. "/firmware_latest_mesh_wide.json"
--     --mup.FIRMWARE_LATEST_JSON_SIGNATURE = mup.FIRMWARE_LATEST_JSON .. '.sig'
-- end

-- mesh_upgrade.set_workdir("/tmp/mesh_upgrade")

-- This function will download latest librerouter os firmware and expose it as
-- a local repository in order to be used for other nodes
function mesh_upgrade.set_up_firmware_repository()
    -- 1. Check if new version is available and download it demonized using eupgrade
    local cached_only = false
    local latest_data = eupgrade.is_new_version_available(cached_only)
    if latest_data then
        utils.execute_daemonized("eupgrade-download")
    else
        ret = { status = 'error', message = 'New version is not availabe' }
    end

    -- 2. Create local repository json data
    --latest_data = json.parse(latest_json)
    local upgrade_url = eupgrade.get_upgrade_api_url()
    for _, im in pairs(latest_data['images']) do
        im['download-urls'] = string.gsub(im['download-urls'], upgrade_url, "test")
    end
    -- todo(kon): implement create signature
    utils.write_file(mesh_upgrade.FIRMWARE_LATEST_JSON, latest_data)
end

-- Shared state functions

-- Validate if the upgrade has already started
function mesh_upgrade.mesh_upgrade_is_started()
    local uci = libuci.cursor()
    return uci:get('mesh-upgrade', 'main', 'transaction_state') == 'started'
    --todo: what happens if a mesh_upgrade has started more than an hour ago ? should this node abort it ? 
end

function mesh_upgrade.mesh_upgrade_abort()
    local uci = libuci.cursor()
    uci:set('mesh-upgrade', 'main', 'transaction_state', mesh_upgrade.transaction_states.ABORTED)
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    -- stop and delete everything
    -- trigger a shared state publish
end

-- set download information for the new firmware from master node
-- Called by a shared state hook in non master nodes
function mesh_upgrade.set_mesh_upgrade_info(upgrade_data)
    local uci = config.get_uci_cursor()
    if (type(upgrade_data.id) == "number") and
        string.match(upgrade_data.data.repo_url, "https?://[%w-_%.%?%.:/%+=&]+") ~= nil
    --perform aditional checks
    then
        uci:get('mesh-upgrade', 'main','repo_url')
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', 'id', upgrade_data.id)
        uci:set('mesh-upgrade', 'main', 'repo_url', upgrade_data.data.repo_url)
        uci:set('mesh-upgrade', 'main', 'firmware_ver', upgrade_data.data.firmware_ver)
        uci:set('mesh-upgrade', 'main', 'upgrade_state', mesh_upgrade.upgrade_states.starting)
        uci:set('mesh-upgrade', 'main', 'error', 0)
        uci:set('mesh-upgrade', 'main', 'timestamp', upgrade_data.timestamp)
        uci:set('mesh-upgrade', 'main', 'master_node', upgrade_data.master_node)
        uci:set('mesh-upgrade', 'main', 'transaction_state', mesh_upgrade.transaction_states.STARTED)
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        --wait for the download to be ready to trigger the shared state upgrade.
        --trigger firmware download from master_node url
    else
        utils.log("upgrade not started input data errors")
        print("upgrade not started input data errors")
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
    return upgrade_data
end

return mesh_upgrade
