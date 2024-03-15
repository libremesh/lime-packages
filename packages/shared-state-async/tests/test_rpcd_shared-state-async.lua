local testUtils = require "tests.utils"
local sharedState = require("shared-state")
local json = require("luci.jsonc")

local testFileName = "packages/shared-state-async/files/usr/libexec/rpcd/shared-state-async"
local sharedStateRpc = testUtils.load_lua_file_as_function(testFileName)
local rpcdCall = testUtils.rpcd_call

--since there is no Shared State async binary, testing possiblities are reduced
--manual testing can be done on a router with bat-hosts package using this commands:
--ubus -S call shared-state-async get "{'data_type': 'bat-hosts'}"
--ubus -S call shared-state-async sync "{'data_type': 'bat-hosts'}"
--ubus -S call shared-state-async sync "{'data_type': 'bat-hosts' ,'peers_ip':['10.0.0.1','10.0.0.2']}'"


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
        assert.is.equal("value", response.get.data_type)
        assert.is.equal("value", response.sync.data_type)
        assert.is.equal("value", response.sync.peers_ip)

    end)
end)
