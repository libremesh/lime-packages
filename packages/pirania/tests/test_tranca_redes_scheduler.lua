local test_utils = require 'tests.utils'

local SCRIPT_PATH = "./packages/pirania/files/usr/bin/tranca-redes-scheduler"

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

local function wait_for_file_contains(path, pattern)
    for _ = 1, 20 do
        local content = read_file(path) or ""
        if string.find(content, pattern, 1, true) ~= nil then
            return content
        end
        os.execute("sleep 0.05")
    end
    return read_file(path) or ""
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

local function run_scheduler()
    write_state("command.out", "")

    local cmd = string.format(
        "PATH='%s':\"$PATH\" TEST_ROOT='%s' sh %s > %s 2>&1",
        bin_dir:sub(1, -2),
        test_dir:sub(1, -2),
        SCRIPT_PATH,
        test_dir .. "command.out"
    )

    local ok, code = command_succeeds(cmd)
    return ok, code, read_file(test_dir .. "command.out") or ""
end

describe('Tranca Redes scheduler shell tests #trancascheduler', function()
    before_each('', function()
        test_dir = test_utils.setup_test_dir()
        bin_dir = test_dir .. "bin/"
        local ok = command_succeeds("mkdir -p " .. bin_dir)
        assert.is_true(ok)

        write_state("pirania_enabled", "1\n")
        write_state("tranca_enabled", "1\n")
        write_state("tranca_active", "0\n")
        write_state("start_time", "09:00\n")
        write_state("end_time", "17:00\n")
        write_state("days", "mon tue wed thu fri\n")
        write_state("current_year", "2026\n")
        write_state("current_time", "10:30\n")
        write_state("current_day", "Mon\n")
        write_state("yesterday_day", "Sun\n")
        write_state("logger.log", "")
        write_state("uci.log", "")
        write_state("captive.log", "")

        write_executable("uci", [[#!/bin/sh
if [ "$1" = "-q" ]; then
    shift
fi

cmd="$1"
arg="$2"
test_root="${TEST_ROOT}"

read_state() {
    local name="$1"
    local path="$test_root/$name"
    if [ -f "$path" ]; then
        cat "$path"
    fi
}

case "$cmd" in
get)
    case "$arg" in
        pirania.base_config.enabled) read_state "pirania_enabled" ;;
        pirania.tranca_redes.enabled) read_state "tranca_enabled" ;;
        pirania.tranca_redes.active) read_state "tranca_active" ;;
        pirania.tranca_redes.start_time) read_state "start_time" ;;
        pirania.tranca_redes.end_time) read_state "end_time" ;;
        pirania.tranca_redes.days) read_state "days" ;;
        pirania.tranca_redes.days.0) read_state "days" | awk '{print $1}' ;;
        pirania.tranca_redes.days.1) read_state "days" | awk '{print $2}' ;;
        pirania.tranca_redes.days.2) read_state "days" | awk '{print $3}' ;;
        pirania.tranca_redes.days.3) read_state "days" | awk '{print $4}' ;;
        pirania.tranca_redes.days.4) read_state "days" | awk '{print $5}' ;;
        pirania.tranca_redes.days.5) read_state "days" | awk '{print $6}' ;;
        pirania.tranca_redes.days.6) read_state "days" | awk '{print $7}' ;;
        *) exit 1 ;;
    esac
    ;;
set)
    printf 'set %s\n' "$arg" >> "$test_root/uci.log"
    key="${arg%%=*}"
    value="${arg#*=}"
    case "$key" in
        pirania.tranca_redes.active)
            printf '%s\n' "$value" > "$test_root/tranca_active"
            ;;
    esac
    ;;
commit)
    printf 'commit %s\n' "$arg" >> "$test_root/uci.log"
    ;;
show)
    if [ "$arg" = "pirania.tranca_redes.days" ]; then
        idx=0
        for day in $(read_state "days"); do
            printf "pirania.tranca_redes.days.%s='%s'\n" "$idx" "$day"
            idx=$((idx + 1))
        done
    else
        exit 1
    fi
    ;;
*)
    exit 1
    ;;
esac
]])

        write_executable("date", [[#!/bin/sh
test_root="${TEST_ROOT}"

read_state() {
    local name="$1"
    local path="$test_root/$name"
    if [ -f "$path" ]; then
        cat "$path"
    fi
}

case "$*" in
    "+%Y")
        read_state "current_year"
        ;;
    "+%H:%M")
        read_state "current_time"
        ;;
    "+%a")
        read_state "current_day"
        ;;
    '-d yesterday +%a')
        read_state "yesterday_day"
        ;;
    *)
        exit 1
        ;;
