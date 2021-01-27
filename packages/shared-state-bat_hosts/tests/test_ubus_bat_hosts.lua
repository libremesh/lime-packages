local bat_hosts = require "bat-hosts"
local test_utils = require "tests.utils"

local test_file_name = "packages/shared-state-bat_hosts/files/usr/libexec/rpcd/bat-hosts"
local ubus_bat_hosts = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call

describe('ubus-bat-hosts tests #ubusbathosts', function()
    it('test get_bathost', function()
        stub(bat_hosts, "get_bathost",
            function() return { hostname = 'lime', iface = 'wlan1-mesh' } end
        )
        local response  = rpcd_call(ubus_bat_hosts, {'call', 'get_bathost'}, '{}')
        assert.is.equal("error", response.status)
        assert.is.equal("invalid mac", response.message)
        local response  = rpcd_call(ubus_bat_hosts, 
            {'call', 'get_bathost'}, '{"mac":"02:95:39:ab:cd:00"}')
        assert.is.equal("ok", response.status)
        assert.is.same({ hostname = 'lime', iface = 'wlan1-mesh' }, response.bathost)
    end)
end)
