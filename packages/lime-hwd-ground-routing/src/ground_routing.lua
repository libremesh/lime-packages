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
		local vlan = section["vlan"]
		local physdev = section["physdev"]
		local secname = ground_routing.sectionNamePrefix..section[".name"].."_"..physdev.."_"..vlan

		local switch_ports = section["switch_ports"]
		if switch_ports then
			local ports = ""
			for _,p in pairs(switch_ports) do ports = ports..p.."t " end

			local uci = libuci:cursor()
			uci:set("network", secname, "switch_vlan")
			uci:set("network", secname, "device", physdev)
			uci:set("network", secname, "vlan", vlan)
			uci:set("network", secname, "ports", ports)
			uci:save("network")
		else
			local uci = libuci:cursor()
			uci:set("network", secname, "device")
			uci:set("network", secname, "name", physdev.."."..vlan)
			uci:set("network", secname, "ifname", physdev)
			uci:set("network", secname, "type", "8021q")
			uci:set("network", secname, "vid", vlan)
			uci:save("network")
		end
	end

	config.foreach("hwd_gr", parse_gr)
end

return ground_routing
