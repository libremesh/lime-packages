local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local JSON = require("luci.jsonc")
local uci = nil

--package.path = package.path .. ";packages/shared-state-bat_links_info/files/usr/share/shared-state/hooks/bat_links_info_ref/?;;"
--require ("shared-state-update_refstate")

local wifi_links_info_sample = [[

{
    "LiMe-b713f7": {
        "ae40411c8516ae40411df935": {
            "freq": 5240,
            "iface": "wlan1-mesh",
            "tx_rate": 300000,
            "dst_mac": "ae:40:41:1c:85:16",
            "channel": 48,
            "chains": [
                -56,
                -57
            ],
            "signal": -54,
            "rx_rate": 270000,
            "src_mac": "ae:40:41:1d:f9:35"
        },
        "ae40411c85c3ae40411df934": {
            "freq": 5785,
            "iface": "wlan2-mesh",
            "tx_rate": 300000,
            "dst_mac": "ae:40:41:1c:85:c3",
            "channel": 157,
            "chains": [
                -43,
                -41
            ],
            "signal": -39,
            "rx_rate": 300000,
            "src_mac": "ae:40:41:1d:f9:34"
        }
    },
    "cheche": {
        "ae40411c8516ae40411df935": {
            "freq": 5240,
            "iface": "wlan1-mesh",
            "tx_rate": 243000,
            "dst_mac": "ae:40:41:1d:f9:35",
            "channel": 48,
            "chains": [
                -58,
                -58
            ],
            "signal": -55,
            "rx_rate": 300000,
            "src_mac": "ae:40:41:1c:85:16"
        },
        "ae40411c85c3ae40411df934": {
            "freq": 5785,
            "iface": "wlan2-mesh",
            "tx_rate": 300000,
            "dst_mac": "ae:40:41:1d:f9:34",
            "channel": 157,
            "chains": [
                -42,
                -45
            ],
            "signal": -40,
            "rx_rate": 300000,
            "src_mac": "ae:40:41:1c:85:c3"
        }
    }
}
]]
describe('bat links ref state tests', function()

    it('test obj store', function()
        local function write_if_diff(data_type, input)
            path = ref_file_folder .. data_type
            local acutal = JSON.parse(utils.read_file(path))
            if input[utils.hostname()] then
                if not(utils.deepcompare(input[utils.hostname()],acutal or {})) then
                    utils.write_file(path,JSON.stringify(input[utils.hostname()]))
                    utils.unsafe_shell("logger -t shared-state-ref-state "..data_type.." state changed")
                    return true
                end
            end
            utils.unsafe_shell("logger -t shared-state-ref-state "..data_type.."  state did not change")
            return false
        end
        
        local test_dir = test_utils.setup_test_dir()
        ref_file_folder = test_dir
        local testfile = test_dir .. 'mydata'
        utils.write_file(testfile,"{}")
        assert.is.same("{}", utils.read_file(testfile))

        local input=JSON.parse(utils.read_file("packages/shared-state-bat_links_info/tests/sample.json"))
        assert.is_true (write_if_diff("mydata",input))
        assert.is.same('[{"dst_mac":"02:ab:46:dd:69:1c","last_seen_msecs":20,"tq":255,"iface":"wlan1-mesh_29","src_mac":"02:ab:46:1f:73:aa"},{"dst_mac":"02:ab:46:43:0b:0c","last_seen_msecs":1300,"tq":251,"iface":"wlan1-mesh_29","src_mac":"02:ab:46:1f:73:aa"},{"dst_mac":"02:cc:4e:43:0b:0c","last_seen_msecs":900,"tq":242,"iface":"wlan2-mesh_29","src_mac":"02:cc:4e:1f:73:aa"},{"dst_mac":"02:58:47:dd:69:1c","last_seen_msecs":1460,"tq":255,"iface":"wlan0-mesh_29","src_mac":"02:58:47:1f:73:aa"},{"dst_mac":"02:58:47:1f:73:f6","last_seen_msecs":520,"tq":255,"iface":"wlan0-mesh_29","src_mac":"02:58:47:1f:73:aa"}]', utils.read_file(testfile))
        assert.is_false (write_if_diff("mydata",input))
        assert.is_true (write_if_diff("mydata",JSON.parse(wifi_links_info_sample  )))

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
