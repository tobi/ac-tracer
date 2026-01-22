-- test_ui_utils.lua - Tests for ui_utils.lua speed display functions
-- Note: Only tests functions that don't require CSP UI APIs

-- Clear cached modules to ensure fresh load with mock environment
package.loaded['lib.settings'] = nil
package.loaded['lib.ui.utils'] = nil
package.loaded['lib.controls.lap_picker'] = nil
package.loaded['lib.core.files'] = nil
package.loaded['lib.ui.theme'] = nil

local ui_utils = require('lib.ui.utils')
local settings = require('lib.settings')

--------------------------------------------------------------------------------
-- Speed Display Tests
--------------------------------------------------------------------------------

suite("ui_utils.speed")

test("converts km/h to display units (km/h mode)", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speed(100), 100)
end)

test("converts km/h to mph when useKMH is false", function()
    settings.setUseKMH(false)
    local mph = ui_utils.speed(100)
    assert_near(mph, 62.14, 0.1, "100 km/h should be ~62 mph")
    settings.setUseKMH(true)  -- Restore
end)

test("handles nil input", function()
    assert_equal(ui_utils.speed(nil), 0)
end)


suite("ui_utils.speedUnit")

test("returns km/h when useKMH is true", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedUnit(), "km/h")
end)

test("returns mph when useKMH is false", function()
    settings.setUseKMH(false)
    assert_equal(ui_utils.speedUnit(), "mph")
    settings.setUseKMH(true)  -- Restore
end)


suite("ui_utils.speedDisplay")

test("formats speed with unit", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedDisplay(150), "150 km/h")
end)

test("formats speed without unit", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedDisplay(150, false), "150")
end)

test("handles nil speed", function()
    assert_equal(ui_utils.speedDisplay(nil), "--")
end)

test("converts to mph when useKMH is false", function()
    settings.setUseKMH(false)
    local result = ui_utils.speedDisplay(100)
    assert_true(result:match("62"), "Should show ~62 mph")
    assert_true(result:match("mph"), "Should include mph unit")
    settings.setUseKMH(true)  -- Restore
end)


suite("ui_utils.speedDeltaDisplay")

test("formats positive delta with sign", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedDeltaDisplay(5), "+5")
end)

test("formats negative delta with sign", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedDeltaDisplay(-3), "-3")
end)

test("formats zero delta", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedDeltaDisplay(0), "+0")
end)

test("includes unit when requested", function()
    settings.setUseKMH(true)
    assert_equal(ui_utils.speedDeltaDisplay(5, true), "+5 km/h")
end)

test("handles nil delta", function()
    assert_equal(ui_utils.speedDeltaDisplay(nil), "--")
end)


--------------------------------------------------------------------------------
-- Delta Formatting Tests
--------------------------------------------------------------------------------

suite("ui_utils.formatDelta")

test("formats positive delta with sign", function()
    assert_equal(ui_utils.formatDelta(0.25), "+0.25")
end)

test("formats negative delta with sign", function()
    assert_equal(ui_utils.formatDelta(-1.03), "-1.03")
end)

test("handles nil input", function()
    assert_equal(ui_utils.formatDelta(nil), "--")
end)

test("uses custom decimal places", function()
    assert_equal(ui_utils.formatDelta(0.12345, 3), "+0.123")
    assert_equal(ui_utils.formatDelta(0.12345, 1), "+0.1")
end)


suite("ui_utils.formatDeltaS")

test("formats delta with seconds suffix", function()
    assert_equal(ui_utils.formatDeltaS(0.25), "+0.25s")
    assert_equal(ui_utils.formatDeltaS(-1.03), "-1.03s")
end)


suite("ui_utils.getDeltaColor")

test("returns color for zero delta", function()
    local color = ui_utils.getDeltaColor(0)
    assert_not_nil(color)
end)

test("returns color for positive delta", function()
    local color = ui_utils.getDeltaColor(1.0, false)
    assert_not_nil(color)
end)

test("returns color for negative delta", function()
    local color = ui_utils.getDeltaColor(-1.0, false)
    assert_not_nil(color)
end)


--------------------------------------------------------------------------------
-- Percentage Formatting Tests
--------------------------------------------------------------------------------

suite("ui_utils.formatPercent")

test("formats as percentage", function()
    assert_equal(ui_utils.formatPercent(0.5), "50%")
    assert_equal(ui_utils.formatPercent(1.0), "100%")
    assert_equal(ui_utils.formatPercent(0.25), "25%")
end)

test("uses custom decimal places", function()
    assert_equal(ui_utils.formatPercent(0.1234, 2), "12.34%")
    assert_equal(ui_utils.formatPercent(0.5, 1), "50.0%")
end)

