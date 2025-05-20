local utils = require "lime.utils"
local node_status = require 'lime.node_status'
local iwinfo = require('iwinfo')
local JSON = require("luci.jsonc")
local shared_state_links_info = require ("shared_state_links_info")


local shared_state_output_text = [[
{"LiMe-462895":{"src_loc":{"lat":"FYI","long":"FYI"},"links":{"c00000010101c04a00be7b0a":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"ae:40:41:1d:f9:35","channel":48,"chains":[-46,-43],"signal":-42,"rx_rate":300000,"src_mac":"c0:4a:00:be:7b:0a"},"a6f3c1462897ae40411c8516":{"freq":5240,"iface":"wlan1-mesh","tx_rate":240000,"dst_mac":"ae:40:41:1c:85:16","channel":48,"chains":[-54,-54],"signal":-51,"rx_rate":300000,"src_mac":"a6:f3:c1:46:28:97"},"a6f3c1462897c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":180000,"dst_mac":"c6:4a:00:fc:3a:bf","channel":48,"chains":[-65,-63],"signal":-61,"rx_rate":270000,"src_mac":"a6:f3:c1:46:28:97"},"a6f3c1462896c64a00fc3abe":{"freq":2462,"iface":"wlan0-mesh","tx_rate":144400,"dst_mac":"c6:4a:00:fc:3a:be","channel":11,"chains":[-51,-40],"signal":-40,"rx_rate":144400,"src_mac":"a6:f3:c1:46:28:96"}}},"LiMe-b713f7":{"a6f3c1462897ae40411df935":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"a6:f3:c1:46:28:97","channel":48,"chains":[-53,-53],"signal":-50,"rx_rate":300000,"src_mac":"ae:40:41:1d:f9:35"},"ae40411c85c3ae40411df934":{"freq":5785,"iface":"wlan2-mesh","tx_rate":150000,"dst_mac":"ae:40:41:1c:85:c3","channel":157,"chains":[-51,-36],"signal":-36,"rx_rate":300000,"src_mac":"ae:40:41:1d:f9:34"},"ae40411df935c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"c6:4a:00:fc:3a:bf","channel":48,"chains":[-58,-63],"signal":-57,"rx_rate":240000,"src_mac":"ae:40:41:1d:f9:35"},"ae40411c8516ae40411df935":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"ae:40:41:1c:85:16","channel":48,"chains":[-58,-70],"signal":-57,"rx_rate":300000,"src_mac":"ae:40:41:1d:f9:35"}},"LiMe-fc3abd":{"ae40411df935c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":240000,"dst_mac":"ae:40:41:1d:f9:35","channel":48,"chains":[-48,-46],"signal":-44,"rx_rate":300000,"src_mac":"c6:4a:00:fc:3a:bf"},"ae40411c8516c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":150000,"dst_mac":"ae:40:41:1c:85:16","channel":48,"chains":[-67,-63],"signal":-62,"rx_rate":270000,"src_mac":"c6:4a:00:fc:3a:bf"},"a6f3c1462897c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"a6:f3:c1:46:28:97","channel":48,"chains":[-64,-67],"signal":-63,"rx_rate":180000,"src_mac":"c6:4a:00:fc:3a:bf"},"a6f3c1462896c64a00fc3abe":{"freq":2462,"iface":"wlan0-mesh","tx_rate":144400,"dst_mac":"a6:f3:c1:46:28:96","channel":11,"chains":[-53,-45],"signal":-44,"rx_rate":130000,"src_mac":"c6:4a:00:fc:3a:be"}},"cheche":{"ae40411c8516ae40411df935":{"freq":5240,"iface":"wlan1-mesh","tx_rate":240000,"dst_mac":"ae:40:41:1d:f9:35","channel":48,"chains":[-55,-59],"signal":-54,"rx_rate":243000,"src_mac":"ae:40:41:1c:85:16"},"ae40411c85c3ae40411df934":{"freq":5785,"iface":"wlan2-mesh","tx_rate":270000,"dst_mac":"ae:40:41:1d:f9:34","channel":157,"chains":[-40,-31],"signal":-30,"rx_rate":150000,"src_mac":"ae:40:41:1c:85:c3"},"a6f3c1462897ae40411c8516":{"freq":5240,"iface":"wlan1-mesh","tx_rate":300000,"dst_mac":"a6:f3:c1:46:28:97","channel":48,"chains":[-56,-58],"signal":-54,"rx_rate":180000,"src_mac":"ae:40:41:1c:85:16"},"ae40411c8516c64a00fc3abf":{"freq":5240,"iface":"wlan1-mesh","tx_rate":270000,"dst_mac":"c6:4a:00:fc:3a:bf","channel":48,"chains":[-73,-75],"signal":-71,"rx_rate":90000,"src_mac":"ae:40:41:1c:85:16"}}}
]]

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

    links_info = shared_state_links_info.add_own_location_to_links(get_wifi_links_info())
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
    stub(iwinfo.nl80211,"frequency",function (iface) return 2400 end)
    stub(network, "get_mac", function (iface)
        if string.match(iface, "wlan0") then
            return iwinfo.mocks.wlan0_mesh_mac
        end
        return iwinfo.mocks.wlan1_mesh_mac
    end)
    local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")

    local links_info = shared_state_links_info.add_own_location_to_links(get_wifi_links_info())
    local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")
    local shared_state_sample_s = JSON.parse(shared_state_output_text)
    utils.printJson(links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    assert.is.equal(nil, links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    shared_state_links_info.add_dst_loc(links_info,shared_state_sample_s,hostname)
    assert.is.equal("FYI", links_info.links["c00000010101c04a00be7b0a"].dst_loc.lat)
    local links_info = shared_state_links_info.add_own_location_to_links(get_wifi_links_info())
    --asume shared state has just initialized 
    local shared_state_sample = JSON.parse("{}")  
    assert.is.equal(nil, links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    shared_state_links_info.add_dst_loc(links_info,shared_state_sample,hostname)
    assert.is.equal(nil, links_info.links["c00000010101c04a00be7b0a"].dst_loc)
    assert.is.equal("c0:00:00:00:00:00", links_info.links["c00000000000c04a00be7b09"].src_mac)

end)
