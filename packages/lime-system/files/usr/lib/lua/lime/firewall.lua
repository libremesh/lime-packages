#!/usr/bin/lua

firewall = {}

function firewall.configure()
    print("Disabling v6 firewall")
    fs.writefile("/etc/firewall.user", "ip6tables -P INPUT ACCEPT\nip6tables -P OUTPUT ACCEPT\nip6tables -P FORWARD ACCEPT\niptables -t mangle -A FORWARD -p tcp -o bmx+ -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu\n")
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
