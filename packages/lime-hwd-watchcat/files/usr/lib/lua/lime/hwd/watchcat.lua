local hardware_detection = require("lime.hardware_detection")
local config = require("lime.config")
local utils = require("lime.utils")

local watchcat = {}

watchcat.sectionNamePrefix = hardware_detection.sectionNamePrefix.."watchcat_"

local function clear_watchcat_section(section)
        if utils.stringStarts(section[".name"], watchcat.sectionNamePrefix) then
            uci:delete("watchcat", section[".name"])
        end
end

function watchcat.clean()
        local uci = config.get_uci_cursor()   
        
        uci:foreach("watchcat", "watchcat", clear_watchcat_section)
        uci:save("watchcat")
end

function watchcat.detect_hardware()
        local uci = config.get_uci_cursor()
        local sec = watchcat.sectionNamePrefix.."ping_reboot"
        
        uci:set("watchcat", sec, "watchcat")
        uci:set("watchcat", sec, "mode", "ping_reboot")
        uci:set("watchcat", sec, "pinghosts", "8.8.8.8")
        uci:set("watchcat", sec, "period", "6h")
        uci:set("watchcat", sec, "pingperiod", "30s")
        uci:set("watchcat", sec, "forcedelay", "1m")
        
        uci:save("watchcat")
end

return watchcat
