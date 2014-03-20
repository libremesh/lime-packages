#!/usr/bin/lua

local fs = require("nixio.fs")

firewall = {}

function firewall.clean()
	local fwcfg = { "/etc/config/firewall", "/etc/lime-firewall.d/10-accept.start", "/etc/lime-firewall.d/15-mss_clamp.start" }
	for _,file in pairs(fwcfg) do
		fs.writefile(file,"")
	end
end

function firewall.configure()

	fs.writefile(
		"/etc/lime-firewall.d/10-accept.start", [[
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

ip6tables -P INPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P FORWARD ACCEPT
]])

	fs.writefile(
		"/etc/lime-firewall.d/15-mss_clamp.start",
		"iptables -t mangle -A FORWARD -p tcp -o bmx+ -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu")

end

return firewall
