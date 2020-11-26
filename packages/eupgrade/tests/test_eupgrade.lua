local utils = require "lime.utils"
local test_utils = require "tests.utils"
local eup = require "eupgrade"
local json = require 'luci.jsonc'

local uci
local snapshot -- to revert luassert stubs and spies

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

describe('eupgrade tests #eupgrade', function()
    it('test get and set download_satus', function()
        assert.is.equal(eup.STATUS_DEFAULT, eup.get_download_status())
        eup.set_download_status(eup.STATUS_DOWNLOADING)
        assert.is.equal(eup.STATUS_DOWNLOADING, eup.get_download_status())
    end)

    it('test is_new_version_available version is the same as current version', function()
        stub(eup, '_get_board_name', function () return 'test-board' end)
        stub(eup, '_get_current_fw_version', function () return 'LibreMesh 20.10' end)
        stub(eup, '_check_signature', function () return true end)
        stub(utils, 'http_client_get', function () return latest_release_data end)
        assert.is_false(eup.is_new_version_available())
    end)

    it('test is_new_version_available latest version is not the same as current version', function()
        stub(eup, '_get_board_name', function () return 'test-board' end)
        stub(eup, '_get_current_fw_version', function () return 'LibreMesh 19.05' end)
        stub(eup, '_check_signature', function () return true end)
        stub(utils, 'http_client_get', function () return latest_release_data end)
        assert.is.equal('LibreMesh 20.10', eup.is_new_version_available()['version'])
    end)

    it('test is_new_version_available latest version is not the same as current version', function()
        stub(eup, '_get_board_name', function () return 'test-board' end)
        stub(eup, '_get_current_fw_version', function () return 'LibreMesh 19.05' end)
        stub(eup, '_check_signature', function () return false end)
        stub(utils, 'http_client_get', function () return latest_release_data end)
        status, message = eup.is_new_version_available()
        assert.is_nil(status)
        assert.is.equal("Bad signature of firmware_latest.json", message)
    end)

    it('test is_new_version_available unable to download info', function()
        stub(eup, '_get_board_name', function () return 'test-board' end)
        stub(eup, '_get_current_fw_version', function () return 'LibreMesh 19.05' end)
        stub(utils, 'http_client_get', function () return nil end)
        status, message = eup.is_new_version_available()
        assert.is_nil(status)
        assert.is.equal("Can't download latest info from: latest/test-board.json", message)
    end)

    it('test download_firmware bad hash', function()
        stub(eup, '_file_sha256', function () return 'faaa' end)
        stub(utils, 'http_client_get', function () return true end)
        local latest_data = json.parse(latest_release_data)
        status, message = eup.download_firmware(latest_data)
        assert.is_nil(status)
        assert.is.equal('Error: the sha256 does not match', message)
        assert.is.equal(eup.STATUS_DOWNLOAD_FAILED, eup.get_download_status())
    end)

    it('test download_firmware ok', function()
        stub(eup, '_file_sha256', function () return 'fbd95fce091ea10cfa05cfb0ef870da43124ac7c1402890eb8f03b440c57d7b5' end)
        stub(utils, 'http_client_get', function () return true end)
        local latest_data = json.parse(latest_release_data)
        assert.is.not_nil(eup.download_firmware(latest_data))
        assert.is.equal(eup.STATUS_DOWNLOADED, eup.get_download_status())
    end)

    it('test download_firmware while downloading', function()
        eup.set_download_status(eup.STATUS_DOWNLOADING)
        status, message = eup.download_firmware()
        assert.is_nil(status)
        assert.is.equal("Already downloading", message)
        assert.is.equal(eup.STATUS_DOWNLOADING, eup.get_download_status())
    end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
        eup.set_workdir(test_utils.setup_test_dir())
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
        test_utils.teardown_test_dir()
    end)
end)
