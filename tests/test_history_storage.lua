-- test_history_storage.lua - Tests for history_storage.lua module

local lap = require('lib.lap')
local history = require('lib.core.history')
local mock = require('tests.mock_ac')

local function makeLap(sessionId, timeMs)
    local l = lap.new("test_track", "test_car", sessionId)
    for i = 1, 12 do
        l:addSample({
            gas = 0.5,
            brake = 0.1,
            clutch = 0.0,
            steer = 0,
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

suite("history_storage")

test("add stores laps in memory (most recent first)", function()
    history.laps = {}
    history.setTrackCar("ks_nords/cheife", "test_car")

    local lap1 = makeLap("session_a", 90000)
    local lap2 = makeLap("session_b", 88000)

    history.add(lap1)
    history.add(lap2)

    -- Both laps should be in memory, most recent first
    assert_table_length(history.laps, 2)
    assert_equal(history.laps[1].sessionId, "session_b")
    assert_equal(history.laps[2].sessionId, "session_a")
end)

test("getFastestFromSession returns best lap", function()
    local lap1 = makeLap("session_x", 95000)
    local lap2 = makeLap("session_x", 92000)
    local lap3 = makeLap("session_y", 91000)
    history.laps = { lap1, lap2, lap3 }

    local fastest, idx = history.getFastestFromSession("session_x")
    assert_not_nil(fastest)
    assert_equal(idx, 2)
    assert_equal(fastest.time, 92000)
end)

test("getLapsFromSession and getLapsNotFromSession filter correctly", function()
    local lap1 = makeLap("session_a", 90000)
    local lap2 = makeLap("session_b", 91000)
    local lap3 = makeLap("session_a", 92000)
    history.laps = { lap1, lap2, lap3 }

    local inSession = history.getLapsFromSession("session_a")
    assert_table_length(inSession, 2)
    assert_equal(inSession[1].lap.sessionId, "session_a")

    local outSession = history.getLapsNotFromSession("session_a")
    assert_table_length(outSession, 1)
    assert_equal(outSession[1].lap.sessionId, "session_b")
end)
