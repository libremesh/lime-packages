local utils = require "lime.utils"
local network = require ("lime.network")
local iwinfo = require "iwinfo"



describe('Tests bat_links_info #bat_links_info', function ()
    stub(utils, "unsafe_shell", function (cmd)
        return '[{"hard_ifindex":26,"hard_ifname":"wlan0-mesh_250","last_seen_msecs":1990,"neigh_address":"02:58:47:da:4e:aa"},{"hard_ifindex":26,"hard_ifname":"wlan0-mesh_250","last_seen_msecs":1690,"neigh_address":"02:58:47:46:28:95"},{"hard_ifindex":28,"hard_ifname":"wlan1-mesh_250","last_seen_msecs":1510,"neigh_address":"02:ab:46:da:4e:aa"},{"hard_ifindex":28,"hard_ifname":"wlan1-mesh_250","last_seen_msecs":970,"neigh_address":"02:ab:46:46:28:95"}]'
    end)
    stub(network, "get_mac", function (iface)
        return iwinfo.mocks.wlan1_mesh_mac
    end)
    
    package.path = package.path .. ";packages/shared-state-bat_links_info/files/usr/bin/?;;"
    require ("shared-state-publish_bat_links_info")
    
    it('a simple test to get node info and assert requiered fields are present', function()
        local links_info = {}
        links_info = get_bat_links_info()
        assert.are.equal(table.concat(iwinfo.mocks.wlan1_mesh_mac,":"), links_info[1].src_mac)
        assert.are.equal('02:58:47:da:4e:aa', links_info[1].dst_mac)
        assert.are.equal(26, links_info[1].hard_ifindex)
        assert.are.equal(1990, links_info[1].last_seen_msecs)
        assert.are.equal("wlan0-mesh_250", links_info[1].iface)
    end)
end)