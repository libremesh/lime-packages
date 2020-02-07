local ubus = {}

function ubus.connect()
    local conn = {}

    function conn.call()
        return {}
    end

    return conn
end

return ubus

