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

describe('Pirania tests #voucher', function()
    it ('create voucher', function ()
        local db = dba.read_db_from_csv(tempFolder)
        assert.is.equal('true', logic.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed))
        dba.save(tempFolder, db)
    end)
    it('renew voucher', function()
        assert.is.equal('true', logic.update_voucher_date(voucher, 0, db))
    end)

    -- before_each('', function()
    --     uci = test_utils.setup_test_uci()
    -- end)

    -- after_each('', function()
    --     test_utils.teardown_test_uci(uci)
    -- end)

end)
