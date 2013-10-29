#!/usr/bin/lua

network = {}

local bit = require "nixio".bit
local ip = require "luci.ip"

local function hex(x)
    return string.format("%02x", x)
end

local function split(string, sep)
    local ret = {}
    for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
    return ret
end

function network.eui64(mac)
    local function flip_7th_bit(x) return hex(bit.bxor(tonumber(x, 16), 2)) end

    local t = split(mac, ":")
    t[1] = flip_7th_bit(t[1])

    return string.format("%s%s:%sff:fe%s:%s%s", t[1], t[2], t[3], t[4], t[5], t[6])
end

function network.generate_host(ipprefix, hexsuffix)
    -- use only the 8 rightmost nibbles for IPv4, or 32 nibbles for IPv6
    hexsuffix = hexsuffix:sub((ipprefix[1] == 4) and -8 or -32)

    -- convert hexsuffix into a cidr instance, using same prefix and family of ipprefix
    local ipsuffix = ip.Hex(hexsuffix, ipprefix:prefix(), ipprefix[1])

    local ipaddress = ipprefix
    -- if it's a network prefix, fill in host bits with ipsuffix
    if ipprefix:equal(ipprefix:network()) then
        for i in ipairs(ipprefix[2]) do
            -- reset ipsuffix netmask bits to 0
            ipsuffix[2][i] = bit.bxor(ipsuffix[2][i],ipsuffix:network()[2][i])
            -- fill in ipaddress host part, with ipsuffix bits
            ipaddress[2][i] = bit.bor(ipaddress[2][i],ipsuffix[2][i])
        end
    end

    return ipaddress
end

function network.generate_address(p, n)
    local id = n
    local m4, m5, m6 = node_id()
    local n1, n2, n3 = network_id()
    local ipv4_template = assert(x:get("lime", "network", "ipv4_net"))
    local ipv6_template = assert(x:get("lime", "network", "ipv6_net"))

    ipv6_template = ipv6_template:gsub("N1", hex(n1)):gsub("N2", hex(n2)):gsub("N3", hex(n3))
    ipv4_template = ipv4_template:gsub("N1", n1):gsub("N2", n2):gsub("N3", n3)

    hexsuffix = hex((m4 * 256*256 + m5 * 256 + m6) + id)
    return network.generate_host(ip.IPv4(ipv4_template), hexsuffix):string(),
           network.generate_host(ip.IPv6(ipv6_template), hexsuffix):string()
end

function network.setup_lan(v4, v6)
    x:set("network", "lan", "ip6addr", v6)
    x:set("network", "lan", "ipaddr", v4:match("^([^/]+)"))
    x:set("network", "lan", "netmask", "255.255.255.0")
    x:set("network", "lan", "ifname", "eth0 bat0")
    x:save("network")
end

function network.setup_anygw(v4, v6)
    local n1, n2, n3 = network_id()

    -- anygw macvlan interface
    print("Ugly overwrite of /etc/rc.local to make it add macvlan interface...")
    local anygw_mac = string.format("aa:aa:aa:%02x:%02x:%02x", n1, n2, n3)
    local v6prefix = v6:match("^([^:]+:[^:]+:[^:]+:[^:]+):")
    local v4prefix = v4:match("^([^.]+.[^.]+.[^.]+).")
    local anygw_ipv6 = string.format(v6prefix .. "::1/64")
    local anygw_ipv4 = string.format(v4prefix .. ".1/24")
    local content = { }
    table.insert(content, "ip link add link br-lan anygw address " .. anygw_mac .. " type macvlan")
    table.insert(content, "ip address add dev anygw " .. anygw_ipv6)
    table.insert(content, "ip address add dev anygw " .. anygw_ipv4)
    table.insert(content, "ip link set anygw up")
    table.insert(content, "ebtables -A FORWARD -j DROP -d " .. anygw_mac)
    table.insert(content, "ebtables -t nat -A POSTROUTING -o bat0 -j DROP -s " .. anygw_mac)
    table.insert(content, "exit 0")
    fs.writefile("/etc/rc.local", table.concat(content, "\n").."\n")

    -- IPv6 router advertisement for anygw interface
    print("Enabling RA in dnsmasq...")
    local content = { }
    table.insert(content,               "enable-ra")
    table.insert(content, string.format("dhcp-range=tag:anygw,%s::, ra-names", v6prefix))
    table.insert(content,               "dhcp-option=tag:anygw,option6:domain-search, lan")
    table.insert(content, string.format("address=/anygw/%s::1", v6prefix))
    table.insert(content, string.format("dhcp-option=tag:anygw,option:router,%s.1", v4prefix))
    table.insert(content, string.format("dhcp-option=tag:anygw,option:dns-server,%s.1", v4prefix))
    table.insert(content,               "no-dhcp-interface=br-lan")
    fs.writefile("/etc/dnsmasq.conf", table.concat(content, "\n").."\n")

    -- and disable 6relayd
    print("Disabling 6relayd...")
    fs.writefile("/etc/config/6relayd", "")
end

function network.clean()
    print("Clearing network config...")
    x:foreach("network", "interface", function(s)
        if s[".name"]:match("^lm_") then
            x:delete("network", s[".name"])
        end
    end)
end

function network.init()
    -- TODO
end

function network.configure()
    local protocols = assert(x:get("lime", "network", "protos"))
    local vlans = assert(x:get("lime", "network", "vlans"))
    local n1, n2, n3 = network_id()
    local m4, m5, m6 = node_id()
    local v4, v6 = network.generate_address(1, 0) -- for br-lan

    network.clean()

    network.setup_lan(v4, v6)
    network.setup_anygw(v4, v6)

    -- For layer2 use a vlan based off network_id, between 16 and 255, if uci doesn't specify a vlan
    if not vlans[2] then vlans[2] = math.floor(16 + ((tonumber(n1) / 255) * (255 - 16))) end

    -- TODO:
    -- for each net ; if protocols = wan or lan ; setup_network_interface_lan
    --             elsif protocols = bmx6 or batadv ; setup_network_interface_ .. protocol
    -- FIXME: currently adds vlan interfaces on top of ethernet, for each proto (batadv or bmx6).
    --        Eg. lm_eth_batadv
    local n
    for n = 1, #protocols do
        local interface = "lm_eth_" .. protocols[n]
        local ifname = string.format("eth1.%d", vlans[n])
        local v4, v6 = network.generate_address(n, 0)

        local proto = require("lime.proto." .. protocols[n])
        proto.configure(v4, v6)
        proto.setup_interface(interface, ifname, v4, v6)
    end
end

function network.apply()
    -- TODO (i.e. /etc/init.d/network restart)
end

return network
