#!/usr/bin/lua

local libuci = require("uci")
local hardware_detection = require("lime.hardware_detection")
local config = require("lime.config")
local utils = require("lime.utils")

local ground_routing = {}

ground_routing.sectionNamePrefix = hardware_detection.sectionNamePrefix.."ground_routing_"

function ground_routing.clean()
	local uci = libuci:cursor()

	function cleanGrSection(section)
		if utils.stringStarts(section[".name"], ground_routing.sectionNamePrefix) then
			uci:delete("network", section[".name"])
		end
	end

	uci:foreach("network", "switch_vlan", cleanGrSection)
	uci:foreach("network", "interface", cleanGrSection)
	uci:save("network")
end

function ground_routing.detect_hardware()
	function parse_gr(section)
		local link_name = section[".name"]
		local net_dev = section["net_dev"]
		local vlan = section["vlan"]

		local uci = libuci:cursor()

		function create_8021q_dev(vlan_p)
			local dev_secname = ground_routing.sectionNamePrefix..link_name.."_"..net_dev.."_"..vlan_p
			uci:set("network", dev_secname, "device")
			uci:set("network", dev_secname, "name", net_dev.."."..vlan_p)
			uci:set("network", dev_secname, "ifname", net_dev)
			uci:set("network", dev_secname, "type", "8021q")
			uci:set("network", dev_secname, "vid", vlan_p)
		end

		local switch_dev = section["switch_dev"]
		if switch_dev then
			local switch_cpu_port = section["switch_cpu_port"]
			function tag_cpu_port(section)
				if (section["device"] ~= switch_dev) then return end

				local patterns = { "^"..switch_cpu_port.." ", " "..switch_cpu_port.."$", " "..switch_cpu_port.." "  }
				local substits = { switch_cpu_port.."t ",     " "..switch_cpu_port.."t", " "..switch_cpu_port.."t " }
				local matchCount = 0
				local m = 0
				for i,p in pairs(patterns) do
					section["ports"], m = section["ports"]:gsub(p, substits[i])
					matchCount = matchCount + m
				end

				if (matchCount > 0) then
					create_8021q_dev(section["vlan"])
					uci:set("network", section[".name"], "ports", section["ports"])
				end
			end

			uci:foreach("network", "switch_vlan", tag_cpu_port)


			local sw_secname = ground_routing.sectionNamePrefix..link_name.."_sw_"..switch_dev.."_"..vlan
			local ports = switch_cpu_port.."t"
			for _,p in pairs(section["switch_ports"]) do
				ports = ports.." "..p
			end

			uci:set("network", sw_secname, "switch_vlan")
			uci:set("network", sw_secname, "device", switch_dev)
			uci:set("network", sw_secname, "vlan", vlan)
			uci:set("network", sw_secname, "ports", ports)
		end

		create_8021q_dev(vlan)

		uci:save("network")
	end

	config.foreach("hwd_gr", parse_gr)
end

return ground_routing
