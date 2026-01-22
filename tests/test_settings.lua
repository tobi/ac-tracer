-- test_settings.lua - Tests for app_settings.lua module
-- These tests verify that settings accessors are functions that must be called

local settings = require('lib.settings')

--------------------------------------------------------------------------------
-- Settings Accessor Tests
--------------------------------------------------------------------------------
-- Bug fixed: settings.brakeThreshold and settings.throttleThreshold were
-- passed as functions instead of being called with (), causing
-- "attempt to compare function with number" errors.

suite("Settings Accessors Are Functions")

test("brakeThreshold is a function that returns a number", function()
    assert_type(settings.brakeThreshold, "function", "brakeThreshold should be a function")
    local value = settings.brakeThreshold()
    assert_type(value, "number", "brakeThreshold() should return a number")
    assert_true(value >= 0, "brakeThreshold should be non-negative")
end)

test("throttleThreshold is a function that returns a number", function()
    assert_type(settings.throttleThreshold, "function", "throttleThreshold should be a function")
    local value = settings.throttleThreshold()
    assert_type(value, "number", "throttleThreshold() should return a number")
    assert_true(value >= 0 and value <= 1, "throttleThreshold should be 0-1")
end)

test("useKMH is a function that returns a boolean", function()
    assert_type(settings.useKMH, "function", "useKMH should be a function")
    local value = settings.useKMH()
    assert_type(value, "boolean", "useKMH() should return a boolean")
end)

test("maxHistoryLaps is a function that returns a number", function()
    assert_type(settings.maxHistoryLaps, "function", "maxHistoryLaps should be a function")
    local value = settings.maxHistoryLaps()
    assert_type(value, "number", "maxHistoryLaps() should return a number")
    assert_true(value > 0, "maxHistoryLaps should be positive")
end)

test("showFlagMarker is a function that takes a flag name", function()
    assert_type(settings.showFlagMarker, "function", "showFlagMarker should be a function")
    local tcValue = settings.showFlagMarker('TC')
    local lockupValue = settings.showFlagMarker('Lockup')
    assert_type(tcValue, "boolean", "showFlagMarker('TC') should return a boolean")
    assert_type(lockupValue, "boolean", "showFlagMarker('Lockup') should return a boolean")
end)

test("telemetryShowLateralG is a function that returns a boolean", function()
    assert_type(settings.telemetryShowLateralG, "function", "telemetryShowLateralG should be a function")
    local value = settings.telemetryShowLateralG()
    assert_type(value, "boolean", "telemetryShowLateralG() should return a boolean")
end)


--------------------------------------------------------------------------------
-- Comparison Safety Tests
--------------------------------------------------------------------------------
-- These tests verify that comparing settings values works correctly
-- (would fail if settings were passed as functions instead of called)

suite("Settings Comparison Safety")

test("brakeThreshold can be compared with numbers", function()
    local threshold = settings.brakeThreshold()
    -- These comparisons should work (not throw "attempt to compare function with number")
    assert_true(threshold >= 0, "threshold >= 0 should work")
    assert_true(threshold < 1000, "threshold < 1000 should work")
    local testValue = 50
    if testValue > threshold then
        assert_true(true, "comparison with variable works")
    else
        assert_true(true, "comparison with variable works")
    end
end)

test("throttleThreshold can be compared with numbers", function()
    local threshold = settings.throttleThreshold()
    -- These comparisons should work
    assert_true(threshold >= 0, "threshold >= 0 should work")
    assert_true(threshold <= 1, "threshold <= 1 should work")
    local testValue = 0.5
    if testValue > threshold then
        assert_true(true, "comparison with variable works")
    else
        assert_true(true, "comparison with variable works")
    end
end)

test("settings values can be used in arithmetic", function()
    local brake = settings.brakeThreshold()
    local throttle = settings.throttleThreshold()

    -- These should work (would fail if values were functions)
    local brakeDoubled = brake * 2
    local throttleHalved = throttle / 2

    assert_type(brakeDoubled, "number", "brake * 2 should be a number")
    assert_type(throttleHalved, "number", "throttle / 2 should be a number")
end)


--------------------------------------------------------------------------------
-- Default Value Tests
--------------------------------------------------------------------------------

suite("Settings Default Values")

test("brakeThreshold has reasonable default", function()
    local value = settings.brakeThreshold()
    -- Default should be around 5 bar for brake point detection
    assert_true(value >= 1 and value <= 20,
        string.format("brakeThreshold default should be 1-20 bar, got %.1f", value))
end)

test("throttleThreshold has reasonable default", function()
    local value = settings.throttleThreshold()
    -- Default should be around 0.95-0.99 for lift point detection
    assert_true(value >= 0.8 and value <= 1.0,
        string.format("throttleThreshold default should be 0.8-1.0, got %.2f", value))
end)

test("showTCMarkers defaults to false", function()
    -- TC markers were defaulted to off in recent changes
    local value = settings.showFlagMarker('TC')
    assert_equal(value, false, "TC markers should default to false")
end)

test("telemetryShowLateralG defaults to false", function()
    -- Lateral G is hidden by default
    local value = settings.telemetryShowLateralG()
    assert_equal(value, false, "telemetryShowLateralG should default to false")
end)
