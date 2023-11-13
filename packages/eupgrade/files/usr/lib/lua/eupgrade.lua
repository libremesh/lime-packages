local utils = require "lime.utils"
local json = require "luci.jsonc"
local libuci = require "uci"
local fs = require("nixio.fs")

local eup = {}

eup.STATUS_DEFAULT = 'not-initiated'
eup.STATUS_DOWNLOADING = 'downloading'
eup.STATUS_DOWNLOADED = 'downloaded'
eup.STATUS_DOWNLOAD_FAILED = 'download-failed'


local uci = libuci.cursor()

function eup.set_workdir(workdir)
    if not utils.file_exists(workdir) then
        os.execute('mkdir -p ' .. workdir)
    end
    if fs.stat(workdir, "type") ~= "dir" then
        error("Can't configure workdir " .. workdir)
    end
    eup.WORKDIR = workdir
    eup.DOWNLOAD_INFO_CACHE_FILE = eup.WORKDIR .. '/download_status'
    eup.FIRMWARE_LATEST_JSON = eup.WORKDIR .. "/firmware_latest.json"
    eup.FIRMWARE_LATEST_JSON_SIGNATURE = eup.FIRMWARE_LATEST_JSON .. '.sig'
end

eup.set_workdir("/tmp/eupgrades")

function eup.is_enabled()
    return uci:get('eupgrade', 'main', 'enabled') == '1'
end

function eup.get_upgrade_api_url()
    return uci:get('eupgrade', 'main', 'api_url') or ''
end

function eup.set_upgrade_api_url(url)
    return uci:set('eupgrade', 'main', 'api_url',url)
end

function eup._check_signature(file_path, signature_path)
    local cmd = string.format("usign -q -V -P /etc/opkg/keys -x %s -m %s",
                              signature_path, file_path)
    local exit_status = os.execute(cmd)
    return exit_status == 0
end

function eup._get_board_name()
    return utils.read_file("/tmp/sysinfo/board_name"):gsub("\n","")
end

function eup._get_current_fw_version()
    return utils.release_info()["DISTRIB_DESCRIPTION"]
end

function eup._file_sha256(path)
    return utils.unsafe_shell(string.format("sha256sum %s", path)):match("^([^%s]+)")
end


--! check if a new firmware is available for download, returning the information of the version
--! when cached_only is true it will not hit the network (only checking the local cache)
function eup.is_new_version_available(cached_only)
    --! if 'latest' files are present is because there is a new version
    if utils.file_exists(eup.FIRMWARE_LATEST_JSON) and utils.file_exists(eup.FIRMWARE_LATEST_JSON_SIGNATURE) then
        if eup._check_signature(eup.FIRMWARE_LATEST_JSON, eup.FIRMWARE_LATEST_JSON_SIGNATURE) then
            return json.parse(utils.read_file(eup.FIRMWARE_LATEST_JSON))
        end
    end
    if cached_only then
        return false
    end
    local message
    local board_name = eup._get_board_name()
    local current_firmware_version = eup._get_current_fw_version()
    local url = string.format("%slatest/%s.json", eup.get_upgrade_api_url(), utils.slugify(board_name))
    local latest_json = utils.http_client_get(url, 10)
    if not latest_json then
        message = "Can't download latest info from: " .. url
    else
        local latest_data = json.parse(latest_json)
        local version = latest_data['version']

        if version and current_firmware_version ~= version then
            utils.write_file(eup.FIRMWARE_LATEST_JSON, latest_json)
            local sig_url = url .. ".sig"
            if not utils.http_client_get(sig_url, 10, eup.FIRMWARE_LATEST_JSON_SIGNATURE) then
                message = "Can't download signature " .. sig_url
                utils.log(message)
            end

            if eup._check_signature(eup.FIRMWARE_LATEST_JSON, eup.FIRMWARE_LATEST_JSON_SIGNATURE) then
                utils.log("Good signature of firmware_latest.json")
                return latest_data
            else
                message = "Bad signature of firmware_latest.json"
                utils.log(message)
            end
        end
    end
    --! remove the 'latest' files.
    utils.unsafe_shell(string.format('rm -f %s %s', eup.FIRMWARE_LATEST_JSON, eup.FIRMWARE_LATEST_JSON_SIGNATURE))
    return false, message
end

function eup.get_latest_info()
    if utils.file_exists(eup.FIRMWARE_LATEST_JSON) then
        return json.parse(utils.read_file(eup.FIRMWARE_LATEST_JSON))
    end
end

function eup.get_downloaded_info()
    local latest_data = eup.get_latest_info()
    if latest_data then
        for _, image in pairs(latest_data['images']) do
            local fw_type = image['type']
            local firmware_path = eup.WORKDIR .. "/" .. image['name']
            if utils.file_exists(firmware_path) then
                return firmware_path, fw_type
            end
        end
    end
end

function eup.set_download_status(status)
    return utils.write_obj_store_var(eup.DOWNLOAD_INFO_CACHE_FILE, 'status', status)
end

function eup.get_download_status()
    local data = utils.read_obj_store(eup.DOWNLOAD_INFO_CACHE_FILE)
    if data.status == nil then
        return eup.STATUS_DEFAULT
    else
        return data.status
    end
end

function eup.download_firmware(latest_data)
    if eup.get_download_status() == eup.STATUS_DOWNLOADING then
        return nil, "Already downloading"
    end

    local image, message

    -- Select the image type, discarding unknown types. Prefer image installer over sysupgrade
    for _, im in pairs(latest_data['images']) do
        if im['type'] == 'installer' then
            image = im
            break
        elseif im['type'] == 'sysupgrade' then
            image = im
        end
    end

    if image then
        eup.set_download_status(eup.STATUS_DOWNLOADING)
        for _, url in pairs(image['download-urls']) do
            if not string.match(url, "://") then
                url = eup.get_upgrade_api_url() .. url
            end
            utils.log("Downloading the firmware from " .. url)

            local firmware_path = eup.WORKDIR .. "/" .. image['name']
            local download_status = utils.http_client_get(url, 10, firmware_path)
            if download_status then
                if image['sha256'] ~= eup._file_sha256(firmware_path) then
                    message = "Error: the sha256 does not match"
                    utils.log(message)
                    utils.unsafe_shell('rm -f ' .. firmware_path)
                else
                    utils.log("Firmware downloaded ok")
                    eup.set_download_status(eup.STATUS_DOWNLOADED)
                    return image
                end
            end
        end
    end

    eup.set_download_status(eup.STATUS_DOWNLOAD_FAILED)
    return nil, message
end

return eup
