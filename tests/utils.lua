local limeutils = require 'lime.utils'
local config = require 'lime.config'
local libuci = require 'uci'
local stub = require 'luassert.stub'

local utils = {}

utils.assert = assert

UCI_CONFIG_FILES = {
	"6relayd", "babeld", "batman-adv", "check-date", "dhcp", "dropbear", "fstab", "firewall",
	"libremap", "lime", "lime-app",
	"luci", "network", "pirania", "rpcd", "shared-state", "system", "ucitrack",
	"uhttpd", "wireless", "deferable-reboot", config.UCI_AUTOGEN_NAME, config.UCI_NODE_NAME,
	config.UCI_COMMUNITY_NAME, config.UCI_DEFAULTS_NAME
}

function utils.disable_asserts()
    _G['assert'] = function(expresion, message) return expresion end
end

function utils.enable_asserts()
    _G['assert'] = utils.assert
end

function utils.lua_path_from_pkgname(pkgname)
    return 'packages/' .. pkgname .. '/files/usr/lib/lua/?.lua;'
end

function utils.enable_package(pkgname)
    path = utils.lua_path_from_pkgname(pkgname)
    if string.find(package.path, path) == nil then
        package.path = path .. package.path
    end
end

function utils.disable_package(pkgname, modulename)
    -- remove pkg from LUA search path
    path = utils.lua_path_from_pkgname(pkgname)
    package.path = string.gsub(package.path, limeutils.literalize(path), '')
    -- remove module from preload table
    package.preload[modulename] = nil
    package.loaded[modulename] = nil
    _G[modulename] = nil
end

-- Creates a custom empty uci environment to be used in unittesting.
-- Should be called in a before_each block and must be followed by a call to
-- teardown_test_uci in an after_each block.
function utils.setup_test_uci()
	local uci = libuci:cursor()
	config.set_uci_cursor(uci)
	local tmpdir = io.popen("mktemp -d"):read('*l')
	uci:set_confdir(tmpdir)
	-- If the uci files does not exists then doing uci add fails
	-- so here we create empty config files
	for _, cfgname in ipairs(UCI_CONFIG_FILES) do
		local f = io.open(tmpdir .. '/' .. cfgname, "w"):close()
	end
	return uci
end

function utils.teardown_test_uci(uci)
	local confdir = uci:get_confdir()
	if(string.find(confdir, '^/tmp') ~= nil) then
		local out = io.popen("rm -rf " .. confdir .. " " .. uci:get_savedir())
		out:read('*all') -- this allows waiting for popen completion
		out:close()
		io.popen("rm -rf " .. confdir .. " " .. uci:get_savedir())
	end
	uci:close()
end

-- Create a temporal empty directory and return its path with a trailin '/'
-- eg: '/tmp/tmp.occigb/'
-- utils.teardown_test_dir() must be called for cleanup
function utils.setup_test_dir()
	utils._tmpdir = io.popen("mktemp -d"):read('*l') .. "/"
	return utils._tmpdir
end

function utils.teardown_test_dir()
	if(utils._tmpdir ~= nil and string.find(utils._tmpdir, '^/tmp') ~= nil) then
		local out = io.popen("rm -rf " .. utils._tmpdir)
		out:read('*all') -- this allows waiting for popen completion
		out:close()
	end
end

function utils.get_board(name)
	local board_path = 'tests/devices/' .. name .. '/board.json'
	return limeutils.getBoardAsTable(board_path)
end

function utils.write_uci_file(uci, filename, content)
    local confdir = uci:get_confdir()
    local f = io.open(confdir .. '/' .. filename, "w")
    f:write(content)
    f:close()
end

function utils.read_uci_file(uci, filename)
    local confdir = uci:get_confdir()
    local f = io.open(confdir .. '/' .. filename, "r")
    local content = nil
    if f ~= nil then
        content = f:read('*all')
        f:close()
    end
    return content
end

function utils.load_lua_file_as_function(filename)
    local f = io.open(filename)

    local content = ""

    -- removes the shebang if it is the first line
    local first_line = f:read("*l")
    if not first_line:find("^#!") then
        content = first_line .. content
    end

    content = content .. f:read("*a")
    f:close()

    -- mimic lua executable arguments handling injecting arg variable from varargs
    content = 'local arg = {...}\n' .. content
    return loadstring(content, filename)
end

-- Use this function to test libexec/rpcd "json API" calls
function utils.rpcd_call(f, script_args, call_args)
    local response = nil

    stub(limeutils, "printJson", function (x) response = x end)
    stub(limeutils, "rpcd_readline", function () return call_args end)

    f(unpack(script_args))

    -- revert the stub
    limeutils.printJson:revert()
    limeutils.rpcd_readline:revert()
    return response
end

return utils
