local utils = require "lime.utils"
local test_utils = require "tests.utils"
local json = require 'luci.jsonc'


require('packages/pirania/tests/pirania_test_utils').fake_for_tests()
local vouchera = require('voucher.vouchera')


local test_file_name = "packages/pirania/files/usr/libexec/rpcd/pirania"
local pirania = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call

describe('pirania rpcd tests #piraniarpcd', function()
    local snapshot -- to revert luassert stubs and spies
    it('test list methods', function()
        local response  = rpcd_call(pirania, {'list'})
        assert.is.equal(0, response.status.no_params)
    end)

    it('test add three vouchers', function()
        --{name:string, duration_m: number, activation_deadline: timestamp, permanent: boolean, qty: number}
        local json_data = json.stringify({name='foo', duration_m=100, activation_deadline=nil, permanent = false, qty=3})
        local response  = rpcd_call(pirania, {'call', 'add_vouchers'}, json_data)
        assert.is.equal("ok", response.status)
        assert.is.equal(3, #response.vouchers)

        vouchera.init()
        assert.is.equal(response.vouchers[1].code, vouchera.vouchers[response.vouchers[1].id].code)
    end)

    it('test rename voucher', function()
        local json_data = json.stringify({name='foo', duration_m=100, activation_deadline=nil, permanent = false, qty=1})
        local response = rpcd_call(pirania, {'call', 'add_vouchers'}, json_data)
        local id = response.vouchers[1]['id']

        local response  = rpcd_call(pirania, {'call', 'rename'}, json.stringify({id=id, name='bar'}))
        assert.is.equal("ok", response.status)
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        stub(os, "time", function () return current_time_s end)
    end)

    after_each('', function()
        snapshot:revert()
        local p = io.popen("rm -rf /tmp/pirania_vouchers")
        p:read('*all')
        p:close()
    end)
end)
