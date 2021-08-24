#!/usr/bin/env lua
--[[
  Copyright (C) 2021 LibreMesh.org
  This is free software, licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3

  Copyright 2021 Santiago Piccinini <spiccinini@altermindi.net>
]]--

local utils = require 'lime.utils'
local config = require 'lime.config'
local iwinfo = require "iwinfo"

local pkg = {}

pkg.DEFAULT_ENCRYPTION = 'psk2'
pkg.DEFAULT_SSID = 'internet'
pkg.DEFAULT_PASSWORD = 'internet'
pkg.DEFAULT_RADIO = 'radio0'
pkg.NETWORK_NAME = 'client_wwan'
pkg.IFNAME = 'client-wwan'

function pkg.iface_section_name(radio_name)
    return radio_name .. '_client_wwan'
end

function pkg._apply_change()
    utils.unsafe_shell("wifi reload")
end

--! Create a client connection to a wifi hotspot
function pkg.enable(ssid, password, encryption, radio)
    local uci = config.get_uci_cursor()
    local encryption = encryption or pkg.DEFAULT_ENCRYPTION
    local ssid = ssid or pkg.DEFAULT_SSID
    local password = password or pkg.DEFAULT_PASSWORD
    local radio = radio or pkg.DEFAULT_RADIO
    local iface_section_name = pkg.iface_section_name(radio)

    uci:set('wireless', radio, 'disabled', '0')
    uci:set('wireless', iface_section_name, 'wifi-iface')
    uci:set('wireless', iface_section_name, 'device', radio)
    uci:set('wireless', iface_section_name, 'network', pkg.NETWORK_NAME)
    uci:set('wireless', iface_section_name, 'mode', 'sta')
    uci:set('wireless', iface_section_name, 'ifname', pkg.IFNAME)
    uci:set('wireless', iface_section_name, 'encryption', encryption)
    uci:set('wireless', iface_section_name, 'ssid', ssid)
    uci:set('wireless', iface_section_name, 'key', password)
    uci:commit('wireless')

    uci:set('network', pkg.NETWORK_NAME, 'interface')
    uci:set('network', pkg.NETWORK_NAME, 'proto', 'dhcp')
    uci:commit('network')

    pkg._apply_change()
    return true
end

function pkg.disable(radio)
    local uci = config.get_uci_cursor()
    local radio = radio or pkg.DEFAULT_RADIO

    uci:delete('wireless', pkg.iface_section_name(radio))
    uci:commit('wireless')

    uci:delete('network', pkg.NETWORK_NAME)
    uci:commit('network')

    pkg._apply_change()
    return true
end

function pkg.status(radio)
    local uci = config.get_uci_cursor()
    local radio = radio or pkg.DEFAULT_RADIO
    local connected = false
    local signal

    local enabled = false

    if uci:get('wireless', pkg.iface_section_name(radio)) then
        enabled = true
    end

    for mac, station in pairs(iwinfo.nl80211.assoclist(pkg.IFNAME)) do
        connected = true
        signal = station['signal']
    end

    return {connected = connected, signal = signal, enabled = enabled}
end


return pkg
