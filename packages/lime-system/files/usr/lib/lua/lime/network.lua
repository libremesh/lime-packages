#!/usr/bin/lua

--! LibreMesh community mesh networks meta-firmware
--!
--! Copyright (C) 2013-2024  Gioacchino Mazzurco <gio@polymathes.cc>
--! Copyright (C) 2023-2024  Asociación Civil Altermundi <info@altermundi.net>
--!
--! SPDX-License-Identifier: AGPL-3.0-only

network = {}

local ip = require("luci.ip")
local fs = require("nixio.fs")

local config = require("lime.config")
local utils = require("lime.utils")


function network.PROTO_PARAM_SEPARATOR() return ":" end
function network.PROTO_VLAN_SEPARATOR() return "_" end
function network.LIME_UCI_IFNAME_PREFIX() return "lm_net_" end


network.MTU_ETH = 1500
network.MTU_ETH_WITH_VLAN = network.MTU_ETH - 4

--! Deprecated use corresponding functions instead
network.protoParamsSeparator=":"
network.protoVlanSeparator="_"
network.limeIfNamePrefix="lm_net_"

--! Retuns the mac address of the interface or nill if it does not exist
function network.get_mac(ifname)
	local _, macaddr = next(network.get_own_macs(ifname))
	--! this is to avoid the error:
	--! ...ackages/lime-system/files/usr/lib/lua/lime/utils.lua:53: attempt to index local 'string' (a nil value)
	if macaddr == nil then
		return nil
	end
	return utils.split(macaddr, ":")
end

--! Return a table of macs based on the interface globing filter
function network.get_own_macs(interface_filter)
	if interface_filter == nil then
		interface_filter = '*'
	end

	local macs = {}
	local search_path = "/sys/class/net/" .. interface_filter .. "/address"
	for address_path in fs.glob(search_path) do
		mac = io.open(address_path):read("*l")
		macs[mac] = 1
	end

	local result = {}
	for mac, _ in pairs(macs) do
		table.insert(result, mac)
	end
	return result
end


function network.assert_interface_exists(ifname)
	assert( ifname ~= nil and ifname ~= "",
	        "network.primary_interface() could not determine ifname!" )

	assert( fs.lstat("/sys/class/net/"..ifname),
	        "network.primary_interface() "..ifname.." doesn't exists!" )
end

function network.primary_interface()
	local ifname = config.get("network", "primary_interface", "eth0")
	if ifname == "auto" then
		local board = utils.getBoardAsTable()
		ifname = board['network']['lan']['device']
	end
	network.assert_interface_exists(ifname)
	return ifname
end

function network.primary_mac()
	return network.get_mac(network.primary_interface())
end

function network.generate_host(ipprefix, hexsuffix)
	local num = 0
	--! If it's a network prefix calculate offset to add
	if ipprefix:equal(ipprefix:network()) then
		local addr_len = ipprefix:is4() and 32 or ipprefix:is6() and 128
		num = tonumber(hexsuffix,16) % 2^(addr_len - ipprefix:prefix())
	end

	return ipprefix:add(num)
end

