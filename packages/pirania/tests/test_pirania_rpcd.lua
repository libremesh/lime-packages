local utils = require "lime.utils"
local test_utils = require "tests.utils"
local json = require 'luci.jsonc'


require('packages/pirania/tests/pirania_test_utils').fake_for_tests()
local vouchera = require('voucher.vouchera')


local test_file_name = "packages/pirania/files/usr/libexec/rpcd/pirania"
local pirania = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call

local current_time_s = 1008513158

describe('pirania rpcd tests #piraniarpcd', function()
    local snapshot -- to revert luassert stubs and spies
    it('test list methods', function()
        local response  = rpcd_call(pirania, {'list'})
        assert.is.equal(0, response.status.no_params)
    end)

    it('test add three vouchers', function()
        local json_data = json.stringify({name='foo', duration_m=100, activation_deadline=nil, qty=3})
        local response  = rpcd_call(pirania, {'call', 'add_vouchers'}, json_data)
        assert.is.equal("ok", response.status)
        assert.is.equal(3, #response.vouchers)

        vouchera.init()
        assert.is.equal(response.vouchers[1].code, vouchera.get_by_id(response.vouchers[1].id).code)
    end)

    it('test rename voucher', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})

        spy.on(vouchera, "rename")
        local response  = rpcd_call(pirania, {'call', 'rename'}, json.stringify({id=voucher.id, name='bar'}))
        assert.is.equal("ok", response.status)
        assert.stub.spy(vouchera.rename).was.called_with(voucher.id, 'bar')
    end)

    it('test list vouchers', function()
        local json_data = json.stringify({name='foo', duration_m=100, activation_deadline=os.time()+10, permanent = false, qty=5})
        local response = rpcd_call(pirania, {'call', 'add_vouchers'}, json_data)

        spy.on(vouchera, "list")
        local response  = rpcd_call(pirania, {'call', 'list_vouchers'}, '{}')
        assert.is.equal("ok", response.status)
        assert.is.equal(5, #response.vouchers)
        assert.stub.spy(vouchera.list).was.called()
    end)

    it('test invalidate voucher', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})

        spy.on(vouchera, "remove_globally")
        local response  = rpcd_call(pirania, {'call', 'invalidate'}, json.stringify({id=voucher.id}))
        assert.is.equal("ok", response.status)
        assert.stub.spy(vouchera.remove_globally).was.called_with(voucher.id)

        local response  = rpcd_call(pirania, {'call', 'invalidate'}, json.stringify({id='invalidid'}))
        assert.is.equal("error", response.status)
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
