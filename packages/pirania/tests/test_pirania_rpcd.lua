local utils = require "lime.utils"
local test_utils = require "tests.utils"
local json = require 'luci.jsonc'
local test_utils = require 'tests.utils'
require('packages/pirania/tests/pirania_test_utils').fake_for_tests()
local vouchera = require('voucher.vouchera')
local portal = require('portal.portal')


local test_file_name = "packages/pirania/files/usr/libexec/rpcd/pirania"
local pirania = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local uci
local current_time_s = 1008513158

describe('pirania rpcd tests #piraniarpcd', function()
    local snapshot -- to revert luassert stubs and spies
    it('test list methods', function()
        local response  = rpcd_call(pirania, {'list'})
        assert.is.equal(0, response.get_portal_config.no_params)
    end)

    it('test portal_config', function()
        stub(portal, "get_config", function () return {activated=false} end)
        stub(portal, "set_config", function () return true end)

        local response  = rpcd_call(pirania, {'call', 'get_portal_config'}, '')
        assert.is.equal("ok", response.status)
        assert.is_false(response.activated)
        assert.stub.spy(portal.get_config).was.called()


        local json_data = json.stringify({activated=false, with_vouchers=true})
        local response  = rpcd_call(pirania, {'call', 'set_portal_config'}, json_data)
        assert.is.equal("ok", response.status)
        assert.stub.spy(portal.set_config).was.called_with(false, true)

        stub(portal, "set_config", function () return nil, 'errormsg' end)
        local json_data = json.stringify({activated=true, with_vouchers=false})
        local response  = rpcd_call(pirania, {'call', 'set_portal_config'}, json_data)
        assert.is.equal("error", response.status)
        assert.is.equal("errormsg", response.message)
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

        spy.on(vouchera, "invalidate")
        local response  = rpcd_call(pirania, {'call', 'invalidate'}, json.stringify({id=voucher.id}))
        assert.is.equal("ok", response.status)
        assert.stub.spy(vouchera.invalidate).was.called_with(voucher.id)

        local response  = rpcd_call(pirania, {'call', 'invalidate'}, json.stringify({id='invalidid'}))
        assert.is.equal("error", response.status)
    end)


    before_each('', function()
        snapshot = assert:snapshot()
        stub(os, "time", function () return current_time_s end)
        stub(portal, "update_captive_portal", function() end)
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        local p = io.popen("rm -rf /tmp/pirania_vouchers")
        p:read('*all')
        p:close()
        test_utils.teardown_test_uci(uci)
    end)
end)
