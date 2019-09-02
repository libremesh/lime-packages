#!/usr/bin/lua

local fs = require("nixio.fs")
local utils = require("lime.utils")


local hardware_detection = {}

hardware_detection.sectionNamePrefix = "lm_hwd_"
hardware_detection.search_paths = {"/usr/lib/lua/lime/hwd/*.lua"}

--! Hardware detection module clean()
--! Call clean() from all installed submodules
function hardware_detection.clean()
    for _,search_path in ipairs(hardware_detection.search_paths) do
        for hwd_module_path in fs.glob(search_path) do
            local module_name = "lime.hwd." .. fs.basename(hwd_module_path):sub(1,-5)
            if utils.isModuleAvailable(module_name) then
                require(module_name).clean()
            end
        end
    end
end

--! Hardware detection module configure()
--! Call detect_hardware() from all installed submodules
function hardware_detection.configure()
    for _,search_path in ipairs(hardware_detection.search_paths) do
        for hwd_module_path in fs.glob(search_path) do
            local module_name = "lime.hwd." .. fs.basename(hwd_module_path):sub(1,-5)
            if utils.isModuleAvailable(module_name) then
                require(module_name).detect_hardware()
            end
        end
	end
end


return hardware_detection
