#!/usr/bin/env lua

local libuci = require "uci"
local eupgrade = require 'eupgrade'

local mesh_upgrade = {}

function mesh_upgrade.set_workdir(workdir)
    if not utils.file_exists(workdir) then
        os.execute('mkdir -p ' .. workdir)
    end
    if fs.stat(workdir, "type") ~= "dir" then
        error("Can't configure workdir " .. workdir)
    end
    mesh_upgrade.WORKDIR = workdir
    --mup.DOWNLOAD_INFO_CACHE_FILE = mup.WORKDIR .. '/download_status'
    mesh_upgrade.FIRMWARE_LATEST_JSON = mup.WORKDIR .. "/firmware_latest_mesh_wide.json"
    --mup.FIRMWARE_LATEST_JSON_SIGNATURE = mup.FIRMWARE_LATEST_JSON .. '.sig'
end

mesh_upgrade.set_workdir("/tmp/mesh_upgrade")

-- This function will download latest librerouter os firmware and expose it as
-- a local repository in order to be used for other nodes
function mesh_upgrade.set_up_firmware_repository()
    -- 1. Check if new version is available and download it demonized using eupgrade
    local cached_only = false
    local latest_data = eupgrade.is_new_version_available(cached_only)
    if latest_data then
        utils.execute_daemonized("eupgrade-download")
    else
        ret = {status = 'error', message = 'New version is not availabe'}
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

-- Validate if the upgrade is already started
function mesh_upgrade.mesh_upgrade_is_started()
    local uci = libuci.cursor()
    return uci:get('mesh-upgrade', 'main', 'transaction_state') == 'started'
end

function mesh_upgrade.mesh_upgrade_abort()
    local uci = libuci.cursor()
    uci:set('mesh-upgrade', 'main', 'transaction_state', 'aborted')
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    -- stop and delete everything
    -- trigger a shared state publish
end

-- It set up the information of where to download the new firmware.
-- Called by a shared state hook
function mesh_upgrade.set_mesh_upgrade_info(upgrade_data)
    local uci = libuci.cursor()
    if (type(upgrade_data.id) == "number") and
        string.match(upgrade_data.data.repo_url, "https?://[%w-_%.%?%.:/%+=&]+") ~= nil
        --perform aditional checks
    then
        print (uci:set('mesh-upgrade', 'main', "mesh-upgrade"))
        print(uci:set('mesh-upgrade', 'main', 'id', upgrade_data.id))
        uci:set('mesh-upgrade', 'main', 'repo_url', upgrade_data.data.repo_url)
        uci:set('mesh-upgrade', 'main', 'firmware_ver', upgrade_data.data.firmware_ver)
        print(uci:set('mesh-upgrade', 'main', 'upgrade_state', 'starting'))
        uci:set('mesh-upgrade', 'main', 'error', 0)
        uci:set('mesh-upgrade', 'main', 'timestamp', upgrade_data.timestamp)
        uci:set('mesh-upgrade', 'main', 'master_node', upgrade_data.master_node)
        uci:set('mesh-upgrade', 'main', 'transaction_state', 'started')
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        --trigger a shared state publish
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
--       eup_STATUS="",
--     },
--     timestamp=231354654,
--     id="",
--     transaction_state="started/aborted/finished",
--     master_node=""
-- }
--
function mesh_upgrade.get_mesh_upgrade_status()
    local uci = libuci.cursor()
    local upgrade_data = {}
    upgrade_data.data={}
    upgrade_data.type= "upgrade"
    upgrade_data.id = uci:get('mesh-upgrade', 'main', 'id')
    upgrade_data.data.firmware_ver = uci:get('mesh-upgrade', 'main', 'firmware_ver')
    upgrade_data.data.repo_url = uci:get('mesh-upgrade', 'main', 'repo_url')
    upgrade_data.data.upgrade_state = uci:get('mesh-upgrade', 'main', 'upgrade_state')
    upgrade_data.data.error = uci:get('mesh-upgrade', 'main', 'error')
    upgrade_data.data.safe_upgrade_status=uci:get('mesh-upgrade', 'main', 'safe_upgrade_status')
    upgrade_data.data.eup_STATUS=uci:get('mesh-upgrade', 'main', 'eup_STATUS')
    upgrade_data.timestamp = uci:get('mesh-upgrade', 'main', 'timestamp')
    upgrade_data.master_node = uci:get('mesh-upgrade', 'main', 'master_node')
    upgrade_data.transaction_state = uci:get('mesh-upgrade', 'main', 'transaction_state')
    return upgrade_data
end

return mesh_upgrade
