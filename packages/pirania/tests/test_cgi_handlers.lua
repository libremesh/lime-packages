local test_utils = require 'tests.utils'
local config = require('voucher.config')
config.db_path = '/tmp/pirania'
local vouchera = require('voucher.vouchera')
local handlers = require('voucher.cgi_handlers')
local utils = require('voucher.utils')


function utils.log(...)
    print(...)
end

describe('Vouchera tests #piraniahandlers', function()
    it('', function()
        local function get_env(key)
            if key == 'REMOTE_ADDR' then
                return '10.1.1.1'
            elseif key == 'QUERY_STRING' then
                return 'asdasdasd?voucher=secret_code'
            end
        end
        stub(os, "getenv",  get_env)
        local url = handlers.handle_voucher()
        assert.is.equal('fail', url)
        
        local voucher = vouchera.add({name='myvoucher', code='secret_code', expiration_date=os.time()+1000, 
                                      vtype='renewable'})

        local url = handlers.handle_voucher()
        -- redirecting to info as there is it is a validable code
        assert.is.equal('info?voucher=secret_code', url)        
        os.getenv:revert()
    end)

    after_each('', function()
        local p = io.popen("rm -rf " .. config.db_path)
        p:read('*all')
        p:close()
    end)

end)
