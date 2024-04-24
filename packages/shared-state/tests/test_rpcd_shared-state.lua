local testUtils = require "tests.utils"
local sharedState = require("shared-state")
local json = require("luci.jsonc")

local testFileName = "packages/shared-state/files/usr/libexec/rpcd/shared-state"
local sharedStateRpc = testUtils.load_lua_file_as_function(testFileName)
local rpcdCall = testUtils.rpcd_call

describe('ubus-shared-state tests #ubus-shared-state', function()
    before_each('', function()
        testDir = testUtils.setup_test_dir()
        sharedState.DATA_DIR = testDir
        sharedState.PERSISTENT_DATA_DIR = testDir
    end)

    after_each('', function()
        testUtils.teardown_test_dir()
    end)

    it('test list methods', function()
        local response = rpcdCall(sharedStateRpc, {'list'})
        assert.is.equal("value", response.getFromSharedState.data_type)
        assert.is.equal("value", response.getFromSharedStateMultiWriter.data_type)
        assert.is.equal("value", response.insertIntoSharedStateMultiWriter.data_type)
        assert.is.equal("value", response.insertIntoSharedStateMultiWriter.json)
    end)

    it('test get data ', function()
        local sharedStateA = sharedState.SharedState:new('wifi_links_info')
        sharedStateA:insert({
            bar = 'foo',
            baz = 'qux',
            zig = 'zag'
        })
        local dbA = sharedStateA:get()
        assert.is.equal(dbA.bar.data, 'foo')
        assert.is.equal(dbA.baz.data, 'qux')
        assert.is.equal(dbA.zig.data, 'zag')
        local response = rpcdCall(sharedStateRpc, {'call', 'getFromSharedState'},
            '{"data_type": "wifi_links_info"}')
        assert.is.equal(response.data.bar, 'foo')
        assert.is.equal(response.data.baz, 'qux')
        assert.is.equal(response.data.zig, 'zag')
    end)

    it('test get multiwriter data from empty data_type ', function()
        local sharedStateA = sharedState.SharedStateMultiWriter:new('EMPTY')
        
        local response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'}, '{"data_type": "EMPTY"}')
        assert.is.equal(response.error, 404)
        assert.is.equal(next(response.data), next({}))
    end)


    it('test get multiwriter data ', function()
        local sharedStateA = sharedState.SharedStateMultiWriter:new('A')
        sharedStateA:insert({
            bar = 'foo',
            baz = 'qux',
            zig = 'zag'
        })
        local dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('zag', dbA.zig.data)
        local response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'}, '{"data_type": "A"}')
        assert.is.equal(response.data.bar, 'foo')
        assert.is.equal(response.data.baz, 'qux')
        assert.is.equal(response.data.zig, 'zag')
    end)

    it('test insert multiwriter data ', function()
        local sharedStateA = sharedState.SharedStateMultiWriter:new('A')
        sharedStateA:insert({
            bar = 'foo',
            baz = 'qux',
            zig = 'zag'
        })
        local dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('zag', dbA.zig.data)
        local response = rpcdCall(sharedStateRpc, {'call', 
            'insertIntoSharedStateMultiWriter'},
            '{"data_type": "A", "json": {"zig": "newzag"}}')
        dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('newzag', dbA.zig.data)
    end)

    it('test insert multiwriter data ', function()
        local sharedStateA = sharedState.SharedStateMultiWriter:new('A')
        sharedStateA:insert({
            bar = 'foo',
            baz = 'qux',
            zig = 'zag'
        })
        local response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'}, '{"data_type": "A"}')
        assert.is.equal('foo', response.data.bar)
        assert.is.equal('zag', response.data.zig)
        response.zig="newzag"
        callargs =  '{"data_type": "A", "json": '..json.stringify(response)..'}'
        local response = rpcdCall(sharedStateRpc, {'call', 
            'insertIntoSharedStateMultiWriter'},
            callargs)
        dbA = sharedStateA:get()
        assert.is.equal('foo', dbA.bar.data)
        assert.is.equal('newzag', dbA.zig.data)
    end)

    it('test set multiwriter big chunk of data ', function()
		
        local wifiStatusJsonsample27 = [[{"data_type": "ref_state_wifilinks",
		"json": {"primero":{"bleachTTL":27, "data":[{"tx_rate":135000,"dst_mac":
		"A0:F3:C1:46:28:97","chains":[-60,-60], "src_mac":"a8:40:41:1d:f9:35",
		"rx_rate":150000,"signal":-57},{"tx_rate":135000,"dst_mac":"14:CC:20:DA:4E:AC",
		"chains":[-57,-55],"src_mac":"a8:40:41:1d:f9:35","rx_rate":243000,
		"signal":-53}],"author":"primero"},"LiMe-da4eaa":{"bleachTTL":27,"data":
		[{"tx_rate":57800,"dst_mac":"A0:F3:C1:46:28:96","chains":[4,-46],
		"src_mac":"14:cc:20:da:4e:ab","rx_rate":58500,"signal":4},{"tx_rate":300000,
		"dst_mac":"A0:F3:C1:46:28:97","chains":[-50,-52],"src_mac":"14:cc:20:da:4e:ac",
		"rx_rate":270000,"signal":-48},{"tx_rate":240000,"dst_mac":"A8:40:41:1D:F9:35",
		"chains":[-81,-67],"src_mac":"14:cc:20:da:4e:ac","rx_rate":135000,
		"signal":-67}],"author":"LiMe-da4eaa"},"LiMe-462895":{"bleachTTL":28,"data":
		[{"tx_rate":21700,"dst_mac":"14:CC:20:DA:4E:AB","chains":[5,-48],
		"signal":5,"rx_rate":43300,"src_mac":"a0:f3:c1:46:28:96"},{"tx_rate":270000,
		"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-44],"signal":-44,
		"rx_rate":270000,"src_mac":"a0:f3:c1:46:28:97"},{"tx_rate":243000,
		"dst_mac":"A8:40:41:1D:F9:35","chains":[-76,-65],"signal":-65,"rx_rate":135000,
		"src_mac":"a0:f3:c1:46:28:97"}],"author":"LiMe-462895"}}}]]
        local wifiStatusJsonsample23 =[[{"data_type": "ref_state_wifilinks",
		"json": {"primero":{"bleachTTL":23, "data":[{"tx_rate":135000,"dst_mac":
		"A0:F3:C1:46:28:97","chains":[-60,-60], "src_mac":"a8:40:41:1d:f9:35",
		"rx_rate":150000,"signal":-57},{"tx_rate":135000,"dst_mac":"14:CC:20:DA:4E:AC",
		"chains":[-57,-55],"src_mac":"a8:40:41:1d:f9:35","rx_rate":243000,
		"signal":-53}],"author":"primero"},"LiMe-da4eaa":{"bleachTTL":27,"data":
		[{"tx_rate":57800,"dst_mac":"A0:F3:C1:46:28:96","chains":[4,-46],
		"src_mac":"14:cc:20:da:4e:ab","rx_rate":58500,"signal":4},{"tx_rate":300000,
		"dst_mac":"A0:F3:C1:46:28:97","chains":[-50,-52],"src_mac":"14:cc:20:da:4e:ac",
		"rx_rate":270000,"signal":-48},{"tx_rate":240000,"dst_mac":"A8:40:41:1D:F9:35",
		"chains":[-81,-67],"src_mac":"14:cc:20:da:4e:ac","rx_rate":135000,
		"signal":-67}],"author":"LiMe-da4eaa"},"LiMe-462895":{"bleachTTL":28,"data":
		[{"tx_rate":21700,"dst_mac":"14:CC:20:DA:4E:AB","chains":[5,-48],
		"signal":5,"rx_rate":43300,"src_mac":"a0:f3:c1:46:28:96"},{"tx_rate":270000,
		"dst_mac":"14:CC:20:DA:4E:AC","chains":[-57,-44],"signal":-44,
		"rx_rate":270000,"src_mac":"a0:f3:c1:46:28:97"},{"tx_rate":243000,
		"dst_mac":"A8:40:41:1D:F9:35","chains":[-76,-65],"signal":-65,"rx_rate":135000,
		"src_mac":"a0:f3:c1:46:28:97"}],"author":"LiMe-462895"}}}]]

        local response = rpcdCall(sharedStateRpc, {'call', 
            'insertIntoSharedStateMultiWriter'},
            '{"data_type": "A", "json": {"zig": "zag"}}')
        response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'}, '{"data_type": "A"}')
        assert.is.equal(response.data.zig, 'zag')

        response = rpcdCall(sharedStateRpc, {'call', 
            'insertIntoSharedStateMultiWriter'},
            wifiStatusJsonsample23)
        response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'},
            '{"data_type": "ref_state_wifilinks"}')
        assert.is.equal(response.data.primero.bleachTTL, 23)
        assert.is.equal(response.data.primero.author, "primero")

        response = rpcdCall(sharedStateRpc, {'call', 
        'insertIntoSharedStateMultiWriter'},wifiStatusJsonsample27)

        response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'},
            '{"data_type": "ref_state_wifilinks"}')

        assert.is.equal(response.data.primero.bleachTTL, 27)
        assert.is.equal(response.data.primero.author, "primero")

        response = rpcdCall(sharedStateRpc, {'call', 
            'insertIntoSharedStateMultiWriter'},
            wifiStatusJsonsample23)
        response = rpcdCall(sharedStateRpc, {'call', 
            'getFromSharedStateMultiWriter'},
            '{"data_type": "ref_state_wifilinks"}')
        assert.is.equal(response.data.primero.bleachTTL, 23)
        assert.is.equal(response.data.primero.author, "primero")
    end)
end)