function network.primary_address(offset)
	local offset = offset or 0
	local pm = network.primary_mac()
	local ipv4_template = config.get("network", "main_ipv4_address")
	local ipv6_template = config.get("network", "main_ipv6_address")

	local ipv4_maskbits = ipv4_template:match("[^/]+/(%d+)")
	ipv4_template = ipv4_template:gsub("/%d-/","/")
	local ipv6_maskbits = ipv6_template:match("[^/]+/(%d+)")
	ipv6_template = ipv6_template:gsub("/%d-/","/")

	ipv4_template = utils.applyMacTemplate10(ipv4_template, pm)
	ipv6_template = utils.applyMacTemplate16(ipv6_template, pm)

	ipv4_template = utils.applyNetTemplate10(ipv4_template)
	ipv6_template = utils.applyNetTemplate16(ipv6_template)

	local m4, m5, m6 = tonumber(pm[4], 16), tonumber(pm[5], 16), tonumber(pm[6], 16)
	local hexsuffix = utils.hex((m4 * 256*256 + m5 * 256 + m6) + offset)
	ipv4_template = network.generate_host(ip.IPv4(ipv4_template), hexsuffix)
	ipv6_template = network.generate_host(ip.IPv6(ipv6_template), hexsuffix)

	ipv4_template:prefix(tonumber(ipv4_maskbits))
	local mc = ipv4_template
	--! Generated address is network address like 192.0.2.0/24 ?
	local invalid = ipv4_template:equal(mc:network()) and "NETWORK"
	--! If anygw enabled, generated address is the one reserved for anygw like 192.0.2.1/24 ?
	if utils.isModuleAvailable("lime.proto.anygw") then
		local generalProtocols = config.get("network", "protocols")
		for _,protocol in pairs(generalProtocols) do
			if protocol == 'anygw' then
				invalid = invalid or ipv4_template:equal(mc:minhost()) and "ANYGW"
				break
			end
		end
	end
	--! Generated address is the broadcast address like 192.0.2.255/24 ?
	invalid = invalid or ipv4_template:equal(mc:broadcast()) and "BROADCAST"
	if invalid then
		ipv4_template = mc:maxhost()
		ipv4_template:prefix(tonumber(ipv4_maskbits))
		utils.log("INVALID main_ipv4_address " ..tostring(mc).. " IDENTICAL TO RESERVED "
			..invalid.. " ADDRESS. USING " ..tostring(ipv4_template))
	end

	ipv6_template:prefix(tonumber(ipv6_maskbits))

	return ipv4_template, ipv6_template
end

function network.setup_rp_filter()
	local sysctl_file_path = "/etc/sysctl.conf";
	local sysctl_options = "";
	local sysctl_file = io.open(sysctl_file_path, "r");
	while sysctl_file:read(0) do
		local sysctl_line = sysctl_file:read();
		if not string.find(sysctl_line, ".rp_filter") then sysctl_options = sysctl_options .. sysctl_line .. "\n" end 
	end
	sysctl_file:close()
	
	sysctl_options = sysctl_options .. "net.ipv4.conf.default.rp_filter=2\nnet.ipv4.conf.all.rp_filter=2\n";
	sysctl_file = io.open(sysctl_file_path, "w");
	if sysctl_file ~= nil then
		sysctl_file:write(sysctl_options);
		sysctl_file:close();
	end
end

function network.setup_dns()
	local cloudDomain = config.get("system", "domain")
	local resolvers = config.get("network", "resolvers")

	local uci = config.get_uci_cursor()
	uci:foreach("dhcp", "dnsmasq",
		function(s)
			uci:set("dhcp", s[".name"], "domain", cloudDomain)
			uci:set("dhcp", s[".name"], "local", "/"..cloudDomain.."/")
			uci:set("dhcp", s[".name"], "expandhosts", "1")
			uci:set("dhcp", s[".name"], "domainneeded", "1")
			--! allow queries from non-local ips (i.e. from other clouds)
			uci:set("dhcp", s[".name"], "localservice", "0")
			uci:set("dhcp", s[".name"], "server", resolvers)
			uci:set("dhcp", s[".name"], "confdir", "/etc/dnsmasq.d")
		end
	)
	uci:save("dhcp")

	fs.mkdir("/etc/dnsmasq.d")
end

function network.clean()
	utils.log("Clearing network config...")

	local uci = config.get_uci_cursor()

	uci:delete("network", "globals", "ula_prefix")
	uci:set("network", "wan", "proto", "none")
	uci:set("network", "wan6", "proto", "none")

	--! Delete sections generated by LiMe
	local function delete_lime_section(s)
		if utils.stringStarts(s[".name"], network.limeIfNamePrefix) then
			uci:delete("network", s[".name"])
		end
	end
	uci:foreach("network", "interface", delete_lime_section)
	uci:foreach("network", "device", delete_lime_section)
	uci:foreach("network", "rule", delete_lime_section)
	uci:foreach("network", "route", delete_lime_section)
	uci:foreach("network", "rule6", delete_lime_section)
	uci:foreach("network", "route6", delete_lime_section)

	uci:save("network")

	if config.get_bool("network", "use_odhcpd", false) then
		utils.log("Use odhcpd as dhcp server")
		uci:set("dhcp", "odchpd", "maindhcp", 1)
		os.execute("[ -e /etc/init.d/odhcpd ] && /etc/init.d/odhcpd enable")
	else
		utils.log("Disabling odhcpd")
		uci:set("dhcp", "odchpd", "maindhcp", 0)
		os.execute("[ -e /etc/init.d/odhcpd ] && /etc/init.d/odhcpd disable")
	end

	utils.log("Cleaning dnsmasq")
	uci:foreach("dhcp", "dnsmasq", function(s) uci:delete("dhcp", s[".name"], "server") end)
	uci:save("dhcp")

	utils.log("Disabling 6relayd...")
	fs.writefile("/etc/config/6relayd", "")
