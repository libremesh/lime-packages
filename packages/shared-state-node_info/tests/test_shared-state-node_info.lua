local JSON = require("luci.jsonc")
local test_utils = require('tests.utils')
local utils = require('lime.utils')

local uci = nil

package.path = package.path .. ";packages/shared-state-node_info/files/usr/share/shared-state/publishers/?;;"
require ("shared-state-publish_node_info")

describe('Tests network_nodes #network_nodes', function ()
    before_each('', function()
        uci = test_utils.setup_test_uci()
        stub(utils, "release_info", function () return {DISTRIB_RELEASE='2021.1'} end)
        stub(utils, "current_board", function () return 'devboard' end)
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

    it('a simple test to get node info and assert requiered fields are present', function()
        uci = config.get_uci_cursor()
        uci:set('network', 'lan', 'interface')
        uci:set('network', 'lan', 'ipaddr', '10.5.0.5')
        uci:set('network', 'lan', 'ip6addr', 'fd0d:fe46:8ce8::ab:cd00/64')
        uci:commit('network')
        nodeinfo = get_node_info()
        assert.are.equal('devboard', nodeinfo.board)
        assert.are.equal('2021.1', nodeinfo.firmware_version)
        assert.are.equal('10.5.0.5', nodeinfo.ipv4)
        assert.are.equal('fd0d:fe46:8ce8::ab:cd00', nodeinfo.ipv6)
    end)
end)
