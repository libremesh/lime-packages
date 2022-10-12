local metrics = require 'lime-metrics'
local utils = require('lime-metrics.utils')
local lutils = require('lime.utils')
local json = require 'luci.jsonc'

local function mock_last_internet_path (data)
    local fake_path = '/tmp/fake_get_last_internet_path'
    stub(metrics, "get_last_internet_path_filename", function () return fake_path  end)
    lutils.write_file(fake_path, data)
end


describe('Lime-metric tests', function()


    it('test get_last_internet_path but file does not exists', function()
        local response  = metrics.get_last_internet_path()
        assert.is.equal("error", response.status)
        assert.is.equal("1", response.error.code)
    end)


    it('test get_last_internet_path', function()
        mock_last_internet_path('[{"ip":"10.133.43.6", "hostname":"node_foo"}, {"ip":"10.0.0.1","hostname":""}]')
        local response  = metrics.get_last_internet_path()
        assert.is.equal("ok", response.status)
        assert.is.equal("10.133.43.6", response.path[1].ip)
        assert.is.equal("node_foo", response.path[1].hostname)
        assert.is.equal("10.0.0.1", response.path[2].ip)
    end)


    it('test get_gateway return last entry on the last internet file', function()
        mock_last_internet_path('[{"ip":"10.133.43.6", "hostname":"node_foo"}, {"ip":"10.0.0.1","hostname":"thegateway"}]')
        local response  = metrics.get_gateway()
        assert.is.equal("ok", response.status)
        assert.are.same("thegateway", response.gateway.hostname)
        assert.are.same("10.0.0.1", response.gateway.ip)
    end)


    it('test get_gateway no gateway', function()
        mock_last_internet_path( '{}')
        local response  = metrics.get_gateway()
        assert.is.equal("error", response.status)
    end)


    -- todo(kon): fail due it always return `ok`
    -- it('test get_station_traffic of inexistent interface or inexistent station', function()
    --     stub(utils, "unsafe_shell", function () return ''  end)
    --     local msg = json.parse('{"iface": "wlan0", "station_mac": "AA:BB:CC:DD:EE:FF"}')
    --     local response  = metrics.get_station_traffic(msg)
    --     assert.is.equal("error", response.status)
    --     assert.is.equal("1", response.error.code)
    -- end)


    it('test get_station_traffic', function()
        stub(lutils, "unsafe_shell", function () return cmd_out  end)
        stub(lutils, "unsafe_shell", function () return '256723649\n22785424'  end)
        local msg = json.parse('{"iface": "wlan0", "station_mac": "AA:BB:CC:DD:EE:FF"}')
        local response  = metrics.get_station_traffic(msg)
        assert.is.equal("ok", response.status)
        assert.is.equal(22785424, response.tx_bytes)
        assert.is.equal(256723649, response.rx_bytes)
    end)


    -- todo(kon): fail due it always return `ok`
    -- it('test get_metrics no protocol', function()
    --     stub(utils, "unsafe_shell", function () return ''  end)
    --     local msg = json.parse('{"target": "nodename"}')
    --     local response  = metrics.get_metrics(msg)
    --     assert.is.equal("error", response.status)
    -- end)

    -- todo(kon): it fail because get loss return random numbers like 256723649
    -- shell_output on get_loss function
    -- it('test get_metrics no link', function()
    --     stub(lutils, "is_installed", function (m) return m == "lime-proto-babeld" end)
    --     local response  = metrics.get_metrics('nodename')
    --     assert.is.equal("ok", response.status)
    --     assert.is.equal("100", response.loss)
    --     assert.is.equal(0, response.bandwidth)
    -- end)


    it('test get_internet_status with internet', function()
        stub(utils, "get_loss", function () return  "25" end)
        stub(utils, "is_nslookup_working", function () return  true end)
        local response  = metrics.get_internet_status()
        assert.is.equal("ok", response.status)
        assert.is.equal(true, response.IPv4.working)
        assert.is.equal(true, response.IPv6.working)
        assert.is.equal(true, response.DNS.working)
    end)


end)
