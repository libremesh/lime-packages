local config = require 'lime.config'
local eupgrade = require 'eupgrade'

local boardname = 'librerouter-v1'
stub(eupgrade, '_get_board_name', function()
    return boardname
end)

local mesh_wide_sample = [[
    {
        "LiMe-8a50aa": {
            "eupgradestate": "not-initiated",
            "confirm_remining": -1,
            "safeupgrade_start_remining": -1,
            "safeupgrade_start_mark": 0,
            "upgrade_state": "UPGRADE_SCHEDULED",
            "current_fw": "LibreRouterOs 23.05-SNAPSHOT r1+1-48c81b80b2",
            "main_node": "NO",
            "node_ip": "10.13.80.170",
            "board_name": "librerouter,librerouter-v1",
            "su_start_time_out": 0,
            "timestamp": 0,
            "error": "0",
            "retry_count": 0
        },
        "LiMe-a51ed1": {
            "repo_url": "http://10.13.80.170/lros/",
            "confirm_remining": -1,
            "candidate_fw": "LibreRouterOs r23744",
            "safeupgrade_start_remining": -1,
            "safeupgrade_start_mark": 0,
            "retry_count": 0,
            "upgrade_state": "ERROR",
            "current_fw": "LibreRouterOs 23.05-SNAPSHOT r1+1-48c81b80b2",
            "main_node": "NO",
            "node_ip": "10.13.30.209",
            "board_name": "librerouter,librerouter-v1",
            "su_start_time_out": 0,
            "timestamp": 1713282042,
            "error": "no_latest_data_available",
            "eupgradestate": "not-initiated"
        }
    }
    
]]

confirm_remaining = -1

stub(utils, 'unsafe_shell', function(command)
    if command == "safe-upgrade confirm-remaining" then
    return confirm_remaining
    elseif command == "shared-state-async get mesh_wide_upgrade" then
        return mesh_wide_sample
    end
    print(command)
    return confirm_remaining

end)



local utils = require "lime.utils"
local lime_mesh_upgrade = {}
local test_utils = require "tests.utils"
local json = require 'luci.jsonc'
local uci

