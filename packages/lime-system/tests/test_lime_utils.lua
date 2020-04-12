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

	it('test set_password', function()
		stub(os, "execute", function (cmd) return cmd end)
		assert.is.equal("(echo 'mypassword'; sleep 1; echo 'mypassword') | passwd 'root' >/dev/null 2>&1",
						utils.set_password("root", "mypassword"))
	end)

	it('test get_root_secret', function()
		local TEST_SHADOW_FILENAME = '/tmp/test_shadow'

		local shadow_content_empty = [[root::0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
dnsmasq:*:18362:0:99999:7:::
]]

		local shadow_content_with_password = [[root:$1$abdccu1H$Y/wmslafly12Tqtwiy1la/:0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
dnsmasq:*:18362:0:99999:7:::
]]
		utils.SHADOW_FILENAME = TEST_SHADOW_FILENAME

        utils.write_file(TEST_SHADOW_FILENAME, shadow_content_empty)

		assert.is.equal("", utils.get_root_secret())

		utils.write_file(TEST_SHADOW_FILENAME, shadow_content_with_password)
		assert.is.equal("$1$abdccu1H$Y/wmslafly12Tqtwiy1la/", utils.get_root_secret())
	end)



	it('test set_root_secret with empty root password', function()
		local TEST_SHADOW_FILENAME = '/tmp/test_shadow'
		local shadow_content_empty = [[root::0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
dnsmasq:*:18362:0:99999:7:::
]]

		local expected_shadow_content = [[root:$1$vv44cu1H$Y/wT9laa7yJ7TqtwiyVO2/:0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
dnsmasq:*:18362:0:99999:7:::
]]
		utils.write_file(TEST_SHADOW_FILENAME, shadow_content_empty)
		utils.SHADOW_FILENAME = TEST_SHADOW_FILENAME

		utils.set_root_secret('$1$vv44cu1H$Y/wT9laa7yJ7TqtwiyVO2/')

		assert.is.equal(expected_shadow_content, utils.read_file(TEST_SHADOW_FILENAME))
		assert.is.equal(shadow_content_empty, utils.read_file(TEST_SHADOW_FILENAME .. "-"))
	end)

	it('test set_root_secret with root password present', function()
		local TEST_SHADOW_FILENAME = '/tmp/test_shadow'

		local shadow_content_with_old_password = [[root:$1$abdccu1H$Y/wmslafly12Tqtwiy1la/:0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
dnsmasq:*:18362:0:99999:7:::
]]

		local expected_shadow_content = [[root:$1$vv44cu1H$Y/wT9laa7yJ7TqtwiyVO2/:0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
dnsmasq:*:18362:0:99999:7:::
]]
		utils.write_file(TEST_SHADOW_FILENAME, shadow_content_with_old_password)
		utils.SHADOW_FILENAME = TEST_SHADOW_FILENAME

		utils.set_root_secret('$1$vv44cu1H$Y/wT9laa7yJ7TqtwiyVO2/')

		assert.is.equal(expected_shadow_content, utils.read_file(TEST_SHADOW_FILENAME))
		assert.is.equal(shadow_content_with_old_password, utils.read_file(TEST_SHADOW_FILENAME .. "-"))
	end)

	it('test random_string', function()
		assert.is.equal(5, #utils.random_string(5))
		assert.is.not_equal(utils.random_string(5), utils.random_string(5))
		assert.is.equal("number", type(tonumber(utils.random_string(5, function (c) return c:match('%d') ~= nil end))))
	end)

end)
