local utils = require "lime.utils"
local node_status = require 'lime.node_status'
local iwinfo = require('iwinfo')

package.path = package.path .. ";packages/shared-state-wifi_links_info/files/usr/share/shared-state/publishers/?;;"
require ("shared-state-publish_wifi_links_info")

it('a simple test to get links info and assert requiered fields are present', function()
    stub(utils, "unsafe_shell", function (cmd) 
        if string.match(cmd, "wlan0") then 
            return iwinfo.mocks.iw_station_get_result_wlan0
        end
        return iwinfo.mocks.iw_station_get_result_wlan1
    end)
    stub(node_status, "get_stations", function () return iwinfo.mocks.get_stations end)
    stub(node_status, "get_stations", function () return iwinfo.mocks.get_stations end)
    stub(iwinfo.nl80211,"frequency",function (iface) return 2400 end)
    stub(network, "get_mac", function (iface)
        if string.match(iface, "wlan0") then
            return iwinfo.mocks.wlan0_mesh_mac
        end
        return iwinfo.mocks.wlan1_mesh_mac
    end)
    local links_info = {}

    links_info = get_wifi_links_info()
    assert.is.equal(26000, links_info["c00000000000c04a00be7b09"].tx_rate)
    assert.is.equal("c0:4a:00:be:7b:09", links_info["c00000000000c04a00be7b09"].dst_mac)
    assert.is.same({-17,-18}, links_info["c00000000000c04a00be7b09"].chains)
    assert.is.equal(-14, links_info["c00000000000c04a00be7b09"].signal)
    assert.is.equal("wlan0-mesh", links_info["c00000000000c04a00be7b09"].iface)
    assert.is.equal(13000, links_info["c00000000000c04a00be7b09"].rx_rate)
    assert.is.equal(2400, links_info["c00000000000c04a00be7b09"].freq)
    assert.is.equal("c0:00:00:00:00:00", links_info["c00000000000c04a00be7b09"].src_mac)
end)