local upgrade_data = {
    candidate_fw = "xxxx",
    repo_url = "http://repo.librerouter.org/lros/api/v1/latest/",
    upgrade_state = "READY_FOR_UPGRADE",
    error = "CODE",
    main_node = "true",
    timestamp = 02,
    current_fw = "LibreRouterOs 1.5 r0+11434-e93615c947",
    board_name = "qemu-standard-pc-i440fx-piix-1996"
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

describe('LiMe mesh upgrade', function()

    it('test get mesh config fresh start', function()
        local fw_version = 'LibreMesh 19.02'
        stub(eupgrade, '_get_current_fw_version', function()
            return fw_version
        end)
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.DEFAULT)
        assert.is.equal(status.main_node, lime_mesh_upgrade.main_node_states.NO)
        assert.is.equal(status.current_fw, fw_version)
        assert.is.equal(status.board_name, boardname)
        assert.is.equal(lime_mesh_upgrade.started(), false)
    end)

    it('test set error ', function()
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 19.05'
        end)
        lime_mesh_upgrade.report_error(lime_mesh_upgrade.errors.CONFIRMATION_TIME_OUT)
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.error, lime_mesh_upgrade.errors.CONFIRMATION_TIME_OUT)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.ERROR)
    end)

    it('test abort ', function()
        stub(utils, 'execute_daemonized', function()
        end)
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 19.05'
        end)
        stub(utils, 'hostname', function()
            return "LiMe-8a50aa"
        end)
        lime_mesh_upgrade.mesh_upgrade_abort()
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.ABORTED)
        assert.stub.spy(utils.execute_daemonized).was.called.with("sleep 30; \
        /etc/shared-state/publishers/shared-state-publish_mesh_wide_upgrade && shared-state-async sync mesh_wide_upgrade")
    end)

    it('test set upgrade info and fail NO_LATEST_AVAILABLE', function()
        stub(eupgrade, '_check_signature', function()
            return true
        end)
        stub(eupgrade, '_file_sha256', function()
            return 'fbd95fc091ea10cfa05cfb0ef870da43124ac7c1402890eb8f03b440c57d7b5'
        end)
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 1.4'
        end)
        lime_mesh_upgrade.become_bot_node(upgrade_data)
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, lime_mesh_upgrade.main_node_states.NO)
        assert.is.equal(status.repo_url, upgrade_data.repo_url)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.ERROR)
        assert.is.equal(status.error, lime_mesh_upgrade.errors.NO_LATEST_AVAILABLE)
    end)

    it('test set upgrade info and fail to download', function()
        stub(eupgrade, '_check_signature', function()
            return true
        end)
        stub(utils, 'http_client_get', function()
            return latest_release_data
        end)
        stub(eupgrade, '_file_sha256', function()
            return 'fbd95fc091ea10cfa05cfb0ef870da43124ac7c1402890eb8f03b440c57d7b5'
        end)
        stub(eupgrade, '_get_current_fw_version', function()
            return 'LibreMesh 1.4'
        end)
        assert.is.equal('LibreRouterOs 1.5', eupgrade.is_new_version_available()['version'])
        lime_mesh_upgrade.become_bot_node(upgrade_data)
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, lime_mesh_upgrade.main_node_states.NO)
        assert.is.equal(status.repo_url, upgrade_data.repo_url)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.ERROR)
        assert.is.equal(status.error, lime_mesh_upgrade.errors.DOWNLOAD_FAILED)
    end)

    it('test become botnode and assert status ready_for_upgrade', function()
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
        lime_mesh_upgrade.become_bot_node(upgrade_data)
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, upgrade_data.main_node)
        assert.is.equal(status.repo_url, upgrade_data.repo_url)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
    end)

    it('test become botnode and assert status ready_for_upgrade', function()
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

        uci = test_utils.setup_test_uci()
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', "upgrade_state", "UPGRADE_SCHEDULED")
        uci:save('mesh-upgrade')
        utils.log("about to become bot node")
        assert.is.equal('LibreRouterOs 1.5', eupgrade.is_new_version_available()['version'])
        lime_mesh_upgrade.become_bot_node(upgrade_data)
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, upgrade_data.main_node)
        --assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.ERROR)

        utils.log("about to become bot node seccond time")
        uci = test_utils.setup_test_uci()
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', "upgrade_state", "CONFIRMED")
        uci:save('mesh-upgrade')

        lime_mesh_upgrade.become_bot_node(upgrade_data)
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, upgrade_data.main_node)
        --assert.is.equal(status.repo_url, upgrade_data.repo_url)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)

    end)

    it('test get fw path', function()

        local fw_path = lime_mesh_upgrade.get_fw_path()
        assert.is.equal(fw_path, " ")

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
        stub(utils, 'file_exists', function()
            return true
        end)

        lime_mesh_upgrade.become_bot_node(upgrade_data)
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, upgrade_data.main_node)
        assert.is.equal(status.repo_url, upgrade_data.repo_url)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        local fw_path = lime_mesh_upgrade.get_fw_path()
        assert.is.equal(fw_path, '/tmp/eupgrades/upgrade-lr-1.5.sh')

    end)

    it('test become main node changes the state to STARTING', function()
        stub(eupgrade, 'is_new_version_available', function()
            return json.parse(latest_release_data)
        end)
        stub(lime_mesh_upgrade, 'start_main_node_repository', function()
        end)
        stub(eupgrade, '_get_current_fw_version', function()
        end)
        local res = lime_mesh_upgrade.become_main_node()
        assert.is.equal(res.code, 'SUCCESS')
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.main_node, lime_mesh_upgrade.main_node_states.STARTING)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.DOWNLOADING)
    end)

    it('test custom latest json file is created', function()
        lime_mesh_upgrade.create_local_latest_json(json.parse(latest_release_data))
        local filexists = utils.file_exists(lime_mesh_upgrade.LATEST_JSON_PATH)
        assert(filexists, "File not found: " .. lime_mesh_upgrade.LATEST_JSON_PATH)
    end)

    it('test set_up_firmware_repository download the files correctly and fix the url on json', function()

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
        -- Create latest json file also
        utils.write_file(lime_mesh_upgrade.LATEST_JSON_PATH, "dummy")
        -- Create the links
        lime_mesh_upgrade.share_firmware_packages(dest)
        -- Check if all files exist in the destination folder
        for _, f in pairs(files) do
            local file_path = dest .. "/" .. f
            local file_exists = utils.file_exists(file_path)
            assert(file_exists, "File not found: " .. file_path)
        end
        -- Check that the local json file is also there
        local json_link = dest .. "latest/" .. lime_mesh_upgrade.LATEST_JSON_FILE_NAME
        local file_exists = utils.file_exists(json_link)
        assert(file_exists, "File not found: " .. json_link)
    end)

    it('test become main node change state to READY_FOR_UPGRADE', function()
        config.set('network', 'lime')
        config.set('network', 'main_ipv4_address', '10.1.1.0/16')
        config.set('network', 'main_ipv6_address', 'fd%N1:%N2%N3:%N4%N5::/64')
        config.set('network', 'protocols', {'lan'})
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        uci:commit('lime')

        stub(eupgrade, 'is_new_version_available', function()
            return json.parse(latest_release_data)
        end)
        stub(lime_mesh_upgrade, 'start_main_node_repository', function()
        end)
        stub(eupgrade, '_get_current_fw_version', function()

        end)
        local dest = "/tmp/www" .. lime_mesh_upgrade.FIRMWARE_REPO_PATH
        -- Delete previous links if exist
        os.execute("rm -rf /tmp/www/lros/")
        lime_mesh_upgrade.FIRMWARE_SHARED_FOLDER = "/tmp/"
        local res = lime_mesh_upgrade.become_main_node('http://repo.librerouter.org/lros/api/v1/')
        assert.is.equal(res.code, 'SUCCESS')
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.DOWNLOADING)
        lime_mesh_upgrade.start_firmware_upgrade_transaction()
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        assert.is.equal(status.candidate_fw, json.parse(latest_release_data).version)
        assert.is.equal(status.board_name, boardname)
        assert.is.equal(status.main_node, lime_mesh_upgrade.main_node_states.MAIN_NODE)
        assert.is.equal(status.repo_url, 'http://10.5.0.5/lros/')
    end)

    it('test start_safe_upgrade default timeouts', function()

        stub(utils, 'execute_daemonized', function()
        end)

        stub(utils, 'file_exists', function()
            return true
        end)
        
        stub(os, 'execute', function()
            return 0
        end)

        stub(lime_mesh_upgrade, 'get_fw_path', function()
            return "/tmp/foo.bar"
        end)

        local fw_version = 'LibreMesh 19.02'
        stub(eupgrade, '_get_current_fw_version', function()
            return fw_version
        end)
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', "upgrade_state", "READY_FOR_UPGRADE")
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')
        local status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.READY_FOR_UPGRADE)
        
        assert.is.equal(lime_mesh_upgrade.su_confirm_timeout, 600)
        assert.is.equal(lime_mesh_upgrade.su_start_time_out, 60)
        --should be called from rpcd
        local response = lime_mesh_upgrade.start_safe_upgrade()
        assert.is.equal(response.code,"SUCCESS")
        assert.is.equal(response.su_confirm_timeout,600)
        assert.is.equal(response.su_start_time_out,60)
        assert.stub.spy(utils.execute_daemonized).was.called.with(
             "sleep 60; safe-upgrade upgrade --reboot-safety-timeout=600 /tmp/foo.bar")

        status = lime_mesh_upgrade.get_node_status()

        assert.stub.spy(utils.execute_daemonized).was.called.with(
            "sleep 1; \
        /etc/shared-state/publishers/shared-state-publish_mesh_wide_upgrade && shared-state-async sync mesh_wide_upgrade")

        assert.is.equal(lime_mesh_upgrade.su_confirm_timeout, 600)
        assert.is.equal(status.su_start_time_out, 60)
        assert(status.safeupgrade_start_remining<61 and status.safeupgrade_start_remining>1)
        assert.is.equal(status.confirm_remining,-1)
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.UPGRADE_SCHEDULED)

        --after reboot confirm confirm_remaining will be grater than 0 
        confirm_remaining = 10
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.CONFIRMATION_PENDING)
        
        lime_mesh_upgrade.confirm()
        status = lime_mesh_upgrade.get_node_status()
        assert.is.equal(status.upgrade_state, lime_mesh_upgrade.upgrade_states.CONFIRMED)
    end)

    it('test start_safe_upgrade different timeouts', function()
        stub(utils, 'execute_daemonized', function()
        end)

        stub(utils, 'file_exists', function()
            return true
        end)
        
        stub(os, 'execute', function()
            return 0
        end)

        stub(lime_mesh_upgrade, 'get_fw_path', function()
            return "/tmp/foo.bar"
        end)

        local fw_version = 'LibreMesh 19.02'
        stub(eupgrade, '_get_current_fw_version', function()
            return fw_version
        end)
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', "upgrade_state", "READY_FOR_UPGRADE")
        uci:save('mesh-upgrade')
        uci:commit('mesh-upgrade')

        local response = lime_mesh_upgrade.start_safe_upgrade(10, 100)
        assert.is.equal(response.code,"SUCCESS")

        assert.is.equal(response.su_confirm_timeout, 100)

        assert.is.equal(lime_mesh_upgrade.su_confirm_timeout, 100)
        assert.is.equal(lime_mesh_upgrade.su_start_time_out, 10)

        assert.stub.spy(utils.execute_daemonized).was.called.with(
            "sleep 10; safe-upgrade upgrade --reboot-safety-timeout=100 /tmp/foo.bar")
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        stub(utils, 'hostname', function()
            return "LiMe-8a50aa"
        end)
        lime_mesh_upgrade = require 'lime-mesh-upgrade'

        stub(lime_mesh_upgrade, 'check_safeupgrade_is_working', function(command)
            return true
            end)

        uci = test_utils.setup_test_uci()
        uci:set('mesh-upgrade', 'main', "mesh-upgrade")
        uci:set('mesh-upgrade', 'main', "upgrade_state", "DEFAULT")
        uci:save('mesh-upgrade')
        config.set('network', 'lime')
        config.set('network', 'main_ipv4_address', '10.%N1.0.0/16')
        config.set('network', 'main_ipv6_address', 'fd%N1:%N2%N3:%N4%N5::/64')
        config.set('network', 'protocols', {'lan'})
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')

        uci = config.get_uci_cursor()
        uci:set('network', 'lan', 'interface')
        uci:set('network', 'lan', 'ipaddr', '10.5.0.5')
        uci:set('network', 'lan', 'ip6addr', 'fd0d:fe46:8ce8::ab:cd00/64')
        uci:commit('network')
        
        uci:commit('lime')

        uci:commit('mesh-upgrade')
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
        test_utils.teardown_test_dir()
    end)
end)
