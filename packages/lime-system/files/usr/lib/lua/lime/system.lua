#!/usr/bin/lua

local function set_hostname()
	local r1, r2, r3 = node_id()
	local hostname = string.format("%02x%02x%02x", r1, r2, r3)

	x:foreach("system", "system", function(s)
		x:set("system", s[".name"], "hostname", hostname)
	end)
	x:save("system")

	fs.writefile("/proc/sys/kernel/hostname", hostname)
end

function configure()
	print("Configuring system...")
	set_hostname()

  print("Let uhttpd listen on IPv4/IPv6")
	x:set("uhttpd", "main", "listen_http", "80")
	x:set("uhttpd", "main", "listen_https", "443")
	x:save("uhttpd")
end

