#!/bin/lua

local store = require('voucher.store')
local config = require('voucher.config')
local utils = require('voucher.utils')

local vouchera = {}

local ID_SIZE = 6

--! Simplify the comparison of vouchers using a metatable for the == operator
local voucher_metatable = {
    __eq = function(self, value)
        return self.tostring() == value.tostring()
    end
}

--! obj attrs id, name, code, mac, expiration_date, duration_m, mod_counter
function voucher_init(obj)
    local voucher = {}

    if not obj.id then
        obj.id = utils.random_string(ID_SIZE)
    end

    voucher.id = obj.id
    if type(obj.id) ~= "string" then
        return nil, "id must be a string"
    end

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

    --! tostring must reflect all the state of a voucher (so vouchers can be compared reliably using tostring)
    voucher.tostring = function()
        local v = voucher
        return(string.format('%s\t%s\t%s\t%s\t%s\t%s\t%s', v.id, v.name, v.code, v.mac or 'xx:xx:xx:xx:xx:xx',
                             os.date("%c", v.expiration_date) or '', tostring(v.duration_m), v.mod_counter))
    end

    setmetatable(voucher, voucher_metatable)
    return voucher
end


function vouchera.init(cfg)
    if cfg ~= nil then
        config = cfg
    end
    vouchera.config = config
    vouchera.PRUNE_OLDER_THAN_S = tonumber(config.prune_expired_for_days) * 60 * 60 * 24
    vouchera.vouchers = store.load_db(config.db_path, voucher_init)

    --! Automatic voucher pruning
    for _, voucher in pairs(vouchera.vouchers) do
        if vouchera.should_be_pruned(voucher) then
            vouchera.remove_locally(voucher.id)
        end
    end
end

function vouchera.add(obj)
    local voucher = voucher_init(obj)
    if vouchera.vouchers[obj.id] ~= nil then
        return nil, "voucher with same id already exists"
    end
    if voucher and store.add_voucher(config.db_path, voucher, voucher_init) then
        vouchera.vouchers[obj.id] = voucher
        return voucher
    end
    return nil, "can't create voucher"
end

--! Remove a voucher from the local db. This won't trigger a remove in the shared db.
function vouchera.remove_locally(id)
    if vouchera.vouchers[id] ~= nil then
        if store.remove_voucher(config.db_path, vouchera.vouchers[id]) then
            vouchera.vouchers[id] = nil
            return true
        else
            return nil, "can't remove voucher"
        end
    end
    return nil, "can't find voucher to remove"
end

--! Remove a voucher from the shared db.
--! Deactivates the voucher, sets the expiration_date to the current time and increment the mod_counter.
--! This will eventualy prune the voucher in all the dbs after PRUNE_OLDER_THAN_S seconds.
--! It is important to maintain the "removed" (deactivated) voucher in the shared db for some time
--! so that all nodes (even nodes that are offline when this is executed) have time to update locally
--! and eventualy prune the voucher.
function vouchera.remove_globally(id)
    local voucher = vouchera.vouchers[id]
    if voucher then
        voucher.expiration_date = os.time()
        voucher.mac = nil
        voucher.mod_counter = voucher.mod_counter + 1
        return store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

--! Activate a voucher returning true or false depending on the status of the operation.
function vouchera.activate(code, mac)
    local voucher = vouchera.is_activable(code)
    if voucher then
        voucher.mac = mac
        --! If the voucher has a duration then create the expiration_date from it
        if voucher.duration_m then
           voucher.expiration_date = os.time() + voucher.duration_m * 60
        end
        voucher.mod_counter = voucher.mod_counter + 1
        store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

function vouchera.deactivate(id)
    local voucher = vouchera.vouchers[id]
    if voucher then
        voucher.mac = nil
        voucher.mod_counter = voucher.mod_counter + 1
        return store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

--! updates the database with the new voucher information
function vouchera.update_with(voucher)
    vouchera.vouchers[voucher.id] = voucher
    return store.add_voucher(config.db_path, voucher, voucher_init)
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

function vouchera.should_be_pruned(voucher)
    return type(voucher.expiration_date) == "number" and (
           voucher.expiration_date <= (os.time() - vouchera.PRUNE_OLDER_THAN_S))
end

function vouchera.update_expiration_date(id, new_date)
    local voucher = vouchera.vouchers[id]
    if voucher then
        voucher.expiration_date = new_date
        voucher.mod_counter = voucher.mod_counter + 1
        return store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

vouchera.voucher = voucher_init

return vouchera
