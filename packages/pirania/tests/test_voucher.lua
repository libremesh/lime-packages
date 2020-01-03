-- local config = require 'lime.config'
local dba = require('voucher.db')
local logic = require('voucher.logic')
local utils = require('voucher.utils')
local test_utils = require 'tests.utils'

-- local fs = require("nixio.fs")

local uci = nil
local tempFolder = '/tmp/pirania'

local key = 'm-belaelu-marcos-android'
local voucher = '2u8hyfve'
local epoc = 1579647256049
local upload = 10
local download = 10
local amountofmacsallowed = 1
local renewDate = 0

describe('Pirania tests #voucher', function()
    it ('create voucher', function ()
        local db = dba.load(tempFolder)
        local output = { logic.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)}
        assert.is.equal(upload, tonumber(output[2]))
        assert.is.equal(download, tonumber(output[3]))
        assert.is.equal(amountofmacsallowed, tonumber(output[4]))
    end)
    it('renew voucher', function()
        local db = dba.load(tempFolder)
        local output = logic.update_voucher_date(voucher, renewDate, db)
        assert.is.equal(true, output.success)
        assert.is.equal(renewDate, db.data[1][3])
    end)

    -- before_each('', function()
    --     uci = test_utils.setup_test_uci()
    -- end)

    -- after_each('', function()
    --     test_utils.teardown_test_uci(uci)
    -- end)

end)