esac
]])

        write_executable("logger", [[#!/bin/sh
printf '%s\n' "$*" >> "$TEST_ROOT/logger.log"
exit 0
]])

        write_executable("captive-portal", [[#!/bin/sh
printf '%s\n' "$*" >> "$TEST_ROOT/captive.log"
exit 0
]])
    end)

    after_each('', function()
        os.remove("/tmp/tranca-redes-scheduler.lock")
        test_utils.teardown_test_dir()
    end)

    it('deactivates Tranca and triggers captive-portal update when disabled while active', function()
        write_state("tranca_enabled", "0\n")
        write_state("tranca_active", "1\n")

        local ok, code, output = run_scheduler()
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local uci_log = read_file(test_dir .. "uci.log") or ""
        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = wait_for_file_contains(test_dir .. "captive.log", 'update')

        assert.is_not_nil(string.find(uci_log, 'set pirania.tranca_redes.active=0', 1, true))
        assert.is_not_nil(string.find(uci_log, 'commit pirania', 1, true))
        assert.is_not_nil(string.find(logger_log, 'Tranca Redes disabled, deactivating', 1, true))
        assert.is_not_nil(string.find(captive_log, 'update', 1, true))
    end)

    it('activates Tranca during a matching same-day schedule', function()
        local ok, code, output = run_scheduler()
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local uci_log = read_file(test_dir .. "uci.log") or ""
        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = wait_for_file_contains(test_dir .. "captive.log", 'update')

        assert.is_not_nil(string.find(uci_log, 'set pirania.tranca_redes.active=1', 1, true))
        assert.is_not_nil(string.find(uci_log, 'commit pirania', 1, true))
        assert.is_not_nil(string.find(logger_log, 'Tranca Redes ACTIVATED', 1, true))
        assert.is_not_nil(string.find(captive_log, 'update', 1, true))
    end)

    it('activates Tranca in the overnight morning window when yesterday was active', function()
        write_state("start_time", "20:00\n")
        write_state("end_time", "07:00\n")
        write_state("current_time", "06:30\n")
        write_state("current_day", "Tue\n")
        write_state("yesterday_day", "Mon\n")
        write_state("days", "mon\n")

        local ok, code, output = run_scheduler()
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local uci_log = read_file(test_dir .. "uci.log") or ""
        local logger_log = read_file(test_dir .. "logger.log") or ""

        assert.is_not_nil(string.find(uci_log, 'set pirania.tranca_redes.active=1', 1, true))
        assert.is_not_nil(string.find(logger_log, 'Tranca Redes ACTIVATED', 1, true))
    end)

    it('warns and fails when schedule times are missing', function()
        write_state("start_time", "")

        local ok, code, output = run_scheduler()
        assert.is_false(ok, output .. "\nexit code: " .. tostring(code))

        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = read_file(test_dir .. "captive.log") or ""

        assert.is_not_nil(string.find(logger_log, 'Schedule not configured', 1, true))
        assert.is_nil(string.find(captive_log, 'update', 1, true))
    end)

    it('warns and fails when schedule time format is invalid', function()
        write_state("start_time", "99:99\n")

        local ok, code, output = run_scheduler()
        assert.is_false(ok, output .. "\nexit code: " .. tostring(code))

        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = read_file(test_dir .. "captive.log") or ""

        assert.is_not_nil(string.find(logger_log, 'Invalid start_time format', 1, true))
        assert.is_nil(string.find(captive_log, 'update', 1, true))
    end)

    it('warns and fails when start_time hour is out of range', function()
        write_state("start_time", "24:00\n")

        local ok, code, output = run_scheduler()
        assert.is_false(ok, output .. "\nexit code: " .. tostring(code))

        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = read_file(test_dir .. "captive.log") or ""

        assert.is_not_nil(string.find(logger_log, 'Invalid start_time format: 24:00 (expected HH:MM)', 1, true))
        assert.is_nil(string.find(captive_log, 'update', 1, true))
    end)

    it('warns and fails when end_time hour is out of range', function()
        write_state("end_time", "29:59\n")

        local ok, code, output = run_scheduler()
        assert.is_false(ok, output .. "\nexit code: " .. tostring(code))

        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = read_file(test_dir .. "captive.log") or ""

        assert.is_not_nil(string.find(logger_log, 'Invalid end_time format: 29:59 (expected HH:MM)', 1, true))
        assert.is_nil(string.find(captive_log, 'update', 1, true))
    end)

    it('does nothing when active state already matches the evaluated schedule', function()
        write_state("tranca_active", "1\n")

        local ok, code, output = run_scheduler()
        assert.is_true(ok, output .. "\nexit code: " .. tostring(code))

        local uci_log = read_file(test_dir .. "uci.log") or ""
        local logger_log = read_file(test_dir .. "logger.log") or ""
        local captive_log = read_file(test_dir .. "captive.log") or ""

        assert.is.equal("", uci_log)
        assert.is.equal("", logger_log)
        assert.is.equal("", captive_log)
    end)
end)
