-- test_lap_picker.lua - Tests for lap_picker.lua module

suite("lap_picker")

test("refresh calls file_utils.invalidateCache", function()
    local originalFileUtils = package.loaded['lib.core.files']
    local originalLapPicker = package.loaded['lib.windows.lap_picker']

    local calls = 0
    package.loaded['lib.core.files'] = {
        invalidateCache = function() calls = calls + 1 end,
        formatFileSize = function() return "1KB" end,
        formatLapTime = function() return "0:00.00" end,
        scanCSVFiles = function() return {} end,
    }

    package.loaded['lib.windows.lap_picker'] = nil
    local lap_picker = require('lib.windows.lap_picker')

    lap_picker.refresh()
    assert_equal(calls, 1)
    assert_true(lap_picker.isLoading() == false)

    package.loaded['lib.core.files'] = originalFileUtils
    package.loaded['lib.windows.lap_picker'] = originalLapPicker
end)
