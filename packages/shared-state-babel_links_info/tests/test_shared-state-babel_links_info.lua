local JSON = require("luci.jsonc")
local utils = require('lime.utils')
local ubus = require "ubus"

local ubus_babel_hosts = [[
{
    "IPv6":{
        "fe80::16cc:20ff:feda:4eac":{
            "uhello-reach":0,
            "hello-reach":65535,
            "txcost":256,
            "channel":255,
            "if_up":true,
            "rxcost":256,
            "dev":"wlan1-mesh_17",
            "rtt":"0.000"
        },
        "fe80::a2f3:c1ff:fe46:2896":{
            "uhello-reach":0,
            "hello-reach":64511,
            "txcost":264,
            "channel":255,
            "if_up":true,
            "rxcost":264,
            "dev":"wlan0-mesh_17",
            "rtt":"0.000"
        },
        "fe80::16cc:20ff:feda:4eab":{
            "uhello-reach":0,
            "hello-reach":65535,
            "txcost":438,
            "channel":255,
            "if_up":true,
            "rxcost":256,
            "dev":"wlan0-mesh_17",
            "rtt":"0.000"
        },
        "fe80::a2f3:c1ff:fe46:2897":{
            "uhello-reach":0,
            "hello-reach":65535,
            "txcost":256,
            "channel":255,
            "if_up":true,
            "rxcost":256,
            "dev":"wlan1-mesh_17",
            "rtt":"0.000"
        }
    },
    "IPv4":[]
}
]]

package.path = package.path ..
    ";packages/shared-state-babel_links_info/files/usr/share/shared-state/publishers/?;;"

describe('Tests network_nodes #network_nodes', function()
    before_each('', function()
        stub(ubus, "call", function()
            return JSON.parse(ubus_babel_hosts)
        end)

        stub(utils, "unsafe_shell", function()
            return "fe80::c24a:ff:fefc:3abd"
        end)
    end)

    it('a simple test to get babel info and assert requiered fields are present', function()
        local sspbli = require("shared-state-publish_babel_links_info")

        local babelinfo = sspbli.get_babel_links_info()
        assert.are.equal('fe80::16cc:20ff:feda:4eac', babelinfo["fe8016cc20fffeda4eacfe80c24afffefc3abd"].dst_ip)
        assert.are.equal("wlan1-mesh_17",babelinfo["fe8016cc20fffeda4eacfe80c24afffefc3abd"].iface)
        assert.are.equal("fe80::c24a:ff:fefc:3abd",babelinfo["fe8016cc20fffeda4eacfe80c24afffefc3abd"].src_ip)
    end)
end)

describe('Test get interface local ipv6', function()
    before_each('', function()
        local ifaces = {'lo', 'eth0-1_250', 'bat0', 'anygw'}
        local unsafe_shell_calls = 0
        stub(utils, "get_ifnames", function () return ifaces end)

        --this function returns an output similar to the command invoked in get_interface_ip
        stub(utils, "unsafe_shell", function (cmd)
            unsafe_shell_calls=unsafe_shell_calls+1
            if string.match(cmd, 'lo') then
                --the loopback interface tipically dont have an ipv6 ip
                return ""
            end
            if string.match(cmd, 'eth0%-1_250') then
                return "fe80::db:d6ff:fefc:3abd"
            end
            if string.match(cmd, 'bat0') then
                --the bat0 interface may not have an ipv6 ip
                return ""
            end
            if string.match(cmd, 'anygw') then
                return "fe80::a8aa:aaff:feea:d2aa"
            end
            return "not expected command: ".. cmd
        end)

    end)
    it('a simple test to get get interface local ipv6 address', function()
        local sspbli = require("shared-state-publish_babel_links_info")
        local unsafe_shell_spy = spy.on(utils, "unsafe_shell")
        local ifs = utils.get_ifnames()

        assert.are.equal("",sspbli.get_interface_ip(ifs[1]))
        assert.are.equal("fe80::db:d6ff:fefc:3abd",sspbli.get_interface_ip(ifs[2]))
        assert.are.equal("",sspbli.get_interface_ip(ifs[3]))
        assert.are.equal("fe80::a8aa:aaff:feea:d2aa",sspbli.get_interface_ip(ifs[4]))
        assert.are.equal("fe80::a8aa:aaff:feea:d2aa",sspbli.get_interface_ip(ifs[4]))
        assert.are.equal("fe80::a8aa:aaff:feea:d2aa",sspbli.get_interface_ip(ifs[4]))
        --cached values shoud be used instead of making the os call
        assert.spy(unsafe_shell_spy).was.called(4)
    end)
end)
