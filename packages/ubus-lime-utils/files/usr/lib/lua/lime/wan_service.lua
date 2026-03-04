--! SPDX-License-Identifier: AGPL-3.0-only
--!
--! Copyright (C) 2026 LibreMesh.org

local utils = require('lime.utils')
local libuci = require('uci')

local wan_service = {}

--! Interface name patterns to exclude from WAN candidates
local EXCLUDE_PATTERNS = {
    "^lo$", "^lo%d",
    "^wlan", "^bat", "^br%-",
    "^lm_", "^anygw", "^dummy",
    "^tunl", "^ip6tnl", "^teql",
}

local function is_excluded(ifname)
    for _, pat in ipairs(EXCLUDE_PATTERNS) do
        if ifname:match(pat) then return true end
    end
    return false
end

--! Read a single-line sysfs file safely via io.open (no unsafe_shell).
local function read_sysfs(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local val = f:read("*l")
    f:close()
    return val
end

--! Returns "usb", "ethernet" or nil (skip) for a given interface.
--! USB detection: the device symlink path in sysfs contains "usb".
--! Ethernet detection: link type == 1 (ARPHRD_ETHER) and has a physical device dir.
--! No shell is spawned, sysfs is read directly with io.open / readlink.
local function get_iface_type(ifname)
    local sysfs_dev = "/sys/class/net/" .. ifname .. "/device"

    -- Check if /sys/class/net/<iface>/device exists at all (no shell needed)
    local f = io.open(sysfs_dev)
    if not f then return nil end
    f:close()

    -- Resolve the real path of the device symlink and look for "usb" in it.
    -- readlink is the only tool for this; ifname here comes from ls /sys/class/net
    -- (kernel-controlled), but we shell_quote it anyway for safety.
    local real_path = utils.unsafe_shell(
        "readlink -f " .. utils.shell_quote(sysfs_dev) .. " 2>/dev/null"):gsub("\n", "")
    if real_path:match("/usb%d") or real_path:match("/usb/") then
        return "usb"
    end

    -- ARPHRD_ETHER == 1 means it is an Ethernet-like interface
    local link_type = read_sysfs("/sys/class/net/" .. ifname .. "/type")
    if link_type == "1" then
        return "ethernet"
    end

    return nil
end

--! Returns true if the interface is currently present (visible in sysfs).
--! Uses io.open, no unsafe_shell.
local function iface_exists(ifname)
    local f = io.open("/sys/class/net/" .. ifname)
    if f then f:close() return true end
    return false
end

--! Returns the operative state of the interface ("up", "down", "unknown", …).
--! Read directly from sysfs, no unsafe_shell.
local function iface_operstate(ifname)
    return read_sysfs("/sys/class/net/" .. ifname .. "/operstate") or "unknown"
end

--! Returns true if the interface actually has a carrier/signal.
--! USB network interfaces (RNDIS, CDC-Ethernet, 4G dongles) almost always
--! report operstate="unknown" even when fully working, because their drivers
--! do not implement link-state reporting.  The carrier file is more reliable:
--!   1 = carrier present (connected / working)
--!   0 or read-error = no carrier (disconnected / down)
local function iface_is_connected(ifname, operstate)
    if operstate == "up" then return true end
    return read_sysfs("/sys/class/net/" .. ifname .. "/carrier") == "1"
end

--! Returns the current WAN device as set in the OpenWrt network UCI
local function get_current_wan_device()
    local uci = libuci:cursor()
    return uci:get("network", "wan", "device") or ""
end

--! Returns WAN status: current device + list of candidate interfaces.
--!
--! Response shape:
--! {
--!   current   = "eth1",          -- current network.wan.device value
--!   interfaces = {
--!     { name="eth1",  type="ethernet", operstate="up",   is_current=true  },
--!     { name="usb0",  type="usb",      operstate="down", is_current=false },
--!   }
--! }
function wan_service.get_wan_status()
    local result = {}
    result.current = get_current_wan_device()
    result.interfaces = {}

    local ifaces_raw = utils.unsafe_shell("ls /sys/class/net/ 2>/dev/null")
    for iface in ifaces_raw:gmatch("[^\n]+") do
        if not is_excluded(iface) then
            local iface_type = get_iface_type(iface)
            if iface_type then
                local operstate = iface_operstate(iface)
                table.insert(result.interfaces, {
                    name         = iface,
                    type         = iface_type,
                    operstate    = operstate,
                    is_connected = iface_is_connected(iface, operstate),
                    is_current   = (iface == result.current),
                })
            end
        end
    end

    return result
end

--! Sets network.wan.device to `ifname` and brings the WAN interface back up.
--!
--! Returns { status="ok", ifname=<ifname> } or { status="error", message=<msg> }
function wan_service.set_wan_interface(ifname)
    if not ifname or ifname == "" then
        return { status = "error", message = "ifname is required" }
    end

    if not iface_exists(ifname) then
        return { status = "error", message = "Interface '" .. ifname .. "' not found" }
    end

    local uci = libuci:cursor()
    -- Ensure the wan section exists with proto dhcp
    uci:set("network", "wan", "interface")
    uci:set("network", "wan", "proto", "dhcp")
    uci:set("network", "wan", "device", ifname)
    uci:save("network")
    uci:commit("network")

    -- Bring the WAN connection down and up again asynchronously
    utils.execute_daemonized("ifdown wan; ifup wan")

    return { status = "ok", ifname = ifname }
end

return wan_service
