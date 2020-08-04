#!/bin/lua

local fs = require("nixio.fs")
local json = require("luci.jsonc")
local utils = require("voucher.utils")

local store = {}

function store.load_db(db_path, voucher_init)
    local vouchers = {}

    local f = io.open(db_path, "r")
    if f ~= nil then
        io.close(f)
    else
        os.execute("mkdir -p " .. db_path)
    end

    for fname in fs.glob(db_path .. '/*.json') do
        local f = io.open(fname, "r")
        if f ~= nil then
            local json_obj = json.parse(f:read("*all"))
            f:close()
            local voucher, err = voucher_init(json_obj)

            if voucher ~= nil then
                if vouchers[voucher.name] ~= nil then
                    utils.log('warning', "vouchers: multiple vouchers with the same name " .. voucher.name)
                end
                vouchers[voucher.name] = voucher
            else
                utils.log('warning', "vouchers: Error loading voucher file " .. fname .. ", " .. err)
            end
        end
    end
    return vouchers
end

function store.add_voucher(db_path, voucher, voucher_init)
    local fname = db_path .. "/" .. voucher.name .. ".json"
    --! check if it already exists and if it is equal do not rewrite it
    local f = io.open(fname, "r")
    if f ~= nil then
        local json_obj = json.parse(f:read("*all"))
        f:close()
        local local_voucher = voucher_init(json_obj)
        if local_voucher == voucher then 
            return false
        end
    end
    f = io.open(fname, "w")
    f:write(json.stringify(voucher))
    f:close()
    return true
end

function store.save_db(db_path, vouchers, voucher_init)
    local changed = false
    for name, voucher in pairs(vouchers) do
        local result = store.add_voucher(db_path, voucher, voucher_init)
        if result then
            changed = true
        end
    end

    if changed then
        --! TODO: hooks("db_change")
        utils.log("info", "voucher.store: db_change")
    end
end


return store
