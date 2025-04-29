--! LibreMesh
--! Generic hook to be called as a symbolic link for each ref type
--! Copyright (C) 2025  Javier Jorge 
--! Copyright (C) 2025  Instituto Nacional de Tecnología Industrial (INTI) 
--! Copyright (C) 2025  Asociación Civil Altermundi <info@altermundi.net>
--! SPDX-License-Identifier: AGPL-3.0-

local JSON = require("luci.jsonc")
local utils = require("lime.utils")
local config = require("lime.config")
local libuci = require("uci")


local luci_config = libuci:cursor()
local eht_config = {}

function eht_config.get_eth_config()
  interfaces = {}
  local uci = config.get_uci_cursor()
  uci:foreach("lime-node", "net", function(entry)
    print(entry['.name'])
    print(entry.eth_role)
    print(entry.linux_name)
    if entry.eth_role ~= nil then
      local interface = {}
      interface.name = entry.linux_name
      interface.role = entry.eth_role
      table.insert(interfaces, interface)
    end
  end)
  return interfaces
end

function eht_config.delete_eth_config(device)
  local uci = config.get_uci_cursor()
  config.uci:delete("lime-node", "lime_app_eth_cfg_" .. device)
  config.uci:save("lime-node")
  uci:commit("lime-node")
end

function eht_config.set_eth_config(device, role)
  local uci = config.get_uci_cursor()
  local eth_role = uci:get("lime-node", "lime_app_eth_cfg_" .. device, "eth_role")
  if eth_role ~= nil then
    if eth_role == role then
      -- No changes needed, the role is already set
      return true
    else
      eht_config.delete_eth_config(device)
    end
  end
  
  uci:set("lime-node", "lime_app_eth_cfg_" ..device, "net")
  uci:set("lime-node", "lime_app_eth_cfg_" ..device, "eth_role", role)
  if role == "default" then
    eht_config.delete_eth_config(device)
  elseif role == "wan" then
    uci:set("lime-node", "lime_app_eth_cfg_" .. device, "linux_name", device)
    uci:set("lime-node", "lime_app_eth_cfg_" .. device, "protocols", {"wan","dynamic"})
  elseif role == "lan" then
    uci:set("lime-node", "lime_app_eth_cfg_" .. device, "linux_name", device)
    uci:set("lime-node", "lime_app_eth_cfg_" .. device, "protocols", {"lan"})
  elseif role == "mesh" then
    uci:set("lime-node", "lime_app_eth_cfg_" .. device, "linux_name", device)
    uci:set("lime-node", "lime_app_eth_cfg_" .. device, "protocols", {"batadv:%N1","babeld:17"})
  else
    return false
  end
  uci:commit("lime-node")
  config.uci:save("lime-node")
  os.execute("lime-config && /etc/init.d/network restart")
  return true
end

return eht_config
