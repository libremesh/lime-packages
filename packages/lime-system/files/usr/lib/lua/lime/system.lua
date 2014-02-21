#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")

system = {}

function system.set_hostname()
    local m4, m5, m6 = node_id()
    local hostname = string.format("%02x%02x%02x", m4, m5, m6)

    local uci = libuci:cursor()
    uci:foreach("system", "system", function(s)
        uci:set("system", s[".name"], "hostname", hostname)
    end)
    uci:save("system")
end

function system.clean()
    -- nothing to clean
end

function system.configure()
    system.clean()

    print("Configuring system...")
    system.set_hostname()

    print("Let uhttpd listen on IPv4/IPv6")
    local uci = libuci:cursor()
    uci:set("uhttpd", "main", "listen_http", "80")
    uci:set("uhttpd", "main", "listen_https", "443")
    uci:save("uhttpd")
end

function system.apply()
    -- apply hostname
    local hostname
    local uci = libuci:cursor()
    uci:foreach("system", "system", function(s)
        hostname = uci:get("system", s[".name"], "hostname") -- FIXME Doesn't we already have hostaname in s["hostname"] without executing the get ?
    end)
    fs.writefile("/proc/sys/kernel/hostname", hostname)

    -- apply uhttpd settings
    os.execute("/etc/init.d/uhttpd reload")
end

return system
