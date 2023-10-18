#!/usr/bin/env lua

--[[
  Copyright (C) 2013-2023 LibreMesh.org
  This is free software, licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3

  Copyright 2023 Selankon <selankon@selankon.xyz>
]] --
local json = require 'luci.jsonc'
local mesh_upgrade = require 'lime-mesh-upgrade'

local function became_master_node(msg)
    local result = mesh_upgrade.became_master_node(msg)
    return utils.printJson(result)
end

local methods = {
    became_master_node = {},
}

if arg[1] == 'list' then utils.printJson(methods) end

if arg[1] == 'call' then
    local msg = utils.rpcd_readline()
    msg = json.parse(msg)
    if      arg[2] == 'became_master_node' then became_master_node(msg)
    else utils.printJson({ error = "Method not found" })
    end
end
