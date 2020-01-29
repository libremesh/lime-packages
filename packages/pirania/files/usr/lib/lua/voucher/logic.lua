#!/bin/lua

local dba = require('voucher.db')
local config = require('voucher.config')
local utils = require('voucher.utils')
local ft = require('voucher.functools')

local uci = require('uci')
local uci_cursor = uci.cursor()

logic = {}

local function isMac(string)
    local string = string:match("%w%w:%w%w:%w%w:%w%w:%w%w:%w%w")
    if string then
       return true
    else
       return false
    end
end

local function split_macs(inputstr, sep)
    if sep == nil then
        sep = "+"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    if (#t < 1 and #inputstr > 1) then
        t[1] = inputstr
    end
    return t
end

local function use_voucher(db, voucher, mac)
    local macs = voucher[7]

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
            expiretime = tostring( tonumber( voucher.expiretime ) - utils.dateNow())
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

function logic.show_vouchers(db)
    local result = {}
    local vName = 1
    local vSecret = 2
    local vExpire = 3
    local vMacsAllowed = 6
    local usedMacs = 7
    for _, v in pairs(db.data) do
        result[_] = utils.parse_voucher_key(v[vName], v[vExpire])
        result[_].name = v[vName]
        result[_].expires = v[vExpire]
        result[_].voucher = v[vSecret]
        result[_].macsAllowed = v[vMacsAllowed]
        result[_].macs = split_macs(v[usedMacs])
    end
    return result
end

function logic.show_active_vouchers(db)
    local result = {}
    local vName = 1
    local vExpire = 3
    local usedMacs = 7
    members = 0
    visitors = 0
    for _, v in pairs(db.data) do
        local macs = split_macs(v[usedMacs])
        local active = function ()
            if (#macs > 0) then
                return true
            end
            return false
        end
        local info = utils.parse_voucher_key(v[vName], v[vExpire])
        if (info.type == 'member') then
            local nextN = members + 1
            members = nextN
        elseif (info.type == 'visitor') then
            local nextN = visitors + 1
            visitors = nextN
        end
    end
    result.members = members
    result.visitors = visitors
    return result
end

function logic.check_valid_voucher(db, row)
    local expireDate = tonumber(dba.describe_values(db, row).expiretime) or 0
    if (expireDate ~= nil) then
        return expireDate > utils.dateNow()
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

function logic._setIpset(mac, expiretime)
    local IPSET_MAX_TIMEOUT = 4294967 -- ipset only supports timeout up to 4294967
    if tonumber(expiretime) > IPSET_MAX_TIMEOUT then expiretime = IPSET_MAX_TIMEOUT end
    os.execute("ipset -exist add pirania-auth-macs " .. mac .. " timeout ".. expiretime)
end

function logic.auth_voucher(db, mac, voucherid)
    local response = {
        success=false,
        limit={'0', '0', '0', '0'}
    }
    local res = logic.check_voucher_validity(voucherid, db)
    if (res.valid) then
        use_voucher(db, res.voucher, mac)
        logic._setIpset(mac, res.voucher[3])
        response.limit={ res.voucher[3], res.voucher[4], res.voucher[5], res.voucher[6] }
        response.success=true
    end
    return response
end


function logic.check_mac_validity(db, mac)
    local macs = logic.valid_macs(db)
    local mac_in_valid_vouchers = 0
    for _, valid_mac in ipairs(macs) do
        if mac == valid_mac then
            mac_in_valid_vouchers = mac_in_valid_vouchers + 1
        end
    end
    return mac_in_valid_vouchers
end

function logic.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)
    local exists = false
    for _, v in pairs (db.data) do
        if (v[2] == voucher) then
            exists = true
        end
    end
    if not exists then
        local rawvoucher = dba.add_voucher(db, key, voucher, epoc, upload, download, amountofmacsallowed)
        return get_limit_from_rawvoucher(db, rawvoucher)
    end
    return '0', '0', '0', '0'
end

function logic.valid_macs(db)
    local rawvouchers, rawvoucher, macs, currentmacs
    local macs = {}
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

function logic.iptables_status()
    local result = {
        onStart = false,
        enabled = false
    }
    local status = uci_cursor:get("pirania", "base_config", "enabled")
	if (status == '1') then
		result.onStart = true
    end
    local output = utils.shell("iptables --list | grep tcp-reset")
    local contentLen = string.len(output)
    if (contentLen > 1) then
        result.enabled = true
    end
    return result
end



function logic.voucher_status(db, mac)
    local rawvouchers, rawvoucher
    rawvouchers = dba.get_vouchers_by_mac(db, mac)

    for _, rawvoucher in ipairs( rawvouchers ) do
        if logic.check_valid_voucher(db, rawvoucher) then
            return get_limit_from_rawvoucher(db, rawvoucher)
        end
    end

    return '0', '0', '0', '0'
end

function logic.update_many_vouchers_date(vouchers, date, db)
    local result = {
        success = false
    }
    local changed = 0
    for _, voucher in pairs (db.data) do
        for __, voucherToChange in pairs (vouchers) do
            if (voucher[2] == voucherToChange) then
                db.data[_] = voucher
                db.data[_][3] = date
                changed = changed+1
            else
                db.data[_] = voucher
            end
        end
        result.updated = changed
        result.success = true
    end
    return result
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
        db.data = validVouchers
        table.insert(db.data, toRenew)
        else result.success = false
    end
    return result
end



return logic
