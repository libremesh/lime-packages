#!/usr/bin/lua

local fs = require("nixio.fs")
local utils = require("lime.utils")
local config = require("lime.config")
firewall = {}

function firewall.clean()
	-- nothing to clean
end

function firewall.configure()
    if utils.is_installed('firewall') then
        local uci = config:get_uci_cursor()
        local lanIfs = {}
        uci:foreach("firewall", "defaults",
            function(section)
                uci:set("firewall", section[".name"], "input", "ACCEPT")
                uci:set("firewall", section[".name"], "output", "ACCEPT")
                uci:set("firewall", section[".name"], "forward", "ACCEPT")
            end
        )

        uci:foreach("network", "interface",
            function(section)
                if "lan" == section[".name"] or
                   "lm_" == string.sub(section[".name"], 1, 3) and
                   "_if" == string.sub(section[".name"], -3) then
                    table.insert(lanIfs, section[".name"])
                end
            end
        )

        uci:foreach("firewall", "zone",
             function(section)
                if uci:get("firewall", section[".name"], "name") == "lan" then
                    uci:set("firewall", section[".name"], "input", "ACCEPT")
                    uci:set("firewall", section[".name"], "output", "ACCEPT")
                    uci:set("firewall", section[".name"], "forward", "ACCEPT")
                    uci:set("firewall", section[".name"], "network", lanIfs)
                end
            end
        )

        uci:set("firewall", "include_firewall_lime", "include")
        uci:set("firewall", "include_firewall_lime", "path", "/etc/firewall.lime")
        uci:save("firewall")
    end
end

return firewall
