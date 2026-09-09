-- Global defaults
std = "lua51"
max_line_length = 120

local include_lua_files = require("luacheck_helper")

local function tableConcat(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

include_dot_lua_files = {
	"packages/**/*.lua",
	"tests/**/*.lua",
	"tools/**/*.lua",
}

include_files = tableConcat(include_dot_lua_files, include_lua_files)

ignore = {
	-- Allow calling nonstandard functions on globals, i.e.:
	-- accessing undefined field 'searchers' of global package
	"143",
}

exclude_files = {
	-- Contains unknown functions like Map() and translate()
	"packages/bmx7-mdns/*",
}

-- Test files: define test framework globals
files["**/tests/**"] = {
	globals = {
		"after_each",
		"assert",
		"before_each",
		"describe",
		"it",
		"match",
		"setup",
		"spy",
		"stub",
		"teardown",
	},
	-- Shadowing an upvalue.
	ignore = { "431" },
}

-- Apply --no-unused-args to modules
files["**/usr/lib/lua/lime/proto/**"] = {
	-- 212 = unused argument
	ignore = { "212" },
}

-- Ignore undefined variable 'metric' in prometheus-collectors
-- since it is made available by the package prometheus-node-exporter-lua
files["**/usr/lib/lua/prometheus-collectors/**"] = {
	globals = {
		"metric",
	},
}

-- Ignore undefined global variable 'uhttpd' in pirania files
files["**/packages/pirania/**"] = {
	globals = {
		"uhttpd",
	},
}
