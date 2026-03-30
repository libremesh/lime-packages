local test_utils = require 'tests.utils'
local shared_state = require('shared-state')
local portal = require('portal.portal')

local uci

describe('Pirania portal tests #portal', function()
    local snapshot -- to revert luassert stubs and spies

    it('get and set config', function()
        stub(utils, "unsafe_shell", function () return end)
        local default_cfg = io.open('./packages/pirania/files/etc/config/pirania'):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)

        local portal_cfg = portal.get_config()

        assert.is_false(portal_cfg.activated)
        local activated = true
        local with_vouchers = true
        local status = portal.set_config(activated, with_vouchers)
        assert.stub.spy(utils.unsafe_shell).was.called_with('captive-portal start')
        assert.is_true(status)

        portal_cfg = portal.get_config()
        assert.is_true(portal_cfg.activated)

        local activated = false
        status = portal.set_config(activated, with_vouchers)
        assert.is_true(status)
        assert.stub.spy(utils.unsafe_shell).was.called_with('captive-portal stop')

        portal_cfg = portal.get_config()
        assert.is_false(portal_cfg.activated)

        with_vouchers = false
        status, message = portal.set_config(activated, with_vouchers)
        assert.is_true(status)
        portal_cfg = portal.get_config()
        assert.is_false(portal_cfg.with_vouchers)
    end)

    it('get and set portal page', function()
        stub(utils, "read_obj_store", function() return {title = "Pirania"} end)

        local content = portal.get_page_content()
        assert.is.equal('Pirania', content.title)
        local title, main_text, logo, link_title, link_url, bgcolor = 'My Portal', 'my text', 'mylogo', 'linktitle', 'http://foo', '#aabbcc'
        portal.set_page_content(title, main_text, logo, link_title, link_url, bgcolor)

        local content = portal.get_page_content()
        assert.are.same({title=title, main_text=main_text, background_color=bgcolor, link_title=link_title, link_url=link_url, logo=logo}, content)

    end)

    it('get_unrestricted_macs returns empty when not in voucher mode', function()
        local default_cfg = io.open('./packages/pirania/files/etc/config/pirania'):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)

        -- Default config has with_vouchers='0'
        local macs = portal.get_unrestricted_macs()
        assert.is.equal(0, #macs)
    end)

    it('get_authorized_macs returns active voucher MACs in voucher mode', function()
        local default_cfg = io.open('./packages/pirania/files/etc/config/pirania'):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)
        uci:set('pirania', 'base_config', 'with_vouchers', '1')

        stub(portal, "update_captive_portal", function() end)
        local vouchera = require('voucher.vouchera')
        local test_utils_pirania = require('packages/pirania/tests/pirania_test_utils')
        test_utils_pirania.fake_for_tests()
        vouchera.init()
        vouchera.add({name='test', code='code1', duration_m=100})
        vouchera.activate('code1', 'AA:BB:CC:DD:EE:FF')

        local macs = portal.get_authorized_macs()
        assert.is.equal(1, #macs)
        assert.is.equal('AA:BB:CC:DD:EE:FF', macs[1])
    end)

    it('get_unrestricted_macs returns only unrestricted MACs in voucher mode', function()
        local default_cfg = io.open('./packages/pirania/files/etc/config/pirania'):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)
        uci:set('pirania', 'base_config', 'with_vouchers', '1')

        stub(portal, "update_captive_portal", function() end)
        local vouchera = require('voucher.vouchera')
        local test_utils_pirania = require('packages/pirania/tests/pirania_test_utils')
        test_utils_pirania.fake_for_tests()
        vouchera.init()

        -- Normal voucher
        vouchera.add({name='normal', code='code1', duration_m=100})
        vouchera.activate('code1', 'AA:BB:CC:DD:EE:FF')

        -- Unrestricted voucher
        vouchera.add({name='unrestricted', code='code2', duration_m=100, unrestricted=true})
        vouchera.activate('code2', '11:22:33:44:55:66')

        local macs = portal.get_unrestricted_macs()
        assert.is.equal(1, #macs)
        assert.is.equal('11:22:33:44:55:66', macs[1])
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
