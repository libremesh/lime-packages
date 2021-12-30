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
        assert.is_nil(status)
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
