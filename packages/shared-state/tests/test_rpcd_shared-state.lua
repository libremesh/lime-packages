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
        utils.log('\n')
        utils.printJson(response)
        utils.log('\n')
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

    


    it('test set multiwriter big chunk of data ', function()
        
        local response  = rpcd_call(shared_state_rpc,{'call','insert_into_sharedState_muti_writer'},'{"data_type": "A", "json": {"zig": "zag"}}')
        response  = rpcd_call(shared_state_rpc,{'call','get_from_sharedState_muti_writer'},'{"data_type": "A"}')
        assert.is.equal(response.zig.data, 'zag')

        response  = rpcd_call(shared_state_rpc,{'call','insert_into_sharedState_muti_writer'},'{"data_type": "ref_state_wifilinks", "json": {"primero":{"bleachTTL":23,"data":[{"tx_rate":135000,"dst_mac":"A0:F3:C1:46:28:97","chains":[-60,-60],"src_mac":"a8:40:41:1d:f9:35","rx_rate":150000,"signal":-57},{"tx_rate":135000,"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-55],"src_mac":"a8:40:41:1d:f9:35","rx_rate":243000,"signal":-53}],"author":"primero"},"LiMe-da4eaa":{"bleachTTL":27,"data":[{"tx_rate":57800,"dst_mac":"A0:F3:C1:46:28:96","chains":[4,-46],"src_mac":"14:cc:20:da:4e:ab","rx_rate":58500,"signal":4},{"tx_rate":300000,"dst_mac":"A0:F3:C1:46:28:97","chains":[-50,-52],"src_mac":"14:cc:20:da:4e:ac","rx_rate":270000,"signal":-48},{"tx_rate":240000,"dst_mac":"A8:40:41:1D:F9:35","chains":[-81,-67],"src_mac":"14:cc:20:da:4e:ac","rx_rate":135000,"signal":-67}],"author":"LiMe-da4eaa"},"LiMe-462895":{"bleachTTL":28,"data":[{"tx_rate":21700,"dst_mac":"14:CC:20:DA:4E:AB","chains":[5,-48],"signal":5,"rx_rate":43300,"src_mac":"a0:f3:c1:46:28:96"},{"tx_rate":270000,"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-44],"signal":-44,"rx_rate":270000,"src_mac":"a0:f3:c1:46:28:97"},{"tx_rate":243000,"dst_mac":"A8:40:41:1D:F9:35","chains":[-76,-65],"signal":-65,"rx_rate":135000,"src_mac":"a0:f3:c1:46:28:97"}],"author":"LiMe-462895"}}}')
        response  = rpcd_call(shared_state_rpc,{'call','get_from_sharedState_muti_writer'},'{"data_type": "ref_state_wifilinks"}')
        assert.is.equal(response.primero.data.bleachTTL,23)
        assert.is.equal(response.primero.data.author,"primero")

        response  = rpcd_call(shared_state_rpc,{'call','insert_into_sharedState_muti_writer'},'{"data_type": "ref_state_wifilinks", "json": {"primero":{"bleachTTL":27,"data":[{"tx_rate":135000,"dst_mac":"A0:F3:C1:46:28:97","chains":[-60,-60],"src_mac":"a8:40:41:1d:f9:35","rx_rate":150000,"signal":-57},{"tx_rate":135000,"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-55],"src_mac":"a8:40:41:1d:f9:35","rx_rate":243000,"signal":-53}],"author":"primero"},"LiMe-da4eaa":{"bleachTTL":27,"data":[{"tx_rate":57800,"dst_mac":"A0:F3:C1:46:28:96","chains":[4,-46],"src_mac":"14:cc:20:da:4e:ab","rx_rate":58500,"signal":4},{"tx_rate":300000,"dst_mac":"A0:F3:C1:46:28:97","chains":[-50,-52],"src_mac":"14:cc:20:da:4e:ac","rx_rate":270000,"signal":-48},{"tx_rate":240000,"dst_mac":"A8:40:41:1D:F9:35","chains":[-81,-67],"src_mac":"14:cc:20:da:4e:ac","rx_rate":135000,"signal":-67}],"author":"LiMe-da4eaa"},"LiMe-462895":{"bleachTTL":28,"data":[{"tx_rate":21700,"dst_mac":"14:CC:20:DA:4E:AB","chains":[5,-48],"signal":5,"rx_rate":43300,"src_mac":"a0:f3:c1:46:28:96"},{"tx_rate":270000,"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-44],"signal":-44,"rx_rate":270000,"src_mac":"a0:f3:c1:46:28:97"},{"tx_rate":243000,"dst_mac":"A8:40:41:1D:F9:35","chains":[-76,-65],"signal":-65,"rx_rate":135000,"src_mac":"a0:f3:c1:46:28:97"}],"author":"LiMe-462895"}}}')
        response  = rpcd_call(shared_state_rpc,{'call','get_from_sharedState_muti_writer'},'{"data_type": "ref_state_wifilinks"}')
        assert.is.equal(response.primero.data.bleachTTL,27)
        assert.is.equal(response.primero.data.author,"primero")

        response  = rpcd_call(shared_state_rpc,{'call','insert_into_sharedState_muti_writer'},'{"data_type": "ref_state_wifilinks", "json": {"primero":{"bleachTTL":23,"data":[{"tx_rate":135000,"dst_mac":"A0:F3:C1:46:28:97","chains":[-60,-60],"src_mac":"a8:40:41:1d:f9:35","rx_rate":150000,"signal":-57},{"tx_rate":135000,"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-55],"src_mac":"a8:40:41:1d:f9:35","rx_rate":243000,"signal":-53}],"author":"primero"},"LiMe-da4eaa":{"bleachTTL":27,"data":[{"tx_rate":57800,"dst_mac":"A0:F3:C1:46:28:96","chains":[4,-46],"src_mac":"14:cc:20:da:4e:ab","rx_rate":58500,"signal":4},{"tx_rate":300000,"dst_mac":"A0:F3:C1:46:28:97","chains":[-50,-52],"src_mac":"14:cc:20:da:4e:ac","rx_rate":270000,"signal":-48},{"tx_rate":240000,"dst_mac":"A8:40:41:1D:F9:35","chains":[-81,-67],"src_mac":"14:cc:20:da:4e:ac","rx_rate":135000,"signal":-67}],"author":"LiMe-da4eaa"},"LiMe-462895":{"bleachTTL":28,"data":[{"tx_rate":21700,"dst_mac":"14:CC:20:DA:4E:AB","chains":[5,-48],"signal":5,"rx_rate":43300,"src_mac":"a0:f3:c1:46:28:96"},{"tx_rate":270000,"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-44],"signal":-44,"rx_rate":270000,"src_mac":"a0:f3:c1:46:28:97"},{"tx_rate":243000,"dst_mac":"A8:40:41:1D:F9:35","chains":[-76,-65],"signal":-65,"rx_rate":135000,"src_mac":"a0:f3:c1:46:28:97"}],"author":"LiMe-462895"}}}')
        response  = rpcd_call(shared_state_rpc,{'call','get_from_sharedState_muti_writer'},'{"data_type": "ref_state_wifilinks"}')
        assert.is.equal(response.primero.data.bleachTTL,23)
        assert.is.equal(response.primero.data.author,"primero")

    end)


end)
