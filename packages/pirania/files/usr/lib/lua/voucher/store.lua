#!/bin/lua

local fs = require("nixio.fs")
local json = require("luci.jsonc")
local hooks = require('voucher.hooks')
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
            local voucher, err
            if json_obj then
                voucher, err = voucher_init(json_obj)
            else
                err = "invalid json"
            end

            if voucher ~= nil then
                if vouchers[voucher.id] ~= nil then
                    utils.log('warning', "vouchers: multiple vouchers with the same id " .. voucher.id)
                end
                vouchers[voucher.id] = voucher
            else
                utils.log('warning', "vouchers: Error loading voucher file " .. fname .. ", " .. err)
            end
        end
    end
    return vouchers
end

function store.add_voucher(db_path, voucher, voucher_init)
    local fname = db_path .. "/" .. voucher.id .. ".json"
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
    hooks.run("db_change")
    return true
end

function store.remove_voucher(db_path, voucher)
    local fname = db_path .. "/" .. voucher.id .. ".json"
    local removed_db = io.open(db_path .. "/removed.txt", "a")
    if removed_db then
        removed_db:write(voucher.id .. ",")
        removed_db:close()
    end
    local removed = os.execute("rm " .. fname) == 0
    if removed then
        hooks.run("db_change")
    end
    return removed
end

return store
