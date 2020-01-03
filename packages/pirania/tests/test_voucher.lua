-- local config = require 'lime.config'
local dba = require('voucher.db')
local logic = require('voucher.logic')
local utils = require('voucher.utils')
local test_utils = require 'tests.utils'

-- local fs = require("nixio.fs")

local uci = nil
local dbFile = '/tmp/pirania'
math.randomseed(os.time())

local key = 'm-belaelu-marcos-android'
local voucher = tostring(math.random())
local epoc = 1579647256049
local upload = 10
local download = 10
local amountofmacsallowed = 1
local renewDate = 0

function formatData (db)
    data = {}
    data[1] = db.headers
    local idx = 2

    for _, v in pairs(db.data) do
        data[idx] = v
        idx = idx + 1
    end
    return data
end

print(voucher)

describe('Pirania tests #voucher', function()
    it ('create voucher', function ()
        local db = dba.load(dbFile)
        local output = { logic.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)}
        assert.is.equal(upload, output[2])
        assert.is.equal(download, output[3])
        assert.is.equal(amountofmacsallowed, tonumber(output[4]))
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it('renew voucher', function()
        local db = dba.load(dbFile)
        local index = #db.data
        local output = logic.update_voucher_date(voucher, renewDate, db)
        assert.is.equal(true, output.success)
        assert.is.equal(renewDate, db.data[index][3])
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
end)
