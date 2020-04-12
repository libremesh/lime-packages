local utils = require 'lime.utils'
local config = require 'lime.config'
local system = require 'lime.system'
local test_utils = require 'tests.utils'
local match = require("luassert.match")


local uci = nil

describe('LiMe Utils tests #limesystem', function()

    it('test setup_root_password() DO_NOTHING', function()
        config.set('system', 'lime')
        config.set('system', 'root_password_policy', 'DO_NOTHING')
        spy.on(utils, "get_root_secret")
        spy.on(utils, "set_root_secret")

        system.setup_root_password()

        assert.spy(utils.get_root_secret).was_not.called()
        assert.spy(utils.set_root_secret).was_not.called()
    end)

    it('test setup_root_password() SET_SECRET', function()
        config.set('system', 'lime')
        config.set('system', 'root_password_policy', 'SET_SECRET')
        config.set('system', 'root_password_secret', '$1$vv44cu1H$Y/wT9laa7yJ7TqtwiyVO2/')
        stub(utils, "get_root_secret", function () return '' end)
        stub(utils, "set_root_secret", function () return '' end)

        system.setup_root_password()

        assert.stub.spy(utils.set_root_secret).was.called_with('$1$vv44cu1H$Y/wT9laa7yJ7TqtwiyVO2/')
    end)

    it('test setup_root_password() RANDOM', function()
        config.set('system', 'lime')
        config.set('system', 'root_password_policy', 'RANDOM')
        stub(utils, "set_password", function (user, pass)  end)

        system.setup_root_password()

        assert.stub(utils.set_password).was.called_with('root', match.is_string())
    end)
    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
