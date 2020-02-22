#!/bin/lua

local utils = require('voucher.utils')
local ft = require('voucher.functools')
local hooks = require('voucher.hooks')
local functools = require('voucher.functools')

local dba = {}

local function read_db_from_csv(dbinfo)
    local rawtable = utils.from_csv_to_table(dbinfo);
    if rawtable == nil then
		local fho = io.open(dbinfo, "w")
        fho:write('key,voucher,expiretime,uploadlimit,downloadlimit,amountofmacsallowed,usedmacs,')
        fho:close()
        rawtable = utils.from_csv_to_table(dbinfo);
    end

    local table = {
        headers = rawtable[1],
        data = ft.filter(function(row, index) return index > 1 end, rawtable),
    }

    local parsed_data = {}
    for element_index, _ in pairs(table.data) do
        local element = {}
        for attribute_index, attribute_name in pairs(rawtable[1]) do
            element[attribute_name] = table.data[element_index][attribute_index]
        end
        parsed_data[element_index] = element
    end
    table.parsed_data = parsed_data

    return table
end

local function write_db_to_csv(csvname, db)
    local data = {}
    data[1] = db.headers
    local idx = 2

    for _, v in pairs(db.data) do
        data[idx] = v
        idx = idx + 1
    end

    utils.from_table_to_csv(csvname, data)
    hooks("db_change")
end

function dba.get_vouchers_by_voucher(db, voucherid)
    local voucher_column = functools.search(function(val) return val == 'voucher' end, db.headers)
    return ft.filter(function(voucher) return voucher[voucher_column] == voucherid end, db.data)
end

function dba.get_vouchers_by_mac(db, mac)
    local mac_column = functools.search(function(val) return val == 'usedmacs' end, db.headers)
    return ft.filter(function(maclist)
        if(maclist[mac_column]) then
            local search_result = string.find(maclist[mac_column], mac)
            return  search_result ~= nil
        end
        return false
    end, db.data)
end

function dba.get_all_vouchers(db)
    return db.data
end

function dba.describe_values(db, row)
    local described_row = {}
    for i, v in pairs(db.headers) do
        described_row[v] = row[i]
    end

    return described_row
end

function dba.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)
    local data = {key, voucher, epoc, upload, download, amountofmacsallowed, ''}
    table.insert(db.data, data)
    return data
end

dba.load = read_db_from_csv
dba.save = write_db_to_csv

return dba
