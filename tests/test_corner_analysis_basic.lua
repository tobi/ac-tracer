-- test_corner_analysis_basic.lua - Basic tests for corner_analysis.lua

local lap = require('lib.lap')

local function makeLap(sessionId, baseSpeed)
    local l = lap.new("test_track", "test_car", sessionId)
    for i = 1, 12 do
        l:addSample({
            gas = 0.6,
            brake = (i >= 4 and i <= 6) and 0.4 or 0.0,
            clutch = 0.0,
            steer = 10,
            speedKmh = baseSpeed - (i == 5 and 30 or 0),
            gear = 3,
            splinePosition = (i - 1) / 11,
            lapTimeMs = i * 1000,
            fuel = 50 - i,
        })
    end
    l.time = 90000
    l.completed = true
    l.valid = true
    return l
end

suite("corner_analysis")

test("analyzeCorner and compareCorners return data", function()
    local originalState = package.loaded['lib.state']
    package.loaded['lib.state'] = {
        onCheckpointLoad = function() end,
        getLapTimeOffset = function() return 0 end,
    }
    package.loaded['lib.windows.corner_analysis'] = nil
    local corner_analysis = require('lib.windows.corner_analysis')

    local currentLap = makeLap("session_a", 120)
    local refLap = makeLap("session_b", 125)
    local corner = { number = 1, startPos = 0.1, endPos = 0.2 }

    local current = corner_analysis.analyzeCorner(currentLap, corner)
    local reference = corner_analysis.analyzeCorner(refLap, corner)

    assert_not_nil(current)
    assert_not_nil(reference)
    assert_equal(current.number, 1)

    local comparison = corner_analysis.compareCorners(current, reference)
    assert_not_nil(comparison)

    local displayData = corner_analysis.compare(corner, currentLap, refLap, { apply = false })
    assert_not_nil(displayData)
    assert_equal(displayData.cornerInfo, corner, "comparison should retain corner range for marker rendering")
    assert_equal(comparison.number, 1)

    package.loaded['lib.state'] = originalState
end)
