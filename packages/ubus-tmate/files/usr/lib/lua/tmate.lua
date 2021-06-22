#!/usr/bin/env lua
--[[ Copyright (C) 2013-2020 LibreMesh.org
  This is free software, licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3

]]--

local utils = require 'lime.utils'


local TMATE_SOCK = "/tmp/tmate.sock"
local TMATE_CONFIG = "/etc/tmate/tmate.conf"

local tmate = {}

function tmate.cmd_as_str(cmd)
   final_cmd = "tmate -f "..TMATE_CONFIG.." -S "..TMATE_SOCK.." "..cmd
   return utils.unsafe_shell(final_cmd)
end

local function unix_socket_listening(name)
   return "" ~= utils.unsafe_shell("netstat -xl | grep "..TMATE_SOCK.." 2>/dev/null")
end

function tmate.session_running()
  return unix_socket_listening(TMATE_SOCK)
end

function tmate.get_rw_session()
  return tmate.cmd_as_str("display -p '#{tmate_ssh}'"):sub(1, -2)
end

function tmate.get_ro_session()
  return tmate.cmd_as_str("display -p '#{tmate_ssh_ro}'"):sub(1, -2)
end

function tmate.get_connected_clients()
  return tmate.cmd_as_str("display -p '#{tmate_num_clients}'"):sub(1, -2)
end

function tmate.open_session()
  tmate.cmd_as_str("new-session -d")
  tmate.cmd_as_str("send-keys C-c")
end

function tmate.wait_session_ready()
  tmate.cmd_as_str("wait tmate-ready")
end

function tmate.close_session()
  tmate.cmd_as_str("kill-session -t 0")
end

return tmate
