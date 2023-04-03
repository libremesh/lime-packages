local lutils = require("lime.utils")

local utils = {}

function utils.is_nslookup_working()
    local shell_output = lutils.unsafe_shell("nslookup google.com | grep Name -A2 | grep Address")
    return shell_output
end

function utils.get_loss(host)
    local shell_output = lutils.unsafe_shell("ping -q  -i 0.1 -c4 -w2 "..host)
    local loss = "100"
    if shell_output ~= "" and shell_output ~= nil then
        loss = shell_output:match("(%d*)%% packet loss")
    end
    return loss
end

return utils
