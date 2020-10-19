local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

local uci = nil

describe('LiMe Utils tests #limeutils', function()
    it('test literalize(str) with a string that has all the reserved chars', function()
        local str = 'f+o[o]?.*(,)_-%a$l^'
        assert.is.equal('f%+o%[o%]%?%.%*%(,%)_%-%%a%$l%^', utils.literalize(str))

        -- check that when replacing the original string with the literalized string
        -- the result is that all the string is replaced
        assert.is.equal('bar', string.gsub(str, utils.literalize(str), 'bar'))
        -- return only the new string
        assert.is.equal(1, #table.pack(utils.literalize(str)))
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

	it('test is_valid_hostname', function()
		assert.is_true(utils.is_valid_hostname('LiMe-ab0cd0'))
		assert.is_true(utils.is_valid_hostname('0foo'))
		assert.is_true(utils.is_valid_hostname('foo-bar'))
		assert.is_false(utils.is_valid_hostname('-foo'))
		assert.is_false(utils.is_valid_hostname('foo-'))
		assert.is_false(utils.is_valid_hostname('.foo'))
		assert.is_false(utils.is_valid_hostname('f.o'))
		assert.is_false(utils.is_valid_hostname('fo.'))
		assert.is_false(utils.is_valid_hostname('foo_bar'))
		assert.is_false(utils.is_valid_hostname('foo#bar'))
		assert.is_false(utils.is_valid_hostname('foo!bar'))
		assert.is_false(utils.is_valid_hostname('fóóbar'))
		assert.is_false(utils.is_valid_hostname('f?o'))
	end)

	it('test slugify', function()
		assert.is.equal('fooBAR123', utils.slugify('fooBAR123'))
		assert.is.equal('foo-BAR--123', utils.slugify('foo-BAR--123'))
		assert.is.equal('foo-bar-baz-', utils.slugify('foo bar baz '))
		assert.is.equal('foo-bar-baz', utils.slugify('foo,bar-baz'))
		assert.is.equal('FOO', utils.slugify('FOO'))
		assert.is.equal('FOO-----------------------bar-----', utils.slugify("FOO~ñ@#$%&/()|[]*¡æł=?bar¡°'"))
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
        os.execute:revert()
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

    it('test set_shared_root_password', function()
		uci:set('lime-community', 'system', 'lime')
		stub(utils, "set_password", function (user, pass) return pass end)

		utils.set_shared_root_password('foo')

		assert.stub(utils.set_password).was.called_with('root', 'foo')
		assert.is.equal("SET_SECRET", uci:get("lime-community", 'system', 'root_password_policy'))
		assert.is_not("", uci:get("lime-community", 'system', 'root_password_secret'))
	end)

	it('test random_string', function()
		assert.is.equal(5, #utils.random_string(5))
		assert.is.not_equal(utils.random_string(5), utils.random_string(5))
		assert.is.equal("number", type(tonumber(utils.random_string(5, function (c) return c:match('%d') ~= nil end))))
	end)

    it('test keep_on_upgrade_files()', function()
        local test_dir = test_utils.setup_test_dir()
        local absolute_keep_file_path = test_dir .. 'absolute_keep_file'
        config.set('system', 'lime')
        config.set('system', 'keep_on_upgrade', 'relative_keep_file inexistent_keep_file  ' .. absolute_keep_file_path)

        utils.KEEP_ON_UPGRADE_FILES_BASE_PATH = test_dir
        utils.write_file(test_dir .. 'relative_keep_file', "# comment \n\n/foo\n/bar")
        utils.write_file(absolute_keep_file_path, "/baz")

        local files = utils.keep_on_upgrade_files()
        assert.are.same({'/foo', '/bar', '/baz'}, files)
    end)

    it('test mac2ipv6linklocal', function()
        assert.is.equal('foo', utils.mac2ipv6linklocal('foo'))
        assert.is.equal('fe80::200:ff:fe00:0', utils.mac2ipv6linklocal('00:00:00:00:00:00'))
        assert.is.equal('fe80::200:ff:fe00:fff', utils.mac2ipv6linklocal('00:00:00:00:0f:ff'))
        assert.is.equal('fe80::ceaa:bbff:feff:11fe', utils.mac2ipv6linklocal('CC:AA:BB:FF:11:FE'))
        assert.is.equal('fe80::aa40:41ff:fe1c:84d1', utils.mac2ipv6linklocal('a8:40:41:1c:84:d1'))
        assert.is.equal('FOOfe80::aa40:41ff:fe1c:84d1BARfe80::aa40:41ff:fe1c:84d1',
                         utils.mac2ipv6linklocal('FOOa8:40:41:1c:84:d1BARa8:40:41:1c:84:d1'))
     end)

    it('test release_info', function()
        local info = [[DISTRIB_ID='LiMe'
DISTRIB_RELEASE='master'
DISTRIB_REVISION='ec81de9'
DISTRIB_TARGET='ar71xx/generic'
DISTRIB_ARCH='mips_24kc'
DISTRIB_DESCRIPTION='LiMe master development (master rev. ec81de9 20190613_1242)'
DISTRIB_TAINTS='no-all busybox'
]]
        stub(utils, "read_file", function (cmd) return info end)
        local data = utils.release_info()
        assert.is.equal('LiMe', data['DISTRIB_ID'])
        assert.is.equal('master', data['DISTRIB_RELEASE'])
        assert.is.equal('ec81de9', data['DISTRIB_REVISION'])
        assert.is.equal('ar71xx/generic', data['DISTRIB_TARGET'])
        assert.is.equal('mips_24kc', data['DISTRIB_ARCH'])
        assert.is.equal('LiMe master development (master rev. ec81de9 20190613_1242)', data['DISTRIB_DESCRIPTION'])
        assert.is.equal('no-all busybox', data['DISTRIB_TAINTS'])
        utils.read_file:revert()
     end)


    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
        test_utils.teardown_test_dir()
    end)

end)
