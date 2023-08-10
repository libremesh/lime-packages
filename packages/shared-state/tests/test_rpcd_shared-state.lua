local utils = require "lime.utils"
local test_utils = require "tests.utils"
local system = require 'lime.system'
local json = require "luci.jsonc"
local shared_state = require("shared-state")                                                    


local test_file_name = "packages/shared-state/files/usr/libexec/rpcd/shared-state"
local shared_state_rpc = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local uci

describe('ubus-shared-state tests #ubus-shared-state', function()
    before_each('', function()
        test_dir = test_utils.setup_test_dir()
        shared_state.DATA_DIR = test_dir
        shared_state.PERSISTENT_DATA_DIR = test_dir
    end)

    after_each('', function()
        test_utils.teardown_test_dir()
    end)

    it('test list methods', function()
        local response  = rpcd_call(shared_state_rpc, {'list'})
        assert.is.equal("value", response.get_from_sharedState.data_type)
        assert.is.equal("value", response.get_from_sharedState_muti_writer.data_type)
        assert.is.equal("value", response.insert_into_sharedState_muti_writer.data_type)
        assert.is.equal("value", response.insert_into_sharedState_muti_writer.json)

    end)

    it('test get data ', function()
        local sharedStateA = shared_state.SharedState:new('wifi_links_info')
        sharedStateA:insert({ bar = 'foo', baz = 'qux', zig = 'zag'})
        local dbA = sharedStateA:get()
        assert.is.equal(dbA.bar.data, 'foo')
        assert.is.equal(dbA.baz.data, 'qux')
        assert.is.equal(dbA.zig.data, 'zag')
        local response  = rpcd_call(shared_state_rpc,{'call','get_from_sharedState'},'{"data_type": "wifi_links_info"}')
        assert.is.equal(response.bar.data, 'foo')
        assert.is.equal(response.baz.data, 'qux')
        assert.is.equal(response.zig.data, 'zag')
    end)


    it('test get multiwriter data ', function()
        local sharedStateA = shared_state.SharedStateMultiWriter:new('A')
        sharedStateA:insert({ bar = 'foo', baz = 'qux', zig = 'zag'})
        local dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('zag', dbA.zig.data)
        local response  = rpcd_call(shared_state_rpc,{'call','get_from_sharedState_muti_writer'},'{"data_type": "A"}')
        assert.is.equal(response.bar.data, 'foo')
        assert.is.equal(response.baz.data, 'qux')
        assert.is.equal(response.zig.data, 'zag')
    end)
    
    it('test set multiwriter data ', function()
        local sharedStateA = shared_state.SharedStateMultiWriter:new('A')
        sharedStateA:insert({ bar = 'foo', baz = 'qux', zig = 'zag'})
        local dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('zag', dbA.zig.data)
        local response  = rpcd_call(shared_state_rpc,{'call','insert_into_sharedState_muti_writer'},'{"data_type": "A", "json": {"zig": "newzag"}}')
        local dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('newzag', dbA.zig.data)
    end)

end)
