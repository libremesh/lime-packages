local config = require 'lime.config'
local lime_mesh_upgrade = require 'lime-mesh-upgrade'
local network = require("lime.network")
local utils = require "lime.utils"
local test_utils = require "tests.utils"
local eup = require "eupgrade"
local json = require 'luci.jsonc'

eupgrade = require 'eupgrade'

utils.enable_logging()

-- disable logging in config module
config.log = function(text)
    print(text)
end

local uci

local upgrade_data = {
    type = "upgrade",
    data = {
        firmware_ver = "xxxx",
        repo_url = "http://repo.librerouter.org/lros/api/v1/latest/",
        upgrde_state = "starting,downloading|ready_for_upgrade|upgrade_scheluded|confirmation_pending|~~confirmed~~|updated|error",
        error = "CODE",
        safe_upgrade_status = "",
        eup_STATUS = ""
    },
    timestamp=231354654,
    id=21,
    transaction_state="started/aborted/finished",
    master_node="primero"
}

local latest_release_data = [[
{
    "metadata-version": 1,
    "images": [
        {
        "name": "upgrade-lr-1.5.sh",
        "type": "installer",
        "download-urls": [
            "http://repo.librerouter.org/lros/releases/1.5/targets/ath79/generic/upgrade-lr-1.5.sh"
        ],
        "sha256": "cec8920f93055cc57cfde1f87968e33ca5215b2df88611684195077402079acb"
        },
        {
        "name": "firmware.bin",
        "type": "sysupgrade",
        "download-urls": [
            "http://repo.librerouter.org/lros/releases/1.5/targets/ath79/generic/librerouteros-1.5-r0+11434-e93615c947-ath79-generic-librerouter_librerouter-v1-squashfs-sysupgrade.bin"
            ],
        "sha256": "2da0abb549d6178a7978b357be3493d5aff5c07b993ea0962575fa61bef18c27"
        }
    ],
    "board": "test-board",
    "version":  "LibreRouterOs 1.5",
    "release-info-url": "https://foro.librerouter.org/t/lanzamiento-librerouteros-1-5/337"
}    
]]

local latest_release_data_real = [[
{
    "metadata-version": 1,
    "images": [
    {
    "name": "upgrade-lr-1.5.sh",
    "type": "installer",
    "download-urls": [
        "http://repo.librerouter.org/lros/releases/1.5/targets/ath79/generic/upgrade-lr-1.5.sh"
    ],
    "sha256": "cec8920f93055cc57cfde1f87968e33ca5215b2df88611684195077402079acb"
    },
        {
        "name": "firmware.bin",
        "type": "sysupgrade",
        "download-urls": [
            "http://repo.librerouter.org/lros/releases/1.5/targets/ath79/generic/librerouteros-1.5-r0+11434-e93615c947-ath79-generic-librerouter_librerouter-v1-squashfs-sysupgrade.bin"
            ],
        "sha256": "2da0abb549d6178a7978b357be3493d5aff5c07b993ea0962575fa61bef18c27"
        }
    ],
    "board": "librerouter,librerouter-v1",
    "version":  "LibreRouterOs 1.5 r0+11434-e93615c947",
    "release-info-url": "https://foro.librerouter.org/t/lanzamiento-librerouteros-1-5/337"
}
    
]]
local latest_release_data_real_sig = [[
untrusted comment: signed by key 47513b83fbc579cd
RWRHUTuD+8V5zSCR6+HGnzSU8qhf1d8K8PqOCo/OYLFAXBeiICUXV33BY3o1ihDWcGbFTBLh8jidfhSkWQev5NoT1PTOTOLvZwc=
]]
local api_url = 'http://repo.librerouter.org/lros/releases/'


