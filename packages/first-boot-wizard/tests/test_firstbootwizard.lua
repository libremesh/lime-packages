local libuci = require 'uci'
local config = require 'lime.config'
local fbw = require 'firstbootwizard'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local fs = require("nixio.fs")
local fbw_utils = require('firstbootwizard.utils')
local iwinfo = require 'iwinfo'
local json = require("luci.jsonc")


local uci = nil
config.log = function () end


local scanlist_result = {
    [1] = {
        ["encryption"] = {
            ["enabled"] = true,
            ["auth_algs"] = { },
            ["description"] = "WPA2 PSK (CCMP)",
            ["wep"] = false,
            ["auth_suites"] = { {"PSK"}} ,
            ["wpa"] = 2,
            ["pair_ciphers"] = {"CCMP"} ,
            ["group_ciphers"] = {"CCMP"} ,
            } ,
        ["quality_max"] = 70,
        ["ssid"] = "foo_ssid",
        ["channel"] = 1,
        ["signal"] = -53,
        ["bssid"] = "38:AB:C0:C1:D6:70",
        ["mode"] = "Master",
        ["quality"] = 57,
      } ,
      [2] = {
        ["encryption"] = {
            ["enabled"] = false,
            ["auth_algs"] = { } ,
            ["description"] = "None",
            ["wep"] = false,
            ["auth_suites"] = { } ,
            ["wpa"] = 0,
            ["pair_ciphers"] = { } ,
            ["group_ciphers"] = { } ,
        } ,
        ["quality_max"] = 70,
        ["ssid"] = "bar_ssid",
        ["channel"] = 11,
        ["signal"] = -67,
        ["bssid"] = "C2:4A:00:BE:7B:B7",
        ["mode"] = "Master",
        ["quality"] = 43,
        } ,
    }
    

local community_file = [[
config lime 'system'

config lime 'network'

config lime 'wifi'
	option ap_ssid 'foo'
	option apname_ssid 'foo/%H'
	option adhoc_ssid 'LiMe.%H'
	option ieee80211s_mesh_id 'LiMe'
]]

local community_file_unconfigured = [[
config lime 'system'

config lime 'network'

config lime 'wifi'
]]


-- For a scan results check that bssid has status
local function check_fetch_network_status(bssid, status) 
    local results = fbw.read_scan_results()
    assert.are_not.equal("[]", json.stringify(results))
    for k, v in pairs(results) do
        if(v['bssid'] == bssid) then 
            assert.is.equal(status['retval'], v['status']['retval'])
            assert.is.equal(status['code'], v['status']['code'])
        else
            assert.is_nil(v['status'])
        end
    end
end

local function save_mocked_scan_results ()
    iwinfo.fake.set_scanlist('phy0', scanlist_result)
    local scanlist =  iwinfo.nl80211.scanlist('phy0')
    assert.is.equal(true, fbw.save_scan_results(scanlist))
    return scanlist
end

