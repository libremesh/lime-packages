#!/usr/bin/env lua

local mesh_upgrade = {}

function mesh_upgrade.became_master_node(urls)
    -- todo
end

function mesh_upgrade.upgrade_in_progress()
    return uci:get('mesh_upgrade', 'main', 'transaction_state') == 'started'
end

function mendmesh_upgrade.start(upgrade_data)
end


return mesh_upgrade