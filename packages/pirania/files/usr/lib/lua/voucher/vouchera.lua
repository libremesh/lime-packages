#!/bin/lua

local store = require('voucher.store')
local config = require('voucher.config')
local utils = require('lime.utils')

local vouchera = {}

vouchera.ID_SIZE = 6
vouchera.CODE_SIZE = 6

--! Simplify the comparison of vouchers using a metatable for the == operator
local voucher_metatable = {
    __eq = function(self, value)
        return self.tostring() == value.tostring()
    end
}

--! obj attrs id, name, code, mac, duration_m, mod_counter, creation_date, activation_date
function voucher_init(obj)
    local voucher = {}

    if not obj.id then
        obj.id = utils.random_string(vouchera.ID_SIZE)
    end

    voucher.id = obj.id
    if type(obj.id) ~= "string" then
        return nil, "id must be a string"
    end

    if type(obj.name) ~= "string" then
        return nil, "name must be a string"
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


    if not (type(obj.duration_m) == "nil" or type(obj.duration_m) == "number") then
        return nil, "invalid duration_m type"
    end
    voucher.duration_m = obj.duration_m -- use nil to create a permanent voucher

    if not obj.creation_date then
        return nil, "creation_date can't be nil"
    end

    voucher.author_node = obj.author_node

    voucher.creation_date = obj.creation_date

    voucher.activation_date = obj.activation_date

    if not (type(obj.activation_deadline) == "nil" or type(obj.activation_deadline) == "number") then
        return nil, "invalid activation_deadline type", type(obj.activation_deadline)
    end
    voucher.activation_deadline = obj.activation_deadline

    voucher.invalidation_date = obj.invalidation_date

    voucher.mod_counter = obj.mod_counter or 1

    --! tostring must reflect all the state of a voucher (so vouchers can be compared reliably using tostring)
    voucher.tostring = function()
        local v = voucher
        local creation = os.date("%c", v.creation_date)
        local expiration = '           -            '
        if v.expiration_date() then
            expiration = os.date("%c", v.expiration_date())
        end
        return(string.format('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s', v.id, v.name, v.code, v.mac or 'xx:xx:xx:xx:xx:xx',
                             creation, v.duration_m or 'perm', expiration, v.mod_counter))
    end

    voucher.expiration_date = function()
        local ret = nil
        if voucher.duration_m and voucher.mac and voucher.activation_date then
            ret = voucher.activation_date + voucher.duration_m * 60
        end
        return ret
    end

    voucher.is_active = function()
        if voucher.is_invalidated() or voucher.mac == nil then
            return false
        else
            if voucher.expiration_date() and voucher.expiration_date() <= os.time() then
                return false
            end
        end
        return true
    end

    voucher.is_invalidated = function()
        return voucher.invalidation_date ~= nil
    end

    voucher.is_expired = function()
        local curr_time = os.time()
        return (voucher.expiration_date() ~= nil and voucher.expiration_date() < curr_time) or
               (voucher.activation_deadline ~= nil and voucher.activation_deadline < curr_time)
    end

    voucher.is_activable = function()
        return voucher.mac == nil and not voucher.is_invalidated() and not voucher.is_expired()
    end

    voucher.status = function()
        local status = 'available'
        if voucher.is_invalidated() then
            status = 'invalidated'
        elseif voucher.is_expired() then
            status = 'expired'
        elseif voucher.is_active() then
            status = 'active'
        end
        return status
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
    if not obj.creation_date then
        obj.creation_date = os.time()
    end
    obj.author_node = utils.hostname()
    local voucher, errmsg = voucher_init(obj)
    if vouchera.vouchers[obj.id] ~= nil then
        return nil, "voucher with same id already exists"
    end
    if voucher and store.add_voucher(config.db_path, voucher, voucher_init) then
        vouchera.vouchers[obj.id] = voucher
        return voucher
    end
    return nil, "can't create voucher: " .. tostring(errmsg)
end

function vouchera.get_by_id(id)
    return vouchera.vouchers[id]
end

function vouchera.create(basename, qty, duration_m, activation_deadline)
    local vouchers = {}
    for n=1, qty do
        local name
        if qty == 1 then
            name = basename
        else
            name = basename .. "-" .. tostring(n)
        end
        local v = {name=name, code=vouchera.gen_code(), duration_m=duration_m,
                   activation_deadline=activation_deadline}
        local voucher, msg = vouchera.add(v)
        if voucher == nil then
            return nil, msg
        end
        table.insert(vouchers, n, {id=voucher.id, code=voucher.code})
    end
    return vouchers
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
--! This will eventualy prune the voucher in all the dbs after PRUNE_OLDER_THAN_S seconds.
--! It is important to maintain the "removed" (invalidated) voucher in the shared db for some time
--! so that all nodes (even nodes that are offline when this is executed) have time to update locally
--! and eventualy prune the voucher.
function vouchera.remove_globally(id)
    return vouchera.invalidate(id)
end

local function modify_voucher_with_func(id, func)
    local voucher = vouchera.vouchers[id]
    if voucher then
        func(voucher)
        voucher.mod_counter = voucher.mod_counter + 1
        return store.add_voucher(config.db_path, voucher, voucher_init)
    end
    return voucher
end

function vouchera.invalidate(id)
    local function _update(v)
        v.invalidation_date = os.time()
    end
    return modify_voucher_with_func(id, _update)
end

--! Activate a voucher returning true or false depending on the status of the operation.
function vouchera.activate(code, mac)
    local voucher = vouchera.is_activable(code)
    if voucher then
        function _update(v)
            v.mac = mac
            v.activation_date = os.time()
        end
        modify_voucher_with_func(voucher.id, _update)
    end
    return voucher
end

function vouchera.deactivate(id)
    local function _update(v)
        v.mac = nil
    end
    return modify_voucher_with_func(id, _update)
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
            if v.mac == mac and v.is_active() then
                return true
            end
        end
    end
    return false
end

--! Check if a code would be good to be activated but without activating it right away.
function vouchera.is_activable(code)
    for _, v in pairs(vouchera.vouchers) do
        if v.code == code then
            if v.is_activable() then
                return v
            else
                return false
            end
        end
    end
    return false
end

function vouchera.should_be_pruned(voucher)
    local current_time = os.time()
    return (voucher.expiration_date() ~= nil and (
           voucher.expiration_date() <= (current_time - vouchera.PRUNE_OLDER_THAN_S))) or
           ((voucher.invalidation_date or false) and (voucher.invalidation_date <= (current_time - vouchera.PRUNE_OLDER_THAN_S)))
end

function vouchera.rename(id, new_name)
    local function _update(v)
        v.name = new_name
    end
    return modify_voucher_with_func(id, _update)
end

function vouchera.gen_code()
    return utils.random_string(vouchera.CODE_SIZE, function (c) return c:match('%u') ~= nil end)
end

function vouchera.list()
    local vouchers = {}
    for k, v in pairs(vouchera.vouchers) do
        table.insert(vouchers, {
            id=v.id,
            name=v.name,
            code=v.code,
            mac=v.mac,
            duration_m=v.duration_m,
            creation_date=v.creation_date,
            activation_date=v.activation_date,
            expiration_date=v.expiration_date(),
            is_active=v.is_active(),
            permanent=not v.duration_m,
            activation_deadline=v.activation_deadline,
            author_node=v.author_node,
            status=v.status(),
            })
    end
    return vouchers
end

vouchera.voucher = voucher_init

return vouchera
