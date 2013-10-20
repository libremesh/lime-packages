#!/usr/bin/lua

function configure()
    print("Disabling v6 firewall")
    fs.writefile("/etc/firewall.user", "ip6tables -P INPUT ACCEPT\nip6tables -P OUTPUT ACCEPT\nip6tables -P FORWARD ACCEPT\niptables -t mangle -A FORWARD -p tcp -o bmx+ -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu\n")
    x:foreach("firewall", "defaults", function(s)
        x:set("firewall", s[".name"], "disable_ipv6", "1")
        x:set("firewall", s[".name"], "input", "ACCEPT")
        x:set("firewall", s[".name"], "output", "ACCEPT")
        x:set("firewall", s[".name"], "forward", "ACCEPT")
    end)

    x:foreach("firewall", "zone", function(s)
        x:set("firewall", s[".name"], "input", "ACCEPT")
        x:set("firewall", s[".name"], "output", "ACCEPT")
        x:set("firewall", s[".name"], "forward", "ACCEPT")
    end)
end