test("handles nil input", function()
    local result = ui_utils.formatPercent(nil)
    assert_true(result:match("%%"), "Should contain percent sign")
    assert_true(result:match("%-%-"), "Should contain dashes for nil")
end)


--------------------------------------------------------------------------------
-- Graph Coordinate Tests
--------------------------------------------------------------------------------

suite("ui_utils.posToX")

test("converts position to X coordinate", function()
    local x = ui_utils.posToX(0.5, 100, 400)
    assert_equal(x, 300, "50% position should be at 300px (100 + 0.5 * 400)")
end)

test("handles position 0", function()
    local x = ui_utils.posToX(0, 100, 400)
    assert_equal(x, 100)
end)

test("handles position 1", function()
    local x = ui_utils.posToX(1, 100, 400)
    assert_equal(x, 500)
end)


suite("ui_utils.timeToX")

test("converts time to X coordinate", function()
    local x = ui_utils.timeToX(50, 0, 100, 0, 400)
    assert_equal(x, 200, "50% time should be at 200px")
end)

test("handles time at start", function()
    local x = ui_utils.timeToX(0, 0, 100, 0, 400)
    assert_equal(x, 0)
end)

test("handles time at end", function()
    local x = ui_utils.timeToX(100, 0, 100, 0, 400)
    assert_equal(x, 400)
end)


suite("ui_utils.xToTime")

test("converts X coordinate to time", function()
    local time = ui_utils.xToTime(200, 0, 100, 0, 400)
    assert_equal(time, 50, "200px should be 50% of range")
end)


suite("ui_utils.valueToY")

test("converts value to Y coordinate", function()
    local y = ui_utils.valueToY(50, 0, 100, 0, 400)
    assert_equal(y, 200, "50% value should be at middle")
end)

test("handles minimum value (bottom)", function()
    local y = ui_utils.valueToY(0, 0, 100, 0, 400)
    assert_equal(y, 400, "Minimum should be at bottom")
end)

test("handles maximum value (top)", function()
    local y = ui_utils.valueToY(100, 0, 100, 0, 400)
    assert_equal(y, 0, "Maximum should be at top")
end)


--------------------------------------------------------------------------------
-- Time Formatting Tests
--------------------------------------------------------------------------------

suite("ui_utils.formatLapTime")

test("formats lap time with minutes", function()
    assert_equal(ui_utils.formatLapTime(90120), "1:30.12")
end)

test("formats lap time less than minute", function()
    assert_equal(ui_utils.formatLapTime(45680), "45.68s")
end)

test("formats exact minute", function()
    assert_equal(ui_utils.formatLapTime(60000), "1:00.00")
end)


--------------------------------------------------------------------------------
-- Position Helpers Tests
--------------------------------------------------------------------------------

suite("ui_utils.getTrackLength")

test("returns track length from sim", function()
    mock.setSim({ trackLengthM = 7500 })
    assert_equal(ui_utils.getTrackLength(), 7500)
end)

test("defaults to 5000 if sim has no track length", function()
    mock.setSim({ trackLengthM = nil })
    local length = ui_utils.getTrackLength()
    -- Default is 5000 when trackLengthM is nil or 0
    assert_true(length > 0, "Should return a positive default length")
end)


suite("ui_utils.positionDeltaToMeters")

test("converts position delta to meters", function()
    mock.setSim({ trackLengthM = 5000 })
    local meters = ui_utils.positionDeltaToMeters(0.6, 0.5)
    assert_near(meters, 500, 1)
end)

test("handles wrap-around at finish line", function()
    mock.setSim({ trackLengthM = 5000 })
    local meters = ui_utils.positionDeltaToMeters(0.1, 0.9)
    -- 0.1 - 0.9 = -0.8, wrap: -0.8 + 1 = 0.2 = 1000m
    assert_near(meters, 1000, 1)
end)

test("returns nil for missing positions", function()
    assert_nil(ui_utils.positionDeltaToMeters(nil, 0.5))
    assert_nil(ui_utils.positionDeltaToMeters(0.5, nil))
end)


suite("ui_utils.formatPosition")

test("formats position as percentage", function()
    assert_equal(ui_utils.formatPosition(0.5), "50.0%")
    assert_equal(ui_utils.formatPosition(0.123), "12.3%")
end)

test("handles nil position", function()
    assert_equal(ui_utils.formatPosition(nil), "--%")
end)


suite("ui_utils.formatPositionMeters")

test("formats position as meters", function()
    mock.setSim({ trackLengthM = 5000 })
    assert_equal(ui_utils.formatPositionMeters(0.5), "2500m")
end)

test("handles nil position", function()
    assert_equal(ui_utils.formatPositionMeters(nil), "--m")
end)
