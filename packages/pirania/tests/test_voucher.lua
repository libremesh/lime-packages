-- local config = require 'lime.config'
local dba = require('voucher.db')
local logic = require('voucher.logic')
local utils = require('voucher.utils')
local test_utils = require 'tests.utils'

local fs = require("nixio.fs")

local uci = nil
local dbFile = '/tmp/pirania'
local hostname = fs.readfile("/proc/sys/kernel/hostname"):gsub("\n","")
math.randomseed(os.time())

local note = 'Marcos Android'
local voucher = tostring(math.random())
local epoc = utils.dateNow() + 600
local upload = 10
local download = 10
local amountofmacsallowed = 1
local mac = '08:8C:2C:40:51:C4'
local renewDate = 0
local renewManyDate = 15796472566666

local memberKey = ''
local visitorKey = ''

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

describe('Pirania tests #voucher', function()
    it ('format member voucher key', function ()
        memberKey = utils.format_voucher_key(note, 'member')
        assert.is.equal(hostname..'-m-marcos-android', memberKey)
    end)
    it ('format visitor voucher key', function ()
        visitorKey = utils.format_voucher_key(note, 'visitor')
        assert.is.equal(hostname..'-v-marcos-android', visitorKey)
    end)
    it ('create voucher', function ()
        local db = dba.load(dbFile)
        local output = { logic.add_voucher(db, memberKey, voucher, epoc, upload, download, amountofmacsallowed)}
        assert.is.equal(upload, output[2])
        assert.is.equal(download, output[3])
        assert.is.equal(amountofmacsallowed, tonumber(output[4]))
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it ('create same voucher', function ()
        local db = dba.load(dbFile)
        local output = { logic.add_voucher(db, memberKey, voucher, epoc, upload, download, amountofmacsallowed)}
        assert.is.equal('0', output[2])
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it ('authenticate voucher', function ()
        local db = dba.load(dbFile)
        local res = logic.auth_voucher(db, mac, voucher)
        assert.is.equal(true, res.success)
        assert.is.equal(tostring(amountofmacsallowed), res.limit[4])
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it ('authenticate same voucher', function ()
        local db = dba.load(dbFile)
        local res = logic.auth_voucher(db, mac, voucher)
        assert.is.equal(false, res.success)
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it ('show active vouchers', function ()
        local db = dba.load(dbFile)
        local output = logic.show_active_vouchers(db)
        assert.is_not_nil(output.visitors)
        assert.is.equal(#db.data, output.members)
    end)
    it('renew voucher', function()
        local db = dba.load(dbFile)
        local index = #db.data
        local output = logic.update_voucher_date(voucher, renewDate, db)
        assert.is.equal(true, output.success)
        assert.is.equal(renewDate, db.data[index][3])
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it('renew many vouchers', function()
        local db = dba.load(dbFile)
        local vouchersToUpdate = {}
        for _, voucher in pairs (db.data) do
            vouchersToUpdate[_] = voucher[2]
        end
        local db = dba.load(dbFile)
        local output = logic.update_many_vouchers_date(vouchersToUpdate, renewManyDate, db)
        assert.is.equal(true, output.success)
        assert.is.equal(#vouchersToUpdate, output.updated)
        utils.from_table_to_csv(dbFile, formatData(db))
    end)
    it('list all vouchers', function()
        local db = dba.load(dbFile)
        local output = logic.show_vouchers(db)
        assert.is.equal(voucher, output[#output].voucher)
        assert.is.equal('member', output[#output].type)
        assert.is.equal(hostname, output[#output].node)
    end)
end)
