#!/usr/bin/lua

local system = require("network-utils")

function equality_test(val1, val2, message)
    if val1 == val2 then
        print("[SUCCESS] " .. message .. ", " .. val1 .. ", " .. val2)
        return 1
    else
        print("[FAILED] " .. message .. ", " .. val1 .. ", " .. val2)
        return 0
    end

end

function multiplied_string(string, multiplier)
    local result = ''
    for i=1, multiplier do
        result = result .. string
    end
    return result
end

equality_test(system.sanitize_hostname("-hello"), "hello", "Removes minus from the beginning.")
equality_test(system.sanitize_hostname("hello-"), "hello",  "Removes minus from end of string.")
equality_test(system.sanitize_hostname("hello----"), "hello",  "Removes minus from end of string.")
equality_test(system.sanitize_hostname("he-llo"), "he-llo",  "Doesn't remove minus from the middle.")
equality_test(system.sanitize_hostname("he_llo"), "hello",  "Removes non-alphanumeric symbols.")
equality_test(system.sanitize_hostname(multiplied_string("a", 36)), multiplied_string("a", 32),  "strips length of hostname to 32 characters.")
