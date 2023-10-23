local config = require 'lime.config'
local network = require 'lime.network'
local wireless = require 'lime.wireless'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local lime_mesh_upgrade = require 'lime-mesh-upgrade'
local json = require 'luci.jsonc'


-- disable logging in config module
config.log = function() end

local uci

local upgrade_data =
{
    type= "upgrade",
    data={
      firmware_ver="xxxx",
      repo_url="http://10.13.0.1/lros/api/v1/",
      upgrde_state="starting,downloading|ready_for_upgrade|upgrade_scheluded|confirmation_pending|~~confirmed~~|updated|error",
      error="CODE",
      safe_upgrade_status="",
      eup_STATUS="",
    },
    timestamp=231354654,
    id=21,
    transaction_state="started/aborted/finished",
    master_node=""
}

describe('LiMe mesh upgrade', function()
    it('test config', function()
        print("pruebaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa2")
        print (uci:set('mesh_upgrade', 'main', "mesh_upgrade"))
        print ("test")
        lime_mesh_upgrade.start(upgrade_data)
        utils.printJson(lime_mesh_upgrade.get_status())
        

    end)

    it('test config 2', function()
        print("pruebaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaa2")
    end)

    before_each('', function()
        print("pruebaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1")
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        print("pruebaaaaaaaaaaaaaaaaaaaaaaaaaa3")

        test_utils.teardown_test_uci(uci)
    end)
end)