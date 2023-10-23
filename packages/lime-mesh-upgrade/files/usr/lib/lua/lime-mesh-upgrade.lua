local libuci = require "uci"

local mesh_upgrade = {}


function mesh_upgrade.became_master_node(urls)
    -- todo
end

function mesh_upgrade.upgrade_in_progress()
    local uci = libuci.cursor()
    return uci:get('mesh-upgrade', 'main', 'transaction_state') == 'started'
end

function mesh_upgrade.abort()
    local uci = libuci.cursor()
    uci:set('mesh-upgrade', 'main', 'transaction_state', 'aborted')
    uci:save('mesh-upgrade')
    uci:commit('mesh-upgrade')
    -- stop and delete everything
    -- trigger a shared state publish
end

function mesh_upgrade.start(upgrade_data)
    local uci = libuci.cursor()
    if (type(upgrade_data.id) == "number") and
        string.match(upgrade_data.data.repo_url, "https?://[%w-_%.%?%.:/%+=&]+") ~= nil
        --perform aditional checks
    then
        uci:set('mesh-upgrade', 'main'))
        uci:set('mesh-upgrade', 'main', "mesh_upgrade"))
        uci:set('mesh-upgrade', 'main', 'id', upgrade_data.id))
        uci:set('mesh-upgrade', 'main', 'repo_url', upgrade_data.data.repo_url)
        uci:set('mesh-upgrade', 'main', 'firmware_ver', upgrade_data.data.firmware_ver)
        uci:set('mesh-upgrade', 'main', 'upgrade_state', 'starting')
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
function mesh_upgrade.get_status()
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
