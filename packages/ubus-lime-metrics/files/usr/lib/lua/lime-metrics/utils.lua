local utils = {}

function utils.shell(command)
    -- TODO(nicoechaniz): sanitize or evaluate if this is a security risk
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end


function utils.nslookup_working()
    local shell_output = utils.shell("nslookup google.com | grep Name -A2 | grep Address")
    return shell_output
end

function utils.get_loss(host, ip_version)
    local ping_cmd = "ping"
    if ip_version then
        if ip_version == 6 then
            ping_cmd = "ping6"
        end
    end
    local shell_output = utils.shell(ping_cmd.." -q  -i 0.1 -c4 -w2 "..host)
    local loss = "100"
    if shell_output ~= "" then
        loss = shell_output:match("(%d*)%% packet loss")
    end
    return loss
end

return utils
