local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local JSON = require("luci.jsonc")
local uci = nil

--package.path = package.path .. ";packages/shared-state-bat_links_info/files/usr/share/shared-state/hooks/bat_links_info_ref/?;;"
--require ("shared-state-update_refstate")

describe('bat links ref state tests', function()

    it('test obj store', function()
        local function write_if_diff(data_type, input)
            path = ref_file_folder .. data_type
            local acutal = JSON.parse(utils.read_file(path))
            if input[utils.hostname()] then
                if not(utils.deepcompare(input[utils.hostname()],acutal or {})) then
                    utils.write_file(path,JSON.stringify(input[utils.hostname()]))
                    utils.unsafe_shell("logger -t shared-sate-ref-state "..data_type.." state changed")
                    return true
                end
            end
            utils.unsafe_shell("logger -t shared-sate-ref-state "..data_type.."  state did not change")
            return false
        end
        
        local test_dir = test_utils.setup_test_dir()
        local testfile = test_dir .. 'mydata'
        assert.is.same({}, utils.read_obj_store(testfile))

        local input=JSON.parse(utils.read_file("packages/shared-state-bat_links_info/tests/sample.json"))
        assert.is_true (write_if_diff(testfile,input))
        assert.is_false (write_if_diff(testfile,input))
       
     end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
        stub(utils, "hostname", function () return "cheche" end)

    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
        test_utils.teardown_test_dir()
    end)

end)