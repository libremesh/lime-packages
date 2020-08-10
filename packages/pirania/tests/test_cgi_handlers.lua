local test_utils = require 'tests.utils'
local config = require('voucher.config')
config.db_path = '/tmp/pirania'
local vouchera = require('voucher.vouchera')
local handlers = require('voucher.cgi_handlers')
local utils = require('voucher.utils')


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
        local voucher = vouchera.add({name='myvoucher', code='secret_code', expiration_date=os.time()+1000})

        local url = handlers.preactivate_voucher()
        -- redirecting to info as there is it is a validable code
        assert.is.equal('/info?voucher=secret_code', url)
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
        local voucher = vouchera.add({name='myvoucher', code='secret_code', expiration_date=os.time()+1000})

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
        local voucher = vouchera.add({name='myvoucher', code='secret_code', expiration_date=os.time()+1000})

        local url = handlers.activate_voucher()
        assert.is.equal(original_url, url)

        os.getenv:revert()
        utils.getIpv4AndMac:revert()
    end)

    it('Test activation with an already authorized client', function()
        stub(os, "getenv",  build_env('10.1.1.1', 'asdasdasd?voucher=secret_code'))
        stub(utils, "getIpv4AndMac", function () return {mac='AA:BB:CC:DD:EE:FF', ip='10.1.1.1'} end)
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', expiration_date=os.time()+1000})

        vouchera.activate('secret_code', 'AA:BB:CC:DD:EE:FF')

        local url = handlers.activate_voucher()
        assert.is.equal('/authenticated', url)
        os.getenv:revert()
        utils.getIpv4AndMac:revert()
    end)

    after_each('', function()
        local p = io.popen("rm -rf " .. config.db_path)
        p:read('*all')
        p:close()
    end)

end)
