#!/usr/bin/lua

network = {}

local ip = require("luci.ip")
local fs = require("nixio.fs")

local config = require("lime.config")
local utils = require("lime.utils")

network.limeIfNamePrefix="lm_net_"
network.protoParamsSeparator=":"
network.protoVlanSeparator="_"

network.MTU_ETH = 1500
network.MTU_ETH_WITH_VLAN = network.MTU_ETH - 4

function network.get_mac(ifname)
	local path = "/sys/class/net/"..ifname.."/address"
	local macaddr = assert(fs.readfile(path), "network.get_mac(...) failed reading: "..path):gsub("\n","")
	return utils.split(macaddr, ":")
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
		ifname = board['network']['lan']['ifname']
	end
	network.assert_interface_exists(ifname)
	return ifname
end

function network.primary_mac()
	return network.get_mac(network.primary_interface())
end

function network.generate_host(ipprefix, hexsuffix)
	local num = 0
	-- If it's a network prefix calculate offset to add
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
			uci:set("dhcp", s[".name"], "server", resolvers)
		end
	)
	uci:save("dhcp")

	--! some dynamic scripts prefer to use confdir=/tmp/dnsmasq.d (which is the openwrt default)
	--! so we add all the /etc/dnsmasq.d/*.conf files as individual conf-file options instead
	--! of using uci set confdir=/etc/dnsmasq.d
	local dnsmasq_conf_file = ""
	for conf_file in fs.glob("/etc/dnsmasq.d/*.conf") do
		dnsmasq_conf_file = dnsmasq_conf_file .. "conf-file=" .. conf_file .. "\n"
	end

	fs.writefile("/etc/dnsmasq.conf", dnsmasq_conf_file)
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
		os.execute("/etc/init.d/odhcpd enable")
	else
		utils.log("Disabling odhcpd")
		uci:set("dhcp", "odchpd", "maindhcp", 0)
		os.execute("/etc/init.d/odhcpd disable")
	end

	utils.log("Cleaning dnsmasq")
	uci:foreach("dhcp", "dnsmasq", function(s) uci:delete("dhcp", s[".name"], "server") end)
	uci:save("dhcp")

	utils.log("Disabling 6relayd...")
	fs.writefile("/etc/config/6relayd", "")
end

function network.scandevices()
	local devices = {}
	local switch_vlan = {}
	local wireless = require("lime.wireless")

	function dev_parser(dev)
		if dev == nil then return end

		if dev:match("^eth%d+$") then
			devices[dev] = devices[dev] or {}
		end

		if dev:match("^eth%d+%.%d+$") then
			local rawif = dev:match("^eth%d+")
			devices[rawif] = { nobridge = true }
			devices[dev] = {}
		end

		if dev:match("^wlan%d+"..wireless.wifiModeSeparator.."%w+$") then
			devices[dev] = {}
		end
	end

	function owrt_ifname_parser(section)
		local ifn = section["ifname"]
		if ( type(ifn) == "string" ) then dev_parser(ifn) end
		if ( type(ifn) == "table" ) then for _,v in pairs(ifn) do dev_parser(v) end end
	end

	function owrt_device_parser(section)
		dev_parser(section["name"])
		dev_parser(section["ifname"])
	end

	function owrt_switch_vlan_parser(section)
		local kernel_visible = section["ports"]:match("0t")
		if kernel_visible then switch_vlan[section["vlan"]] = section["device"] end
	end

	--! Scrape from uci wireless
	local uci = config.get_uci_cursor()
	uci:foreach("wireless", "wifi-iface", owrt_ifname_parser)

	--! Scrape from uci network
	uci:foreach("network", "interface", owrt_ifname_parser)
	uci:foreach("network", "device", owrt_device_parser)
	uci:foreach("network", "switch_vlan", owrt_switch_vlan_parser)

	--! Scrape plain ethernet devices from /sys/class/net/
	local stdOut = io.popen("ls -1 /sys/class/net/ | grep -x 'eth[0-9][0-9]*'")
	for dev in stdOut:lines() do dev_parser(dev) end
	stdOut:close()

	--! Scrape switch_vlan devices from /sys/class/net/
	local stdOut = io.popen("ls -1 /sys/class/net/ | grep -x 'eth[0-9][0-9]*\.[0-9][0-9]*'")
	for dev in stdOut:lines() do if switch_vlan[dev:match("%d+$")] then dev_parser(dev) end end
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

	local fisDevs = network.scandevices()

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
			if args[1] == "manual" then break end -- If manual is specified do not configure interface
			local protoModule = "lime.proto."..args[1]
			for k,v in pairs(flags) do args[k] = v end
			if utils.isModuleAvailable(protoModule) then
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

-- Creates a network Interface with static protocol
-- ipAddr can be IPv4 or IPv6
-- the function can be called twice to set both IPv4 and IPv6
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
		uci:set("network", owrtInterfaceName, "ifname", linux802adIfName)
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
	owrtDeviceName = owrtDeviceName:gsub("[^%w_]", "_") -- sanitize uci section name
	owrtInterfaceName = owrtInterfaceName:gsub("[^%w_]", "_") -- sanitize uci section name

	local uci = config.get_uci_cursor()

	uci:set("network", owrtDeviceName, "device")
	uci:set("network", owrtDeviceName, "type", "macvlan")
	uci:set("network", owrtDeviceName, "name", linuxName)
	uci:set("network", owrtDeviceName, "ifname", baseIfname)
	for k,v in pairs(argsDev) do
		uci:set("network", owrtDeviceName, k, v)
	end

	uci:set("network", owrtInterfaceName, "interface")
	uci:set("network", owrtInterfaceName, "proto", "none")
	uci:set("network", owrtInterfaceName, "ifname", linuxName)
	uci:set("network", owrtInterfaceName, "auto", "1")
	for k,v in pairs(argsIf) do
		uci:set("network", owrtInterfaceName, k, v)
	end

	uci:save("network")

	return owrtInterfaceName, linuxName, owrtDeviceName
end

return network
