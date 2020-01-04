#!/usr/bin/lua

local config = require('voucher.config')
local fs = require("nixio.fs")

local hooks = function(action)
    local hookPath = config.hooksDir..action..'/'
    local files = fs.dir(hookPath) or pairs({})
    for file in files do
        os.execute("(( sh "..hookPath..file.." 0<&- &>/dev/null &) &)")
    end

end

if debug.getinfo(2).name == nil then
    arguments = { ... }
    if (arguments ~= nil and arguments[1] ~= nil) then
        hooks(arguments[1])
    end
end

return hooks
