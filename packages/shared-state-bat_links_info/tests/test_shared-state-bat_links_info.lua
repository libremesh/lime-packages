local utils = require "lime.utils"

package.path = package.path .. ";packages/shared-state-bat_links_info/files/usr/bin/?;;"
require ("shared-state-publish_bat_links_info")

local sample_batman_nj = 

describe('Tests bat_links_info #bat_links_info', function ()
    it('a simple test to get node info and assert requiered fields are present', function()
        utils.log("presss")

        stub(utils, "unsafe_shell", function (cmd)
            if cmd == "batctl nj" then
                utils.log(" tubbbbbbbbbbbbbbbbbbbb")
            else
                utils.log("sssssss")
            end
            return '[{"hard_ifindex":26,"hard_ifname":"wlan0-mesh_250","last_seen_msecs":1990,"neigh_address":"02:58:47:da:4e:aa"},{"hard_ifindex":26,"hard_ifname":"wlan0-mesh_250","last_seen_msecs":1690,"neigh_address":"02:58:47:46:28:95"},{"hard_ifindex":28,"hard_ifname":"wlan1-mesh_250","last_seen_msecs":1510,"neigh_address":"02:ab:46:da:4e:aa"},{"hard_ifindex":28,"hard_ifname":"wlan1-mesh_250","last_seen_msecs":970,"neigh_address":"02:ab:46:46:28:95"}]'
        end)

        local links_info = {}

        links_info = get_bat_links_info()
        assert.are.equal('"02:58:47:da:4e:aa"', links_info[0].dst_mac)
        utils.printJson(links_info)

    end)
end)