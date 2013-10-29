#!/usr/bin/lua

firewall = {}

function firewall.configure()
    print("Disabling v6 firewall")

    local content = { insert = table.insert, concat = table.concat }
    for line in io.lines("/etc/firewall.user") do
        if not line:match("^ip6?tables ") then content:insert(line) end
    end
    content:insert("ip6tables -P INPUT ACCEPT")
    content:insert("ip6tables -P OUTPUT ACCEPT")
    content:insert("ip6tables -P FORWARD ACCEPT")
    content:insert("iptables -t mangle -A FORWARD -p tcp -o bmx+ -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu")
    fs.writefile("/etc/firewall.user", content:concat("\n").."\n")

    uci:foreach("firewall", "defaults", function(s)
        uci:set("firewall", s[".name"], "disable_ipv6", "1")
        uci:set("firewall", s[".name"], "input", "ACCEPT")
        uci:set("firewall", s[".name"], "output", "ACCEPT")
        uci:set("firewall", s[".name"], "forward", "ACCEPT")
    end)
    uci:foreach("firewall", "zone", function(s)
        uci:set("firewall", s[".name"], "input", "ACCEPT")
        uci:set("firewall", s[".name"], "output", "ACCEPT")
        uci:set("firewall", s[".name"], "forward", "ACCEPT")
    end)
    uci:save("firewall")
end

return firewall
