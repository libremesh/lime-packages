#!/usr/bin/lua

local fs = require("nixio.fs")
local libuci = require("uci")
local opkg = require("luci.model.ipkg")
firewall = {}

function firewall.clean()
	-- nothing to clean
end

function firewall.configure()
	fs.writefile(
		"/etc/firewall.user",
		"# Put your custom iptables rules in a new file in /etc/firewall.user.d/\n" ..
		"# they will be executed with each firewall (re-)start.\n" ..
		"# They are interpreted as shell script.\n" ..
		"for hook in /etc/firewall.user.d/* ; do\n" ..
		"\t[ -s \"$hook\" ] && /bin/sh \"$hook\"\n" ..
		"done\n"
	)

    if opkg.installed("firewall") then
        local uci = libuci:cursor()
        uci:foreach("firewall", "defaults",
            function(section)
                uci:set("firewall", section[".name"], "input", "ACCEPT")
                uci:set("firewall", section[".name"], "output", "ACCEPT")
                uci:set("firewall", section[".name"], "forward", "ACCEPT")
            end
        )
        uci:foreach("firewall", "zone",
            function(section)
                if uci:get("firewall", section[".name"], "name") == "wan"
                or uci:get("firewall", section[".name"], "name") == "lan" then
                    uci:set("firewall", section[".name"], "input", "ACCEPT")
                    uci:set("firewall", section[".name"], "output", "ACCEPT")
                    uci:set("firewall", section[".name"], "forward", "ACCEPT")
                end
            end
        )
        uci:save("firewall")
    else
        os.execute("ln -s /etc/firewall.user /etc/lime-rc.d/50-firewall.user 2>/dev/null")
        os.execute("chmod +x /etc/firewall.user")
    end
    
end

return firewall
