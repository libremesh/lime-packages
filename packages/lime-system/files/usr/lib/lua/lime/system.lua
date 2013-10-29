#!/usr/bin/lua

system = {}

function system.set_hostname()
    local m4, m5, m6 = node_id()
    local hostname = string.format("%02x%02x%02x", m4, m5, m6)

    x:foreach("system", "system", function(s)
        x:set("system", s[".name"], "hostname", hostname)
    end)
    x:save("system")
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
    x:set("uhttpd", "main", "listen_http", "80")
    x:set("uhttpd", "main", "listen_https", "443")
    x:save("uhttpd")
end

function system.apply()
    -- apply hostname
    local hostname
    x:foreach("system", "system", function(s)
        hostname = x:get("system", s[".name"], "hostname")
    end)
    fs.writefile("/proc/sys/kernel/hostname", hostname)

    -- apply uhttpd settings
    os.execute("/etc/init.d/uhttpd reload")
end

return system
