local config = require 'lime.config'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local lime_mesh_upgrade = require 'lime-mesh-upgrade'
eupgrade = require 'eupgrade'


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

local latest_release_data = [[
{
    "metadata-version": 1,
    "images": [
        {
        "name": "test-board-upgrade.sh",
        "type": "installer",
        "download-urls": [
            "../20.xx/targets/ar71xx/generic/test-board-upgrade.sh",
            ],
        "sha256": "fbd95fce091ea10cfa05cfb0ef870da43124ac7c1402890eb8f03b440c57d7b5"
        }
    ],
    "board": "test-board",
    "version":  "LibreMesh 20.10",
    "release-info-url": "https://libremesh.org/news/"
}
]]


describe('LiMe mesh upgrade', function()

    it('test get mesh config fresh start', function()
        local status = lime_mesh_upgrade.get_mesh_upgrade_status()
        utils.printJson(status)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.NO_TRANSACTION)
        assert.is.equal(lime_mesh_upgrade.started(),false)
    end)

    it('test set mesh config', function()
        config.log("test set mesh config.... ")

        stub(eupgrade, '_get_board_name', function () return 'test-board' end)
        stub(eupgrade, '_get_current_fw_version', function () return 'LibreMesh 19.05' end)
        stub(eupgrade, '_check_signature', function () return true end)
        stub(utils, 'http_client_get', function () return latest_release_data end)
        assert.is.equal('LibreMesh 20.10', eupgrade.is_new_version_available()['version'])
        
        lime_mesh_upgrade.set_mesh_upgrade_info(upgrade_data,lime_mesh_upgrade.upgrade_states.STARTING)
        status = lime_mesh_upgrade.get_mesh_upgrade_status()
        utils.printJson(status)
        assert.is.equal(status.master_node, upgrade_data.master_node)
        assert.is.equal(status.data.repo_url,upgrade_data.data.repo_url )
        assert.is.equal(status.data.upgrade_state, lime_mesh_upgrade.upgrade_states.ERROR)
        assert.is.equal(status.data.eup_STATUS, eupgrade.STATUS_DOWNLOAD_FAILED)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.STARTED)
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