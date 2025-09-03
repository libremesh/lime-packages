#!/usr/bin/env lua
--! SPDX-License-Identifier: AGPL-3.0-only
--!
--! Copyright (C) 2020 LibreMesh.org
--! Copyright 2020 Santiago Piccinini <spiccinini@altermindi.net>

local utils = require 'lime.utils'
local config = require 'lime.config'
local upgrade = require 'lime.upgrade'
local hotspot_wwan = require "lime.hotspot_wwan"


local UPGRADE_METADATA_FILE = "/etc/upgrade_metadata"

local limeutilsadmin = {}

function limeutilsadmin.set_root_password(msg)
    local result = nil
    if type(msg.password) ~= "string" then
        result = {status = 'error', msg = 'Password must be a string'}
    else
        utils.set_shared_root_password(msg.password or '')
        result = {status = 'ok'}
    end
    return result
end

function limeutilsadmin.set_hostname(msg)
    if msg.hostname ~= nil and utils.is_valid_hostname(msg.hostname) then
        local uci = config.get_uci_cursor()
        uci:set(config.UCI_NODE_NAME, 'system', 'hostname', msg.hostname)
        uci:commit(config.UCI_NODE_NAME)
        utils.unsafe_shell("lime-config")
        return { status = 'ok'}
    else
        local err
        if msg.hostname then
            err = 'Invalid hostname'
        else
            err = 'Hostname not provided'
        end
        return { status = 'error', msg = err }
    end
end

function limeutilsadmin.is_upgrade_confirm_supported()
    local supported = upgrade.is_upgrade_confirm_supported()
    return {status = 'ok', supported = supported}
end


function limeutilsadmin.firmware_upgrade(msg)
    local status, ret = upgrade.firmware_upgrade(msg.fw_path, msg.preserve_config, msg.metadata, msg.fw_type)
    if status then
        return {status = 'ok', metadata = ret}
    else
        return {status = 'error', message = ret}
    end
end

function limeutilsadmin.last_upgrade_metadata()
    local metadata
    if utils.file_exists(UPGRADE_METADATA_FILE) then
        metadata = utils.read_obj_store(UPGRADE_METADATA_FILE)
        return {status = 'ok', metadata = metadata}
    else
        return {status = 'error', message = 'No metadata available'}
    end
end

function limeutilsadmin.firmware_confirm()
    local exit_code = os.execute("safe-upgrade confirm > /dev/null 2>&1")
    local status = 'error'
    if exit_code == 0 then
        status = 'ok'
    end
    return {status = status, exit_code = exit_code}
end

--! Creates a client connection to a wifi hotspot
function limeutilsadmin.hotspot_wwan_enable(msg)
    local msg = msg or {}
    local status, errmsg = hotspot_wwan.safe_enable(msg.ssid, msg.password, msg.encryption, msg.radio)
    if status then
        return {status = 'ok'}
    else
        return {status = 'error', message = errmsg}
    end
end


function limeutilsadmin.hotspot_wwan_disable(msg)
    local msg = msg or {}
    local status, errmsg = hotspot_wwan.disable(msg.radio)
    if status then
        return {status = 'ok'}
    else
        return {status = 'error', message = errmsg}
    end
end


function limeutilsadmin.safe_reboot(msg)
    local result = {}
    local function getStatus()
        local f = io.open('/overlay/upper/.etc.last-good.tgz', "rb")
        if f then f:close() end
        return f ~= nil
    end

    --! Get safe-reboot status
    if msg.action == nil then return {error = true} end
    if msg.action == 'status' then result.status = getStatus() end

    --! Start safe-reboot
    if msg.action == 'start' then
        local args = ''
        if msg.value ~= nil then
            if msg.value.wait ~= nil then
                args = args .. ' -w ' .. msg.value.wait
            end
            if msg.value.fallback ~= nil then
                args = args .. ' -f ' .. msg.value.fallback
            end
        end
        local sr = assert(io.popen('safe-reboot ' .. args))
        sr:close()
        result.status = getStatus()
        if result.status == true then result.started = true end
    end

    --! Rreboot now and wait for fallback timeout
    if msg.action == 'now' then
        local sr = assert(io.popen('safe-reboot now'))
        result.status = getStatus()
        result.now = result.status
    end

    --! Keep changes and stop safe-reboot
    if msg.action == 'cancel' then
        result.status = true
        result.canceled = false
        local sr = assert(io.popen('safe-reboot cancel'))
        sr:close()
        if getStatus() == false then
            result.status = false
            result.canceled = true
        end
    end

    --! Discard changes - Restore previous state and reboot
    if msg.action == 'discard' then
        local sr = assert(io.popen('safe-reboot discard'))
        sr:close()
        result.status = getStatus()
        if result.status == true then result.started = true end
    end

    return result
end

return limeutilsadmin

