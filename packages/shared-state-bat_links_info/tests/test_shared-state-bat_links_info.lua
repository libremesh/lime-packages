local utils = require "lime.utils"
local network = require ("lime.network")
local iwinfo = require "iwinfo"



describe('Tests bat_links_info #bat_links_info', function ()

    oj_output = [[
        [{"hard_ifindex":28,"hard_ifname":"wlan1-mesh_250","orig_address":
        "02:95:39:46:28:95","last_seen_msecs":20,"neigh_address":
        "02:ab:46:da:4e:aa","tq":222},{"hard_ifindex":26,"hard_ifname":
        "wlan0-mesh_250","orig_address":"02:95:39:46:28:95","last_seen_msecs":
        20,"neigh_address":"02:58:47:da:4e:aa","tq":0},{"hard_ifindex":28,
        "hard_ifname":"wlan1-mesh_250","orig_address":"02:95:39:46:28:95",
        "best":true,"last_seen_msecs":20,"neigh_address":"02:ab:46:46:28:95",
        "tq":251},{"hard_ifindex":26,"hard_ifname":"wlan0-mesh_250","orig_address"
        :"02:95:39:46:28:95","last_seen_msecs":20,"neigh_address":
        "02:58:47:46:28:95","tq":239},{"hard_ifindex":26,"hard_ifname":
        "wlan0-mesh_250","orig_address":"02:58:47:da:4e:aa","last_seen_msecs":
        1260,"neigh_address":"02:58:47:46:28:95","tq":179},{"hard_ifindex":26,
        "hard_ifname":"wlan0-mesh_250","orig_address":"02:58:47:da:4e:aa","best"
        :true,"last_seen_msecs":1260,"neigh_address":"02:58:47:da:4e:aa","tq":
        255},{"hard_ifindex":28,"hard_ifname":"wlan1-mesh_250","orig_address":
        "02:95:39:da:4e:aa","last_seen_msecs":1100,"neigh_address":
        "02:ab:46:46:28:95","tq":214},{"hard_ifindex":26,"hard_ifname":
        "wlan0-mesh_250","orig_address":"02:95:39:da:4e:aa","last_seen_msecs":
        1100,"neigh_address":"02:58:47:46:28:95","tq":0},{"hard_ifindex":28,
        "hard_ifname":"wlan1-mesh_250","orig_address":"02:95:39:da:4e:aa","best":
        true,"last_seen_msecs":1100,"neigh_address":"02:ab:46:da:4e:aa","tq":255}]
        ]]

    stub(utils, "unsafe_shell", function (cmd)
        return oj_output
    end)
    stub(network, "get_mac", function (iface)
        return iwinfo.mocks.wlan1_mesh_mac
    end)
    
    package.path = package.path .. ";packages/shared-state-bat_links_info/files/usr/bin/?;;"
    require ("shared-state-publish_bat_links_info")
    
    it('a simple test to get node info and assert requiered fields are present', function()
        local links_info = {}
        links_info = get_bat_links_info()
        assert.are.equal('02:95:39:46:28:95', links_info[1].src_mac)
        assert.are.equal('02:ab:46:da:4e:aa', links_info[1].dst_mac)
        assert.are.equal(20, links_info[1].last_seen_msecs)
        assert.are.equal("wlan1-mesh_250", links_info[1].iface)
        assert.are.equal(222, links_info[1].tq)

    end)
end)
