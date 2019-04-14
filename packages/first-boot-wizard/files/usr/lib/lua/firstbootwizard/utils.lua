local utils = {}

local ft = require('firstbootwizard.functools')
local fs = require("nixio.fs")
local iwinfo = require("iwinfo")
local json = require("luci.json")

function execute(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    return s
end

function utils.execute (cmd)
    return execute(cmd)
end

function utils.eui64(mac)
    local cmd = [[
    function eui64 {
        mac="$(echo "$1" | tr -d : | tr A-Z a-z)"
        mac="$(echo "$mac" | head -c 6)fffe$(echo "$mac" | tail -c +7)"
        let "b = 0x$(echo "$mac" | head -c 2)"
        let "b ^= 2"
        printf "%02x" "$b"
        echo "$mac" | tail -c +3 | head -c 2
        echo -n :
        echo "$mac" | tail -c +5 | head -c 4
        echo -n :
        echo "$mac" | tail -c +9 | head -c 4
        echo -n :
        echo "$mac" | tail -c +13
    }
    echo -n `eui64 ]]..mac..'`'
    return 'fe80::'..execute(cmd)
end

function utils.file_exists(filename)
    return fs.stat(filename, "type") == "reg"
end

function split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function utils.split(str, sep)
    return split(str, sep)
end

-- splits a multiline string in a list of strings, one per line
function lsplit(mlstring)
    return split(mlstring, "\n")
end

function utils.lsplit(mlstring)
    return lsplit(mlstring)
end

function utils.phy_to_idx(phy)
    local substr = string.gsub(phy, "phy", "")
    return tonumber(substr)
end

function utils.radio_to_phy(radio)
    return "phy"..radio.sub(radio, -1)
end

function utils.not_own_network(net) 
    return net.signal ~= -256
end

function utils.add_prop(option, value)
    return function(tab)
        tab[option] = value
        return tab
    end
end

function utils.extract_prop(prop)
    return function(tab)
        return tab[prop]
    end
end

function utils.read_file(file)
    local lines = utils.lines_from("/tmp/"..file)
    return lines
end


function tableEmpty(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function utils.tableEmpty(self)
    return tableEmpty(self)
end

function utils.hash_file(file)
    return execute("md5sum "..file.." | awk '{print $1}'")
end

function utils.are_files_different(file1, file2)
    return hash_file(file1) ~= hash_file(file2)
end

function utils.unpack_table(t)
    local unpacked = {}
    for k,v in ipairs(t) do
        for sk, sv in ipairs(v) do
            unpacked[#unpacked+1] = sv
        end
    end
    return unpacked
end

function utils.sortNetworks(networks)
    networks = ft.splitBy('mode')(networks)
    networks = ft.map(ft.sortBy('channel'), networks)
    networks = ft.reduce(ft.flatTable,networks, {})
    return networks
end

function utils.filter_mesh(n)
    return n.mode == "Ad-Hoc" or n.mode == "Mesh Point"
end

function utils.is_connected(dev_id)
    local isAssociated = {}
    local i = 0
    while (tableEmpty(isAssociated)) and i < 5 do
        isAssociated = iwinfo.nl80211.assoclist(dev_id)
        if tableEmpty(isAssociated) == false then break end
        i = i + 1
        os.execute("sleep 5s")
    end
end

function utils.get_stations_macs(network)
    return lsplit(execute('iw dev '..network..' station dump | grep ^Station | cut -d\\  -f 2'))
end

function utils.append_network(dev)
    return function (ipv6)
        return ipv6..'%'..dev
    end
end

return utils