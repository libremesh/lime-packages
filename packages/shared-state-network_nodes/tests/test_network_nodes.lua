local network_nodes = require('network-nodes')
local utils = require('lime.utils')
local test_utils = require('tests.utils')
local shared_state = require('shared-state')

describe('Tests network_nodes #network_nodes', function () 
    before_each('', function()
        test_dir = test_utils.setup_test_dir()
        shared_state.PERSISTENT_DATA_DIR = test_dir
    end)

    after_each('', function()
        test_utils.teardown_test_dir()
    end)

    it('test get_nodes return expected format #network_nodes', function()
        local sharedState = shared_state.SharedStatePersistent:new('network_nodes')
        local data = {
            ["node1"] = true,
            ["node2"] = false,
            ["node3"] = true,
        }
        sharedState:insert(data)
        local expected = {
            { hostname = "node1", status = "connected"},
            { hostname = "node2", status = "disconnected"},
            { hostname = "node3", status = "connected"},
        }
        assert.are.same(expected, network_nodes.get_nodes())
    end)
    
    it('test mark_nodes_as_gone marks nodes as gone', function ()
        network_nodes.mark_nodes_as_gone({
            'node1', 'node2', 'node3'
        })
        local expected = {
            { hostname = "node1", status = "disconnected"},
            { hostname = "node2", status = "disconnected"},
            { hostname = "node3", status = "disconnected"},
        }
        assert.are.same(expected, network_nodes.get_nodes())
    end)
end)