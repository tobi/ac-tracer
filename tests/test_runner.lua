#!/usr/bin/env lua
-- test_runner.lua - Simple test runner for ac-tracer
-- Usage: lua tests/test_runner.lua [test_file...]

-- Setup package path to find modules
local script_dir = arg[0]:match("(.*/)")
if script_dir then
    package.path = script_dir .. "../?.lua;" .. package.path
    package.path = script_dir .. "../?/init.lua;" .. package.path
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

--------------------------------------------------------------------------------
-- Syntax Check Phase
-- Verifies all Lua files compile without errors (catches typos, missing end, etc.)
--------------------------------------------------------------------------------

-- Find all .lua files in a directory (cross-platform)
local function findLuaFiles(dir, exclude_patterns)
    local files = {}
    exclude_patterns = exclude_patterns or {}

    local function shouldExclude(path)
        for _, pattern in ipairs(exclude_patterns) do
            if path:match(pattern) then return true end
        end
        return false
    end

    -- Try Unix find first, fall back to Windows dir
    local cmd
    if package.config:sub(1,1) == '/' then
        -- Unix/macOS
        cmd = string.format('find "%s" -name "*.lua" -type f 2>/dev/null', dir)
    else
        -- Windows
        cmd = string.format('dir /s /b "%s\\*.lua" 2>nul', dir)
    end

    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            -- Normalize path separators
            local path = line:gsub("\\", "/")
            if not shouldExclude(path) then
                table.insert(files, path)
            end
        end
        handle:close()
    end

    table.sort(files)
    return files
end

local function checkSyntax(files)
    local errors = {}
    for _, file in ipairs(files) do
        local fn, err = loadfile(file)
        if not fn then
            table.insert(errors, { file = file, error = err })
        end
    end
    return errors
end

local function runSyntaxChecks()
    print("\n=== Syntax Check ===")

    -- Find all source files, excluding tests and reference docs
    local exclude_patterns = {
        "^tests/",           -- Test files (checked separately)
        "%.claude/",         -- Claude skills/reference
        "/reference/",       -- Reference documentation
    }

    -- Get all .lua files from lib/ and root
    local source_files = {}

    -- Add root-level .lua files
    local root_files = findLuaFiles(".", {
        "^%./tests/",
        "^%./%.claude/",
        "^%./lib/",  -- Will add lib separately with recursion
    })
    for _, f in ipairs(root_files) do
        -- Only include .lua files directly in root (not subdirs)
        if f:match("^%./[^/]+%.lua$") then
            table.insert(source_files, f)
        end
    end

    -- Add lib/ files recursively
    local lib_files = findLuaFiles("lib", {})
    for _, f in ipairs(lib_files) do
        table.insert(source_files, f)
    end

    if #source_files == 0 then
        print("  [WARN] No source files found for syntax check")
        return true
    end

    local errors = checkSyntax(source_files)

    if #errors == 0 then
        print(string.format("  [PASS] All %d source files have valid syntax", #source_files))
        tests.passed = tests.passed + 1
        return true
    else
        for _, err in ipairs(errors) do
            print(string.format("  [FAIL] %s", err.file))
            print(string.format("         %s", err.error))
            tests.failed = tests.failed + 1
            table.insert(tests.errors, { name = "Syntax: " .. err.file, error = err.error })
        end
        return false
    end
end

--------------------------------------------------------------------------------
-- Run Tests
--------------------------------------------------------------------------------

-- Run syntax checks first
runSyntaxChecks()

-- Run test files
local test_files = { ... }
if #test_files == 0 then
    -- Default test files (no shell commands - works everywhere)
    test_files = {
        "tests/test_lap.lua",
        "tests/test_csv_loading.lua",
        "tests/test_csv_export.lua",
        "tests/test_csv_parser.lua",
        "tests/test_corner_detection.lua",
        "tests/test_corner_notes.lua",
        "tests/test_corner_analysis_basic.lua",
        "tests/test_checkpoint.lua",
        "tests/test_scoring.lua",
        "tests/test_settings.lua",
        "tests/test_ui_utils.lua",
        "tests/test_file_utils.lua",
        "tests/test_history_storage.lua",
        "tests/test_markdown.lua",
        "tests/test_theme.lua",
        "tests/test_wedge.lua",
        "tests/test_delta_bar.lua",
        "tests/test_lap_picker.lua",
        "tests/test_state.lua",
        "tests/test_lap_telemetry_basic.lua",
        "tests/test_sim_playback.lua",
        "tests/test_background_writer.lua",
        "tests/test_motec_parser.lua",
    }
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
