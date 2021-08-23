

local utils = {}

function utils.fake_for_tests()
    local hooks = require('voucher.hooks')
    local config = require('voucher.config')

    config.db_path = '/tmp/pirania_vouchers'
    config.prune_expired_for_days = '30'

    hooks.run = function(action) end
end

return utils

