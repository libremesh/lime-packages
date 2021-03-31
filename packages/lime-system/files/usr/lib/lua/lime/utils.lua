#!/usr/bin/lua

utils = {}

local config = require("lime.config")
local json = require("luci.jsonc")
local fs = require("nixio.fs")
local nixio = require("nixio")

utils.BOARD_JSON_PATH = "/etc/board.json"
utils.SHADOW_FILENAME = "/etc/shadow"
utils.KEEP_ON_UPGRADE_FILES_BASE_PATH = '/lib/upgrade/keep.d/'

function utils.log(...)
	if DISABLE_LOGGING ~= nil then return end
	if os.getenv("LUA_DISABLE_LOGGING") ~= nil and os.getenv("LUA_ENABLE_LOGGING") == nil then return end
	print(string.format(...))
end

function utils.disable_logging()
	DISABLE_LOGGING = 1
end

function utils.enable_logging()
	DISABLE_LOGGING = nil
end

function utils.split(string, sep)
	local ret = {}
	for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
	return ret
end

function utils.stringStarts(string, start)
   return (string.sub(string, 1, string.len(start)) == start)
end

function utils.stringEnds(string, _end)
   return ( _end == '' or string.sub( string, -string.len(_end) ) == _end)
end

function utils.hex(x)
	return string.format("%02x", x)
end

function utils.printf(fmt, ...)
	print(string.format(fmt, ...))
end

--! escape the magic characters: ( ) . % + - * ? [ ] ^ $
--! useful to use with gsub / match when finding exactly a string
function utils.literalize(str)
    local ret, _ = str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
    return ret
end

function utils.isModuleAvailable(name)
	if package.loaded[name] then
		return true
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

function utils.applyMacTemplate16(template, mac)
	for i=1,6,1 do template = template:gsub("%%M"..i, mac[i]) end
	local macid = utils.get_id(mac)
	for i=1,6,1 do template = template:gsub("%%m"..i, macid[i]) end
	return template
end

function utils.applyMacTemplate10(template, mac)
	for i=1,6,1 do template = template:gsub("%%M"..i, tonumber(mac[i], 16)) end
	local macid = utils.get_id(mac)
	for i=1,6,1 do template = template:gsub("%%m"..i, tonumber(macid[i], 16)) end
	return template
end

function utils.applyHostnameTemplate(template)
	local system = require("lime.system")
	return template:gsub("%%H", system.get_hostname())
end

function utils.get_id(input)
	if type(input) == "table" then
		input = table.concat(input, "")
	end
	local id = {}
	local fd = io.popen('echo "' .. input .. '" | md5sum')
	if fd then
		local md5 = fd:read("*a")
		local j = 1
		for i=1,16,1 do
			id[i] = string.sub(md5, j, j + 1)
			j = j + 2
		end
		fd:close()
	end
	return id
end

function utils.network_id()
	local network_essid = config.get("wifi", "ap_ssid")
	return utils.get_id(network_essid)
end

function utils.applyNetTemplate16(template)
	local netid = utils.network_id()
	for i=1,6,1 do template = template:gsub("%%N"..i, netid[i]) end
	return template
end

function utils.applyNetTemplate10(template)
	local netid = utils.network_id()
	for i=1,6,1 do template = template:gsub("%%N"..i, tonumber(netid[i], 16)) end
	return template
end


--! This function is inspired to http://lua-users.org/wiki/VarExpand
--! version: 0.0.1
--! code: Ketmar // Avalon Group
--! licence: public domain
--! expand $var and ${var} in string
--! ${var} can call Lua functions: ${string.rep(' ', 10)}
--! `$' can be screened with `\'
--! `...': args for $<number>
--! if `...' is just a one table -- take it as args
function utils.expandVars(s, ...)
	local args = {...}
	args = #args == 1 and type(args[1]) == "table" and args[1] or args;

	--! return true if there was an expansion
	local function DoExpand(iscode)
		local was = false
		local mask = iscode and "()%$(%b{})" or "()%$([%a%d_]*)"
		local drepl = iscode and "\\$" or "\\\\$"
		s = s:gsub(mask,
			function(pos, code)
				if s:sub(pos-1, pos-1) == "\\" then
					return "$"..code
				else
					was = true
					local v, err
					if iscode then
						code = code:sub(2, -2)
					else
						local n = tonumber(code)
						if n then
							v = args[n]
						else
							v = args[code]
						end
					end
					if not v then
						v, err = loadstring("return "..code)
						if not v then error(err) end
						v = v()
					end
					if v == nil then v = "" end
					v = tostring(v):gsub("%$", drepl)
					return v
				end
		end)
		if not (iscode or was) then s = s:gsub("\\%$", "$") end
		return was
	end
	repeat DoExpand(true); until not DoExpand(false)
	return s
end

--! return a string that can be a part of an url
function utils.slugify(s)
	s = s:gsub('[^-a-zA-Z0-9]', '-')
	return s
end

