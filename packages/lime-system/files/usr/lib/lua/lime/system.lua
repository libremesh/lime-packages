#!/usr/bin/lua

system = {}

function system.set_hostname()
    local m4, m5, m6 = node_id()
    local hostname = string.format("%02x%02x%02x", m4, m5, m6)

    uci:foreach("system", "system", function(s)
        uci:set("system", s[".name"], "hostname", hostname)
    end)
    uci:save("system")
end

function system.clean()
    -- nothing to clean
end

function system.init()
    -- TODO
end

function system.configure()
    system.clean()

    print("Configuring system...")
    system.set_hostname()

    print("Let uhttpd listen on IPv4/IPv6")
    uci:set("uhttpd", "main", "listen_http", "80")
    uci:set("uhttpd", "main", "listen_https", "443")
    uci:save("uhttpd")
end

function system.apply()
    -- apply hostname
    local hostname
    uci:foreach("system", "system", function(s)
        hostname = uci:get("system", s[".name"], "hostname")
    end)
    fs.writefile("/proc/sys/kernel/hostname", hostname)

    -- apply uhttpd settings
    os.execute("/etc/init.d/uhttpd reload")
end

return system
