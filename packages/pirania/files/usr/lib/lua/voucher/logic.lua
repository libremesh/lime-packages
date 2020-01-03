#!/bin/lua

local dba = require('voucher.db')
local config = require('voucher.config')
local utils = require('voucher.utils')
local ft = require('voucher.functools')

logic = {}

local function shell(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

local function isMac(string)
    local string = string:match("%w%w:%w%w:%w%w:%w%w:%w%w:%w%w")
    if string then
       return true
    else
       return false
    end
end


local function dateNow()
    local output = shell('date +%s000')
    local parsed = string.gsub(output, "%s+", "")
    local dateNow = tonumber(parsed)
    return dateNow
end



local function use_voucher(db, voucher, mac)
    macs = voucher[7]

    if (string.find(macs, mac) == nil) then
        if (macs == '') then
            voucher[7] = mac
        else
            voucher[7] = macs .. '+' .. mac
        end
    end
end

local function get_valid_rawvoucher(db, rawvouchers)
    local voucher, expiretime, uploadlimit, downloadlimit

    for _, rawvoucher in ipairs( rawvouchers ) do
        if (logic.check_valid_voucher(db, rawvoucher)) then
            return rawvoucher
        end
    end

    return
end

local function get_limit_from_rawvoucher(db, rawvoucher)
    local voucher, expiretime, uploadlimit, downloadlimit

    if (rawvoucher ~= nil) then
        voucher = dba.describe_values (db, rawvoucher)

        if tonumber(voucher.expiretime) ~= nil then
            expiretime = tostring( tonumber( voucher.expiretime ) - dateNow())
            uploadlimit = voucher.uploadlimit ~= '0' and voucher.uploadlimit or config.uploadlimit
            downloadlimit = voucher.downloadlimit ~= '0' and voucher.downloadlimit or config.downloadlimit
            currentmacs = table.getn(utils.string_split(voucher.usedmacs, '+'))
            valid = currentmacs < tonumber(voucher.amountofmacsallowed) and '1' or '0'
            return expiretime, uploadlimit, downloadlimit, valid
        end
    end

    return '0', '0', '0', '0'
end

local function checkIfIpv4(ip)
    if ip == nil or type(ip) ~= "string" then
        return 0
    end
    -- check for format 1.11.111.111 for ipv4
    local chunks = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if (#chunks == 4) then
        for _,v in pairs(chunks) do
            if (tonumber(v) < 0 or tonumber(v) > 255) then
                return 0
            end
        end
        return true
    else
        return false
    end
end

function logic.getIpv4AndMac()
    local address = os.getenv('REMOTE_ADDR')
    local isIpv4 = checkIfIpv4(address)
    if (isIpv4) then
        local ipv4macCommand = "cat /proc/net/arp | grep "..address.." | awk -F ' ' '{print $4}' | head -n 1"
        fd = io.popen(ipv4macCommand, 'r')
        ipv4mac = fd:read('*l')
        fd:close()
        local res = {}
        res.ip = address
        res.mac = ipv4mac
        return res
    else
        local ipv6macCommand = "ip neighbor | grep "..address.." | awk -F ' ' '{print $5}' | head -n 1"
        fd6 = io.popen(ipv6macCommand, 'r')
        ipv6mac = fd6:read('*l')
        fd6:close()
        local ipv4Command = "cat /proc/net/arp | grep "..ipv6mac.." | awk -F ' ' '{print $1}' | head -n 1"
        fd4 = io.popen(ipv4Command, 'r')
        ipv4 = fd4:read('*l')
        fd4:close()
        local res = {}
        res.ip = ipv4
        res.mac = ipv6mac
        return res
    end
end

function logic.check_valid_voucher(db, row)
    local expireDate = tonumber(dba.describe_values(db, row).expiretime) or 0
    if (expireDate ~= nil) then
        return expireDate > dateNow()
    end
end

function logic.check_voucher_validity(voucherid, db)
    local res = {}
    res.valid = false
    local rawvouchers = dba.get_vouchers_by_voucher(db, voucherid)
    if (rawvouchers ~= nil) then
        local voucher = get_valid_rawvoucher(db, rawvouchers)
        local expiretime, uploadlimit, downloadlimit, valid = get_limit_from_rawvoucher(db, voucher)
        if(voucher ~= nil and valid == '1' and tonumber(expiretime) > 0) then
            res.valid = true
            res.voucher = voucher
        end
    end
    return res
end

local function setIpset(mac, expiretime)
    -- ipset only supports timeout up to 4294967
    if tonumber(expiretime) > 4294967 then expiretime = 4294967 end
    os.execute("ipset -exist add pirania-auth-macs " .. mac .. " timeout ".. expiretime)
end

function logic.check_mac_validity(mac)
    local command = 'voucher print_valid_macs | grep -o '..mac..' | wc -l | grep "[^[:blank:]]"'
    fd = io.popen(command, 'r')
    local output = fd:read('*all')
    fd:close()
    return tonumber(output)
end

function logic.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)
    local rawvoucher = dba.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)
    return get_limit_from_rawvoucher(db, rawvoucher)
end

function logic.valid_macs(db)
    local rawvouchers, rawvoucher, macs, currentmacs
    macs = {}
    rawvouchers = dba.get_all_vouchers(db)

    for _, rawvoucher in ipairs( rawvouchers ) do
        if logic.check_valid_voucher(db, rawvoucher) then
            local voucher = dba.describe_values(db, rawvoucher)
            currentmacs = utils.string_split(voucher.usedmacs, '+')
            for _, mac in ipairs( currentmacs ) do
                local intAmount = tonumber(voucher.amountofmacsallowed)
                local amountofmacs = 0
                if (intAmount ~= nil) then
                    amountofmacs = intAmount
                end
                if (_ <= amountofmacs and isMac(mac)) then
                    table.insert(macs, mac)
                end
            end
        end
    end

    return macs
end

function logic.status(db, mac)
    local rawvouchers, rawvoucher
    rawvouchers = dba.get_vouchers_by_mac(db, mac)

    for _, rawvoucher in ipairs( rawvouchers ) do
        if logic.check_valid_voucher(db, rawvoucher) then
            return get_limit_from_rawvoucher(db, rawvoucher)
        end
    end

    return '0', '0', '0', '0'
end

function logic.update_voucher_date(secret, date, db)
    local result = {}
    local toRenew = {}
    for _, voucher in pairs (db.data) do
        if (voucher[2] == secret) then
            toRenew = voucher
        end
    end
    if (#toRenew > 0) then
        result.success = true
        toRenew[3] = tonumber(date)
        local validVouchers = ft.filter(function(row, index) return row[2] ~= secret end, db.data)
        local newDb = db
        newDb.data = validVouchers
        table.insert(newDb.data, toRenew)
        else result.success = false
    end
    return result
end



return logic
