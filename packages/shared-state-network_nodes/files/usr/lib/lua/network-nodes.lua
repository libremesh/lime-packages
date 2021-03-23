local shared_state = require("shared-state")
local network_nodes = {}

function network_nodes.get_nodes()
    local sharedState = shared_state.SharedStatePersistent:new("network_nodes")
    local result = {}
    for key, value in pairs(sharedState:get()) do
        local status = value.data and "connected" or "disconnected"
        table.insert(result, { hostname = key, status = status})
    end
    return result
end

function network_nodes.mark_nodes_as_gone(hostnames)
    local sharedState = shared_state.SharedStatePersistent:new("network_nodes")
    local data = {}
    for _, hostname in pairs(hostnames or {}) do
        data[hostname] = false
    end
    sharedState:insert(data)
end

return network_nodes