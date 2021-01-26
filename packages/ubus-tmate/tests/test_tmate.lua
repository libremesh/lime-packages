local utils = require "lime.utils"
local test_utils = require "tests.utils"

local tmate = require "tmate"

describe('ubus-tmate tests #tmate', function()

    it('get_session returns a valid session', function()
	expectedResponse = "ssh NnAR3Md9HJ7NTJhqVsxqW2P8m@nyc1.tmate.io"
        stub(tmate, 'cmd_as_str', function () return expectedResponse.."\n" end)

	tmate.open_session()
	tmate.wait_session_ready()

	local response = tmate.get_rw_session()
        assert.is.equal(expectedResponse, response)

	local response = tmate.get_ro_session()
        assert.is.equal(expectedResponse, response)

	tmate.close_session()
    end)

    it('get_session returns an empty session when no open session', function()
	expectedResponse = ""
        stub(tmate, 'cmd_as_str', function () return expectedResponse.."\n" end)

	local response = tmate.get_rw_session()
        assert.is.equal(expectedResponse, response)

	local response = tmate.get_ro_session()
        assert.is.equal(expectedResponse, response)
    end)

    it('get_session returns an empty session when you close an open session', function()
	expectedResponse = ""
        stub(tmate, 'cmd_as_str', function () return expectedResponse.."\n" end)

	tmate.open_session()
	tmate.wait_session_ready()
	tmate.close_session()

	local response = tmate.get_rw_session()
        assert.is.equal(expectedResponse, response)

	local response = tmate.get_ro_session()
        assert.is.equal(expectedResponse, response)
    end)

    it('get_connected_clients returns empty string when no session exists', function()
	expectedResponse = ""
        stub(tmate, 'cmd_as_str', function () return expectedResponse.."\n" end)

	local response = tmate.get_connected_clients()
        assert.is.equal(expectedResponse, response)
    end)

    it('get_connected_clients returns number of connected clients when connected', function()
	expectedResponse = "0"
        stub(tmate, 'cmd_as_str', function () return expectedResponse.."\n" end)

	tmate.open_session()
	tmate.wait_session_ready()

	local response = tmate.get_connected_clients()
        assert.is.equal(expectedResponse, response)

	tmate.close_session()
    end)

end)
