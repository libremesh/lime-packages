local shared_state = require("shared-state")
local utils = require("lime.utils")

local network_nodes = {}

function network_nodes.node(hostname, member, fw_version, board)
    return {hostname=hostname, member=member, fw_version=fw_version, board=board}
end

function network_nodes.serialize_for_network_nodes(node)
    return {hostname=node.hostname, member=node.member, fw_version=node.fw_version, board=node.board}
end

function network_nodes.deserialize_from_network_nodes(data)
    return network_nodes.node(data.hostname, data.member, data.fw_version, data.board)
end

function network_nodes._nodes_from_db(db)
    local nodes = {}
    for hostname, value in pairs(db:get()) do
        nodes[hostname] = network_nodes.deserialize_from_network_nodes(value.data)
    end
    return nodes
end

function network_nodes.create_node()
    local hostname = utils.hostname()
    local fw_version = utils.release_info()['DISTRIB_RELEASE']
    local board = utils.current_board()
    local member = true
    local node = network_nodes.node(hostname, member, fw_version, board)
    node.status = "recently_connected"
    return node
end

function network_nodes.publish()
    local node = network_nodes.create_node()
    local data = {
        [node.hostname] = network_nodes.serialize_for_network_nodes(node)
    }
    network_nodes_db = shared_state.SharedStateMultiWriter:new("network_nodes")
    network_nodes_db:insert(data)
end

function network_nodes.as_csv()
    local nodes = network_nodes.get_nodes()
    local tmpl = "%-30s %-40s %-30s %-20s\n"
    local out = string.format(tmpl, "hostname", "board", "fw_version", "status")
    for _, node in pairs(nodes) do
        if node.member then
            out = out .. string.format(tmpl, node.hostname, node.board, node.fw_version, node.status)
        end
    end
    return out
end


function network_nodes.get_nodes()
    local network_nodes_db = shared_state.SharedStateMultiWriter:new("network_nodes")
    local node_and_links_db = shared_state.SharedState:new("nodes_and_links")

    local nodes = {}
    -- augment the node information from the network_nodes and the 'nodes_and_links' dbs
    for hostname, node in pairs(network_nodes._nodes_from_db(network_nodes_db)) do
        if node_and_links_db:get()[hostname] then
            node.status = "recently_connected"
        elseif node.member then
            node.status = "disconnected"
        else
            node.status = "gone"
        end
        nodes[hostname] = node
    end
    return nodes
end

function network_nodes.mark_nodes_as_gone(hostnames)
    local network_nodes_db = shared_state.SharedStateMultiWriter:new("network_nodes")
    local nodes = network_nodes._nodes_from_db(network_nodes_db)
    local data = {}
    for _, hostname in pairs(hostnames or {}) do
        local node = nodes[hostname]
        if node then
            node.member = false
            data[hostname] = network_nodes.serialize_for_network_nodes(node)
        end
    end
    network_nodes_db:insert(data)
end

return network_nodes