describe('LiMe mesh upgrade', function()

    it('test get mesh config fresh start', function()
        config.log("\n test set mesh config.... \n")
        local status = lime_mesh_upgrade.get_mesh_upgrade_status()
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.NO_TRANSACTION)
        assert.is.equal(lime_mesh_upgrade.started(), false)
    end)

    it('test set mesh config and get status', function()
        stub(eupgrade, '_get_board_name', function()
            return 'test-board'
        end)
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 19.05'
        end)
        stub(eupgrade, '_check_signature', function()
            return true
        end)
        stub(utils, 'http_client_get', function()
            return latest_release_data
        end)
        stub(eupgrade, '_file_sha256', function()
            return 'fbd95fc091ea10cfa05cfb0ef870da43124ac7c1402890eb8f03b440c57d7b5'
        end)

        assert.is.equal('LibreRouterOs 1.5', eupgrade.is_new_version_available()['version'])
        lime_mesh_upgrade.set_mesh_upgrade_info(upgrade_data, lime_mesh_upgrade.upgrade_states.STARTING)
        stub(eupgrade, '_get_board_name', function () return 'test-board' end)
        stub(eupgrade, '_get_current_fw_version', function () return 'LibreMesh 1.4' end)
        stub(eupgrade, '_check_signature', function () return true end)
        stub(utils, 'http_client_get', function () return latest_release_data end)
        assert.is.equal('LibreRouterOs 1.5', eupgrade.is_new_version_available()['version'])

        lime_mesh_upgrade.set_mesh_upgrade_info(upgrade_data,lime_mesh_upgrade.upgrade_states.STARTING)
        status = lime_mesh_upgrade.get_mesh_upgrade_status()
        assert.is.equal(status.master_node, upgrade_data.master_node)
        assert.is.equal(status.data.repo_url, upgrade_data.data.repo_url)
        assert.is.equal(status.data.upgrade_state, lime_mesh_upgrade.upgrade_states.ERROR)
        assert.is.equal(status.data.eup_STATUS, eupgrade.STATUS_DOWNLOAD_FAILED)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.STARTED)
        -- assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.ABORTED)
        -- TODO: javi en caso de falla ... reintentar ? abortar ? 
    end)
    it('test set mesh config start download and assert status ready_for_upgrade', function()
        stub(eupgrade, '_get_board_name', function()
            return 'test-board'
        end)
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 19.05'
        end)
        stub(eupgrade, '_check_signature', function()
            return true
        end)
        stub(utils, 'http_client_get', function()
            return latest_release_data
        end)
        stub(eupgrade, '_file_sha256', function()
            return 'cec8920f93055cc57cfde1f87968e33ca5215b2df88611684195077402079acb'
        end)

        assert.is.equal('LibreRouterOs 1.5', eupgrade.is_new_version_available()['version'])
        lime_mesh_upgrade.set_mesh_upgrade_info(upgrade_data, lime_mesh_upgrade.upgrade_states.STARTING)
        status = lime_mesh_upgrade.get_mesh_upgrade_status()
        utils.printJson(status)
        assert.is.equal(status.master_node, upgrade_data.master_node)
        assert.is.equal(status.data.repo_url, upgrade_data.data.repo_url)
        assert.is.equal(status.data.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        assert.is.equal(status.data.eup_STATUS, eupgrade.STATUS_DOWNLOADED)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.STARTED)
    end)

    it('test set mesh config start download and assert status ready_for_upgrade', function()
        stub(eupgrade, '_get_board_name', function()
            return 'librerouter-v1'
        end)
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 19.05'
        end)
        stub(eupgrade, '_check_signature', function()
            return true
        end)
        stub(eupgrade, '_file_sha256', function()
            return 'cec8920f93055cc57cfde1f87968e33ca5215b2df88611684195077402079acb'
        end)
        -- todo: javi este netodo no seria necesario que sea stub porque deberia tomar la url del set upgrade api pero no toma el config uci
        stub(eupgrade, 'get_upgrade_api_url', function()
            return 'http://repo.librerouter.org/lros/api/v1/'
        end)
        stub(utils, 'http_client_get', function(url, to, file)
            config.log("http_client_get " .. url .. "  " .. to .. (args or ""))
            if url == "http://repo.librerouter.org/lros/releases/1.5/targets/ath79/generic/upgrade-lr-1.5.sh" then
                return true
            end
            if url == "http://repo.librerouter.org/lros/api/v1/latest/librerouter-v1.json.sig" then
                return latest_release_data_real_sig
            end
            if url == "http://repo.librerouter.org/lros/api/v1/latest/librerouter-v1.json" then
                return latest_release_data_real
            end
            config.log("http_client_get " .. url .. "  " .. to .. (args or ""))
            config.log("http_client_get " .. url .. "  " .. to .. (args or ""))
            config.log("http_client_get " .. url .. "  " .. to .. (args or ""))
            config.log("http_client_get " .. url .. "  " .. to .. (args or ""))
            config.log("http_client_get " .. url .. "  " .. to .. (args or ""))

            return true
        end)
        -- assert.is.equal('LibreRouterOs 1.5 r0+11434-e93615c947', eupgrade.is_new_version_available()['version'])
        lime_mesh_upgrade.set_mesh_upgrade_info(upgrade_data, lime_mesh_upgrade.upgrade_states.STARTING)
        status = lime_mesh_upgrade.get_mesh_upgrade_status()
        utils.printJson(status)
        assert.is.equal(status.master_node, upgrade_data.master_node)
        assert.is.equal(status.data.repo_url, upgrade_data.data.repo_url)
        assert.is.equal(status.data.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        assert.is.equal(status.data.eup_STATUS, eupgrade.STATUS_DOWNLOADED)
        assert.is.equal(status.transaction_state, lime_mesh_upgrade.transaction_states.STARTED)
    end)

    it('test custom latest json file is created', function()
        stub(network, 'primary_address', function () return '10.13.0.1', 'ipv6' end)
        lime_mesh_upgrade.create_local_latest_json(json.parse(latest_release_data))
        local filexists = utils.file_exists(lime_mesh_upgrade.LATEST_JSON_PATH)
        assert(filexists, "File not found: " .. lime_mesh_upgrade.LATEST_JSON_PATH)
    end)

    it('test set_up_firmware_repository download the files correctly and fix the url on json', function()
        stub(network, 'primary_address', function () return '10.13.0.1', 'ipv6' end)
        lime_mesh_upgrade.create_local_latest_json(json.parse(latest_release_data))
        local latest = json.parse(utils.read_file(lime_mesh_upgrade.LATEST_JSON_PATH))
        local repo_url = lime_mesh_upgrade.FIRMWARE_REPO_PATH
        for _, im in pairs(latest['images']) do
            for a, url in pairs(im['download-urls']) do
                assert(string.find(url, repo_url))
            end
        end
    end)

    it('test that link properly the files downloaded by eupgrade to desired destination', function()
        -- Create some dummy files
        local files = {"file1", "file2", "file3"}
        local dest = "/tmp/www" .. lime_mesh_upgrade.FIRMWARE_REPO_PATH
        -- Delete previous links if exist
        os.execute("rm -rf " .. dest)
        for _, f in pairs(files) do
            utils.write_file(eupgrade.WORKDIR .. "/" .. f, "dummy")
        end
        lime_mesh_upgrade.share_firmware_packages(dest)
        -- Check if all files exist in the destination folder
        for _, f in pairs(files) do
            local file_path = dest .. "/" .. f
            local file_exists = utils.file_exists(file_path)
            assert(file_exists, "File not found: " .. file_path)
        end
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
        test_utils.teardown_test_dir()
    end)
end)
