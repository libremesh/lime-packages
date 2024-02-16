local testUtils = require "tests.utils"
local sharedState = require("shared-state")
local json = require("luci.jsonc")

local testFileName = "packages/shared-state-async/files/usr/libexec/rpcd/shared-state-async"
local sharedStateRpc = testUtils.load_lua_file_as_function(testFileName)
local rpcdCall = testUtils.rpcd_call

--sicce there is no Shared State async binary, testing posiblilites are reduced
--manual testing can be done on a routeer with bat-hosts package using this:
-- # ubus -S call shared-state-async getFromSharedState "{'data_type': 'bat-hosts'}"
-- # ubus -S call shared-state-async getFromSharedState "{'data_type': 'bat-hosss'}"
-- {"error":"invalid_data_type"}
-- # ubus -S call shared-state-async sync "{'data_type': 'bat-hosts' ,'peers_ip':['10.0.0.1','10.0.0.2']}'"
-- {"status":"success"}
-- # ubus -S call shared-state-async sync "{'data_type': 'bat-hosts' ,'peers_ip':['10.0.0.1','10.0..2']}'"
-- {"error":"invalid_peer_address"}
-- # ubus -S call shared-state-async sync "{'data_type': 'bat-hoss' ,'peers_ip':['10.0.0.1','10.0.0.2']}'"
-- {"error":"invalid_data_type"}



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
        assert.is.equal("value", response.sync.data_type)
        assert.is.equal("value", response.sync.peers_ip)

    end)
end)
