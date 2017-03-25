-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2008-2013 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local fs = require "nixio.fs"
local notesfile = "/etc/banner.notes"

f = SimpleForm("notes", translate("System Notes"), translate("Notes that will be shown on console login and will be at hand here."))

t = f:field(TextValue, "notes")
t.rmempty = true
t.rows = 10
function t.cfgvalue()
    return fs.readfile(notesfile) or ""
end

function f.handle(self, state, data)
    if state == FORM_VALID then
        if data.notes then
            fs.writefile(notesfile, data.notes:gsub("\r\n", "\n"))
        else
            fs.writefile(notesfile, "")
        end
    end
    return true
end

return f
