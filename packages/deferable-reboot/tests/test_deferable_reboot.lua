local config = require "lime.config"
local test_utils = require 'tests.utils'
local defreboot = require 'deferable_reboot'

local uci = nil

describe('Deferable Reboot tests #defreboot', function()

    it('test load config from lime.config default value', function()
        defreboot.config()
        assert.is.equal(defreboot.DEFAULT_REBOOT_UPTIME, defreboot.min_uptime)
    end)

    it('test load config from lime.config', function()
        config.set('system', 'lime')
        config.set('system', 'deferable_reboot_uptime', '120')
        defreboot.config()
        assert.is.equal(120, defreboot.min_uptime)
    end)

    it('test should_reboot always true as time in the past', function()
        defreboot.config(0)
        assert.is_true(defreboot.should_reboot())

        defreboot.config(120)
        stub(utils, "uptime_s", function () return 110 end)
        assert.is_false(defreboot.should_reboot())
    end)

    it('test should_reboot false as time in the future', function()
        defreboot.config(utils.uptime_s() + 10)
        assert.is_false(defreboot.should_reboot())

        defreboot.config(100)
        stub(utils, "uptime_s", function () return 120 end)
        assert.is_true(defreboot.should_reboot())
    end)

    it('test should_reboot posponed with time in the future', function()
        defreboot.config(100)
        defreboot.postpone_util_s(150)
        stub(utils, "uptime_s", function () return 130 end)
        assert.is_false(defreboot.should_reboot())
    end)

    it('test should_reboot posponed with time in the past', function()
        defreboot.config(100)
        defreboot.postpone_util_s(110.5)
        stub(utils, "uptime_s", function () return 130 end)
        assert.is_true(defreboot.should_reboot())
    end)

    it('test should_reboot false when sysupgrade or safe-upgrade', function()
        defreboot.config(100)
        defreboot.postpone_util_s(110.5)
        stub(utils, "uptime_s", function () return 130 end)
        assert.is_true(defreboot.should_reboot())
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
        os.remove(defreboot.POSTPONE_FILE_PATH)
    end)

end)
