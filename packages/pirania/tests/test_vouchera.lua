local test_utils = require 'tests.utils'
local fs = require("nixio.fs")

local config = require('voucher.config')
local hooks = require('voucher.hooks')
local portal = require('portal.portal')
local test_utils_pirania = require('packages/pirania/tests/pirania_test_utils')
local vouchera = require('voucher.vouchera')
local utils = require('lime.utils')
local current_time_s = 1008513158

describe('Vouchera tests #vouchera', function()
    local snapshot -- to revert luassert stubs and spies
    it('vouchera init empty', function()
        vouchera.init()
        assert.is.equal(0, #vouchera.vouchers)
    end)

    it('vouchera init with broken database does not crash', function()
        os.execute:revert()
        os.execute("echo '{asdasd,,,asd.' > /tmp/pirania_vouchers/broken.json")
        vouchera.init()
        assert.is.equal(0, #vouchera.vouchers)
    end)

    it('init and compare vouchers', function()
        vouchera.init()
        local v = {name='myvoucher', code='secret_code', creation_date=current_time_s}
        local voucher_a = vouchera.voucher(v)
        local voucher_b = vouchera.voucher(v)
        v.name = 'othername'
        local voucher_c = vouchera.voucher(v)
        v.name, v.code = 'myvoucher', 'othercode'
        local voucher_d = vouchera.voucher(v)
        v.code = 'myvoucher'
        local voucher_e = vouchera.voucher(v)
        local voucher_f = vouchera.voucher({name='myvoucher', code='secret_code', mod_counter=2, creation_date=current_time_s})
        local voucher_g = vouchera.voucher({name='myvoucher', code='secret_code', mod_counter=3, creation_date=current_time_s})

        assert.is_not_nil(voucher_a)
        assert.is.equal(voucher_a, voucher_b)
        assert.is.not_equal(voucher_a, voucher_c)
        assert.is.not_equal(voucher_a, voucher_d)
        assert.is.not_equal(voucher_a, voucher_e)
        assert.is.not_equal(voucher_a, voucher_f)
        assert.is.not_equal(voucher_f, voucher_g)

        local voucher_h = vouchera.voucher({name='myvoucher', code='secret_code', id='foo', duration_m=100, creation_date=current_time_s})
        local voucher_i = vouchera.voucher({name='myvoucher', code='secret_code', id='foo', duration_m=100, creation_date=current_time_s})
        local voucher_j = vouchera.voucher({name='myvoucher', code='secret_code', id='bar', duration_m=100, creation_date=current_time_s})
        assert.is.equal(voucher_h, voucher_i)
        assert.is.not_equal(voucher_h, voucher_j)
    end)

    it('test add voucher', function()
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code'})
        assert.is.equal(voucher.author_node, utils.hostname())
        assert.is.equal(voucher.status(), 'available')
    end)

    it('Rename vouchers', function()
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code'})
        assert.is.equal(1, voucher.mod_counter)
        vouchera.rename(voucher.id, 'newname')
        assert.is.equal('newname', voucher.name)
        assert.is.equal(2, voucher.mod_counter)
    end)

    it('vouchera create and reload database', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code'})
        assert.is.equal('myvoucher', voucher.id)
        assert.is.equal('foo', voucher.name)
        assert.is.equal('secret_code', voucher.code)
        assert.is_nil(voucher.mac)
        assert.is.equal(current_time_s, voucher.creation_date)

        v1 = vouchera.get_by_id('myvoucher')
        vouchera.init()
        v2 = vouchera.get_by_id('myvoucher')
        assert.is.equal(v1, v2)
        assert.is.not_nil(v1)
    end)

    it('activate vouchers', function()
        vouchera.init()

        assert.is_false(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
        assert.is_false(vouchera.is_activable('secret_code'))

        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=100})
        assert.is.equal(1, voucher.mod_counter)
        assert.is.not_false(vouchera.is_activable('secret_code'))
        assert.is_false(voucher.is_active())
        assert.is.not_false(vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff"))

        assert.is.equal(2, voucher.mod_counter)
        assert.is.equal(current_time_s, voucher.activation_date)
        assert.is_false(vouchera.is_activable('secret_code'))
        assert.is_true(voucher.is_active())
        assert.is_true(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
        assert.is.equal(voucher.status(), 'active')

        --! let's pretend that the expiration date is in the past now
        stub(os, "time", function () return current_time_s + (101*60) end)
        assert.is_false(vouchera.is_mac_authorized("aa:bb:cc:dd:ee:ff"))
        assert.is_false(voucher.is_active())
    end)

    it('activate voucher calls and waits for captive portal update when activable', function()
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=100})
        -- when activable
        stub(portal, "update_captive_portal", function() end)
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.stub(portal.update_captive_portal).was_called_with(false)
        -- when no activable
        stub(portal, "update_captive_portal", function() end)
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.stub(portal.update_captive_portal).was_not_called()
    end)

    it('activate triggers db_change hooks when activable', function()
        vouchera.init()
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=100})
        -- when activable
        stub(hooks, "run", function() end)
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.stub(hooks.run).was_called_with("db_change")
        hooks.run:revert()
        -- when no activable
        stub(hooks, "run", function() end)
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.stub(hooks.run).was_not_called_with("db_change")
        hooks.run:revert()
    end)

    it('vouchera create with duration and activate', function()
        vouchera.init()
        local minutes = 10
        local expiration_date = os.time() + minutes * 60

        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=minutes})
        assert.is_nil(voucher.expiration_date())
        local voucher = vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.is.equal(expiration_date, voucher.expiration_date())
    end)

    it('create calls captive-portal update daemonized', function()
        vouchera.init()
        stub(portal, "update_captive_portal", function() end)
        vouchera.create('test', 2, 60)
        assert.stub(portal.update_captive_portal).was_called_with(true)
    end)

    it('create triggers db_change hooks', function()
        vouchera.init()
        stub(hooks, "run", function() end)
        vouchera.create('test', 2, 60)
        assert.stub(hooks.run).was_called_with("db_change")
    end)

    it('deactivate vouchers', function()
        vouchera.init()

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code'})
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

    it('test activation deadline', function()
        vouchera.init()
        deadline = current_time_s + 10
        local voucher = vouchera.add({name='myvoucher', code='secret_code', duration_m=100,
                                     activation_deadline=deadline})

        assert.is.not_false(vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff"))

        local voucher = vouchera.add({name='myvoucher2', code='secret_code2', duration_m=100,
                                     activation_deadline=deadline})
        assert.is_false(voucher.is_expired())
        assert.is.equal('available', voucher.status())
        stub(os, "time", function () return deadline + 1 end)
        assert.is_false(vouchera.activate('secret_code2', "aa:bb:cc:dd:ee:ff"))
        assert.is_true(voucher.is_expired())
        assert.is.equal('expired', voucher.status())

    end)

    it('add and remove vouchers', function()
        vouchera.init()

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code'})
        os.execute:revert()
        assert.is_true(vouchera.remove_locally('myvoucher'))
        assert.is_nil(vouchera.get_by_id('myvoucher'))
        vouchera.init()
        assert.is_nil(vouchera.get_by_id('myvoucher'))
        assert.is_nil(vouchera.remove_locally('myvoucher'))
    end)

    it('add and invalidate vouchers', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.is_true(voucher.is_active())
        assert.is_false(vouchera.should_be_pruned(voucher))
        assert.is_true(vouchera.invalidate('myvoucher'))
        assert.is_true(voucher.is_invalidated())
        assert.is_false(vouchera.should_be_pruned(voucher))
        assert.is_false(vouchera.is_activable(voucher))
        assert.is_false(voucher.is_active())

    end)

    it('invalidate return nils for invalid id', function()
        vouchera.init()
        assert.is_nil(vouchera.invalidate('non_existent_id'))
    end)

    it('invalidate calls captive portal update daemonized if the voucher was active', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        stub(portal, "update_captive_portal", function() end)
        vouchera.invalidate('myvoucher')
        assert.stub(portal.update_captive_portal).was_called_with(true)
    end)

    it('invalidate doesnt call captive portal update if the voucher was inactive', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})
        stub(portal, "update_captive_portal", function() end)
        vouchera.invalidate('myvoucher')
        assert.stub(portal.update_captive_portal).was_not_called()
    end)

    it('invalidates triggers db_change hooks', function()
        vouchera.init()
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        stub(hooks, "run", function() end)
        vouchera.invalidate('myvoucher')
        assert.stub(hooks.run).was_called_with("db_change")
    end)

    it('prune invalidated vouchers', function()
        vouchera.init()

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code'})
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.is_true(vouchera.invalidate('myvoucher'))

        assert.is.equal('invalidated', voucher.status())
        local pre_expiry_time = current_time_s + vouchera.PRUNE_OLDER_THAN_S - 1
        stub(os, "time", function () return pre_expiry_time end)
        assert.is_false(vouchera.should_be_pruned(voucher))
        stub(os, "time", function () return pre_expiry_time + 10 end)
        assert.is_true(vouchera.should_be_pruned(voucher))
    end)

    it('prune expired vouchers', function()
        vouchera.init()
        duration_m = 100
        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=duration_m})
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        local pre_expiry_time = current_time_s + vouchera.PRUNE_OLDER_THAN_S + (duration_m*60) - 1

        stub(os, "time", function () return pre_expiry_time end)
        assert.is_false(vouchera.should_be_pruned(voucher))
        stub(os, "time", function () return pre_expiry_time + 10 end)
        assert.is_true(vouchera.should_be_pruned(voucher))
    end)


    it('add and invalidate inactive vouchers', function()
        vouchera.init()

        local voucher = vouchera.add({id='myvoucher', name='foo', code='secret_code', duration_m=100})
        assert.is_false(vouchera.should_be_pruned(voucher))
        assert.is_true(vouchera.invalidate('myvoucher'))
        assert.is_false(vouchera.should_be_pruned(voucher))
        assert.is_false(vouchera.is_activable(voucher))
        assert.is_false(voucher.is_active())
        assert.is_true(voucher.is_invalidated())
    end)

    it('test automatic pruning of old voucher', function()
        config.prune_expired_for_days = '30'
        vouchera.init()
        local v = vouchera.voucher({id='myvoucher', name='foo', code='secret_code',
                                    duration_m=100, creation_date=current_time_s})
        local voucher = vouchera.add(v)
        vouchera.activate('secret_code', "aa:bb:cc:dd:ee:ff")
        assert.is_not_nil(vouchera.get_by_id('myvoucher'))

        -- voucher is pruned when vouchera is initialized
        stub(os, "time", function () return current_time_s+(31*60*60*24) end)
        os.execute:revert()
        vouchera.init()
        assert.is_nil(vouchera.get_by_id('myvoucher'))
    end)

    it('test automatic pruning is not removing a not too old voucher', function()
        config.prune_expired_for_days = '100'
        vouchera.init()
        local some_seconds = 10
        local v = vouchera.voucher({id='myvoucher', name='foo', code='secret_code',
                                    duration_m=100, creation_date=current_time_s})

        local voucher = vouchera.add(v)

        assert.is_not_nil(vouchera.get_by_id('myvoucher'))

        -- voucher is not pruned when vouchera is initialized
        stub(os, "time", function () return current_time_s+(31*60*60*24) end)
        vouchera.init()
        assert.is_not_nil(vouchera.get_by_id('myvoucher'))
    end)

    it('test create', function()
        vouchera.init()
        local base_name = 'foo'
        local qty = 1
        local duration_m = 100
        local created_vouchers = vouchera.create(base_name, qty, duration_m)
        assert.is.equal(#created_vouchers, qty)
        local v = vouchera.get_by_id(created_vouchers[1].id)
        assert.is.not_nil(v)
        assert.is.equal(duration_m, v.duration_m)
        assert.is.equal('foo', v.name)

        local qty = 5
        local duration_m = 100
        local deadline = current_time_s + 10
        local created_vouchers = vouchera.create(base_name, qty, duration_m, deadline)
        assert.is.equal(#created_vouchers, qty)

        local v1 = vouchera.get_by_id(created_vouchers[1].id)
        assert.is.equal('foo-1', v1.name)
        assert.is.equal(deadline, v1.activation_deadline)
        assert.is.equal('string', type(created_vouchers[1].code))
        assert.is.not_equal(created_vouchers[1].code, created_vouchers[2].code)

        local v5 = vouchera.get_by_id(created_vouchers[5].id)
        assert.is.equal('foo-5', v5.name)
    end)

    it('test list vouchers', function()
        vouchera.init()
        local base_name = 'foo'
        local qty = 5
        local duration_m = 100
        local created_vouchers = vouchera.create(base_name, qty, duration_m)

        local listed = vouchera.list()
        assert.is.equal(qty, #listed)
        assert.is.equal(100, listed[1].duration_m)
        assert.is.equal(100, listed[5].duration_m)
        assert.is_false(listed[1].permanent)
        assert.is_false(listed[1].is_active)
        assert.is.equal(utils.hostname(), listed[1].author_node)
        assert.is.equal('available', listed[1].status)
    end)

    -- Tranca Redes: Unrestricted voucher tests
    it('test create unrestricted voucher', function()
        vouchera.init()
        local voucher = vouchera.add({name='unrestricted_voucher', code='unrestricted_code', unrestricted=true})
        assert.is.equal(true, voucher.unrestricted)
    end)

    it('test create normal voucher has unrestricted false', function()
        vouchera.init()
        local voucher = vouchera.add({name='normal_voucher', code='normal_code'})
        assert.is.equal(false, voucher.unrestricted)
    end)

    it('test create batch with unrestricted flag', function()
        vouchera.init()
        local created_vouchers = vouchera.create('unrestricted', 3, 60, nil, true)
        assert.is.equal(3, #created_vouchers)
        for _, created in ipairs(created_vouchers) do
            local v = vouchera.get_by_id(created.id)
            assert.is.equal(true, v.unrestricted)
        end
    end)

    it('test create batch without unrestricted flag', function()
        vouchera.init()
        local created_vouchers = vouchera.create('normal', 3, 60)
        assert.is.equal(3, #created_vouchers)
        for _, created in ipairs(created_vouchers) do
            local v = vouchera.get_by_id(created.id)
            assert.is.equal(false, v.unrestricted)
        end
    end)

    it('test get_unrestricted_macs returns only unrestricted active MACs', function()
        vouchera.init()

        -- Create normal voucher
        local normal = vouchera.add({name='normal', code='normal_code', duration_m=100})
        vouchera.activate('normal_code', "aa:bb:cc:dd:ee:ff")

        -- Create unrestricted voucher
        local unrestricted = vouchera.add({name='unrestricted', code='unrestricted_code', duration_m=100, unrestricted=true})
        vouchera.activate('unrestricted_code', "11:22:33:44:55:66")

        -- get_authorized_macs should return both
        local auth_macs = vouchera.get_authorized_macs()
        assert.is.equal(2, #auth_macs)

        -- get_unrestricted_macs should return only unrestricted
        local unrestricted_macs = vouchera.get_unrestricted_macs()
        assert.is.equal(1, #unrestricted_macs)
        assert.is.equal("11:22:33:44:55:66", unrestricted_macs[1])
    end)

    it('test get_unrestricted_macs returns empty for inactive unrestricted voucher', function()
        vouchera.init()

        -- Create unrestricted voucher but don't activate
        local unrestricted = vouchera.add({name='unrestricted', code='unrestricted_code', duration_m=100, unrestricted=true})

        local unrestricted_macs = vouchera.get_unrestricted_macs()
        assert.is.equal(0, #unrestricted_macs)
    end)

    it('test list includes unrestricted field', function()
        vouchera.init()
        vouchera.add({name='normal', code='normal_code'})
        vouchera.add({name='unrestricted', code='unrestricted_code', unrestricted=true})

        local listed = vouchera.list()
        assert.is.equal(2, #listed)

        local has_normal = false
        local has_unrestricted = false
        for _, v in ipairs(listed) do
            if v.name == 'normal' then
                has_normal = true
                assert.is.equal(false, v.unrestricted)
            elseif v.name == 'unrestricted' then
                has_unrestricted = true
                assert.is.equal(true, v.unrestricted)
            end
        end
        assert.is_true(has_normal)
        assert.is_true(has_unrestricted)
    end)

    it('test unrestricted voucher persists after reload', function()
        vouchera.init()
        local voucher = vouchera.add({id='unrestricted_voucher', name='unrestricted', code='unrestricted_code', unrestricted=true})
        assert.is.equal(true, voucher.unrestricted)

        -- Reload database
        vouchera.init()
        local reloaded = vouchera.get_by_id('unrestricted_voucher')
        assert.is.not_nil(reloaded)
        assert.is.equal(true, reloaded.unrestricted)
    end)

    before_each('', function()
        test_utils_pirania.fake_for_tests()
        snapshot = assert:snapshot()
        stub(os, "time", function () return current_time_s end)
        stub(portal, "update_captive_portal", function() end)
        -- If os.execute is needed, please revert this stub
        stub(os, "execute", function(args) print("Warn, os.execute called with: " .. args) end)
    end)

    after_each('', function()
        snapshot:revert()
        local p = io.popen("rm -rf /tmp/pirania_vouchers")
        p:read('*all')
        p:close()
    end)

end)
