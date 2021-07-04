#!/usr/bin/lua

local config = require('voucher.config')
local fs = require("nixio.fs")

local hooks = {}


function hooks.run(action)
    local hookPath = config.hooksDir..action..'/'
    local files = fs.dir(hookPath)
    if files then
        for file in files do
            os.execute("(( sh "..hookPath..file.." 0<&- &>/dev/null &) &)")
        end
    end
end

if debug.getinfo(2).name == nil then
    local arguments = { ... }
    if (arguments ~= nil and arguments[1] ~= nil) then
        hooks.run(arguments[1])
    end
end

return hooks
