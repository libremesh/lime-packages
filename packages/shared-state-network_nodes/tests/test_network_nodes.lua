local utils = require('lime.utils')
local test_utils = require('tests.utils')
local shared_state = require('shared-state')
local network_nodes = require('network-nodes')

local uci = nil

describe('Tests network_nodes #network_nodes', function ()
    before_each('', function()
        test_dir = test_utils.setup_test_dir()
        shared_state.PERSISTENT_DATA_DIR = test_dir
        shared_state.DATA_DIR = test_dir
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_dir()
        test_utils.teardown_test_uci(uci)
    end)

    it('test node creation and serialization', function()
        stub(utils, "release_info", function () return {DISTRIB_RELEASE='2021.1'} end)
        stub(utils, "current_board", function () return 'devboard' end)
        uci:set('network', 'lan', 'interface')
        uci:set('network', 'lan', 'ipaddr', '10.5.0.5')
        uci:set('network', 'lan', 'ip6addr', 'fd0d:fe46:8ce8::ab:cd00/64')
        uci:commit('network')
        local node = network_nodes.create_node()
        assert.are.equal('devboard', node.board)
        assert.are.equal('2021.1', node.fw_version)
        assert.are.equal('recently_reachable', node.status)
        assert.are.equal('10.5.0.5', node.ipv4)
        assert.are.equal('fd0d:fe46:8ce8::ab:cd00', node.ipv6)

        local node = network_nodes.node("node1", true, "2021.1", "librerouter-v1")
        assert.are.same(node, network_nodes.deserialize_from_network_nodes(network_nodes.serialize_for_network_nodes(node)))

    end)

    it('test get_nodes return expected format #get_nodes', function()
        uci:set('network', 'lan', 'interface')
        uci:set('network', 'lan', 'ipaddr', '10.5.0.5')
        uci:set('network', 'lan', 'ip6addr', 'fd0d:fe46:8ce8::ab:cd00/64')
        uci:commit('network')
        local node1 = network_nodes.node("node1", true, "2021.1", "librerouter-v1", "10.24.3.97",
                                         "fd0d:fe46:8ce8::ab:cd00")
        local node2 = network_nodes.node("node2", true, "2020.3", "librerouter-v1", "10.24.3.98",
                                         "fd0d:fe46:8ce8::ab:cd01")
        local node3 = network_nodes.node("node3", true, "2020.1", "tplink-wdr3600", "10.24.3.98",
                                         "fd0d:fe46:8ce8::ab:cd02")
        local network_nodes_db = shared_state.SharedStateMultiWriter:new('network_nodes')
        local data = {
            ["node1"] = network_nodes.serialize_for_network_nodes(node1),
            ["node2"] = network_nodes.serialize_for_network_nodes(node2),
            ["node3"] = network_nodes.serialize_for_network_nodes(node3),
        }
        network_nodes_db:insert(data)

        local nodes_and_links_db = shared_state.SharedState:new('nodes_and_links')
        nodes_and_links_db:get()
        nodes_and_links_db:insert({node1={foo='bar'}})

        assert.are.same({node1=node1, node2=node2, node3=node3}, network_nodes._nodes_from_db(network_nodes_db))

        local nodes = network_nodes.get_nodes()
        assert.is.equal("recently_reachable", nodes["node1"].status)
        assert.is.equal("unreachable", nodes["node2"].status)
        assert.is.equal("librerouter-v1", nodes["node2"].board)

        local csv = network_nodes.as_human_readable_table() -- ok just some excercise...
    end)

    it('test mark_nodes_as_gone marks nodes as gone', function ()
        local node1 = network_nodes.node("node1", true, "2021.1", "librerouter-v1")
        local node2 = network_nodes.node("node2", true, "2020.3", "librerouter-v1")
        local node3 = network_nodes.node("node3", true, "2020.1", "tplink-wdr3600")
        local network_nodes_db = shared_state.SharedStateMultiWriter:new('network_nodes')
        local data = {
            ["node1"] = network_nodes.serialize_for_network_nodes(node1),
            ["node2"] = network_nodes.serialize_for_network_nodes(node2),
            ["node3"] = network_nodes.serialize_for_network_nodes(node3),
        }
        network_nodes_db:insert(data)

        network_nodes.mark_nodes_as_gone({
            'node1', 'node2'
        })

        local nodes = network_nodes.get_nodes()
        assert.is.equal("gone", nodes["node1"].status)
        assert.is.equal("gone", nodes["node2"].status)
        assert.is.equal("unreachable", nodes["node3"].status)
        assert.is.equal("2020.1", nodes["node3"].fw_version)
    end)

    it('test publish', function ()
        local hostname = 'mydevpc'
        stub(utils, "hostname", function () return hostname end)
        stub(utils, "release_info", function () return {RELEASE='2021.1'} end)
        stub(utils, "current_board", function () return 'devboard' end)
        network_nodes.publish()
        local nodes = network_nodes.get_nodes()
        assert.is.equal("devboard", nodes[hostname].board)
    end)

end)
