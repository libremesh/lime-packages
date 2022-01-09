local test_utils = require 'tests.utils'
local config = require('voucher.config')
local vouchera = require('voucher.vouchera')
local handlers = require('voucher.cgi_handlers')
local utils = require('voucher.utils')
local rfa_handlers = require('read_for_access.cgi_handlers')
local read_for_access = require('read_for_access.read_for_access')
local portal = require('portal.portal')

require('packages/pirania/tests/pirania_test_utils').fake_for_tests()

function utils.log(...)
    print(...)
end


function build_env(ip_address, querystring)
    local function get_env(key)
        if key == 'REMOTE_ADDR' then
            return ip_address
        elseif key == 'QUERY_STRING' then
            return querystring
        end
    end
    return get_env
end


describe('Vouchera tests #piraniahandlers', function()
    it('Test preactivation of a valid voucher', function()
        stub(os, "getenv",  build_env('10.1.1.1', 'asdasdasd?voucher=secret_code'))
        local url = handlers.preactivate_voucher()
        assert.is.equal('/fail', url)
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=15})

        local url = handlers.preactivate_voucher()
        -- redirecting to info as there is it is a validable code
        assert.is.equal('/info?voucher=secret_code', url)
        os.getenv:revert()
    end)

    it('Test preactivation of a validable voucher with prev url', function()
        local original_url = 'http://original.url/baz?a=1&b=2'
        stub(os, "getenv",  build_env('10.1.1.1', 'asdasdasd?voucher=secret_code&prev=' .. utils.urlencode(original_url)))
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=15})
        local url = handlers.preactivate_voucher()
        -- redirecting to info as there is it is a validable code
        assert.is.equal('/info?voucher=secret_code&prev='..original_url, url)
        os.getenv:revert()
    end)

    it('Test preactivation of an ivalid voucher', function()
        stub(os, "getenv",  build_env('10.1.1.1', 'asdasdasd?voucher=secret_code'))
        local url = handlers.preactivate_voucher()
        assert.is.equal('/fail', url)

        vouchera.init()

        local url = handlers.preactivate_voucher()
        assert.is.equal('/fail', url)
        os.getenv:revert()
    end)

    it('Test preactivation of an already authorized client', function()
        stub(os, "getenv",  build_env('10.1.1.1', 'asdasdasd?voucher=secret_code'))
        stub(utils, "getIpv4AndMac", function () return {mac='AA:BB:CC:DD:EE:FF', ip='10.1.1.1'} end)
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=15})

        vouchera.activate('secret_code', 'AA:BB:CC:DD:EE:FF')

        local url = handlers.preactivate_voucher()
        assert.is.equal('/authenticated', url)
        os.getenv:revert()
        utils.getIpv4AndMac:revert()
    end)

    it('Test activation with previous url', function()
        local original_url = 'http://original.url/baz?a=1&b=2'

        stub(os, "getenv",  build_env('10.1.1.1', "asdasdasd?voucher=secret_code&prev="..utils.urlencode(original_url)))
        stub(utils, "getIpv4AndMac", function () return {mac='AA:BB:CC:DD:EE:FF', ip='10.1.1.1'} end)
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=15})

        local url = handlers.activate_voucher()
        assert.is.equal(original_url, url)

        os.getenv:revert()
        utils.getIpv4AndMac:revert()
    end)

    it('Test preactivation of invalid voucher with previous url', function()
        local original_url = 'http://original.url/baz?a=1&b=2'

        stub(os, "getenv",  build_env('10.1.1.1', "asdasdasd?voucher=secret_code&prev="..utils.urlencode(original_url)))

        local url = handlers.preactivate_voucher()
        assert.is.equal("/fail?prev="..original_url, url)

        os.getenv:revert()
    end)

    it('Test activation of invalid voucher with previous url', function()
        local original_url = 'http://original.url/baz?a=1&b=2'

        stub(os, "getenv",  build_env('10.1.1.1', "asdasdasd?voucher=secret_code&prev="..utils.urlencode(original_url)))

        local url = handlers.activate_voucher()
        assert.is.equal("/fail?prev="..original_url, url)

        os.getenv:revert()
    end)

    it('Test activation with an already authorized client', function()
        stub(os, "getenv",  build_env('10.1.1.1', 'asdasdasd?voucher=secret_code'))
        stub(utils, "getIpv4AndMac", function () return {mac='AA:BB:CC:DD:EE:FF', ip='10.1.1.1'} end)
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=15})
        
        vouchera.activate('secret_code', 'AA:BB:CC:DD:EE:FF')
        
        local url = handlers.activate_voucher()
        assert.is.equal('/authenticated', url)
        os.getenv:revert()
        utils.getIpv4AndMac:revert()
    end)
    
    before_each('', function()
        stub(portal, "update_captive_portal", function() end)
    end)

    after_each('', function()
        local p = io.popen("rm -rf /tmp/pirania_vouchers")
        p:read('*all')
        p:close()
    end)

end)


describe('read_for_access cgi_handler authorize_mac #readforaccess', function()
    local snapshot
    local uci
    local CONFIG_PATH = "./packages/pirania/files/etc/config/pirania"

    it('calls authorize_mac with the mac from the arp table for the client IP', function()
        rfa_handlers.authorize_mac()
        assert.stub(read_for_access.authorize_mac).was_called_with(
            'AA:BB:CC:DD:EE:FF'
        )
    end)
    
    it("doesn't call authorize_mac if vouchers are being used", function()
        uci:set('pirania', 'base_config', 'with_vouchers', "1")
        rfa_handlers.authorize_mac()
        assert.stub(read_for_access.authorize_mac).was_not.called()
    end)
    
    it("return prev url if there is one", function()
        local original_url = 'http://original.url/baz?a=1&b=2'
        local querystring = "?prev="..utils.urlencode(original_url)
        stub(os, "getenv", build_env('10.1.1.1', querystring))
        local url = rfa_handlers.authorize_mac()
        assert.is_equal(original_url, url)
    end)

    it("return authenticated url if there is no prev url", function()
        stub(os, "getenv", build_env('10.1.1.1'))
        local url = rfa_handlers.authorize_mac()
        local url_authenticated = uci:get('pirania', 'base_config', 'url_authenticated')
        assert.is_equal(url_authenticated, url)
    end)
    
    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
        local default_cfg = io.open(CONFIG_PATH):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)
        stub(os, "getenv",  build_env('10.1.1.1'))
        stub(utils, "getIpv4AndMac", function () return {mac='AA:BB:CC:DD:EE:FF', ip='10.1.1.1'} end)
        stub(read_for_access, "authorize_mac", function() return end)
        uci:set('pirania', 'base_config', 'with_vouchers', "0")
    end)
    
    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)
end)
