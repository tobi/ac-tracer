#!/usr/bin/env lua
-- test_runner.lua - Simple test runner for ac-tracer
-- Usage: lua tests/test_runner.lua [test_file...]

-- Setup package path to find modules
local script_dir = arg[0]:match("(.*/)")
if script_dir then
    package.path = script_dir .. "../?.lua;" .. package.path
    package.path = script_dir .. "?.lua;" .. package.path
end

-- Load mock environment first
local mock = require('tests.mock_ac')

-- Test framework
local tests = {
    passed = 0,
    failed = 0,
    errors = {},
    current_suite = nil,
}

function tests.suite(name)
    tests.current_suite = name
    print("\n=== " .. name .. " ===")
end

function tests.test(name, fn)
    local full_name = tests.current_suite and (tests.current_suite .. ": " .. name) or name
    local ok, err = pcall(fn)
    if ok then
        tests.passed = tests.passed + 1
        print("  [PASS] " .. name)
    else
        tests.failed = tests.failed + 1
        print("  [FAIL] " .. name)
        print("         " .. tostring(err))
        table.insert(tests.errors, { name = full_name, error = err })
    end
end

function tests.assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function tests.assertEqual(actual, expected, message)
    if actual ~= expected then
        local msg = string.format("%s\n    Expected: %s\n    Actual: %s",
            message or "Values not equal",
            tostring(expected),
            tostring(actual))
        error(msg, 2)
    end
end

function tests.assertNear(actual, expected, tolerance, message)
    tolerance = tolerance or 0.0001
    if math.abs(actual - expected) > tolerance then
        local msg = string.format("%s\n    Expected: %s (±%s)\n    Actual: %s",
            message or "Values not within tolerance",
            tostring(expected),
            tostring(tolerance),
            tostring(actual))
        error(msg, 2)
    end
end

function tests.assertNil(value, message)
    if value ~= nil then
        error((message or "Expected nil") .. ", got: " .. tostring(value), 2)
    end
end

function tests.assertNotNil(value, message)
    if value == nil then
        error(message or "Expected non-nil value", 2)
    end
end

function tests.assertType(value, expected_type, message)
    local actual_type = type(value)
    if actual_type ~= expected_type then
        local msg = string.format("%s\n    Expected type: %s\n    Actual type: %s",
            message or "Type mismatch",
            expected_type,
            actual_type)
        error(msg, 2)
    end
end

function tests.assertTableLength(tbl, expected_len, message)
    local actual_len = #tbl
    if actual_len ~= expected_len then
        local msg = string.format("%s\n    Expected length: %d\n    Actual length: %d",
            message or "Table length mismatch",
            expected_len,
            actual_len)
        error(msg, 2)
    end
end

function tests.assertNotEqual(actual, expected, message)
    if actual == expected then
        local msg = string.format("%s\n    Values should not be equal: %s",
            message or "Values are equal but should differ",
            tostring(actual))
        error(msg, 2)
    end
end

function tests.summary()
    print("\n" .. string.rep("=", 50))
    print(string.format("Results: %d passed, %d failed", tests.passed, tests.failed))
    
    if #tests.errors > 0 then
        print("\nFailures:")
        for i, err in ipairs(tests.errors) do
            print(string.format("  %d. %s", i, err.name))
        end
    end
    
    print(string.rep("=", 50))
    return tests.failed == 0
end

-- Make test functions global for convenience
_G.suite = tests.suite
_G.test = tests.test
_G.assert_true = tests.assert
_G.assert_equal = tests.assertEqual
_G.assert_not_equal = tests.assertNotEqual
_G.assert_near = tests.assertNear
_G.assert_nil = tests.assertNil
_G.assert_not_nil = tests.assertNotNil
_G.assert_type = tests.assertType
_G.assert_table_length = tests.assertTableLength
_G.mock = mock

-- Run test files
local test_files = { ... }
if #test_files == 0 then
    -- Default: run all test_*.lua files in tests/ (excluding test_runner.lua)
    local handle = io.popen('ls tests/test_*.lua 2>/dev/null')
    if handle then
        for file in handle:lines() do
            if not file:match("test_runner%.lua$") then
                table.insert(test_files, file)
            end
        end
        handle:close()
    end
end

print("AC Tracer Test Runner")
print("=====================")

for _, file in ipairs(test_files) do
    print("\nLoading: " .. file)
    local ok, err = pcall(dofile, file)
    if not ok then
        print("ERROR loading " .. file .. ": " .. tostring(err))
        tests.failed = tests.failed + 1
    end
end

local success = tests.summary()
os.exit(success and 0 or 1)
