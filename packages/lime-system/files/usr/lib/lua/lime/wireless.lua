#!/usr/bin/lua

wireless = {}

function wireless.generate_ssid()
    local m4, m5, m6 = node_id()

    return string.format("%02x%02x%02x.lime", m4, m5, m6)
end

function wireless.clean()
    print("Clearing wireless config...")
    uci:foreach("wireless", "wifi-iface", function(s)
        uci:delete("wireless", s[".name"])
    end)
end

function wireless.init()
    -- TODO
end

function wireless.configure()
    local protocols = assert(uci:get("lime", "network", "protos"))
    local vlans = assert(uci:get("lime", "network", "vlans"))
    local n1, n2, n3 = network_id()
    local m4, m5, m6 = node_id()

    local channel2 = assert(uci:get("lime", "wireless", "mesh_channel_2ghz"))
    local channel5 = assert(uci:get("lime", "wireless", "mesh_channel_5ghz"))
    local mcast_rate_2 = assert(uci:get("lime", "wireless", "mesh_mcast_rate_2ghz"))
    local mcast_rate_5 = assert(uci:get("lime", "wireless", "mesh_mcast_rate_5ghz"))
    local wifi_num = 0

    wireless.clean()

    print("Defining wireless networks...")
    uci:foreach("wireless", "wifi-device", function(s)
        local t = iw.type(s[".name"])
        if not t then return end

        local is_5ghz = iw[t].hwmodelist(s[".name"]).a
        local ch = table.remove(is_5ghz and channel5 or channel2, 1)
        local mcr = is_5ghz and mcast_rate_5 or mcast_rate_2
        local id = string.format("mesh%d", wifi_num)
        local net = "lm_" .. id
        local ifn = string.format("mesh%d", wifi_num)
        local ifn_ap = string.format("wlan%dap", wifi_num)

        if not ch then
            printf("-> No channel defined for %dGHz %s", is_5ghz and 5 or 2, s[".name"])
            return
        end

        local ht = ch:match("[-+]?$")

        printf("-> Using channel %s for %dGHz %s", ch, is_5ghz and 5 or 2, s[".name"])
        uci:set("wireless", s[".name"], "channel", (ch:gsub("[-+]$", "")))

        if uci:get("wireless", s[".name"], "ht_capab") then
            if ht == "+" or ht == "-" then
                uci:set("wireless", s[".name"], "htmode", "HT40"..ht)
            else
                uci:set("wireless", s[".name"], "htmode", "HT20")
            end
        end

        uci:set("wireless", s[".name"], "disabled", 0)

        uci:set("wireless", id, "wifi-iface")
        uci:set("wireless", id, "mode", "adhoc")
        uci:set("wireless", id, "device", s[".name"])
        uci:set("wireless", id, "network", net)
        uci:set("wireless", id, "ifname", ifn)
        uci:set("wireless", id, "mcast_rate", mcr)
        uci:set("wireless", id, "ssid", wireless.generate_ssid())
        uci:set("wireless", id, "bssid", assert(uci:get("lime", "wireless", "mesh_bssid")))

        uci:set("wireless", ifn_ap, "wifi-iface")
        uci:set("wireless", ifn_ap, "mode", "ap")
        uci:set("wireless", ifn_ap, "device", s[".name"])
        uci:set("wireless", ifn_ap, "network", "lan")
        uci:set("wireless", ifn_ap, "ifname", ifn_ap)
        uci:set("wireless", ifn_ap, "ssid", assert(uci:get("lime", "wireless", "ssid")))

        -- base (untagged) wifi interface
        uci:set("network", net, "interface")
        uci:set("network", net, "proto", "none")
        uci:set("network", net, "mtu", "1528")

        -- For layer2 use a vlan based off network_id, between 16 and 255, if uci doesn't specify a vlan
        if not vlans[2] then vlans[2] = math.floor(16 + ((tonumber(n1) / 255) * (255 - 16))) end

        -- Add vlan interfaces on top of wlans, for each proto. Eg. lm_mesh0_batadv
        local n
        for n = 1, #protocols do
            local interface = "lm_" .. id .. "_" .. protocols[n]
            local ifname = string.format("@lm_%s.%d", id, vlans[n])
            local v4, v6 = network.generate_address(n, wifi_num)

            local proto = require("lime.proto." .. protocols[n])
            proto.setup_interface(interface, ifname, v4, v6)
        end

        wifi_num = wifi_num + 1
    end)
    uci:save("wireless")
    uci:save("network")
end

function wireless.apply()
    -- TODO (i.e. /etc/init.d/network restart)
end

return wireless
