#!/usr/bin/lua

--! LibreMesh
--! Copyright (c) 2024  Javier Jorge <jjorge@inti.gob.ar>
--! Copyright (c) 2024  Instituto Nacional de Tecnología Industrial
--! Copyright (C) 2024  Asociación Civil Altermundi <info@altermundi.net>
--! SPDX-License-Identifier: AGPL-3.0-only

local JSON = require("luci.jsonc")
local location = require 'lime.location'

local shared_state_links_info = {}

function shared_state_links_info.add_dst_loc(links_info, shared_state_sample, hostname)
    if shared_state_sample ~= nil then
        for link, l_data in pairs(links_info.links) do
            for node, data in pairs(shared_state_sample) do
                if node ~= hostname and data.links ~= nil then
                    local link_data = data.links[link]
                    if link_data ~= nil and data.src_loc~= nil then
                        l_data.dst_loc = {}
                        l_data.dst_loc.lat = data.src_loc.lat
                        l_data.dst_loc.long = data.src_loc.long
                    end
                end
            end
        end
    end
end

function shared_state_links_info.add_own_location_to_links(links)
return {
    links = links,
    -- we are not interested in the community location.
    src_loc = location.get_node() or { 
        lat = "FIXME",
        long = "FIXME"
    }
}
end

function shared_state_links_info.insert_in_ss_with_location(links,data_type_name)
    local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")
    local links_info = shared_state_links_info.add_own_location_to_links(links)
    local shared_state_sample = JSON.parse(io.popen("shared-state-async get "..data_type_name, "r"):read('*all'))
    shared_state_links_info.add_dst_loc(links_info, shared_state_sample, hostname)
    local result = {[hostname] = links_info}
    io.popen("shared-state-async insert "..data_type_name, "w"):write(JSON.stringify(result))
end

return shared_state_links_info
