local testUtils = require "tests.utils"
local stub      = require "luassert.stub"

local publisher_file =
  "packages/shared-state-odhcpd_leases/files/usr/share/shared-state/publishers/" ..
  "shared-state-publish_odhcpd_leases"
local run_publisher = testUtils.load_lua_file_as_function(publisher_file)

local captured_json
local ubus_reply

local popen_stub, execute_stub

local function stub_system_calls()
  popen_stub = stub(io, "popen", function(cmd, _)
    if cmd:match("^ubus call dhcp ipv4leases") then
      return { read = function() return "" end, close = function() end }

    elseif cmd:match("^shared%-state%-async insert") then
      return {
        write = function(_, s) captured_json = s end,
        close = function() end
      }

    else
      return { read = function() return "" end, close = function() end }
    end
  end)

  execute_stub = stub(os, "execute", function() return true end)
end

local function revert_system_stubs()
  if popen_stub   then popen_stub:revert()   end
  if execute_stub then execute_stub:revert() end
end

describe("shared-state-odhcpd_leases publisher #odhcpd-leases", function()

  before_each(function()
    captured_json = nil
    ubus_reply    = nil

    package.loaded["luci.jsonc"]  = nil
    package.preload["luci.jsonc"] = function()
      return {
        parse = function() return ubus_reply end,
        stringify = function(tbl)
          if next(tbl) == nil then return "[]" end
          local parts = {}
          for ip, info in pairs(tbl) do
            parts[#parts + 1] = string.format(
              '"%s":{"mac":"%s","hostname":"%s"}',
              ip, info.mac or "", info.hostname or "")
          end
          return "{" .. table.concat(parts, ",") .. "}"
        end
      }
    end

    stub_system_calls()
  end)

  after_each(function()
    revert_system_stubs()
    package.preload["luci.jsonc"] = nil 
  end)

  it("#happy_path publica todas las leases", function()
    ubus_reply = {
      device = {
        eth0 = {
          leases = {
            { address = "10.0.0.5", mac = "aa:bb", hostname = "h1" },
            { address = "10.0.0.6", mac = "cc:dd", hostname = "h2" }
          }
        }
      }
    }

    run_publisher()

    assert.is_string(captured_json, "Se esperaba JSON")
    assert.matches('"10%.0%.0%.5"%s*:%s*{[^}]-"mac"%s*:%s*"aa:bb"', captured_json)
    assert.matches('"10%.0%.0%.6"%s*:%s*{[^}]-"mac"%s*:%s*"cc:dd"', captured_json)
    assert.matches('"hostname"%s*:%s*"h1"', captured_json)
    assert.matches('"hostname"%s*:%s*"h2"', captured_json)
  end)

  it("#empty ante cero leases publica '[]'", function()
    ubus_reply = {}
    run_publisher()
    assert.equals("[]", captured_json)
  end)

  it("#malformed ante parse nil publica '[]'", function()
    ubus_reply = nil
    run_publisher()
    assert.equals("[]", captured_json)
  end)
end)