describe('FirstBootWizard tests #fbw', function()

    it('test start/end_scan() and check_scan_file()', function()
        assert.is_nil(fbw.check_scan_file())

        fbw.start_scan_file()
        assert.are.same('true', io.open("/tmp/scanning"):read("*a"))
        assert.is.equal('true', fbw.check_scan_file())

        fbw.end_scan()
        assert.are.same('false', io.open("/tmp/scanning"):read("*a"))
        assert.is.equal('false', fbw.check_scan_file())
    end)

    it('test is_configured() / mark_as_configured() ', function()

        assert.is.equal(false, fbw.is_configured())

        uci:set(config.UCI_NODE_NAME, 'system', 'lime')
        fbw.mark_as_configured()
        assert.is.equal('true', uci:get(config.UCI_NODE_NAME, 'system', 'firstbootwizard_configured'))

        config.uci_autogen()
        assert.is.equal(true, fbw.is_configured())

    end)

    it('test is_dismissed() / dismiss()', function()
        assert.is.equal(false, fbw.is_dismissed())
        uci:set(config.UCI_NODE_NAME, 'system', 'lime')
        fbw.dismiss()
        assert.is.equal(true, fbw.is_dismissed())
        assert.is.equal(true, config.get_bool('system', 'firstbootwizard_dismissed', false))
    end)

    it('test get_networks()', function()
        fbw.get_networks() -- TODO
    end)

    it('test get_networks() empty', function()
        local configs = fbw.read_configs()
        assert.is.equal(0, #configs)
    end)

    it('test get_networks() empty', function()
        local configs = fbw.read_configs()
        assert.is.equal(0, #configs)
    end)

    it('test get_networks() empty', function()
        utils.write_file('/tmp/fbw/lime-community__host__foonode', community_file)

        local configs = fbw.read_configs()
        assert.is.equal(1, #configs)
        assert.is.equal('foo', configs[1]['config']['wifi']['ap_ssid'])
        assert.is.equal('lime-community__host__foonode', configs[1]['file'])
    end)


    it('test create_network() empty', function()
        stub(utils, "set_password", function () return nil end)
        stub(utils, "get_root_secret", function () return "mysecret" end)
        stub(fbw, "end_config", function () end)
        uci:set('lime-community', 'system', 'lime')

        fbw.create_network("LibreMesh", "myhost", "mypassword")

        assert.is.equal('SET_SECRET', uci:get("lime-community", 'system', 'root_password_policy'))
        assert.is.equal('mysecret', uci:get("lime-community", 'system', 'root_password_secret'))
        assert.stub(utils.set_password).was.called_with('root', "mypassword")
    end)

    it('test save_scan_results write and read', function()
        local scanlist = save_mocked_scan_results()
        local f = io.open(fbw.WORKDIR .. fbw.SCAN_RESULTS_FILE,"r")
        assert.is.equal(true, f~=nil)
        assert.is.equal(json.stringify(scanlist), f:read("*a"))
        io.close(f)

        -- Assert reading data
        fbw.start_scan_file() -- simulate is scanning to don't start the scan
        local results = fbw.status_search_networks()
        assert(true, type(results['scanned']) == table)
        assert(true, utils.deepcompare(scanlist, results['scanned']))
    end)

    it('test start search networks', function()
        fbw.end_scan()
        local results = fbw.start_search_networks()
        assert(true, results)
        assert(true, fbw.check_scan_file())
    end)

    it('test stop search networks', function()
        fbw.start_search_networks()
        assert(true, fbw.stop_search_networks())
        assert('false', fbw.check_scan_file())
    end)

    it('test restart search networks', function()
        fbw.start_search_networks()
        assert(true, fbw.check_scan_file())
        assert(true, fbw.restart_search_networks())
        assert(true, fbw.stop_search_networks())
        assert(true, fbw.restart_search_networks())       
    end)

    it('test search networks status', function()
        fbw.start_search_networks()
        assert(true, fbw.check_scan_file())
        local scanlist = save_mocked_scan_results()
        utils.write_file('/tmp/fbw/lime-community__host__foonode', community_file)
        local networks = fbw.read_configs()

        local results = fbw.status_search_networks()
        assert(true, type(results['scanned']) == table)
        assert(true, utils.deepcompare(scanlist, results['scanned']))
        assert(true, type(results['networks']) == table)
        assert(true, utils.deepcompare(networks, results['networks']))
        assert(true, results['status'] == 'scanning')
    end)

    it('test add status message to scan_results.json', function()
        save_mocked_scan_results()

        local destBssid = 'C2:4A:00:BE:7B:B7'
        local status = fbw.FETCH_CONFIG_STATUS.downloading_config

        fbw.set_status_to_scanned_bbsid(destBssid, status)

        check_fetch_network_status(destBssid, status)
        status = fbw.FETCH_CONFIG_STATUS.downloaded_config
        fbw.set_status_to_scanned_bbsid(destBssid, status)
        check_fetch_network_status(destBssid, status)
    end)

    it('test fetch lime assets download error handling', function()
        local host = "dummy"
        local fname = fbw.lime_community_assets_name(host)
        -- Check error downloading assets
        assert.is.equal(nil, fbw.fetch_lime_community_assets(host, fname))
        -- Check download ok 
        stub(utils, 'http_client_get', function() return true end)
        assert.is.equal(true, fbw.fetch_lime_community_assets(host, fname))
        utils.http_client_get:revert()
    end)

    it('test fetch_config can\'t get lime community', function()
        local scanlist = save_mocked_scan_results()
        local destBssid = "38:AB:C0:C1:D6:70"

        scanlist[1]["host"] = "dummy" 
        local status = fbw.FETCH_CONFIG_STATUS.error_download_lime_community
        local result = fbw.fetch_config(scanlist[1])
        assert.is.equal(false, result['success']) 
        check_fetch_network_status(destBssid, status)

    end)

    it('test fetch_config not ap_ssid configured', function()
        local scanlist = save_mocked_scan_results()
        local destBssid = "38:AB:C0:C1:D6:70"

        scanlist[1]["host"] = "::1" 
        stub(fbw, "fetch_lime_community", 
            function(host, fname) 
                utils.write_file(fname, community_file_unconfigured)
                return true
            end
        )
        result = fbw.fetch_config(scanlist[1])
        status = fbw.FETCH_CONFIG_STATUS.error_not_configured
        check_fetch_network_status(destBssid, status)
        assert.is.equal(false, result['success']) 
    end)

    it('test fetch_config community files configured but error downloading community assets', function()
        local scanlist = save_mocked_scan_results()
        local destBssid = "38:AB:C0:C1:D6:70"

        stub(fbw, "fetch_lime_community", 
            function(host, fname) 
                utils.write_file(fname, community_file)
                return true
            end
        )
        result = fbw.fetch_config(scanlist[1])
        status = fbw.FETCH_CONFIG_STATUS.error_download_lime_assets
        check_fetch_network_status(destBssid, status)
        assert.is.equal(false, result['success']) 
    end)

    it('test fetch_config community files and assets download correctly', function()
        local scanlist = save_mocked_scan_results()
        local destBssid = "38:AB:C0:C1:D6:70"
        stub(fbw, "fetch_lime_community_assets", 
            function(host, fname) 
                return true
            end)

        result = fbw.fetch_config(scanlist[1])
        status = fbw.FETCH_CONFIG_STATUS.downloaded_config
        assert.is.equal(true, result['success']) 
    end)

    before_each('', function()
        fbw_utils.execute('rm -f /tmp/fbw/*')
        fbw_utils.execute('rm -f /tmp/scanning')
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)

end)
