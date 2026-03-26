local test_utils = require 'tests.utils'

local CONFIG_PATH = "./packages/pirania/files/etc/config/pirania"
local SCRIPT_PATH = "./packages/pirania/files/usr/bin/captive-portal"
local GLOBAL_ALLOWLIST_URL = "https://raw.githubusercontent.com/HybridNetworks/whatsapp-cidr/refs/heads/main/WhatsApp/whatsapp_cidr_ipv4.txt"
local TRANCA_ALLOWLIST_URL = "https://raw.githubusercontent.com/nickoppen/libremesh-whatsapp-ipv4-allowlist/refs/heads/main/whatsapp_ipv4_cidr.txt"

local test_dir
local bin_dir
local command_succeeds

local function write_file(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

local function read_file(path)
    local file = io.open(path, "r")
    if file == nil then
        return nil
    end

    local content = file:read("*all")
    file:close()
    return content
end

local function write_executable(name, content)
    local path = bin_dir .. name
    write_file(path, content)
    local ok = command_succeeds("chmod +x " .. path)
    assert.is_true(ok)
end

local function write_state(name, content)
    write_file(test_dir .. name, content)
end

command_succeeds = function(cmd)
    local ok, _, code = os.execute(cmd)
    if type(ok) == "number" then
        return ok == 0, ok
    end
    if ok == true then
        return true, code or 0
    end
    return false, code or 1
end

local function run_update(tranca_active, marker_present)
    write_state("tranca_active", tranca_active and "1\n" or "0\n")
    write_state("nft.log", "")
    write_state("wget.log", "")
    write_state("logger.log", "")
    write_state("command.out", "")

    local marker_path = test_dir .. "tranca_marker_present"
    if marker_present then
        write_state("tranca_marker_present", "1\n")
    else
        os.remove(marker_path)
    end

    local cmd = string.format(
        "PATH='%s':\"$PATH\" TEST_ROOT='%s' sh %s update > %s 2>&1",
        bin_dir:sub(1, -2),
        test_dir:sub(1, -2),
        SCRIPT_PATH,
        test_dir .. "command.out"
    )

    local ok, code = command_succeeds(cmd)
    return ok, code, read_file(test_dir .. "command.out") or ""
end

describe('Pirania captive-portal shell tests #captiveportal', function()
    before_each('', function()
        test_dir = test_utils.setup_test_dir()
        bin_dir = test_dir .. "bin/"
        local ok = command_succeeds("mkdir -p " .. bin_dir)
        assert.is_true(ok)

        local uci_script = string.format([[#!/bin/sh
if [ "$1" = "-q" ]; then
    shift
fi

cmd="$1"
key="$2"
test_root="${TEST_ROOT}"

case "$cmd" in
get)
    case "$key" in
        pirania.base_config.enabled) echo "1" ;;
        pirania.base_config.catch_interfaces) echo "wlan0-ap" ;;
        pirania.base_config.catch_bridged_interfaces) echo "" ;;
        pirania.base_config.allowlist_ipv4) echo "10.0.0.0/8 172.16.0.0/12 192.168.0.0/16" ;;
        pirania.base_config.allowlist_ipv4_url) echo "" ;;
        pirania.base_config.allowlist_ipv4_url_insecure) echo "0" ;;
        pirania.base_config.allowlist_ipv6) echo "fc00::/7 fe80::/64 2a00:1508:0a00::/40" ;;
        pirania.tranca_redes.active) cat "$test_root/tranca_active" ;;
        *) exit 1 ;;
    esac
    ;;
show)
    case "$key" in
        pirania.tranca_redes.allowlist_category) echo "pirania.tranca_redes.allowlist_category='messenger'" ;;
        pirania.messenger.ipv4_url) echo "pirania.messenger.ipv4_url='%s'" ;;
        *) exit 1 ;;
    esac
    ;;
*)
    exit 1
    ;;
