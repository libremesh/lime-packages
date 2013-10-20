#!/usr/bin/lua

module(..., package.seeall)

function clean()
    print("Clearing wireless config...")
    x:foreach("wireless", "wifi-iface", function(s)
        x:delete("wireless", s[".name"])
    end)
end

function init()
    -- TODO
end

function configure()
    local protocols = assert(x:get("lime", "network", "protos"))
    local vlans = assert(x:get("lime", "network", "vlans"))
    local n1, n2, n3 = network_id()
    local r1, r2, r3 = node_id()

    local channel2 = assert(x:get("lime", "wireless", "mesh_channel_2ghz"))
    local channel5 = assert(x:get("lime", "wireless", "mesh_channel_5ghz"))
    local mcast_rate_2 = assert(x:get("lime", "wireless", "mesh_mcast_rate_2ghz"))
    local mcast_rate_5 = assert(x:get("lime", "wireless", "mesh_mcast_rate_5ghz"))
    local wifi_num = 0

    clean()

    print("Defining wireless networks...")
    x:foreach("wireless", "wifi-device", function(s)
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
        x:set("wireless", s[".name"], "channel", (ch:gsub("[-+]$", "")))

        if x:get("wireless", s[".name"], "ht_capab") then
            if ht == "+" or ht == "-" then
                x:set("wireless", s[".name"], "htmode", "HT40"..ht)
            else
                x:set("wireless", s[".name"], "htmode", "HT20")
            end
        end

        x:set("wireless", s[".name"], "disabled", 0)

        x:set("wireless", id, "wifi-iface")
        x:set("wireless", id, "mode", "adhoc")
        x:set("wireless", id, "device", s[".name"])
        x:set("wireless", id, "network", net)
        x:set("wireless", id, "ifname", ifn)
        x:set("wireless", id, "mcast_rate", mcr)
        x:set("wireless", id, "ssid", generate_ssid())
        x:set("wireless", id, "bssid", assert(x:get("lime", "wireless", "mesh_bssid")))

        x:set("wireless", ifn_ap, "wifi-iface")
        x:set("wireless", ifn_ap, "mode", "ap")
        x:set("wireless", ifn_ap, "device", s[".name"])
        x:set("wireless", ifn_ap, "network", "lan")
        x:set("wireless", ifn_ap, "ifname", ifn_ap)
        x:set("wireless", ifn_ap, "ssid", assert(x:get("lime", "wireless", "ssid")))

        -- base (untagged) wifi interface
        x:set("network", net, "interface")
        x:set("network", net, "proto", "none")
        x:set("network", net, "mtu", "1528")

        -- For layer2 use a vlan based off network_id, between 16 and 255, if uci doesn't specify a vlan
        if not vlans[2] then vlans[2] = math.floor(16 + ((tonumber(n1) / 255) * (255 - 16))) end

        -- Add vlan interfaces on top of wlans, for each proto. Eg. lm_mesh0_batadv
        local n
        for n = 1, #protocols do
            local interface = "lm_" .. id .. "_" .. protocols[n]
            local ifname = string.format("@lm_%s.%d", id, vlans[n])
            local v4, v6 = generate_address(n, wifi_num)

            assert(loadstring("setup_interface_" .. protocols[n] .. "(interface, ifname, v4, v6)"))
        end

        wifi_num = wifi_num + 1
    end)
end

function apply()
    -- TODO (i.e. /etc/init.d/network restart)
end
