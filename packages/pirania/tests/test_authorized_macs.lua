local test_utils = require 'tests.utils'
local shared_state = require('shared-state')
local portal = require('portal.portal')

local AUTHORIZED_MACS_PATH = "packages/pirania/files/usr/bin/pirania_authorized_macs"

local uci

--! Capture stdout prints from the loaded script
local captured_output = {}
local function capture_print(...)
    local args = {...}
    for _, v in ipairs(args) do
        table.insert(captured_output, tostring(v))
    end
end

describe('pirania_authorized_macs script tests #authorizedmacs', function()
    local snapshot

    it('prints all authorized MACs when called without flags', function()
        stub(portal, "get_authorized_macs", function()
            return {'AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'}
        end)
        stub(portal, "get_unrestricted_macs", function()
            return {'11:22:33:44:55:66'}
        end)

        local script = test_utils.load_lua_file_as_function(AUTHORIZED_MACS_PATH)
        captured_output = {}
        stub(_G, "print", capture_print)
        script()
        _G.print:revert()

        assert.is.equal(2, #captured_output)
        assert.is.equal('AA:BB:CC:DD:EE:FF', captured_output[1])
        assert.is.equal('11:22:33:44:55:66', captured_output[2])
    end)

    it('prints only unrestricted MACs when called with --unrestricted', function()
        stub(portal, "get_authorized_macs", function()
            return {'AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'}
        end)
        stub(portal, "get_unrestricted_macs", function()
            return {'11:22:33:44:55:66'}
        end)

        local script = test_utils.load_lua_file_as_function(AUTHORIZED_MACS_PATH)
        captured_output = {}
        stub(_G, "print", capture_print)
        script('--unrestricted')
        _G.print:revert()

        assert.is.equal(1, #captured_output)
        assert.is.equal('11:22:33:44:55:66', captured_output[1])
    end)

    it('prints only unrestricted MACs when called with -u', function()
        stub(portal, "get_authorized_macs", function()
            return {'AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'}
        end)
        stub(portal, "get_unrestricted_macs", function()
            return {'11:22:33:44:55:66'}
        end)

        local script = test_utils.load_lua_file_as_function(AUTHORIZED_MACS_PATH)
        captured_output = {}
        stub(_G, "print", capture_print)
        script('-u')
        _G.print:revert()

        assert.is.equal(1, #captured_output)
        assert.is.equal('11:22:33:44:55:66', captured_output[1])
    end)

    it('prints nothing when there are no authorized MACs', function()
        stub(portal, "get_authorized_macs", function()
            return {}
        end)

        local script = test_utils.load_lua_file_as_function(AUTHORIZED_MACS_PATH)
        captured_output = {}
        stub(_G, "print", capture_print)
        script()
        _G.print:revert()

        assert.is.equal(0, #captured_output)
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        test_dir = test_utils.setup_test_dir()
        shared_state.PERSISTENT_DATA_DIR = test_dir
        shared_state.DATA_DIR = test_dir
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_dir()
        test_utils.teardown_test_uci(uci)
    end)
end)
