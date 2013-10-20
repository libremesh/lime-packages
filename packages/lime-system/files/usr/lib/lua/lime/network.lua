#!/usr/bin/lua

function clean()
  print("Clearing network config...")
  x:foreach("network", "interface", function(s)
    if s[".name"]:match("^lm_") then
      x:delete("network", s[".name"])
    end
  end)
end

function init()
  -- TODO
end

function configure(v4, v6)
	local protocols = assert(x:get("lime", "network", "protos"))
	local vlans = assert(x:get("lime", "network", "vlans"))
	local n1, n2, n3 = network_id()
	local r1, r2, r3 = node_id()

  clean()

  setup_lan(v4, v6)
  setup_anygw(v4, v6)

  -- For layer2 use a vlan based off network_id, between 16 and 255, if uci doesn't specify a vlan
	if not vlans then vlans = math.floor(16 + ((tonumber(n1) / 255) * (255 - 16))) end
  
  -- TODO:
  -- for each net ; if protocols = wan or lan ; setup_network_interface_lan
  --             elsif protocols = bmx6 or batadv ; setup_network_interface_ .. protocol
  -- FIXME: currently adds vlan interfaces on top of ethernet, for each proto (batadv or bmx6).
  --        Eg. lm_eth_batadv
	local n
	for n = 1, #protocols do
		local interface = "lm_eth_" .. protocols[n]
		local ifname = string.format("eth1.%d", vlans[n])
		local v4, v6 = generate_address(n, 0)

    assert(loadstring("setup_interface_" .. protocols[n] .. "(interface, ifname, v4, v6)"))
	end
end

function apply()
  -- TODO (i.e. /etc/init.d/network restart)
end

function setup_lan(v4, v6)
	x:set("network", "lan", "ip6addr", v6)
	x:set("network", "lan", "ipaddr", v4:match("^([^/]+)"))
	x:set("network", "lan", "netmask", "255.255.255.0")
	x:set("network", "lan", "ifname", "eth0 bat0")
end

function setup_anygw(v4, v6)
  -- anygw macvlan interface
  print("Ugly overwrite of /etc/rc.local to make it add macvlan interface...")
  local anygw_mac = string.format("aa:aa:aa:%02x:%02x:%02x", n1, n2, n3)
  local v6prefix = v6:match("^([^:]+:[^:]+:[^:]+):")
  local v4prefix = v4:match("^([^.]+.[^.]+.[^.]+).")
  local anygw_ipv6 = string.format(v6prefix .. "::1/64")
  local anygw_ipv4 = string.format(v4prefix .. ".1/24")
  local content = { }
  table.insert(content, "ip link add link br-lan anygw address " .. anygw_mac .. " type macvlan")
  table.insert(content, "ip address add dev anygw " .. anygw_ipv6)
  table.insert(content, "ip address add dev anygw " .. anygw_ipv4)
  table.insert(content, "ip link set anygw up")
  table.insert(content, "ebtables -A FORWARD -j DROP -d " .. anygw_mac)
  table.insert(content, "exit 0")
  fs.writefile("/etc/rc.local", table.concat(content, "\n").."\n")

  -- IPv6 router advertisement for anygw interface
  print("Enabling RA in dnsmasq...")
  local content = { }
  table.insert(content, "enable-ra")
  table.insert(content, string.format("dhcp-range=%s::, ra-names", v6prefix))
  table.insert(content, "dhcp-option=option6:domain-search, lan")
  table.insert(content, string.format("address=/anygw/%s::1", v6prefix))
  table.insert(content, string.format("dhcp-option=option:router,%s.1", v4prefix))
  table.insert(content, string.format("dhcp-option=option:dns-server,%s.1", v4prefix))
  fs.writefile("/etc/dnsmasq.conf", table.concat(content, "\n").."\n")

  -- and disable 6relayd
  print("Disabling 6relayd...")
  fs.writefile("/etc/config/6relayd", "")
end
