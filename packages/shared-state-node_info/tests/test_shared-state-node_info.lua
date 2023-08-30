local network_nodes = require('network-nodes')
local JSON = require("luci.jsonc")
local test_utils = require('tests.utils')
local utils = require('lime.utils')
local node_status = require ("lime.node_status")



local uci = nil

package.path = package.path .. ";packages/shared-state-node_info/files/usr/bin/?;;"
require ("shared-state-publish_node_info")


describe('Tests network_nodes #network_nodes', function ()
    before_each('', function()
        uci = test_utils.setup_test_uci()
        stub(utils, "release_info", function () return {DISTRIB_RELEASE='2021.1'} end)
        stub(utils, "current_board", function () return 'devboard' end)
        stub(node_status,"get_ips",function () return 'caca' end)
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

    it('a simple test to get links info and assert requiered fields are present', function()
        utils.log("holaaaaaaa")
        print("laaaaaaa")
        uci = config.get_uci_cursor()

        uci:set('network', 'lan', 'interface')
        uci:set('network', 'lan', 'ipaddr', '10.5.0.5')
        uci:set('network', 'lan', 'ip6addr', 'fd0d:fe46:8ce8::ab:cd00/64')
        utils.log("holaaaaaaa")
        uci:commit('network')
        local node = network_nodes._create_node()
        utils.log("holaaaaaaa")
        utils.log(utils.release_info()['DISTRIB_RELEASE'])
        utils.log("\n")
        utils.log(JSON.stringify(node))
        utils.log("\n")
        nodeinfo = get_node_info()
        utils.log(JSON.stringify(nodeinfo))
    end)
end)