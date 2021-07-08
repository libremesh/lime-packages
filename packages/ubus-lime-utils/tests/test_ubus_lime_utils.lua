local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'

local test_file_name = "packages/ubus-lime-utils/files/usr/libexec/rpcd/lime-utils"
local ubus_lime_utils = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local uci
local snapshot -- to revert luassert stubs and spies

describe('ubus-lime-utils tests #ubuslimeutils', function()
    it('test list methods', function()
        local response  = rpcd_call(ubus_lime_utils, {'list'})
        assert.is.equal(0, response.get_notes.no_params)
    end)

    it('test get_notes', function()
        stub(utils, "read_file", function () return 'a note' end)

        local response  = rpcd_call(ubus_lime_utils, {'call', 'get_notes'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal("a note", response.notes)
        assert.stub(utils.read_file).was.called_with('/etc/banner.notes')
    end)

    it('test get_notes when there are no notes', function()
        local response  = rpcd_call(ubus_lime_utils, {'call', 'get_notes'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal("", response.notes)
    end)

    it('test set_notes', function()
        stub(utils, "read_file", function () return 'a note' end)
        stub(utils, "write_file", function ()  end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'set_notes'}, '{"text": "a new note"}')
        assert.is.equal("ok", response.status)
        assert.is.equal("a note", response.notes)
        assert.stub(utils.read_file).was.called_with('/etc/banner.notes')
    end)

    it('test get_cloud_nodes', function()
        stub(utils, "unsafe_shell", function () return 'lm-node1\nlm-node2\n' end)
        local response  = rpcd_call(ubus_lime_utils, {'call', 'get_cloud_nodes'}, '')
        assert.is.equal("ok", response.status)
        assert.are.same({"lm-node1", "lm-node2"}, response.nodes)
    end)

    it('test get_node_status', function()
        stub(utils, "unsafe_shell", function () return '' end)
        stub(utils, "uptime_s", function () return '123' end)

        local response  = rpcd_call(ubus_lime_utils, {'call', 'get_node_status'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal(utils.hostname(), response.hostname)
        assert.are.same({}, response.ips)
        assert.is.equal("123", response.uptime)
    end)

    it('test get_upgrade_info', function()
        stub(utils, "unsafe_shell", function () return '-1' end)
        stub(os, "execute", function () return '0' end)

        local response  = rpcd_call(ubus_lime_utils, {'call', 'get_upgrade_info'}, '')
        assert.is.equal("ok", response.status)
        assert.is_false(response.is_upgrade_confirm_supported)
        assert.are.same(-1, response.safe_upgrade_confirm_remaining_s)

        os.execute:revert()
        os.execute("rm -f /tmp/upgrade_info_cache")
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)
end)
