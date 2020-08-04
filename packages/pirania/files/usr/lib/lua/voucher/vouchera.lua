#!/bin/lua

local store = require('voucher.store')
local config = require('voucher.config')


local function deepcompare(t1, t2)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- exclude functions
    if ty1 == 'function' and ty1 == ty2 then
        return true
    end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepcompare(v1, v2) then return false end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepcompare(v1, v2) then
            return false
        end
    end
    return true
end

--! Simplify the comparison of vouchers using a metatable for the == operator
local voucher_metatable = {
    __eq = function(self, value)
        return deepcompare(self, value)
    end
}

--! obj attrs name, code, mac, expiration_date, duration_m, mod_counter
function voucher_init(obj)
    local voucher = {}
    voucher.name = obj.name

    if type(obj.code) ~= "string" then
        return nil, "code must be a string"
    end
    voucher.code = obj.code

    if type(obj.mac) == "string" and #obj.mac ~= 17 then
        return nil, "invalid mac"
    end
    voucher.mac = obj.mac

    if obj.expiration_date == nil and obj.duration_m == nil then
        return nil
    elseif obj.expiration_date ~= nil then
        voucher.expiration_date = obj.expiration_date
    elseif obj.duration_m ~= nil then
        voucher.duration_m = obj.duration_m
    end

    voucher.mod_counter = obj.mod_counter or 1

    voucher.tostring = function()
        local v = voucher
        return(string.format('%s\t%s\t%s\t%s\t%s', v.name, v.code, v.mac or 'xx:xx:xx:xx:xx:xx',
                             os.date("%c", v.expiration_date) or '', v.mod_counter))
    end

    setmetatable(voucher, voucher_metatable)
    return voucher
end

local vouchera = {}

function vouchera.init(cfg)
    if cfg ~= nil then
        config = cfg
    end
    vouchera.config = config
    vouchera.vouchers = store.load_db(config.db_path, voucher_init)
end

function vouchera.add(obj)
    local voucher = voucher_init(obj)
    if vouchera.vouchers[obj.name] ~= nil then
        return nil, "voucher with same name already exists"
    end
    if voucher and store.add_voucher(config.db_path, voucher, voucher_init) then
        vouchera.vouchers[obj.name] = voucher
        return voucher
    end
    return nil, "can't create voucher"
end

--! Activate a voucher returning true or false depending on the status of the operation.
function vouchera.activate(code, mac)
    local voucher = vouchera.is_activable(code)
    if voucher then
        voucher.mac = mac
        --! If the voucher has a duration then create the expiration_date from it
        if voucher.duration_m then
           voucher.expiration_date = os.time() + duration_m * 60
        end
        voucher.mod_counter = voucher.mod_counter + 1
        store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

function vouchera.deactivate(name)
    local voucher = vouchera.vouchers[name]
    if voucher then
        voucher.mac = mac
        voucher.expiration_date = 0
        voucher.mod_counter = voucher.mod_counter + 1
        return store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

--! Return true if there is an activated voucher that grants a access to the specified MAC
function vouchera.is_mac_authorized(mac)
    if mac ~= nil then
        for k, v in pairs(vouchera.vouchers) do
            if v.mac == mac and vouchera.is_active(v) then
                return true
            end
        end
    end
    return false
end

--! Check if a code would be good to be activated but without activating it right away.
function vouchera.is_activable(code)
    for k, v in pairs(vouchera.vouchers) do
        if v.code == code and v.mac == nil then
            if v.expiration_date ~= nil and v.expiration_date > os.time() then
                return v
            end
            return v
        end
    end
    return false
end

function vouchera.is_active(voucher)
    return voucher.mac ~= nil and voucher.expiration_date > os.time()
end

vouchera.voucher = voucher_init

return vouchera
