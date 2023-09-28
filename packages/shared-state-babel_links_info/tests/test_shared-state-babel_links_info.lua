local JSON = require("luci.jsonc")
local test_utils = require('tests.utils')
local utils = require('lime.utils')
local ubus = require "ubus"

local uci = nil

local ubus_babel_hosts = [[{"IPv6":{"fe80::16cc:20ff:feda:4eac":{"uhello-reach":
0,"hello-reach":65535,"txcost":256,"channel":255,"if_up":true,"rxcost":256,
"dev":"wlan1-mesh_17","rtt":"0.000"},"fe80::a2f3:c1ff:fe46:2896":
{"uhello-reach":0,"hello-reach":64511,"txcost":264,"channel":255,"if_up":true,
"rxcost":264,"dev":"wlan0-mesh_17","rtt":"0.000"},"fe80::16cc:20ff:feda:4eab":
{"uhello-reach":0,"hello-reach":65535,"txcost":438,"channel":255,"if_up":true,
"rxcost":256,"dev":"wlan0-mesh_17","rtt":"0.000"},"fe80::a2f3:c1ff:fe46:2897":
{"uhello-reach":0,"hello-reach":65535,"txcost":256,"channel":255,"if_up":true,
"rxcost":256,"dev":"wlan1-mesh_17","rtt":"0.000"}},"IPv4":[]}]]

describe('Tests network_nodes #network_nodes', function()
    before_each('', function()
        stub(ubus, "call", function(arg)
            return JSON.parse(ubus_babel_hosts)
        end)

        stub(utils, "unsafe_shell", function(cmd)
            return "fe80::c24a:ff:fefc:3abd"
        end)
    end)

    it('a simple test to get babel info and assert requiered fields are present', function()
        package.path = package.path .. ";packages/shared-state-babel_links_info/files/usr/bin/?;;"
        require("shared-state-publish_babel_links_info")

        babelinfo = get_babel_links_info()
        assert.are.equal('fe80::16cc:20ff:feda:4eac', babelinfo[1].dst_ip)
        assert.are.equal("wlan1-mesh_17",babelinfo[1].iface)
        assert.are.equal("fe80::c24a:ff:fefc:3abd",babelinfo[1].src_ip)
    end)
end)
