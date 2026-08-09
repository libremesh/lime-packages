#!/usr/bin/env lua
--! SPDX-License-Identifier: AGPL-3.0-only
--!
--! Copyright (C) 2021 LibreMesh.org
--! Copyright 2021 Santiago Piccinini <spiccinini@altermindi.net>

local utils = require 'lime.utils'
local config = require 'lime.config'
local iwinfo = require "iwinfo"
local wireless = require "lime.wireless"

local pkg = {}

--! checkout ap_match_encryption for supported encryptions
pkg.DEFAULT_ENCRYPTION = 'psk2'
pkg.DEFAULT_SSID = 'internet'
pkg.DEFAULT_PASSWORD = 'internet'
pkg.DEFAULT_RADIO = 'radio0'
pkg.GENERIC_SECTION_NAME = 'hotspot_wwan'
pkg.IFACE_SECTION_NAME = 'lm_client_wwan'
pkg.IFACE_NAME = 'client-wwan'

function pkg._apply_change()
    utils.execute_daemonized("lime-config && wifi reload")
end

--! Create a client connection to a wifi hotspot
function pkg.enable(ssidArg, passwordArg, encryptionArg, radioArg)
    local uci = config.get_uci_cursor()
    local encryption = encryptionArg or pkg.DEFAULT_ENCRYPTION
    local ssid = ssidArg or pkg.DEFAULT_SSID
    local password = passwordArg or pkg.DEFAULT_PASSWORD
    local radio = radioArg or pkg.DEFAULT_RADIO

    uci:set(config.UCI_NODE_NAME, pkg.GENERIC_SECTION_NAME, "generic_uci_config")
    uci:set(config.UCI_NODE_NAME, pkg.GENERIC_SECTION_NAME, "uci_set", {
        "wireless." .. radio .. ".disabled=0",
        "wireless." .. radio .. ".channel=auto",
        "wireless." .. pkg.IFACE_SECTION_NAME .. "=wifi-iface",
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".device=" .. radio,
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".network=" .. pkg.IFACE_SECTION_NAME,
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".mode=sta",
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".ifname=" .. pkg.IFACE_NAME,
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".ssid=" .. ssid,
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".encryption=" .. encryption,
        "wireless." .. pkg.IFACE_SECTION_NAME .. ".key=" .. password,
        "network." .. pkg.IFACE_SECTION_NAME .. "=interface",
        "network." .. pkg.IFACE_SECTION_NAME .. ".proto=dhcp",
        }
    )
    uci:commit(config.UCI_NODE_NAME)
    pkg._apply_change()
    return true
end

local function ap_match_encryption(ap, encryption)
    if encryption == 'psk2' then
        return ap.encryption.enabled and ap.encryption.wpa == 2
    end
    return false
end

function pkg._is_safe(ssid, encryption, radio)
    local ifaces = wireless.get_radio_ifaces(radio)
    if utils.tableLength(ifaces) == 0 then
        return true
    end
    for _, iface in pairs(ifaces) do
        if wireless.is_mesh(iface) then
            return false, 'radio has mesh ifaces'
        end
    end
    local ifname = ifaces[1].ifname
    local iface_type = iwinfo.type(ifname)
    if iface_type ~= nil then
        local scanlist = iwinfo[iface_type].scanlist(ifname)
        for _, ap in pairs(scanlist) do
            if (ap.ssid == ssid and ap_match_encryption(ap, encryption)) then
                return true
            end
        end
    end
    return false, 'hotspot ap not found'
end

function pkg.safe_enable(ssidArg, password, encryptionArg, radioArg)
    --! Enables the hotpost client only if the hotpost is already available
    --! in order to avoid clients from ap interfaces to be kicked out.
    local encryption = encryptionArg or pkg.DEFAULT_ENCRYPTION
    local ssid = ssidArg or pkg.DEFAULT_SSID
    local radio = radioArg or pkg.DEFAULT_RADIO

    local is_safe, reason = pkg._is_safe(ssid, encryption, radio)
    if is_safe then
        return pkg.enable(ssid, password, encryption, radio)
    else
        return false, reason
    end
end

function pkg.disable()
    local uci = config.get_uci_cursor()

    uci:delete(config.UCI_NODE_NAME, pkg.GENERIC_SECTION_NAME)
    uci:commit(config.UCI_NODE_NAME)
    uci:delete('system', 'hotspot_watchping')
    uci:commit('system')
    pkg._apply_change()
    return true
end

function pkg.status()
    local uci = config.get_uci_cursor()
    local connected = false
    local signal

    local enabled = false

    if uci:get(config.UCI_NODE_NAME, pkg.GENERIC_SECTION_NAME) then
        enabled = true
    end

    for _, station in pairs(iwinfo.nl80211.assoclist(pkg.IFACE_NAME)) do
        connected = true
        signal = station['signal']
    end

    return {connected = connected, signal = signal, enabled = enabled}
end


return pkg
