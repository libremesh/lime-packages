--[[
LuCI - Lua Configuration Interface

Copyright 2013 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.status.switch", package.seeall)

function index()
   local page

   node("status")

   page = entry({"status", "switch"}, template("status/switch"), _("Switch"), 2)
   page.leaf = true

   node("status", "json")

   page = node("status", "json", "switch")
   page.target = call("action_json_switch")
   page.leaf = true
end

---------------------------------------------------------------

function action_json_switch()
    local s = require "luci.tools.status"
    local nw = require "luci.model.network"

    -- m = Map("network")
    local switches = { }

    local _uci = uci.cursor()
    _uci:foreach("network", "switch",
    function(x)
        local sid = x['.name']
        local switch_name = x.name or sid
        switches[#switches+1] = switch_name
    end
    )

    luci.http.prepare_content("application/json")
    luci.http.write_json(switch_status_json(switches[1]))
end

function switch_status_json(devs)

    local dev
    local switches = { }
    for dev in devs:gmatch("[^%s,]+") do
        local ports = { }
        local swc = io.popen("swconfig dev %q show" % dev, "r")
        if swc then
            local l
            repeat
                l = swc:read("*l")
                if l then
                    local port, up = l:match("port:(%d+) link:(%w+)")
                    if port then
                        local speed  = l:match(" speed:(%d+)")
                        local duplex = l:match(" (%w+)-duplex")
                        local txflow = l:match(" (txflow)")
                        local rxflow = l:match(" (rxflow)")
                        local auto   = l:match(" (auto)")

                        ports[#ports+1] = {
                            port   = tonumber(port) or 0,
                            speed  = tonumber(speed) or 0,
                            link   = (up == "up"),
                            duplex = (duplex == "full"),
                            rxflow = (not not rxflow),
                            txflow = (not not txflow),
                            auto   = (not not auto)
                        }
                    end
                end
            until not l
            swc:close()
        end
        switches[dev] = ports
    end
    return switches
end
