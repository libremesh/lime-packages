local fs = require 'nixio.fs'
local config = require 'lime.config'
local utils = require 'lime.utils'
local test_utils = require "tests.utils"

local uci = nil

describe("Test utils tests #testutils", function()
    it("test setup_test_uci check creation of empty config files", function()
        local uci = test_utils.setup_test_uci()
        local uci_confdir = uci:get_confdir()
        local f = io.open(uci_confdir .. "/wireless")
        assert.is_not_nil(f)
        assert.is.equal("", f:read("*a"))
        f:close()

        -- test that config file is not there anymore
        test_utils.teardown_test_uci(uci)
        f = io.open(uci_confdir .. "/wireless")
        assert.is_nil(f)
    end)

    it("test enable/disable asserts", function()
        --! usinng _G to access the original assert function and not the
        --! overrided by busted in this context
        local original_assert = _G['assert']

        test_utils.disable_asserts()
        assert.are.Not.equal(_G['assert'], original_assert)

        test_utils.enable_asserts()
        assert.are.equal(_G['assert'], original_assert)
    end)

    it("test enable package", function()
        test_utils.enable_package('foobar')
        local path = 'packages/foobar/files/usr/lib/lua/?.lua;'
        assert.are.equal(path, string.sub(package.path, 1, string.len(path)))

        test_utils.disable_package('foobar', 'foobar')
        assert.are.Not.equal(path, string.sub(package.path, 1, string.len(path)))
    end)

    it("test write_uci_file", function()
        local content = [[
        config interface 'wan'
            option ifname 'wan'
            option proto 'dhcp'
        ]]
        test_utils.write_uci_file(uci, 'foo', content)
        assert.is.equal('dhcp', uci:get_all('foo', 'wan', 'proto'))
        assert.is.equal(content, test_utils.read_uci_file(uci, 'foo'))
    end)

    it("test setup and teardown _test_dir", function()
        local dir = test_utils.setup_test_dir()
        assert.is_true(utils.file_exists(dir))
        assert.is_true(utils.stringStarts(dir, "/tmp/"))
        assert.is_true(utils.stringEnds(dir, "/"))
        test_utils.teardown_test_dir()
        assert.is_false(utils.file_exists(dir))
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
