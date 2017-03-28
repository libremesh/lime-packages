--[[
    Copyright (C) libremesh.org

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

module("luci.controller.lime", package.seeall)

-- Flashing accessory functions
local function image_supported(image)
	return (os.execute("sysupgrade -T %q >/dev/null" % image) == 0)
end

local function image_checksum(image)
	return (luci.sys.exec("md5sum %q" % image):match("^([^%s]+)"))
end

local function image_sha256_checksum(image)
	return (luci.sys.exec("sha256sum %q" % image):match("^([^%s]+)"))
end

local function supports_sysupgrade()
	return nixio.fs.access("/lib/upgrade/platform.sh")
end

local function supports_reset()
	return (os.execute([[grep -sqE '"rootfs_data"|"ubi"' /proc/mtd]]) == 0)
end

function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end

local function storage_size()
	local size = 0
	if nixio.fs.access("/proc/mtd") then
		for l in io.lines("/proc/mtd") do
			local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
			if n == "linux" or n == "firmware" then
				size = tonumber(s, 16)
				break
			end
		end
	elseif nixio.fs.access("/proc/partitions") then
		for l in io.lines("/proc/partitions") do
			local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
			if b and n and not n:match('[0-9]') then
				size = tonumber(b) * 1024
				break
			end
		end
	end
	return size
end

-- /Flashing accessory functions

function index()

	-- Making lime as default
	local root = node()
	root.target = alias("lime")
	root.index  = true

	-- Main window with auth enabled
	status = entry({"lime"}, firstchild(), _("Simple Config"), 9.5)
	status.dependent = false
	status.sysauth = "root"
	status.sysauth_authenticator = "htmlauth"

	-- Rest of entries
	entry({"lime","essentials"}, cbi("lime/essentials"), _("Advanced"), 70).dependent=false
	entry({"lime","about"}, call("action_about"), _("About"), 80).dependent=false
	entry({"lime","logout"}, call("action_logout"), _("Logout"), 90)

	entry({"lime", "flashops"}, call("action_flashops"), _("Flash Firmware"), 70)
	entry({"lime", "flashops", "sysupgrade"}, call("action_sysupgrade"))
end

function action_about()
--	package.path = package.path .. ";/etc/lime/?.lua"
	luci.template.render("lime/about",{})
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url())
end

function action_flashops()
	luci.template.render("lime/flashops", {
		reset_avail   = supports_reset(),
		upgrade_avail = supports_sysupgrade()
	})
end

function action_sysupgrade()
	local fs = require "nixio.fs"
	local http = require "luci.http"
	local image_tmp = "/tmp/firmware.img"

	local fp
	http.setfilehandler(
	function(meta, chunk, eof)
		if not fp and meta and meta.name == "image" then
			fp = io.open(image_tmp, "w")
		end
		if fp and chunk then
			fp:write(chunk)
		end
		if fp and eof then
			fp:close()
		end
	end
	)

	if not luci.dispatcher.test_post_security() then
		fs.unlink(image_tmp)
		return
	end

	if http.formvalue("cancel") then
		fs.unlink(image_tmp)
		http.redirect(luci.dispatcher.build_url('lime/flashops'))
		return
	end

	local step = tonumber(http.formvalue("step") or 1)
	if step == 1 then
		if image_supported(image_tmp) then
			luci.template.render("lime/upgrade", {
				checksum = image_checksum(image_tmp),
				sha256ch = image_sha256_checksum(image_tmp),
				storage  = storage_size(),
				size	 = (fs.stat(image_tmp, "size") or 0),
				keep	 = (not not http.formvalue("keep"))
			})
		else
			fs.unlink(image_tmp)
			luci.template.render("lime/flashops", {
				reset_avail   = supports_reset(),
				upgrade_avail = supports_sysupgrade(),
				image_invalid = true
			})
		end

	elseif step == 2 then
		local keep = (http.formvalue("keep") == "1") and "" or "-n"
		luci.template.render("admin_system/applyreboot", {
			title = luci.i18n.translate("Flashing..."),
			msg   = luci.i18n.translate("The system is flashing now.<br /> DO NOT POWER OFF THE DEVICE!<br /> Wait a few minutes before you try to reconnect. It might be necessary to renew the address of your computer to reach the device again, depending on your settings."),
			addr  = (#keep > 0) and "192.168.1.1" or nil
		})
		fork_exec("sleep 1; killall dropbear uhttpd; sleep 1; FORCE=1 /usr/bin/lime-sysupgrade %q > /tmp/lime-sysupgrade.log" %{ image_tmp })
	end
end

