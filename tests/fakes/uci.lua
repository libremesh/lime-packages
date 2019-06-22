
local libuci = {}

function libuci.cursor()
    local uci = {}
    local store = {}
    uci._store = store

    local function _get(local_store, ...)
        local args = {...}
        if #args > 1 then
            local name = table.remove(args, 1)
            if local_store[name] == nil then
                return nil
            else
                return _get(local_store[name], unpack(args))
            end
        else
            return local_store[args[1]]
        end
    end

    function uci.get(...)
        local args = {...}
        return _get(uci._store, ...)
    end

    local function _set(local_store, ...)
        local args = {...}
        if #args > 2 then
            local name = table.remove(args, 1)
            if local_store[name] == nil then
                local_store[name] = {}
            end
            -- overwrite value when adding a section inside an existing non table element
            if type(local_store[name]) ~= 'table' then

                local_store[name] = {}
            end
            _set(local_store[name], unpack(args))
        else
            local_store[args[1]] = args[2]
        end
    end


    function uci.set(...)
        -- the value is the last argument, that is retrieved when removing from the table
        _set(uci._store, ...)
    end

    function uci.save()
    end

    local function _delete(local_store, ...)
        local args = {...}
        if #args > 1 then
            local name = table.remove(args, 1)
            return _delete(local_store[name], unpack(args))
        else
            local_store[args[1]] = nil
        end
    end

    function uci.delete(...)
        _delete(uci._store, ...)
    end


    function uci.foreach(...)
        local args = {...}
        local func = table.remove(args)
        local elements = uci.get(unpack(args))
        for key, value in pairs(elements) do
            local s = {}
            s['.name'] = key
            func(s)
        end
    end
    return uci
end



return libuci
