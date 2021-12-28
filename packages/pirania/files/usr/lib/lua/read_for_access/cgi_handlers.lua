local utils = require('voucher.utils')
local read_for_access = require('read_for_access.read_for_access')
local portal = require('portal.portal')

handlers = {}
local TESTING_URL_AUTHENTICATED = '/authenticated'

function handlers.authorize_mac()
    local uci_cursor = require('uci').cursor()
    local with_vouchers = portal.get_config().with_vouchers
    if with_vouchers then
        return uci_cursor:get("pirania", "base_config", "url_auth")
    end
    local client_data = utils.getIpv4AndMac(os.getenv('REMOTE_ADDR'))
    read_for_access.authorize_mac(client_data.mac)
    local params = utils.urldecode_params(os.getenv("QUERY_STRING"))
    local url_prev = utils.urldecode(params['prev'])
    local url_authenticated = uci_cursor:get("pirania", "base_config", "url_authenticated") or TESTING_URL_AUTHENTICATED
    return url_prev or url_authenticated
end

return handlers
