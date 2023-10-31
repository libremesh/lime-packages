local config = require 'lime.config'
local network = require 'lime.network'
local wireless = require 'lime.wireless'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local lime_mesh_upgrade = require 'lime-mesh-upgrade'
local json = require 'luci.jsonc'


-- disable logging in config module
config.log = function(text)
    print (text)
 end

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
    master_node="prmiero"
}

describe('LiMe mesh upgrade', function()

    it('test set mesh config fresh start', function()
        local status = lime_mesh_upgrade.get_mesh_upgrade_status()
        utils.printJson(status)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.NO_TRANSACTION)
        assert.is.equal(lime_mesh_upgrade.mesh_upgrade_is_started(),false)
    end)


    it('test set mesh config', function()

        config.log("test set mesh config.... ")
        lime_mesh_upgrade.set_mesh_upgrade_info(upgrade_data)
        status = lime_mesh_upgrade.get_mesh_upgrade_status()
        utils.printJson(status)
        assert.is.equal(status.master_node, upgrade_data.master_node)
        assert.is.equal(status.data.repo_url,upgrade_data.data.repo_url )
        assert.is.equal(status.data.upgrade_state, lime_mesh_upgrade.upgrade_states.STARTING)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.STARTED)

    end)

    it('test config 2', function()
        config.log("")
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
        config.log (uci:set('mesh-upgrade', 'main', "mesh-upgrade"))
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)