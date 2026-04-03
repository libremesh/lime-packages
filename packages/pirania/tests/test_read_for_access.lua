local test_utils = require 'tests.utils'
local utils = require('lime.utils')
local read_for_access = require('read_for_access.read_for_access')
local CONFIG_PATH = "./packages/pirania/files/etc/config/pirania"

local current_time_s = 66040.78
local uci

describe('read_for_access tests #readforaccess', function()
    local snapshot -- to revert luassert stubs and spies

    it('saves authorized macs with configurable duration', function()
        stub(os, 'execute', function() end)
        local duration_m = uci:get('pirania', 'read_for_access', 'duration_m')
        read_for_access.authorize_mac('AA:BB:CC:DD:EE:FF', '10.1.1.1')
        local auth_macs = read_for_access.get_authorized_macs()
        assert.is.equal(1, utils.tableLength(auth_macs))
        assert.is.equal('AA:BB:CC:DD:EE:FF', auth_macs[1])
        local auth_ips = read_for_access.get_authorized_ips()
        assert.is.equal(1, utils.tableLength(auth_ips))
        assert.is.equal('10.1.1.1', auth_ips[1])
        current_time_s = current_time_s + (duration_m * 60) + 1
        auth_macs = read_for_access.get_authorized_macs()
        assert.is.equal(0, utils.tableLength(auth_macs))
        auth_ips = read_for_access.get_authorized_ips()
        assert.is.equal(0, utils.tableLength(auth_ips))
    end)

    
    it('calls captive-portal-update on authorize_mac', function()
        stub(os, 'execute', function() end)
        read_for_access.authorize_mac('AA:BB:CC:DD:EE:FF', '10.1.1.1')
        assert.stub(os.execute).was_called_with('/usr/bin/captive-portal update > /dev/null 2>&1')
    end)
    
    it('let us re-authorize a mac', function()
        stub(os, 'execute', function() end)
        local duration_m = uci:get('pirania', 'read_for_access', 'duration_m')
        read_for_access.authorize_mac('AA:BB:CC:DD:EE:FF', '10.1.1.1')
        current_time_s = current_time_s + (duration_m * 60) + 1
        read_for_access.authorize_mac('AA:BB:CC:DD:EE:FF', '10.1.1.1')
        local auth_macs = read_for_access.get_authorized_macs()
        assert.is.equal(1, utils.tableLength(auth_macs))
        assert.is.equal('AA:BB:CC:DD:EE:FF', auth_macs[1])
        local auth_ips = read_for_access.get_authorized_ips()
        assert.is.equal(1, utils.tableLength(auth_ips))
        assert.is.equal('10.1.1.1', auth_ips[1])
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        local tmp_dir = test_utils.setup_test_dir()
        read_for_access.set_workdir(tmp_dir)
        uci = test_utils.setup_test_uci()
        local default_cfg = io.open(CONFIG_PATH):read("*all")
        test_utils.write_uci_file(uci, 'pirania', default_cfg)
        stub(utils, "uptime_s", function () return current_time_s end)
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_dir()
        test_utils.teardown_test_uci(uci)
    end)

end)
