#!/usr/bin/lua

local fs = require("nixio.fs")
local libuci = require("uci")
local utils = require("lime.utils")
firewall = {}

function firewall.clean()
	-- nothing to clean
end

function firewall.configure()
    if utils.is_installed('firewall') then
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
	uci:set("firewall", "include_firewall_lime", "include")
	uci:set("firewall", "include_firewall_lime", "path", "/etc/firewall.lime")

        uci:save("firewall")
    end
    
end

return firewall
