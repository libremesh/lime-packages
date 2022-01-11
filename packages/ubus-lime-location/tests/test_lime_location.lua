local utils = require "lime.utils"
local test_utils = require "tests.utils"
local config = require 'lime.config'
local network = require 'lime.network'
local location = require 'lime.location'
local iwinfo = require('iwinfo')
local system = require 'lime.system'
local json = require "luci.jsonc"

local test_file_name = "packages/ubus-lime-location/files/usr/libexec/rpcd/lime-location"
local ubus_lime_loc = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call
local uci

describe('ubus-lime-utils tests #ubuslimelocation', function()
    it('test list methods', function()
        local response  = rpcd_call(ubus_lime_loc, {'list'})
        assert.is.equal(0, response.get.no_params)
    end)

    it('test get with no config', function()
        uci:set("location", "settings", "location")
        local response  = rpcd_call(ubus_lime_loc, {'call', 'get'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal("FIXME", response.location.lat)
        assert.is.equal("FIXME", response.location.lon)
        assert.is.equal(true, response.default)
    end)

    it('test get with no specific location provided defaulting to community', function()
        uci:set("location", "settings", "location")
        lat = uci:set("location", "settings", "community_latitude", "23.123")
        lon = uci:set("location", "settings", "community_longitude", "-45")

        local response  = rpcd_call(ubus_lime_loc, {'call', 'get'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal("23.123", response.location.lat)
        assert.is.equal("-45", response.location.lon)
        assert.is.equal(true, response.default)
    end)

    it('test get with location', function()
        uci:set("location", "settings", "location")
        local latitude = "15.123"
        local longitude = "-5"
        lat = uci:set("location", "settings", "node_latitude", latitude)
        lon = uci:set("location", "settings", "node_longitude", longitude)
        uci:commit("location")

        local response  = rpcd_call(ubus_lime_loc, {'call', 'get'}, '')
        assert.is.equal("ok", response.status)
        assert.is.equal(latitude, response.location.lat)
        assert.is.equal(longitude, response.location.lon)
        assert.is.equal(false, response.default)
    end)

    it('test set location', function()
        local f = io.open("/tmp/lime_location_testing", "w")
        stub(network, "get_own_macs", function () return {"00:11:7f:13:36:16", "02:ce:16:aa:83:52"} end)
        stub(io, "popen", function () return f end)
        stub(system, "get_hostname", function() return 'my-hostname' end)
        uci:set("location", "settings", "location")
        lat = uci:set("location", "settings", "node_latitude", "15.123")
        lon = uci:set("location", "settings", "node_longitude", "-5")

        local response  = rpcd_call(ubus_lime_loc, {'call', 'set'}, '{"lat":"1", "lon":"3.14"}')
        io.popen:revert()
        assert.is.equal("ok", response.status)
        assert.is.equal("1", response.lat)
        assert.is.equal("3.14", response.lon)
        assert.is.equal("1", uci:get("location", "settings", "node_latitude"))
        assert.is.equal("3.14", uci:get("location", "settings", "node_longitude"))
    end)

    it('test nodes_and_links', function()
        uci:set("location", "settings", "location")
        local lat = uci:set("location", "settings", "community_latitude", "23.123")
        local lon = uci:set("location", "settings", "community_longitude", "-45")

        local own_macs = {"00:11:7f:13:36:16", "02:ce:16:aa:83:52"}
        uci:set('wireless', 'wlan0_mesh_foo', 'wifi-iface')
        uci:set('wireless', 'wlan0_mesh_foo', 'mode', 'mesh')
        uci:set('wireless', 'wlan0_mesh_foo', 'ifname', 'wlan0-mesh')

        uci:set('wireless', 'wlan1_mesh_foo', 'wifi-iface')
        uci:set('wireless', 'wlan1_mesh_foo', 'mode', 'adhoc')
        uci:set('wireless', 'wlan1_mesh_foo', 'ifname', 'wlan1-adhoc')
        iwinfo.fake.load_from_uci(uci)
        local sta = iwinfo.fake.gen_assoc_station("HT20", "HT40", -66, 50, 10000, 300, 120)
        local assoclist = {['AA:BB:CC:DD:EE:FF'] = sta}
        iwinfo.fake.set_assoclist('wlan1-adhoc', assoclist)

        stub(network, "get_own_macs", function () return own_macs end)
        local response  = rpcd_call(ubus_lime_loc, {'call', 'nodes_and_links'}, '')
        local hostname = utils.hostname()
        assert.is.equal(hostname, response[hostname].hostname)

        assert.are.same(own_macs, response[hostname].macs)
        assert.are.same({lat='23.123', lon='-45'}, response[hostname].coordinates)
        assert.are.same({'aa:bb:cc:dd:ee:ff'}, response[hostname].links)
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)


describe('ubus-lime-utils tests #liblocation', function()
    it('test get with no config', function()
        uci:set("location", "settings", "location")
        assert.is_nil(location.get_node())
    end)

    it('test get with no node config', function()
        uci:set("location", "settings", "location")
        lat = uci:set("location", "settings", "community_latitude", "23.123")
        lon = uci:set("location", "settings", "community_longitude", "-45")
        assert.is_nil(location.get_node())
    end)

    it('test get with node config', function()
        uci:set("location", "settings", "location")
        local latitude = "15.123"
        local longitude = "-5"
        lat = uci:set("location", "settings", "node_latitude", latitude)
        lon = uci:set("location", "settings", "node_longitude", longitude)
        lat = uci:set("location", "settings", "community_latitude", "23.123")
        lon = uci:set("location", "settings", "community_longitude", "-45")
        assert.are.same({lat=latitude, long=longitude}, location.get_node())
    end)

    it('test set calls shared-state insert with hostname = data json', function()
        local nodes_and_links = location.nodes_and_links()
        stub(system, "get_hostname", function() return 'my-hostname' end)
        local fake_io_popen = { write = function() end }
        stub(fake_io_popen, "write", function() end)
        stub(io, "popen", fake_io_popen)
        local latitude = "15.123"
        local longitude = "-5"
        location.set(latitude, longitude)
        assert.stub(io.popen).was_called_with('shared-state insert nodes_and_links', 'w')
        local expected = {}
        expected['my-hostname'] = nodes_and_links
        assert.stub(fake_io_popen.write).was_called_with(match.is_table(), json.stringify(expected))
        io.popen:revert()
    end)


    it('test nodes_and_links no wireless', function()
        local result = location.nodes_and_links()
        assert.are.same({}, result.links)
        assert.are.same({lat="FIXME", lon="FIXME"}, result.coordinates)
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
