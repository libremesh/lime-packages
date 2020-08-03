local vouchera = require('voucher.vouchera')
local utils = require('voucher.utils')

handlers = {}

local TESTING_URL_INFO = '/info'
local TESTING_URL_FAIL = '/fail'
local TESTING_URL_AUTHENTICATED = '/authenticated'


function handlers.preactivate_voucher()
    local uci_cursor = require('uci').cursor()

    --! using defaults for testing as uci environment is not available
    local url_authenticated = uci_cursor:get("pirania", "base_config", "url_authenticated") or TESTING_URL_AUTHENTICATED
    local url_fail = uci_cursor:get("pirania", "base_config", "url_fail") or TESTING_URL_FAIL
    local url_info = uci_cursor:get("pirania", "base_config", "url_info") or TESTING_URL_INFO

    vouchera.init()

    local url

    local client_data = utils.getIpv4AndMac(os.getenv('REMOTE_ADDR'))
    local client_is_authorized = vouchera.is_mac_authorized(client_data.mac)

    if client_is_authorized then
        url = url_authenticated
    else
        local output
        local params = utils.urldecode_params(os.getenv("QUERY_STRING"))
        local code = params['voucher']
        local prevUrl = params['prev']
        --! if client does not have javascript then activate right away without going to the INFO portal
        if params['nojs'] == 'true' then
            if vouchera.activate(code, client_data.mac) then
                url = url_authenticated
            else
                url = url_fail
            end
        else
            local setParams = prevUrl and '?voucher=' .. code .. '&prev=' .. prevUrl or '?voucher=' .. code
            --! redirect to the INFO portal for some seconds with the url params already set to activate
            --! the voucher after this time
            if vouchera.is_activable(code) then
                url = url_info .. setParams
            else
                url = url_fail
            end
        end
    end
    return url
end

function handlers.activate_voucher()
    local uci_cursor = require('uci').cursor()

    local url_authenticated = uci_cursor:get("pirania", "base_config", "url_authenticated") or TESTING_URL_AUTHENTICATED
    local url_fail = uci_cursor:get("pirania", "base_config", "url_fail") or TESTING_URL_FAIL

    vouchera.init()
    local client_data = utils.getIpv4AndMac(os.getenv('REMOTE_ADDR'))
    local client_is_authorized = vouchera.is_mac_authorized(client_data.mac)

    local params = utils.urldecode_params(os.getenv("QUERY_STRING"))
    local code = params['voucher']
    local prevUrl = params['prev']

    if client_is_authorized then
        return url_authenticated
    end

    local url = url_fail

    if code and client_data.mac then
        if vouchera.activate(code, client_data.mac) then
            if prevUrl ~= nil then
                url = prevUrl
            else
                url = url_authenticated
            end
        end
    end
    return url
end

return handlers
