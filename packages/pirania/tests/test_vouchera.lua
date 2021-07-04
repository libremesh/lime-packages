local test_utils = require 'tests.utils'
local fs = require("nixio.fs")

local config = require('voucher.config')
config.db_path = '/tmp/pirania_vouchers'
config.prune_expired_for_days = '30'
local vouchera = require('voucher.vouchera')
local utils = require('voucher.utils')
local hooks = require('voucher.hooks')

-- fake hooks
hooks.run = function(action) end

function utils.log(...)
    print(...)
end

local current_time_s = 1008513158

describe('Vouchera tests #vouchera', function()
    local snapshot -- to revert luassert stubs and spies
    it('vouchera init empty', function()
        vouchera.init()
        assert.is.equal(0, #vouchera.vouchers)
    end)

    it('vouchera init with broken database does not crash', function()
        os.execute("mkdir /tmp/pirania; echo '{asdasd,,,asd.' > /tmp/pirania/broken.json")
        vouchera.init()
        assert.is.equal(0, #vouchera.vouchers)
    end)

    it('init and compare vouchers', function()
        vouchera.init()
        local expiration_date = os.time()
        local v = {name='myvoucher', code='secret_code', expiration_date=expiration_date}
        local voucher_a = vouchera.voucher(v)
        local voucher_b = vouchera.voucher(v)
        v.name = 'othername'
        local voucher_c = vouchera.voucher(v)
        v.name, v.code = 'myvoucher', 'othercode'
        local voucher_d = vouchera.voucher(v)
        v.code, v.expiration_date = 'myvoucher', v.expiration_date + 1
        local voucher_e = vouchera.voucher(v)
        local voucher_f = vouchera.voucher({name='myvoucher', code='secret_code', expiration_date=expiration_date, mod_counter=2})
        local voucher_g = vouchera.voucher({name='myvoucher', code='secret_code', expiration_date=expiration_date, mod_counter=3})

        assert.is.equal(voucher_a, voucher_b)
        assert.is.not_equal(voucher_a, voucher_c)
        assert.is.not_equal(voucher_a, voucher_d)
        assert.is.not_equal(voucher_a, voucher_e)
        assert.is.not_equal(voucher_a, voucher_f)
        assert.is.not_equal(voucher_f, voucher_g)

        local voucher_h = vouchera.voucher({name='myvoucher', code='secret_code', id='foo', expiration_date=expiration_date})
        local voucher_i = vouchera.voucher({name='myvoucher', code='secret_code', id='foo', expiration_date=expiration_date})
        local voucher_j = vouchera.voucher({name='myvoucher', code='secret_code', id='bar', expiration_date=expiration_date})
        assert.is.equal(voucher_h, voucher_i)
        assert.is.not_equal(voucher_h, voucher_j)
    end)

    it('vouchera create and reload database', function()
        vouchera.init()
        local expiration_date = os.time()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', expiration_date=expiration_date})
        assert.is.equal('myvoucher', voucher.id)
        assert.is.equal('foo', voucher.name)
        assert.is.equal('secret_code', voucher.code)
        assert.is_nil(voucher.mac)
        assert.is.equal(expiration_date, voucher.expiration_date)

        v1 = vouchera.vouchers['myvoucher']
        vouchera.init()
        v2 = vouchera.vouchers['myvoucher']
        assert.is.equal(v1, v2)
        assert.is.not_nil(v1)
    end)

    it('activate vouchers', function()

        vouchera.init()
        local expiration_date = os.time() + 1000

        assert.is_false(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
        assert.is_false(vouchera.is_activable('secret_code'))

        local voucher = vouchera.add({name='myvoucher', code='secret_code', expiration_date=expiration_date})
        assert.is.equal(1, voucher.mod_counter)
        assert.is.not_false(vouchera.is_activable('secret_code'))
        assert.is.not_false(vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff"))

        assert.is.equal(2, voucher.mod_counter)
        assert.is_false(vouchera.is_activable('secret_code'))
        assert.is_true(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))

        --! let's pretend that the expiration date is in the past now
        stub(os, "time", function () return expiration_date + 1 end)
        assert.is_false(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
    end)

    it('vouchera create with duration and activate', function()
        vouchera.init()
        local minutes = 10
        local expiration_date = os.time() + minutes * 60

        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=minutes})

        assert.is_nil(voucher.expiration_date)
        local voucher = vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.is.equal(expiration_date, voucher.expiration_date)
    end)

    it('deactivate vouchers', function()
        vouchera.init()
        local expiration_date = os.time() + 1000

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', expiration_date=expiration_date})

        assert.is.equal(1, voucher.mod_counter)

        local voucher = vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.is.not_false(voucher)
        assert.is_true(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
        assert.is.equal(2, voucher.mod_counter)

        local ret = vouchera.deactivate('myvoucher')
        assert.is.equal(3, voucher.mod_counter)
        assert.is_nil(voucher.mac)
        assert.is_true(ret)
        assert.is_false(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
    end)

    it('add and remove vouchers', function()
        vouchera.init()
        local expiration_date = os.time()

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', expiration_date=expiration_date})
        assert.is_true(vouchera.remove_locally('myvoucher'))
        assert.is_nil(vouchera.vouchers['myvoucher'])
        vouchera.init()
        assert.is_nil(vouchera.vouchers['myvoucher'])
        assert.is_nil(vouchera.remove_locally('myvoucher'))
    end)

    it('add and remove globally vouchers', function()
        vouchera.init()
        local expiration_date = os.time() + 1000

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', expiration_date=expiration_date})
        assert.is_false(vouchera.should_be_pruned(voucher))
        assert.is_true(vouchera.remove_globally('myvoucher'))
        assert.is.equal(os.time(), vouchera.vouchers['myvoucher'].expiration_date)
    end)

    it('test automatic pruning of old voucher', function()
        config.prune_expired_for_days = '30'
        vouchera.init()
        local expiration_date = os.time() - vouchera.PRUNE_OLDER_THAN_S
        local v = vouchera.voucher({id='myvoucher', name='foo', code='secret_code', expiration_date=expiration_date})
        local voucher = vouchera.add(v)

        assert.is_not_nil(vouchera.vouchers['myvoucher'])

        -- voucher is pruned when vouchera is initialized
        vouchera.init()
        assert.is_nil(vouchera.vouchers['myvoucher'])
    end)

    it('test automatic pruning is not removing a not too old voucher', function()
        config.prune_expired_for_days = '100'
        vouchera.init()
        local some_seconds = 10
        local expiration_date = os.time() - vouchera.PRUNE_OLDER_THAN_S + some_seconds
        local v = vouchera.voucher({id='myvoucher', name='foo', code='secret_code',
                                    expiration_date=expiration_date})

        local voucher = vouchera.add(v)

        assert.is_not_nil(vouchera.vouchers['myvoucher'])

        -- voucher is not pruned when vouchera is initialized
        vouchera.init()
        assert.is_not_nil(vouchera.vouchers['myvoucher'])
    end)

    it('test update expiration date', function()
        vouchera.init()
        local v = vouchera.voucher({name='myvoucher', code='secret_code', expiration_date=current_time_s})
        local voucher = vouchera.add(v)

        local new_expiration_date = current_time_s + 200
        assert.is_true(vouchera.update_expiration_date(v.id, new_expiration_date))
        assert.is.equal(new_expiration_date, voucher.expiration_date)
    end)


    before_each('', function()
        snapshot = assert:snapshot()
        stub(os, "time", function () return current_time_s end)
    end)

    after_each('', function()
        snapshot:revert()
        local p = io.popen("rm -rf " .. config.db_path)
        p:read('*all')
        p:close()
    end)

end)
