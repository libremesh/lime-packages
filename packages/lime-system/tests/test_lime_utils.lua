local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

describe('LiMe Utils tests #limeutils', function()
    it('test literalize(str) with a string that has all the reserved chars', function()
        local str = 'f+o[o]?.*(,)_-%a$l^'
        assert.is.equal('f%+o%[o%]%?%.%*%(,%)_%-%%a%$l%^', utils.literalize(str))

        -- check that when replacing the original string with the literalized string
        -- the result is that all the string is replaced
        assert.is.equal('bar', string.gsub(str, utils.literalize(str), 'bar'))
    end)

    it('test isModuleAvailable existing modules', function()
        assert.is_true(utils.isModuleAvailable('lime.utils'))
        assert.is_true(utils.isModuleAvailable('lime.firewall'))
    end)

    it('test isModuleAvailable non existing modules', function()
        assert.is_false(utils.isModuleAvailable('foobar'))
        assert.is_false(utils.isModuleAvailable('lime.foobar'))
    end)

    it('test isModuleAvailable enabling a package', function()
        test_utils.enable_package('lime-proto-anygw')
        assert.is_true(utils.isModuleAvailable('lime.proto.anygw'))
        test_utils.disable_package('lime-proto-anygw', 'lime.proto.anygw')
        assert.is_false(utils.isModuleAvailable('lime.proto.anygw'))
    end)

	it('test tableLength', function()
        assert.is.equal(0, utils.tableLength({}))
		assert.is.equal(3, utils.tableLength({'a', 3, 9}))
		assert.is.equal(1, utils.tableLength({['foo'] = 'foo'}))
		assert.is.equal(2, utils.tableLength({['foo'] = 'foo', ['bar'] = 'bar'}))
    end)

    it('test indexFromName', function()
        assert.is.equal(0, utils.indexFromName('radio0'))
		assert.is.equal(0, utils.indexFromName('phy0'))
		assert.is.equal(1, utils.indexFromName('phy1'))
		assert.is.equal(11, utils.indexFromName('phy11'))
    end)

	it('test uptime_s #uptime', function()
		utils._uptime_line = '20331.28 69742.87'
		local uptime = utils.uptime_s()
		assert.is.equal(uptime, 20331.28)
		utils._uptime_line = nil

		local uptime_1 = utils.uptime_s()
		local uptime_2 = utils.uptime_s()
		assert.is_true(uptime_2 >= uptime_1)
    end)

	it('test read_file / write_file', function()
		local filename = '/tmp/test_foo'
		local content = 'bar'
		utils.write_file(filename, content)
		assert.is.equal(content, utils.read_file(filename))
    end)

	it('test shell_quote', function()
		assert.is.equal("'foo'", utils.shell_quote("foo"))
		assert.is.equal("'ls ; cmd'", utils.shell_quote("ls ; cmd"))
		assert.is.equal([['"']], utils.shell_quote('"'))
		assert.is.equal([['$'"'"'b']], utils.shell_quote("$'b"))
	end)

	it('test unsafe_shell', function()
		assert.is.equal("1\n", utils.unsafe_shell("echo 1"))
	end)

	it('test unsafe_shell returns only stdout', function()
		assert.is.equal("", utils.unsafe_shell("ls /wrong/path 2>/dev/null"))
		assert.is.equal("", utils.unsafe_shell("echo 1 2>/dev/null 1>&2"))
	end)

end)
