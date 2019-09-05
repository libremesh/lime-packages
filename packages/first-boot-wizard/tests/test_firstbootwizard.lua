local libuci = require 'uci'
local config = require 'lime.config'
local fbw = require 'firstbootwizard'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local fs = require("nixio.fs")

utils.disable_logging()

local uci = nil

describe('FirstBootWizard tests', function()

    it('test start/end_scan()', function()
        fbw.start_scan_file()
        assert.are.same('true', io.open("/tmp/scanning"):read("*a"))
        fbw.end_scan()
        assert.are.same('false', io.open("/tmp/scanning"):read("*a"))
    end)


    it('test get_networks()', function()
        fbw.get_networks() -- TODO
    end)


    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
