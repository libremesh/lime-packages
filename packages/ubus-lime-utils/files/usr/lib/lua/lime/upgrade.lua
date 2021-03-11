#!/usr/bin/env lua
--[[
  Copyright (C) 2020 LibreMesh.org
  This is free software, licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3

  Copyright 2020 Santiago Piccinini <spiccinini@altermindi.net>
]]--

local json = require 'luci.jsonc'
local utils = require 'lime.utils'

local pkg = {}

pkg.UPGRADE_INFO_CACHE_FILE = '/tmp/upgrade_info_cache'

pkg.UPGRADE_STATUS_DEFAULT = 'NOT_STARTED'
pkg.UPGRADE_STATUS_UPGRADING = 'UPGRADING'
pkg.UPGRADE_STATUS_FAILED = 'FAILED'
pkg.LIME_SYSUPGRADE_BACKUP_EXTRA_DIR = "/tmp/lime-sysupgrade/preserve"
pkg.UPGRADE_METADATA_FILE = "/etc/upgrade_metadata"

function pkg.safe_upgrade_confirm_remaining_s()
    local remaining_s = tonumber(utils.unsafe_shell("safe-upgrade confirm-remaining"))
    if not remaining_s then
        remaining_s = -1
    end
    return remaining_s
end

function pkg.is_upgrade_confirm_supported()
    local exit_value = os.execute("safe-upgrade board-supported > /dev/null 2>&1")
    return exit_value == 0
end

function pkg.get_upgrade_status()
    local info = utils.read_obj_store(pkg.UPGRADE_INFO_CACHE_FILE)
    if info.status == nil then
        return pkg.UPGRADE_STATUS_DEFAULT
    else
        return info.status
    end
end

function pkg.set_upgrade_status(status)
    return utils.write_obj_store_var(pkg.UPGRADE_INFO_CACHE_FILE, 'status', status)
end

function pkg.get_upgrade_info()
    local result = utils.read_obj_store(pkg.UPGRADE_INFO_CACHE_FILE)
    if result.is_upgrade_confirm_supported == nil then
        result.is_upgrade_confirm_supported = pkg.is_upgrade_confirm_supported()
    end
    if not result.is_upgrade_confirm_supported then
        result.safe_upgrade_confirm_remaining_s = -1
    else
        result.safe_upgrade_confirm_remaining_s = pkg.safe_upgrade_confirm_remaining_s()
    end
    utils.write_obj_store(pkg.UPGRADE_INFO_CACHE_FILE, result)
    return result
end

function pkg.firmware_verify(fw_path)
    local command
    if pkg.is_upgrade_confirm_supported() then
        command = "safe-upgrade verify "
    else
        command = "sysupgrade --test "
    end
    command = command ..  fw_path .. " > /dev/null 2>&1"
    local exit_value = os.execute(command)
    return exit_value == 0
end


function pkg.firmware_upgrade(fw_path, preserve_config, metadata, fw_type)
    if not fw_path then
        return nil, "Firmware file needed"
    end
    if not utils.file_exists(fw_path) then
        return nil, "Firmware file not found"
    end
    if pkg.get_upgrade_status() == pkg.UPGRADE_STATUS_UPGRADING then
        return nil, "There is an upgrade in progress"
    end

    metadata = metadata or {}

    if not fw_type then
        if utils.stringEnds(fw_path, ".bin") then
            fw_type = 'sysupgrade'
        elseif utils.stringEnds(fw_path, ".sh") then
            fw_type = 'installer'
        else
            return nil, "Unsupported firmware type"
        end
    end

    if fw_type == 'sysupgrade' then
        if not pkg.firmware_verify(fw_path) then
            return nil, "Invalid firmware"
        end
    end

    local backup = ""
    if preserve_config == nil then
        preserve_config = true
    end
    if not preserve_config then
        backup = "DO_NOT_BACKUP=1"
    end

    metadata['config_preserved'] = preserve_config or false

    -- store info of the current firmware
    local current_fw_description = utils.release_info()["DISTRIB_DESCRIPTION"]
    if current_fw_description then
        metadata['old_release_description'] = current_fw_description
    end

    metadata['local_timestamp'] = os.time()

    --! Use the BACKUP_EXTRA_DIR function of lime-sysupgrade to store the medatada file
    utils.unsafe_shell("mkdir -p " .. pkg.LIME_SYSUPGRADE_BACKUP_EXTRA_DIR .. "/etc")
    local meta_file_path = pkg.LIME_SYSUPGRADE_BACKUP_EXTRA_DIR .. pkg.UPGRADE_METADATA_FILE
    if not utils.write_file(meta_file_path, json.stringify(metadata)) then
        return nil, "Can't write " .. meta_file_path
    end

    pkg.set_upgrade_status(pkg.UPGRADE_STATUS_UPGRADING)
    if fw_type == 'sysupgrade' then
        --! Give some time so the response can be returned to the client
        local cmd = "sleep 3; FORCE=1 " .. backup .. " lime-sysupgrade " ..  fw_path
        --! stdin must be /dev/null because of a tar bug when using gzip that tries to read from stin and fails
        --! if it is closed
        utils.execute_daemonized(cmd, "/tmp/lime-sysupgrade.log", "/dev/null")
    elseif fw_type == 'installer' then
        utils.unsafe_shell("chmod +x " .. fw_path)
        utils.execute_daemonized(fw_path, "/tmp/upgrade-installer.log", "/dev/null")
        --! give the installer some time and try to collect the status up to that moment
        utils.unsafe_shell("sleep 10s")
        local progress_status = utils.read_file("/tmp/upgrade-installer-status") or 'unknown'
        if progress_status == 'failed' then
            pkg.set_upgrade_status(pkg.UPGRADE_STATUS_FAILED)
            return nil, utils.read_file("/tmp/upgrade-installer-error-mesage") or 'Installer failed without error message'
        end
    end
    return true, metadata
end

return pkg
