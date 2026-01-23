-- test_markdown.lua - Tests for markdown.lua module

local lap = require('lib.lap')

local function makeLap(sessionId, timeMs)
    local l = lap.new("test_track", "test_car", sessionId)
    for i = 1, 12 do
        l:addSample({
            gas = 0.6,
            brake = 0.1,
            clutch = 0.0,
            steer = 5,
            speedKmh = 100 + i,
            gear = 3,
            splinePosition = (i - 1) / 11,
            lapTimeMs = i * 1000,
            fuel = 50 - i,
        })
    end
    l.time = timeMs
    l.completed = true
    l.valid = true
    return l
end

suite("markdown")

test("generate outputs expected sections", function()
    local originalState = package.loaded['lib.core.state']
    local originalCorner = package.loaded['lib.windows.corner_analysis']
    local originalMarkdown = package.loaded['lib.ui.markdown']

    package.loaded['lib.core.state'] = {
        track = "test_track",
        car = "test_car",
        trackCorners = {
            { number = 1, name = "T1", startPos = 0.1, endPos = 0.2 }
        }
    }

    package.loaded['lib.windows.corner_analysis'] = {
        analyzeCorner = function()
            return {
                entrySpeed = 100,
                apexSpeed = 80,
                exitSpeed = 110,
                brakePos = 0.12,
                liftOffPos = 0.11,
                apexPos = 0.15,
                maxSteeringDeg = 20,
                minGear = 3,
                entryTime = 1,
                exitTime = 2,
                overlapTime = 0.2,
            }
        end,
        compareCorners = function()
            return {
                entrySpeedDelta = 5,
                apexSpeedDelta = -3,
                exitSpeedDelta = 2,
                timeDelta = 0.1,
                refBrakePos = 0.11,
                currentBrakePos = 0.12,
                refLiftOffPos = 0.10,
                currentLiftOffPos = 0.11,
                steeringDelta = 12,
                currentMinGear = 3,
                refMinGear = 4,
                gearDelta = -1,
                currentOverlapTime = 0.2,
                refStartPos = 0.1,
                refEndPos = 0.2,
            }
        end
    }

    package.loaded['lib.ui.markdown'] = nil
    local markdown = require('lib.ui.markdown')

    local currentLap = makeLap("session_a", 90000)
    local referenceLap = makeLap("session_b", 88000)

    local output = markdown.generate(currentLap, referenceLap)
    assert_true(output:find("# Lap Telemetry Export") ~= nil)
    assert_true(output:find("## Corner Definitions") ~= nil)
    assert_true(output:find("## Lap Comparison") ~= nil)
    assert_true(output:find("### T1") ~= nil)

    package.loaded['lib.core.state'] = originalState
    package.loaded['lib.windows.corner_analysis'] = originalCorner
    package.loaded['lib.ui.markdown'] = originalMarkdown
end)

test("copyToClipboard returns success and message", function()
    local originalState = package.loaded['lib.core.state']
    local originalCorner = package.loaded['lib.windows.corner_analysis']
    local originalMarkdown = package.loaded['lib.ui.markdown']
    local originalClipboard = ac.setClipboardText

    package.loaded['lib.core.state'] = {
        track = "test_track",
        car = "test_car",
        trackCorners = { { number = 1, name = "T1", startPos = 0.1, endPos = 0.2 } }
    }
    package.loaded['lib.windows.corner_analysis'] = {
        analyzeCorner = function() return nil end,
        compareCorners = function() return nil end
    }

    ac.setClipboardText = function(text) end

    package.loaded['lib.ui.markdown'] = nil
    local markdown = require('lib.ui.markdown')
    local currentLap = makeLap("session_a", 90000)

    local ok, msg = markdown.copyToClipboard(currentLap, nil)
    assert_true(ok)
    assert_true(msg:find("Copied to clipboard") ~= nil)

    ac.setClipboardText = originalClipboard
    package.loaded['lib.core.state'] = originalState
    package.loaded['lib.windows.corner_analysis'] = originalCorner
    package.loaded['lib.ui.markdown'] = originalMarkdown
end)
