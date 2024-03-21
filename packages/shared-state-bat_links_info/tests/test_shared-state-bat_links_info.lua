local utils = require "lime.utils"
local network = require ("lime.network")
local iwinfo = require "iwinfo"



describe('Tests bat_links_info #bat_links_info', function ()

    local oj_output = [[
        [
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:95:39:46:28:95",
              "last_seen_msecs": 1820,
              "neigh_address": "02:ab:46:da:4e:aa",
              "tq": 225
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:95:39:46:28:95",
              "last_seen_msecs": 1820,
              "neigh_address": "02:58:47:da:4e:aa",
              "tq": 0
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:95:39:46:28:95",
              "best": true,
              "last_seen_msecs": 1820,
              "neigh_address": "02:ab:46:46:28:95",
              "tq": 255
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:95:39:46:28:95",
              "last_seen_msecs": 1820,
              "neigh_address": "02:58:47:46:28:95",
              "tq": 253
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:58:47:da:4e:aa",
              "last_seen_msecs": 0,
              "neigh_address": "02:58:47:46:28:95",
              "tq": 193
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:58:47:da:4e:aa",
              "best": true,
              "last_seen_msecs": 0,
              "neigh_address": "02:58:47:da:4e:aa",
              "tq": 111
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:95:39:da:4e:aa",
              "last_seen_msecs": 10,
              "neigh_address": "02:ab:46:46:28:95",
              "tq": 221
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:95:39:da:4e:aa",
              "last_seen_msecs": 10,
              "neigh_address": "02:58:47:46:28:95",
              "tq": 0
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:95:39:da:4e:aa",
              "best": true,
              "last_seen_msecs": 10,
              "neigh_address": "02:ab:46:da:4e:aa",
              "tq": 255
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:95:39:da:4e:aa",
              "last_seen_msecs": 10,
              "neigh_address": "02:58:47:da:4e:aa",
              "tq": 254
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:58:47:46:28:95",
              "last_seen_msecs": 140,
              "neigh_address": "02:58:47:da:4e:aa",
              "tq": 198
            },
            {
              "hard_ifindex": 26,
              "hard_ifname": "wlan0-mesh_250",
              "orig_address": "02:58:47:46:28:95",
              "best": true,
              "last_seen_msecs": 140,
              "neigh_address": "02:58:47:46:28:95",
              "tq": 222
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:ab:46:46:28:95",
              "last_seen_msecs": 1420,
              "neigh_address": "02:ab:46:da:4e:aa",
              "tq": 198
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:ab:46:46:28:95",
              "best": true,
              "last_seen_msecs": 1420,
              "neigh_address": "02:ab:46:46:28:95",
              "tq": 444
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:ab:46:da:4e:aa",
              "last_seen_msecs": 1680,
              "neigh_address": "02:ab:46:46:28:95",
              "tq": 195
            },
            {
              "hard_ifindex": 28,
              "hard_ifname": "wlan1-mesh_250",
              "orig_address": "02:ab:46:da:4e:aa",
              "best": true,
              "last_seen_msecs": 1680,
              "neigh_address": "02:ab:46:da:4e:aa",
              "tq": 333
            }
          ]
        ]]
    local nj_output = [[
    [
        {
            "hard_ifindex": 26,
            "hard_ifname": "wlan0-mesh_250",
            "last_seen_msecs": 1040,
            "neigh_address": "02:58:47:da:4e:aa"
        },
        {
            "hard_ifindex": 26,
            "hard_ifname": "wlan0-mesh_250",
            "last_seen_msecs": 1250,
            "neigh_address": "02:58:47:46:28:95"
        },
        {
            "hard_ifindex": 28,
            "hard_ifname": "wlan1-mesh_250",
            "last_seen_msecs": 640,
            "neigh_address": "02:ab:46:da:4e:aa"
        },
        {
            "hard_ifindex": 28,
            "hard_ifname": "wlan1-mesh_250",
            "last_seen_msecs": 450,
            "neigh_address": "02:ab:46:46:28:95"
        }
    ]
    ]]

    stub(utils, "unsafe_shell", function (cmd)
        if cmd == "batctl nj" then
            return nj_output
        elseif cmd == "batctl oj" then
            return oj_output
        end
        return ""
    end)

    stub(network, "get_mac", function (iface)
        if string.match(iface, "wlan0") then
            return iwinfo.mocks.wlan0_mesh_mac
        end
        return iwinfo.mocks.wlan1_mesh_mac
    end)

    package.path = package.path .. ";packages/shared-state-bat_links_info/files/usr/bin/?;;"
    require ("shared-state-publish_bat_links_info")
    
    it('a simple test to get node info and assert requiered fields are present', function()
        local links_info = {}
        links_info = get_bat_links_info()
        assert.are.equal(table.concat(iwinfo.mocks.wlan0_mesh_mac,":"), links_info[1].src_mac)
        assert.are.equal(table.concat(iwinfo.mocks.wlan1_mesh_mac,":"), links_info[4].src_mac)
        assert.are.equal('02:58:47:da:4e:aa', links_info[1].dst_mac)
        assert.are.equal(1040, links_info[1].last_seen_msecs)
        assert.are.equal("wlan0-mesh_250", links_info[1].iface)
        assert.are.equal(111, links_info[1].tq)
        assert.are.equal(222, links_info[2].tq)
        assert.are.equal(333, links_info[3].tq)
        assert.are.equal(444, links_info[4].tq)
    end)
end)
