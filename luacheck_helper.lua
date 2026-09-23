#!/usr/bin/lua

local lfs = require("lfs")

local function firstLine(path)
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local line = f:read("*l")
	f:close()
	return line
end

local function isLuaShebang(line)
	if not line then
		return false
	end

	if line == "#!/usr/bin/lua" then
		return true
	end

	-- /usr/bin/env lua (with optional version suffix)
	-- Examples:
	--   #!/usr/bin/env lua
	--   #!/usr/bin/env lua5.4
	local envLua = line:match("^#!.*/env%s+lua[%d%.]*$")
	if envLua then
		return true
	end

	return false
end

local function endsWith(s, suffix)
	return s:sub(-#suffix) == suffix
end

local function walk(dir, callback)
	for entry in lfs.dir(dir) do
		if entry ~= "." and entry ~= ".." then
			local path = dir .. "/" .. entry
			local attr = lfs.attributes(path)
			if attr then
				if attr.mode == "directory" then
					walk(path, callback)
				elseif attr.mode == "file" then
					callback(path)
				end
			end
		end
	end
end

-- Change this to the directory you want to scan
local root = "packages"
local include_lua_files = {}

walk(root, function(path)
	if not endsWith(path, ".lua") then
		local line = firstLine(path)
		if isLuaShebang(line) then
			print(path)
			table.insert(include_lua_files, path)
		end
	end
end)

return include_lua_files
