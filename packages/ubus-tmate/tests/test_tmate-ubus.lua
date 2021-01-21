local utils = require "lime.utils"
local test_utils = require "tests.utils"

local test_file_name = "packages/ubus-tmate/files/usr/libexec/rpcd/tmate"
local ubus_tmate = test_utils.load_lua_file_as_function(test_file_name)

local tmate = require "tmate"

local rpcd_call = test_utils.rpcd_call

describe('ubus-tmate tests #tmateubus', function()

    it('test list methods', function()
        local response  = rpcd_call(ubus_tmate, {'list'})
        assert.is.equal(0, response.get_session.no_params)
    end)

    it('get_session returns a string if no session exists', function()
        local response  = rpcd_call(ubus_tmate, {'call', 'get_session'}, '')
        assert.is.equal("no session", response.session)
    end)


    it('get_session returns an object if a session exists', function()
	stub(tmate, "open_session")
	stub(tmate, "wait_session_ready")
	stub(tmate, "get_rw_session")
	stub(tmate, "get_ro_session")
	stub(tmate, "get_connected_clients")
        stub(tmate, 'session_running', function () return true end)

        local response  = rpcd_call(ubus_tmate, {'call', 'open_session'}, '')
        local response  = rpcd_call(ubus_tmate, {'call', 'get_session'}, '')
        assert.is_not.equal("no session", response.session)
    end)
end)
