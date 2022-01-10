local test_utils = require("tests.utils")
local match = require("luassert.match")
local REDIRECT_PATH = "packages/pirania/files/www/pirania-redirect/redirect"
local CONFIG_PATH = "./packages/pirania/files/etc/config/pirania"

local FAKE_ENV = {
    HTTP_HOST = 'detectportal.firefox.com',
    REQUEST_URI = '/success.txt'
}

local uci

describe('Pirania redirect request handler #portalredirect', function()
    local snapshot
    
    it('should redirect to url_auth when vouchers are active', function()
        uci:set('pirania', 'base_config', 'with_vouchers', '1')
        uci:commit('pirania')
        local url_auth = uci:get('pirania', 'base_config', 'url_auth')
        handle_request(FAKE_ENV)
        assert.stub(uhttpd.send).was_called_with(
            'Location: http://thisnode.info' .. url_auth ..
            '?prev=http%3A%2F%2Fdetectportal.firefox.com%2Fsuccess.txt' ..
            '\r\n'
        )
    end)

    it('should redirect to read_for_access portal when vouchers are non active', function()
        uci:set('pirania', 'base_config', 'with_vouchers', '0')
        uci:commit('pirania')
        local url_portal = uci:get('pirania', 'read_for_access', 'url_portal')
        handle_request(FAKE_ENV)
        assert.stub(uhttpd.send).was_called_with(
            'Location: http://thisnode.info' .. url_portal ..
            '?prev=http%3A%2F%2Fdetectportal.firefox.com%2Fsuccess.txt' ..
            '\r\n'
        )
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        test_dir = test_utils.setup_test_dir()
        uci = test_utils.setup_test_uci()
        local default_cfg = io.open(CONFIG_PATH):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)
        test_utils.load_lua_file_as_function(REDIRECT_PATH)()
        _G.uhttpd = {
            send = function(msg) end
        }
        stub(uhttpd, "send")
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_dir()
        test_utils.teardown_test_uci(uci)
    end)
end)
