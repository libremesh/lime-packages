#!/usr/bin/lua

local hardware_detection = require("lime.hardware_detection")
local config = require("lime.config")
local utils = require("lime.utils")

local watchcat = {}

watchcat.sectionNamePrefix = hardware_detection.sectionNamePrefix.."watchcat_"

local function reload_watchcat()
        os.execute("/etc/init.d/watchcat reload")
end

function watchcat.clean()
        local uci = config.get_uci_cursor()
        local modified = false

        local function clear_watchcat_section(section)
                local is_ours = utils.stringStarts(section[".name"], watchcat.sectionNamePrefix)
                
                local is_anon = section[".anonymous"]

                if is_ours or is_anon then
                        uci:delete("watchcat", section[".name"])
                        modified = true
                end
        end

        uci:foreach("watchcat", "watchcat", clear_watchcat_section)
        if modified then
                uci:save("watchcat")
                reload_watchcat()
        end
end

function watchcat.detect_hardware()
        local uci = config.get_uci_cursor()
        local user_defined = false 
        
        config.foreach("hwd_watchcat", function(user_section)
                user_defined = true
                local identifier = user_section.id or "default"
                local section_name = watchcat.sectionNamePrefix .. identifier

                uci:set("watchcat", section_name, "watchcat")

                for option_key, option_value in pairs(user_section) do
                        -- discards .name, .type keys and id name sections
                        if option_key:sub(1,1) ~= "." and option_key ~= "id" then
                                uci:set("watchcat", section_name, option_key, option_value)
                        end
                end 
        end)
        -- only saved if we actually aplied any user section
        if user_defined then
                uci:save("watchcat")
                reload_watchcat()
        end
end

return watchcat