end

function network._get_lower(dev)
    local lower_if_path = utils.unsafe_shell("ls /sys/class/net/" .. dev .. "/ | grep ^lower")
    local lower_if_table = utils.split(lower_if_path, "_")
    local lower_if = lower_if_table[#lower_if_table]
    return lower_if and lower_if:gsub("\n", "")
end

function network._is_dsa_conduit(dev)
	return "reg" == fs.stat("/sys/class/net/" .. dev .. "/dsa/tagging", "type")
end


function network.scandevices(specificIfaces)
	local devices = {}
	local wireless = require("lime.wireless")
	local cpu_ports = {}
	local board = utils.getBoardAsTable()

	function dev_parser(dev)
		if dev == nil then
			utils.log("network.scandevices.dev_parser got nil device")
			return
		end

		--! Avoid configuration on DSA conduit interfaces.
		--! See also:
		--! https://www.kernel.org/doc/html/latest/networking/dsa/dsa.html#common-pitfalls-using-dsa-setups
		if network._is_dsa_conduit(dev) then
			utils.log( "network.scandevices.dev_parser ignored DSA conduit " ..
			           "device %s", dev )
			return
		end

		--! Filter out ethernet ports connected to switch in a swconfig device.
		for cpu_port,_ in pairs(cpu_ports) do
			if cpu_port == dev then
				utils.log( "network.scandevices.dev_parser ignored ethernet " ..
				           "device %s connected to internal switch", dev )
				return
			end
		end

		if dev:match("^eth%d+$") then
			--! We only get here with devices not listed in board.json, e.g
			--! pluggable ethernet dongles.
			utils.log( "network.scandevices.dev_parser found plain Ethernet " ..
			           "device %s", dev )
		elseif dev:match("^wlan%d+"..wireless.WIFI_MODE_SEPARATOR().."%w+$") then
			utils.log( "network.scandevices.dev_parser found WiFi device %s",
			           dev )
		elseif specificIfaces[dev] then
			utils.log( "network.scandevices.dev_parser found device %s that " ..
			           "matches the config net section %s", dev,
			           specificIfaces[dev][".name"])
		else
			return
		end

		local is_dsa = utils.is_dsa(dev)
		devices[dev] = devices[dev] or {}
		devices[dev]["dsa"] = is_dsa
	end

	function owrt_ifname_parser(section)
		local ifn = section["ifname"]
		if ( type(ifn) == "string" ) then
			utils.log( "network.scandevices.owrt_ifname_parser found ifname %s",
			           ifn )
			dev_parser(ifn)
		end
	end

	function board_port_parser(dev)
		local is_dsa = utils.is_dsa(dev)
		devices[dev] = devices[dev] or {}
		devices[dev]["dsa"] = is_dsa
		if is_dsa then
			utils.log( "network.scandevices found DSA-port %s in board.json",
			           dev )
		else
			utils.log( "network.scandevices found device %s in board.json", dev )
		end
	end

	--! Collect switch facing ethernet ports for swconfig devices from board.json
	for switch, switch_table in pairs(board["switch"] or {}) do
		for _,port_table in pairs(switch_table["ports"] or {}) do
			local dev = port_table["device"]
			if dev then
				cpu_ports[dev] = true
			end
		end
	end

	--! Collect dsa ports and usable ethernet and vlan devices from board.json
	for role, role_table in pairs(board["network"] or {}) do
		--! "ports" and "device" fields may be specified at the same time.
		--! In this case, "ports" must be used.
		local ports = role_table["ports"]
		if ports == nil then
			ports = { role_table["device"] }
		end
		local protocol = role_table["protocol"]
		--! Protocol can be dhcp, static, pppoe, ncm, qmi, mbim.
		--! Ethernet interfaces usually have protocol "dhcp" or "static",
		--! depending on their role.
		if protocol == "dhcp" or protocol == "static" then
			for _,port in pairs(ports) do
				board_port_parser(port)
			end
		end
	end

	--! Scrape from uci wireless
	local uci = config.get_uci_cursor()
	uci:foreach("wireless", "wifi-iface", owrt_ifname_parser)

	--! Scrape from /sys/class/net/
	local stdOut = io.popen("ls -1 /sys/class/net/")
	for dev in stdOut:lines() do dev_parser(dev) end
	stdOut:close()

	return devices
end

function network.configure()
	local specificIfaces = {}

	config.foreach("net", function(iface)
		if iface["linux_name"] then
			specificIfaces[iface["linux_name"]] = iface
		end
	end)

	local fisDevs = network.scandevices(specificIfaces)

	network.setup_rp_filter()

	network.setup_dns()

	local generalProtocols = config.get("network", "protocols")
	for _,protocol in pairs(generalProtocols) do
		local protoModule = "lime.proto."..utils.split(protocol,":")[1]
		if utils.isModuleAvailable(protoModule) then
			local proto = require(protoModule)
			xpcall(function() proto.configure(utils.split(protocol, network.protoParamsSeparator)) end,
				   function(errmsg) print(errmsg) ; print(debug.traceback()) end)
		end
	end

	--! For each scanned fisical device, if there is a specific config apply that one otherwise apply general config
	for device,flags in pairs(fisDevs) do
		local owrtIf = specificIfaces[device]
		local deviceProtos = generalProtocols
		if owrtIf then
			deviceProtos = owrtIf["protocols"] or {"manual"}
			flags["specific"] = true
			flags["_specific_section"] = owrtIf
		end

		for _,protoParams in pairs(deviceProtos) do
			local args = utils.split(protoParams, network.protoParamsSeparator)
			local protoName = args[1]
			if protoName == "manual" then break end -- If manual is specified do not configure interface
			local protoModule = "lime.proto."..protoName
			local needsConfig = utils.isModuleAvailable(protoModule)
			if protoName ~= 'lan' and not flags["specific"] then
				--! Work around issue 1121. Do not configure any other
				--! protocols than lime.proto.lan on dsa devices unless there
				--! is a config net section for the device.
				needsConfig = needsConfig and not utils.is_dsa(device)
			end
			if needsConfig then
				for k,v in pairs(flags) do args[k] = v end
				local proto = require(protoModule)
				xpcall(function() proto.configure(args) ; proto.setup_interface(device, args) end,
					   function(errmsg) print(errmsg) ; print(debug.traceback()) end)
			end
		end
	end
end

function network.sanitizeIfaceName(ifName)
	return network.limeIfNamePrefix..ifName:gsub("[^%w_]", "_")
end

--! Creates a network Interface with static protocol
--! ipAddr can be IPv4 or IPv6
--! the function can be called twice to set both IPv4 and IPv6
function network.createStaticIface(linuxBaseIfname, openwrtNameSuffix, ipAddr, gwAddr)
	local openwrtNameSuffix = openwrtNameSuffix or ""
	local owrtInterfaceName = network.sanitizeIfaceName(linuxBaseIfname) .. openwrtNameSuffix
	local uci = config.get_uci_cursor()

	uci:set("network", owrtInterfaceName, "interface")
	uci:set("network", owrtInterfaceName, "proto", "static")
	uci:set("network", owrtInterfaceName, "auto", "1")
	uci:set("network", owrtInterfaceName, "ifname", linuxBaseIfname)

	local addr = luci.ip.new(ipAddr)
	local host = addr:host():string()

	if addr:is4() then
		local mask = addr:mask():string()
		uci:set("network", owrtInterfaceName, "ipaddr", host)
		uci:set("network", owrtInterfaceName, "netmask", mask)
		if gwAddr then
			uci:set("network", owrtInterfaceName, "gateway", gwAddr)
		end
	elseif addr:is6() then
		uci:set("network", owrtInterfaceName, "ip6addr", addr:string())
		if gwAddr then
			uci:set("network", owrtInterfaceName, "ip6gw", gwAddr)
		end
	else
		uci:delete("network", owrtInterfaceName, "interface")
	end

	uci:save("network")
end

function network.createVlanIface(linuxBaseIfname, vid, openwrtNameSuffix, vlanProtocol)
	vlanProtocol = vlanProtocol or "8021ad"
	openwrtNameSuffix = openwrtNameSuffix or ""
	vid = tonumber(vid)
	
	--! sanitize passed linuxBaseIfName for constructing uci section name
	--! because only alphanumeric and underscores are allowed
	local owrtInterfaceName = network.sanitizeIfaceName(linuxBaseIfname)
	local owrtDeviceName = owrtInterfaceName
	local linux802adIfName = linuxBaseIfname

	local uci = config.get_uci_cursor()

	owrtInterfaceName = owrtInterfaceName..openwrtNameSuffix.."_if"

	if vid ~= 0 then
		local vlanId = tostring(vid)
		--! sanitize passed linuxBaseIfName for constructing uci section name
		--! because only alphanumeric and underscores are allowed
		owrtDeviceName = network.sanitizeIfaceName(linuxBaseIfname)..openwrtNameSuffix.."_dev"

		if linuxBaseIfname:match("^wlan") then
			linuxBaseIfname = "@"..network.sanitizeIfaceName(linuxBaseIfname)
		end

		--! Do not use . as separator as this will make netifd create an 802.1q interface anyway
		--! and sanitize linuxBaseIfName because it can contain dots as well (i.e. switch ports)
		linux802adIfName = linux802adIfName:gsub("[^%w-]", "-")..network.protoVlanSeparator..vlanId
		
		uci:set("network", owrtDeviceName, "device")
		uci:set("network", owrtDeviceName, "type", vlanProtocol)
		uci:set("network", owrtDeviceName, "name", linux802adIfName)
		--! This is ifname also on current OpenWrt
		uci:set("network", owrtDeviceName, "ifname", linuxBaseIfname)
		uci:set("network", owrtDeviceName, "vid", vlanId)
	end

	uci:set("network", owrtInterfaceName, "interface")
	local proto = "none"
	if vid == 0 then
		proto = "static"
	end
	uci:set("network", owrtInterfaceName, "proto", proto)
	uci:set("network", owrtInterfaceName, "auto", "1")

	--! In case of wifi interface not using vlan (vid == 0) avoid to set
	--! ifname in network because it is already set in wireless, because
	--! setting ifname on both places cause a netifd race condition
	if vid ~= 0 or not linux802adIfName:match("^wlan") then
		uci:set("network", owrtInterfaceName, "device", linux802adIfName)
	end

	uci:save("network")

	return owrtInterfaceName, linux802adIfName, owrtDeviceName
end

function network.createMacvlanIface(baseIfname, linuxName, argsDev, argsIf)
	--! baseIfname can be a linux interface name like eth0 or an openwrt
	--! interface name like @lan of the base interface;
	--! linuxName is the linux name of the new interface;
	--! argsDev optional additional arguments for device like
	--! { macaddr="aa:aa:aa:aa:aa:aa", mode="vepa" };
	--! argsIf optional additional arguments for ifname like
	--! { proto="static", ip6addr="2001:db8::1/64" }
	--!
	--! Although this function is defined here lime-system may not depend
	--! on macvlan if it doesn't use this function directly. Instead a
	--! lime.proto which want to use macvlan so this function should depend
	--! on its own on kmod-macvlan as needed.

	argsDev = argsDev or {}
	argsIf = argsIf or {}

	local owrtDeviceName = network.limeIfNamePrefix..baseIfname.."_"..linuxName.."_dev"
	local owrtInterfaceName = network.limeIfNamePrefix..baseIfname.."_"..linuxName.."_if"
	--! sanitize uci sections name
	owrtDeviceName = owrtDeviceName:gsub("[^%w_]", "_")
	owrtInterfaceName = owrtInterfaceName:gsub("[^%w_]", "_")

	local uci = config.get_uci_cursor()

	uci:set("network", owrtDeviceName, "device")
	uci:set("network", owrtDeviceName, "type", "macvlan")
	uci:set("network", owrtDeviceName, "name", linuxName)
	--! This is ifname also on current OpenWrt
	uci:set("network", owrtDeviceName, "ifname", baseIfname)
	for k,v in pairs(argsDev) do
		uci:set("network", owrtDeviceName, k, v)
	end

	uci:set("network", owrtInterfaceName, "interface")
	uci:set("network", owrtInterfaceName, "proto", "none")
	uci:set("network", owrtInterfaceName, "device", linuxName)
	uci:set("network", owrtInterfaceName, "auto", "1")
	for k,v in pairs(argsIf) do
		uci:set("network", owrtInterfaceName, k, v)
	end

	uci:save("network")

	return owrtInterfaceName, linuxName, owrtDeviceName
end

--! Create a static interface at runtime via ubus
function network.createStatic(linuxBaseIfname)
	local ipv4, ipv6 = network.primary_address()
	local ubusIfaceName = network.sanitizeIfaceName(
		network.LIME_UCI_IFNAME_PREFIX()..linuxBaseIfname.."_static")
	local ifaceConf = {
		name    = ubusIfaceName,
		proto   = "static",
		auto    = "1",
		ifname  = linuxBaseIfname,
		ipaddr  = ipv4:host():string(),
		netmask = "255.255.255.255"
	}

	local libubus = require("ubus")
	local ubus = libubus.connect()
	ubus:call('network', 'add_dynamic', ifaceConf)
	ubus:call('network.interface.'..ifaceConf.name, 'up', {})

--! TODO: As of today ubus silently fails to properly setup the interface,
--! subsequent status query return NO_DEVICE error
--!  ubus -v call network.interface.lm_net_lm_net_wlan0_peer1_static status
--!  {
--!          "up": false,
--!          "pending": false,
--!          "available": false,
--!          "autostart": true,
--!          "dynamic": true,
--!          "proto": "static",
--!          "data": {
--!
--!          },
--!          "errors": [
--!                  {
--!                          "subsystem": "interface",
--!                          "code": "NO_DEVICE"
--!                  }
--!          ]
--!  }
--!
--! ATM work around the problem configuring IP addresses via ip command

	utils.unsafe_shell("ip link set up dev "..ifaceConf.ifname)
	utils.unsafe_shell("ip address add "..ifaceConf.ipaddr.."/32 dev "..ifaceConf.ifname)

	return ifaceConf.name
end

--! Check if a device exists in the system
function network.device_exists(dev)
    local handle = io.popen("ip link show " .. dev .. " 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    return result ~= nil and result ~= ""
end

--! Create a vlan at runtime via ubus
function network.createVlan(linuxBaseIfname, vid, vlanProtocol)
	local vlanConf = {
		name   = linuxBaseIfname .. network.PROTO_VLAN_SEPARATOR() .. vid,
		type   = vlanProtocol or "8021ad",
		ifname = linuxBaseIfname,
		vid    = vid
	}

	utils.log("lime.network.createVlan(%s, ...)", linuxBaseIfname)
	utils.dumptable(vlanConf)

	local libubus = require("ubus")
	local ubus = libubus.connect()
	ubus:call('network', 'add_dynamic_device', vlanConf)

--! TODO: as of today ubus silently fails to properly creating a device
--! dinamycally work around it by using ip command instead
	utils.unsafe_shell("ip link add name "..vlanConf.name.." link "..vlanConf.ifname.." type vlan proto 802.1ad id "..vlanConf.vid)

	return vlanConf.name
end

--! Run protocols at runtime on top of linux network devices
--! TODO: probably some code between here and configure might be deduplicaded
function network.runProtocols(linuxBaseIfname)
	utils.log("lime.network.runProtocols(%s, ...)", linuxBaseIfname)
	local protoConfs = config.get("network", "protocols")
	for _,protoConf in pairs(protoConfs) do
		local args = utils.split(protoConf, network.PROTO_PARAM_SEPARATOR())
		local protoModule = "lime.proto."..args[1]
		if utils.isModuleAvailable(protoModule) then
			local proto = require(protoModule)
			xpcall(function() proto.runOnDevice(linuxBaseIfname, args) end,
				   function(errmsg) print(errmsg) ; print(debug.traceback()) end)
		end
	end
end

return network
