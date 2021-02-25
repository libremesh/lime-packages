#!/usr/bin/lua

local config = require("lime.config")
local uci = config.get_uci_cursor()

-- Redistribute default routes only if they are of protocol 7.
-- This routes are installed and removed using watchping.

uci:set("babeld", "default4", "proto", "7")
uci:set("babeld", "default6", "proto", "7")
uci:commit("babeld")
