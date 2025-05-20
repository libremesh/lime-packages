local testUtils = require "tests.utils"
local sharedState = require("shared-state")
local json = require("luci.jsonc")

local testFileName = "packages/shared-state-async/files/usr/libexec/rpcd/shared-state-async"


--since there is no Shared State async binary, testing possiblities are reduced
--also testing the full 
--manual testing can be done on a router with bat-hosts package using this commands:
--ubus -S call shared-state-async get "{'data_type': 'bat-hosts'}"
--ubus -S call shared-state-async sync "{'data_type': 'bat-hosts'}"
--ubus -S call shared-state-async sync "{'data_type': 'bat-hosts' ,'peers_ip':['10.0.0.1','10.0.0.2']}'"


describe('ubus-shared-state tests #ubus-shared-state', function()

    it('test list methods', function()
        local response = utils.unsafe_shell(testFileName.." list")
        response = json.parse(response)
        assert.is.equal("str", response.get.data_type)
        assert.is.equal("str", response.sync.data_type)
        assert.is.equal("str", response.sync.peers_ip)
    end)
end)