function utils.sanitize_hostname(hostname)
	hostname = hostname:gsub(' ', '-')
	hostname = hostname:gsub('[^-a-zA-Z0-9]', '')
	hostname = hostname:gsub('^-*', '')
	hostname = hostname:gsub('-*$', '')
	hostname = hostname:sub(1, 32)
	return hostname
end

--! validate that a hostname is also DNS valid
function utils.is_valid_hostname(hostname)
    if hostname and (#hostname < 64) and
       hostname:match("^[a-zA-Z0-9][a-zA-Z0-9%-]*[a-zA-Z0-9]$")
    then
        return true
    end
    return false
end

function utils.file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function utils.read_file(name)
	local f = io.open(name,"r")
	local ret = nil
	if f ~= nil then
		ret = f:read("*all")
		f:close()
	end
	return ret
end

function utils.write_file(name, content)
	local f = io.open(name, "w")
    local ret = false
	if f ~= nil then
		f:write(content)
		f:close()
		ret = true
	end
	return ret
end

function utils.is_installed(pkg)
	return utils.file_exists('/usr/lib/opkg/info/'..pkg..'.control')
end

function utils.has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

--! contact array a2 to the end of array a1
function utils.arrayConcat(a1,a2)
	for _,i in ipairs(a2) do
		table.insert(a1,i)
	end
	return a1
end

--! melt table t1 into t2, if keys exists in both tables use value of t2
function utils.tableMelt(t1, t2)
	for key, value in pairs(t2) do
		t1[key] = value
	end
	return t1
end

function utils.tableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function utils.indexFromName(name)
	return tonumber(name:match("%d+"))
end

function utils.getBoardAsTable(board_path)
	if board_path == nil then
		board_path = utils.BOARD_JSON_PATH
	end
	return json.parse(fs.readfile(board_path))
end

function utils.printJson(obj)
    print(json.stringify(obj))
end

--! use rpcd_readline() in libexec/rpcd/ scripts to access the arguments that
--! are passed through stdin. The use of this functions allows testing.
function utils.rpcd_readline()
    return io.read()
end

--! for testing only
utils._uptime_line = nil

function utils.uptime_s()
    local uptime_line = utils._uptime_line or io.open("/proc/uptime"):read("*l")
    return tonumber(string.match(uptime_line, "^%S+"))
end

--! Escape strings for safe shell usage.
function utils.shell_quote(s)
    --! Based on Python's shlex.quote()
    return "'" .. string.gsub(s, "'", "'\"'\"'") .. "'"
end

--! Excutes a shell command, waits for completion and returns stdout.
--! Warning! Use this function carefully as it could be exploted if used with
--! untrusted input. Always use function utils.shell_quote() to escape untrusted
--! input.
function utils.unsafe_shell(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

--! based on luci.sys.setpassword
function utils.set_password(username, password)
	local user = utils.shell_quote(username)
	local pass = utils.shell_quote(password)
	return os.execute(string.format("(echo %s; sleep 1; echo %s) | passwd %s >/dev/null 2>&1",
									pass, pass, user))
end

function utils.get_root_secret()
	local f = io.open(utils.SHADOW_FILENAME, "r")
	if f ~= nil then
		local root_line = f:read("*l") --! root user is always in the first line
		local secret = root_line:match("root:(.-):")
		return secret
	end
end

function utils.set_root_secret(secret)
	local f = io.open(utils.SHADOW_FILENAME, "r")
	if f ~= nil then
		--! perform a backup of the shadow
		local f_bkp = io.open(utils.SHADOW_FILENAME .. "-", "w")
		f_bkp:write(f:read("*a"))
		f:seek("set")
		f_bkp:close()

		local root_line = f:read("*l") --! root user is always in the first line
		local starts, ends = string.find(root_line, "root:.-:")
		local content = "root:" .. secret .. root_line:sub(ends) .. "\n"
		content = content .. f:read("*a")
		f:close()
		f = io.open(utils.SHADOW_FILENAME, "w")
		f:write(content)
		f:close()
	end
end

function utils.set_shared_root_password(password)
    local uci = config.get_uci_cursor()
    utils.set_password('root', password) -- this takes 1 second, it may be replaced with nixio.crypt(password, '$1$vv44cu1H')
    uci:set("lime-community", 'system', 'root_password_policy', 'SET_SECRET')
    uci:set("lime-community", 'system', 'root_password_secret', utils.get_root_secret())
end

--! returns a random string. filter is an optional function to reduce the possible characters.
--! by default the filter allows all the alphanumeric characters
function utils.random_string(length, filter)
    if filter == nil then
        --! all alphanumeric characters
        filter = function (c) return string.match(c, "%w") ~= nil end
    end
    local urandom = io.open("/dev/urandom", "rb")
    local out = ""
    while length > #out do
        local c = urandom:read(1)
        if filter(c) then
            out = out .. c
        end
    end
    return out
end

--! Return a list of files to keep when upgrading. Existence of the files is not guaranteed.
function utils.keep_on_upgrade_files()
    local file_lists = config.get("system", "keep_on_upgrade", "")
    local files = {}
    for _, list in pairs(utils.split(file_lists, " ")) do
        --! convert non absolute paths to absolute
        if not utils.stringStarts(list, "/") then
            list =  utils.KEEP_ON_UPGRADE_FILES_BASE_PATH .. list
        end
        if utils.file_exists(list) then
            for file_name in io.lines(list) do
                --! exclude comments, blank lines, etc
                if utils.stringStarts(file_name, "/") then
                    table.insert(files, file_name)
                end
            end
        end
    end
    return files
end

--! Run a command in a shell and daemonized directly in pid 1 (similar to diswon/nohup)
--! If out_file optional arg is passed then stdout and stderr will go to that file.
function utils.execute_daemonized(cmd, out_file, stdin)
    if out_file == nil then
        out_file = "/dev/null"
    end
    if not stdin then
        stdin = "0<&-" -- closing standard input
    else
        stdin = "0<" .. stdin
    end

    return os.execute("(( " .. cmd .. " " .. stdin .. " &> " .. out_file .. " &) &)")
end

function utils.bitwise_xor(a, b)
  local r = 0
  for i = 0, 31 do
    local x = a / 2 + b / 2
    if x ~= math.floor(x) then
      r = r + 2^i
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
  end
  return r
end

function utils.mac2ipv6linklocal(text)
    function f(mac0, mac1, mac2, mac3, mac4, mac5, mac6)
        local mac0 = string.format("%x", utils.bitwise_xor(tonumber(mac0, 16), 0x02))
        --! going from and to string to remove leading zeroes and convert to lowercase
        local gr1 = string.format("%x", tonumber(mac0 .. mac1, 16))
        local gr2 = string.format("%x", tonumber(mac2 .. 'ff', 16))
        local gr3 = string.format("%x", tonumber('fe' .. mac3, 16))
        local gr4 = string.format("%x", tonumber(mac4 .. mac5, 16))
        return 'fe80::' .. gr1 .. ":" .. gr2 .. ":" .. gr3 .. ":" .. gr4
    end
    local ret, _ = string.gsub(text, "(%x%x):(%x%x):(%x%x):(%x%x):(%x%x):(%x%x)", f)
    return ret
end

--! do a HTTP GET returning the body or nil. If out_file is provided then the body is saved
--! to this file and true is returned instead
function utils.http_client_get(url, timeout_s, out_file)
    local remove_file = false
    if not out_file then
        remove_file = true
        out_file = os.tmpname()
    end
    local cmd = string.format("uclient-fetch -q -O %s --timeout=%d %s 2> /dev/null", out_file,
                              timeout_s, url)
    local exit_value = os.execute(cmd)
    if exit_value == 0 then
        if remove_file then
            local data = utils.read_file(out_file)
            os.execute("rm -f " .. out_file)
            return data
        else
            return true
        end
    else
        return nil
    end
end

function utils.release_info()
    local result = {}
    local release_data = utils.read_file("/etc/openwrt_release")
    for key, value in release_data:gmatch("(.-)='(%C-)'\n") do
        result[key] = value
    end
    return result
end

function utils.open_with_lock(fname, max_wait_s)
    max_wait_s = max_wait_s or 1
    local locked = false

    local fd = nixio.open(fname, nixio.open_flags("rdwr", "creat") )
    if not fd then
        return nil, "Can't create file"
    end

    for i=0,max_wait_s do
        if not fd:lock("tlock") then
            nixio.nanosleep(1)
        else
            locked = true
            break
        end
    end

    if not locked then
        if fd then fd:close() end
        return nil, "Failed acquiring lock"
    end

    return fd
end

--! Object store database. Uses json as on disk format. Uses posix file locks to prevent corruption,
--! be aware that this mechanism does only works between processes and not beteen threads or same thread.
function utils.read_obj_store(datafile)
    local fd = utils.open_with_lock(datafile)
    local store
    if fd then
        store = json.parse(nixio.fs.readfile(datafile)) or {}
        fd:close()
    end
    return store
end

function utils.write_obj_store_var(datafile, name, data)
    local fd = utils.open_with_lock(datafile)
    local store
    if fd then
        store = json.parse(nixio.fs.readfile(datafile)) or {}
        fd:seek(0)
        store[name] = data
        fd:write(json.stringify(store))
        fd:close()
    end
    return store
end

function utils.write_obj_store(datafile, data)
    local fd = utils.open_with_lock(datafile)
    if fd then
        fd:write(json.stringify(data))
        fd:close()
        return true
    end
end

function utils.get_ifnames()
    local ifnames = {}
    for ifname in fs.dir("/sys/class/net/") do
        table.insert(ifnames, ifname)
    end
    return ifnames
end

function utils.is_valid_mac(string)
    local string = string:match("%w%w:%w%w:%w%w:%w%w:%w%w:%w%w")
    if string then
       return true
    else
       return false
    end
end

function utils.deepcompare(t1,t2)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not utils.deepcompare(v1, v2) then return false end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not utils.deepcompare(v1, v2) then return false end
    end
    return true
end

return utils
