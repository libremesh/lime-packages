local utils = require "lime.utils"
local network = require 'lime.network'
local node_status = require 'lime.node_status'
local iwinfo = require('iwinfo')
local JSON = require("luci.jsonc")
local shared_state_links_info = require ("shared_state_links_info")
local shared_state_output_text = require (
    "./packages/shared-state-wifi_links_info/tests/shared_state_wifi_links_info_output_text")

package.path = package.path .. ";packages/shared-state-wifi_links_info/files/usr/share/shared-state/publishers/?;;"
local sspwli = require ("shared-state-publish_wifi_links_info")

it('a simple test to get links info and assert requiered fields are present', function()
    stub(utils, "unsafe_shell", function (cmd)
        if string.match(cmd, "wlan0") then
            return iwinfo.mocks.iw_station_get_result_wlan0
        end
        return iwinfo.mocks.iw_station_get_result_wlan1
    end)
    stub(node_status, "get_stations", function () return iwinfo.mocks.get_stations end)
    stub(node_status, "get_stations", function () return iwinfo.mocks.get_stations end)
    stub(iwinfo.nl80211,"frequency",function () return 2400 end)
    stub(network, "get_mac", function (iface)
        if string.match(iface, "wlan0") then
            return iwinfo.mocks.wlan0_mesh_mac
        end
        return iwinfo.mocks.wlan1_mesh_mac
    end)

    local links_info = shared_state_links_info.add_own_location_to_links(sspwli.get_wifi_links_info())
    assert.is.equal(26000, links_info.links["c00000000000c04a00be7b09"].tx_rate)
    assert.is.equal("c0:4a:00:be:7b:09", links_info.links["c00000000000c04a00be7b09"].dst_mac)
    assert.is.same({-17,-18}, links_info.links["c00000000000c04a00be7b09"].chains)
    assert.is.equal(-14, links_info.links["c00000000000c04a00be7b09"].signal)
    assert.is.equal("wlan0-mesh", links_info.links["c00000000000c04a00be7b09"].iface)
    assert.is.equal(13000, links_info.links["c00000000000c04a00be7b09"].rx_rate)
    assert.is.equal(2400, links_info.links["c00000000000c04a00be7b09"].freq)
    assert.is.equal("c0:00:00:00:00:00", links_info.links["c00000000000c04a00be7b09"].src_mac)
end)

it('a simple test to get location info', function()
    stub(utils, "unsafe_shell", function (cmd)
        if string.match(cmd, "wlan0") then
            return iwinfo.mocks.iw_station_get_result_wlan0
        end
        return iwinfo.mocks.iw_station_get_result_wlan1
    end)
    stub(node_status, "get_stations", function () return iwinfo.mocks.get_stations end)
    stub(node_status, "get_stations", function () return iwinfo.mocks.get_stations end)
    stub(iwinfo.nl80211,"frequency",function () return 2400 end)
    stub(network, "get_mac", function (iface)
        if string.match(iface, "wlan0") then
            return iwinfo.mocks.wlan0_mesh_mac
        end
        return iwinfo.mocks.wlan1_mesh_mac
    end)

    local links_info = shared_state_links_info.add_own_location_to_links(sspwli.get_wifi_links_info())
    local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")
    local shared_state_sample_s = JSON.parse(shared_state_output_text)
    utils.printJson(links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    assert.is.equal(nil, links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    shared_state_links_info.add_dst_loc(links_info,shared_state_sample_s,hostname)
    assert.is.equal("FYI", links_info.links["c00000010101c04a00be7b0a"].dst_loc.lat)
    links_info = shared_state_links_info.add_own_location_to_links(sspwli.get_wifi_links_info())
    --asume shared state has just initialized
    local shared_state_sample = JSON.parse("{}")
    assert.is.equal(nil, links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    shared_state_links_info.add_dst_loc(links_info,shared_state_sample,hostname)
    assert.is.equal(nil, links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    assert.is.equal("c0:00:00:00:00:00", links_info.links["c00000000000c04a00be7b09"].src_mac)

end)