esac
]], TRANCA_ALLOWLIST_URL)
        write_executable("uci", uci_script)

        write_executable("nft", [[#!/bin/sh
printf '%s\n' "$*" >> "$TEST_ROOT/nft.log"

if [ "$1" = "list" ] && [ "$2" = "chain" ] && [ "$3" = "inet" ] && [ "$4" = "pirania" ] && [ "$5" = "pirania_forward" ]; then
    if [ -f "$TEST_ROOT/tranca_marker_present" ]; then
        printf 'chain pirania_forward {\n'
        printf '    ether saddr @pirania-auth-macs drop comment "TRANCA_BLOCK_AUTH_MAC"\n'
        printf '}\n'
    fi
fi

exit 0
]])

        write_executable("wget", [[#!/bin/sh
url=""
for arg in "$@"; do
    url="$arg"
done
printf '%s\n' "$url" >> "$TEST_ROOT/wget.log"
printf '203.0.113.0/24\n'
exit 0
]])

        write_executable("pirania_authorized_macs", [[#!/bin/sh
if [ "$1" = "--unrestricted" ]; then
    exit 0
fi

printf 'aa:bb:cc:dd:ee:ff\n'
]])

        write_executable("logger", [[#!/bin/sh
printf '%s\n' "$*" >> "$TEST_ROOT/logger.log"
exit 0
]])
    end)

    after_each('', function()
        os.remove("/tmp/allowlist_ipv4_urls.txt")
        test_utils.teardown_test_dir()
    end)

    it('does not ship the legacy WhatsApp global allowlist URL', function()
        local file = assert(io.open(CONFIG_PATH))
        local config = file:read("*all")
        file:close()
        assert.is_nil(string.find(config, GLOBAL_ALLOWLIST_URL, 1, true))
    end)

    it('ignores stale global allowlist cache when no allowlist URL is configured', function()
        write_file("/tmp/allowlist_ipv4_urls.txt", "198.51.100.0/24\n")

        local ok, code, output = run_update(false, false)
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local nft_log = read_file(test_dir .. "nft.log") or ""
        assert.is_nil(string.find(nft_log, '198.51.100.0/24', 1, true))
    end)

    it('rebuilds Tranca rules when active and marker is missing', function()
        local ok, code, output = run_update(true, false)
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local nft_log = read_file(test_dir .. "nft.log") or ""
        local wget_log = read_file(test_dir .. "wget.log") or ""

        assert.is_not_nil(string.find(nft_log, 'list chain inet pirania pirania_forward', 1, true))
        assert.is_nil(string.find(nft_log, 'list chain inet pirania forward', 1, true))
        assert.is_not_nil(string.find(nft_log, 'delete table inet pirania', 1, true))
        assert.is_not_nil(string.find(nft_log, 'TRANCA_BLOCK_AUTH_MAC', 1, true))
        assert.is_not_nil(string.find(wget_log, TRANCA_ALLOWLIST_URL, 1, true))
    end)

    it('skips rebuild when active and the Tranca marker is already present', function()
        local ok, code, output = run_update(true, true)
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local nft_log = read_file(test_dir .. "nft.log") or ""

        assert.is_not_nil(string.find(nft_log, 'list chain inet pirania pirania_forward', 1, true))
        assert.is_nil(string.find(nft_log, 'delete table inet pirania', 1, true))
        assert.is_nil(string.find(nft_log, 'TRANCA_BLOCK_AUTH_MAC', 1, true))
    end)

    it('rebuilds when inactive and a Tranca marker is still present', function()
        local ok, code, output = run_update(false, true)
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local nft_log = read_file(test_dir .. "nft.log") or ""

        assert.is_not_nil(string.find(nft_log, 'list chain inet pirania pirania_forward', 1, true))
        assert.is_not_nil(string.find(nft_log, 'delete table inet pirania', 1, true))
        assert.is_nil(string.find(nft_log, 'TRANCA_BLOCK_AUTH_MAC', 1, true))
    end)

    it('lets HTTPS bypass prerouting drop and rejects it in input and forward with tcp reset', function()
        local ok, code, output = run_update(true, false)
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local nft_log = read_file(test_dir .. "nft.log") or ""

        assert.is_not_nil(string.find(nft_log, 'add rule inet pirania pirania_prerouting tcp dport 443 return', 1, true))
        assert.is_not_nil(string.find(nft_log, 'add rule inet pirania pirania_input tcp dport 443 ether saddr != @pirania-auth-macs reject with tcp reset', 1, true))
        assert.is_not_nil(string.find(nft_log, 'add rule inet pirania pirania_forward tcp dport 443 ether saddr != @pirania-auth-macs reject with tcp reset', 1, true))
    end)
end)
