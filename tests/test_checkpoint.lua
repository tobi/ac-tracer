-- test_checkpoint.lua - Tests for checkpoint stack and delta outlap behavior

local function loadStateFresh()
    package.loaded['lib.core.state'] = nil
    package.loaded['lib.core.history'] = nil
    package.loaded['lib.windows.corner_analysis'] = nil
    package.loaded['lib.lap'] = nil
    return require('lib.core.state')
end

local function resetUiLog()
    ui._textLog = {}
end

--------------------------------------------------------------------------------
-- Checkpoint Auto-Save Tests
--------------------------------------------------------------------------------

suite("checkpoint auto-save")

test("auto-saves checkpoint on lap completion", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()
    ac._messages = {}
    ac._saveCalls = 0

    local state = loadStateFresh()
    local car = ac.getCar(0)

    -- Initialize state
    state.update(0.1, car)
    assert_true(not state.hasCheckpoint(), "should start without checkpoint")

    -- Simulate lap completion
    mock.setCar({
        lapCount = car.lapCount + 1,
        previousLapTimeMs = 90000,
        isLastLapValid = true,
    })
    state.update(0.1, ac.getCar(0))

    assert_true(state.hasCheckpoint(), "checkpoint should be created")
    assert_equal(ac._saveCalls, 1, "checkpoint save should be called once")
    assert_table_length(ac._messages or {}, 0, "auto checkpoint should be silent")
end)

test("pushes new checkpoint to stack on each lap completion", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()
    ac._messages = {}
    ac._saveCalls = 0

    local state = loadStateFresh()
    local car = ac.getCar(0)

    -- Initialize state
    state.update(0.1, car)

    -- First completion
    mock.setCar({ lapCount = car.lapCount + 1, previousLapTimeMs = 90000 })
    state.update(0.1, ac.getCar(0))
    assert_true(state.hasCheckpoint(), "checkpoint should exist after first lap")
    -- S/F checkpoint is always at ~0.0, so subsequent laps replace it (same position)
    -- The save call count should still increment
    assert_equal(ac._saveCalls, 1, "first save call")

    -- Second completion (replaces S/F checkpoint since same position)
    mock.setCar({ lapCount = car.lapCount + 2, previousLapTimeMs = 89000 })
    state.update(0.1, ac.getCar(0))
    assert_equal(ac._saveCalls, 2, "second save call should happen")
end)

--------------------------------------------------------------------------------
-- Checkpoint Stack Tests
--------------------------------------------------------------------------------

suite("checkpoint stack")

test("cycles through checkpoints on repeated loads", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    -- Push 3 checkpoints at different positions
    state.pushCheckpoint({
        carState = { mock = "state1" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.1,
        lapCount = 1,
        lapTimeMs = 5000,
    })
    state.pushCheckpoint({
        carState = { mock = "state2" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.5,
        lapCount = 1,
        lapTimeMs = 25000,
    })
    state.pushCheckpoint({
        carState = { mock = "state3" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.8,
        lapCount = 1,
        lapTimeMs = 40000,
    })

    assert_equal(state.getCheckpointCount(), 3, "should have 3 checkpoints")

    -- Load first
    mock.setCar({ lapCount = 1, lapTimeMs = 50000 })
    ac._messages = {}
    state.loadCheckpoint()
    local msg1 = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg1, "1/3") ~= nil, "should show 1/3, got: " .. msg1)

    -- Load second (immediately, no driving time)
    ac._messages = {}
    state.loadCheckpoint()
    local msg2 = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg2, "2/3") ~= nil, "should show 2/3, got: " .. msg2)

    -- Load third
    ac._messages = {}
    state.loadCheckpoint()
    local msg3 = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg3, "3/3") ~= nil, "should show 3/3, got: " .. msg3)

    -- Loop back to first
    ac._messages = {}
    state.loadCheckpoint()
    local msg4 = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg4, "1/3") ~= nil, "should loop back to 1/3, got: " .. msg4)
end)

test("non-repeat press reloads marker checkpoint", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    -- Push 3 checkpoints
    state.pushCheckpoint({
        carState = { mock = "state1" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.1, lapCount = 1, lapTimeMs = 5000,
    })
    state.pushCheckpoint({
        carState = { mock = "state2" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.5, lapCount = 1, lapTimeMs = 25000,
    })
    state.pushCheckpoint({
        carState = { mock = "state3" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.8, lapCount = 1, lapTimeMs = 40000,
    })

    mock.setCar({ lapCount = 1, lapTimeMs = 50000 })

    -- Load checkpoint 1
    ac._messages = {}
    state.loadCheckpoint()
    local msg1 = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg1, "1/3") ~= nil, "should load 1/3")

    -- Simulate 11 seconds of driving
    for i = 1, 110 do
        state.updateCheckpointDriveTimer(0.1)
    end

    -- Next load should go back to checkpoint 1 (resume behavior)
    ac._messages = {}
    state.loadCheckpoint()
    local msg2 = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg2, "1/3") ~= nil, "should reload 1/3 after resume, got: " .. msg2)
end)

test("repeat press (within 1s) advances to next older checkpoint", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    state.pushCheckpoint({
        carState = { mock = "state1" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.1, lapCount = 1, lapTimeMs = 5000,
    })
    state.pushCheckpoint({
        carState = { mock = "state2" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.5, lapCount = 1, lapTimeMs = 25000,
    })

    mock.setCar({ lapCount = 1, lapTimeMs = 50000 })

    -- Load checkpoint 1 (marker = 1)
    state.loadCheckpoint()

    -- Simulate 0.5 seconds of driving (within 1s repeat window)
    for i = 1, 5 do
        state.updateCheckpointDriveTimer(0.1)
    end

    -- Repeat press should advance to checkpoint 2 (next older)
    ac._messages = {}
    state.loadCheckpoint()
    local msg = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg, "2/2") ~= nil, "should advance to 2/2, got: " .. msg)
end)

test("shows next corner name in checkpoint message", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    -- Set up corners
    state.trackCorners = {
        { number = 1, name = "Bus Stop", startPos = 0.2, endPos = 0.3 },
        { number = 2, name = "Karussell", startPos = 0.6, endPos = 0.7 },
    }

    -- Push checkpoint before Bus Stop
    state.pushCheckpoint({
        carState = { mock = "state1" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.15, lapCount = 1, lapTimeMs = 5000,
    })

    mock.setCar({ lapCount = 1, lapTimeMs = 50000 })
    ac._messages = {}
    state.loadCheckpoint()

    local msg = ac._messages[1] and ac._messages[1].title or ""
    assert_true(string.find(msg, "Bus Stop") ~= nil, "should mention next corner Bus Stop, got: " .. msg)
end)

test("keeps current car lap count on load", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    state.pushCheckpoint({
        carState = { mock = "car_state" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.25,
        lapCount = 3,
        lapTimeMs = 10000,
    })

    mock.setCar({ lapCount = 5, lapTimeMs = 20000 })
    state.loadCheckpoint()

    assert_equal(state.lapNumber, 5, "lap number should follow current car")
end)

test("caps stack at 20 checkpoints", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    -- Push 25 checkpoints at different positions
    for i = 1, 25 do
        state.pushCheckpoint({
            carState = { mock = "state" .. i },
            lapSnapshot = state.currentLap:clone(),
            pos = i * 0.038, -- spread across track
            lapCount = 1,
            lapTimeMs = i * 3000,
        })
    end

    assert_equal(state.getCheckpointCount(), 20, "stack should be capped at 20")
end)

test("replaces nearby checkpoint instead of adding duplicate", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    -- Push checkpoint at 0.5
    state.pushCheckpoint({
        carState = { mock = "state_old" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.5, lapCount = 1, lapTimeMs = 5000,
    })
    assert_equal(state.getCheckpointCount(), 1, "should have 1 checkpoint")

    -- Push another checkpoint very close to 0.5
    state.pushCheckpoint({
        carState = { mock = "state_new" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.501, lapCount = 1, lapTimeMs = 6000,
    })
    assert_equal(state.getCheckpointCount(), 1, "should still have 1 checkpoint (replaced)")
end)

test("clearCheckpoint empties the stack", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    state.pushCheckpoint({
        carState = { mock = "state1" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.5, lapCount = 1, lapTimeMs = 5000,
    })
    assert_true(state.hasCheckpoint(), "should have checkpoint")

    state.clearCheckpoint()
    assert_true(not state.hasCheckpoint(), "should be empty after clear")
    assert_equal(state.getCheckpointCount(), 0, "count should be 0")
end)

--------------------------------------------------------------------------------
-- Delta Bar Outlap Tests
--------------------------------------------------------------------------------

suite("delta bar outlap")

test("shows OUTLAP when S/F crossed with pit limiter active", function()
    mock.resetCar()
    resetUiLog()

    -- Stub corner_analysis to avoid unrelated UI work
    package.loaded['lib.windows.corner_analysis'] = {
        getRecentCornerScores = function() return {} end
    }
    package.loaded['lib.windows.delta_bar'] = nil
    package.loaded['lib.lap'] = nil

    local lap = require('lib.lap')
    local delta_bar = require('lib.windows.delta_bar')

    local reference = lap.new("test_track", "test_car", "session")
    reference.pos = { 0.0, 0.5, 1.0 }
    reference.times = { 0, 30, 60 }

    -- Simulate pit exit: first frame at lapCount=0 with pit limiter on
    mock.setCar({ lapCount = 0, lapTimeMs = 0, splinePosition = 0.9, speedLimiterInAction = true })
    delta_bar.draw(0.1, reference, reference, 0.9, nil)

    -- Cross S/F with pit limiter still active -> outlap
    resetUiLog()
    mock.setCar({ lapCount = 1, lapTimeMs = 1000, splinePosition = 0.05, speedLimiterInAction = true })
    delta_bar.draw(0.1, reference, reference, 0.05, nil)

    local found = false
    for _, text in ipairs(ui._textLog or {}) do
        if text == "OUTLAP" then
            found = true
            break
        end
    end
    assert_true(found, "delta bar should show OUTLAP after S/F crossing with pit limiter")
end)

test("does NOT show OUTLAP when S/F crossed without pit limiter", function()
    mock.resetCar()
    resetUiLog()

    package.loaded['lib.windows.corner_analysis'] = {
        getRecentCornerScores = function() return {} end
    }
    package.loaded['lib.windows.delta_bar'] = nil
    package.loaded['lib.lap'] = nil

    local lap = require('lib.lap')
    local delta_bar = require('lib.windows.delta_bar')

    local reference = lap.new("test_track", "test_car", "session")
    reference.pos = { 0.0, 0.5, 1.0 }
    reference.times = { 0, 30, 60 }

    -- First frame at lapCount=0, no pit limiter (started on track)
    mock.setCar({ lapCount = 0, lapTimeMs = 0, splinePosition = 0.5, speedLimiterInAction = false })
    delta_bar.draw(0.1, reference, reference, 0.5, nil)

    -- Cross S/F without pit limiter -> real lap, not outlap
    resetUiLog()
    mock.setCar({ lapCount = 1, lapTimeMs = 1000, splinePosition = 0.05, speedLimiterInAction = false })
    delta_bar.draw(0.1, reference, reference, 0.05, nil)

    local found = false
    for _, text in ipairs(ui._textLog or {}) do
        if text == "OUTLAP" then
            found = true
            break
        end
    end
    assert_true(not found, "delta bar should NOT show OUTLAP after normal S/F crossing")
end)

--------------------------------------------------------------------------------
-- Checkpoint Integration: replay a lap, jump back, verify delta & corner data
--------------------------------------------------------------------------------

suite("checkpoint integration")

-- Helper: generate a MoTeC CSV with realistic lap data
-- Returns CSV string and the data arrays for verification
local function generateRealisticCSV(numSamples, lapTimeSec, trackName)
    trackName = trackName or "test_track"
    local lines = {
        '"Format","MoTeC CSV File"',
        '"Venue","' .. trackName .. '"',
        '"Vehicle","test_car"',
        '"Sample Rate","50","Hz"',
        '',
        '"Time","Lap Progression","Ground Speed","Driver Throttle Pos","Brake Pressure F","Brake Pressure R","Clutch Pos","Steering Angle","Fuel Remaining","Gear","G Force Lat","G Force Long"',
        '"s","","km/h","%","bar","bar","%","deg","l","","g","g"',
        '',
    }

    local data = {
        times = {},
        pos = {},
        speed = {},
        throttle = {},
        brake = {},
        steering = {},
        gear = {},
        fuel = {},
    }

    for i = 0, numSamples - 1 do
        local t = i * lapTimeSec / numSamples
        local p = i / numSamples
        -- Simulate realistic speed profile: straights and braking zones
        local phase = (p * 6) % 1  -- 6 "sectors" per lap
        local speed, throttle, brake, steer, gear
        if phase < 0.6 then
            -- Straight: full throttle, no brake, high speed
            speed = 200 + phase * 100
            throttle = 100
            brake = 0
            steer = 0
            gear = 5
        elseif phase < 0.7 then
            -- Braking: off throttle, heavy brake
            speed = 260 - (phase - 0.6) * 1200
            throttle = 0
            brake = 80
            steer = 2
            gear = 4
        else
            -- Corner: partial throttle, some brake, turning
            speed = 120 + (phase - 0.7) * 300
            throttle = (phase - 0.7) * 333
            brake = 0
            steer = 15 * (1 - (phase - 0.7) * 3.33)
            gear = 3
        end
        speed = math.max(80, math.min(300, speed))
        local fuel = 50 - (p * 5)

        data.times[i + 1] = t
        data.pos[i + 1] = p
        data.speed[i + 1] = speed
        data.throttle[i + 1] = throttle / 100
        data.brake[i + 1] = brake
        data.steering[i + 1] = steer
        data.gear[i + 1] = gear
        data.fuel[i + 1] = fuel

        table.insert(lines, string.format(
            '"%.4f","%.6f","%.1f","%.1f","%.1f","%.1f","0","%.1f","%.2f","%d","0.00","0.00"',
            t, p, speed, throttle, brake, brake, steer, fuel, gear
        ))
    end

    return table.concat(lines, "\n"), data
end

test("checkpoint restore preserves delta time accuracy", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()
    ac._messages = {}
    ac._saveCalls = 0

    -- Parameters
    local NUM_SAMPLES = 500  -- 500 samples at 50Hz = 10 second lap
    local LAP_TIME_SEC = 10
    local LAP_TIME_MS = LAP_TIME_SEC * 1000

    -- Generate CSV and write to VFS
    local csvContent = generateRealisticCSV(NUM_SAMPLES, LAP_TIME_SEC)
    local csvPath = "C:\\test_data\\reference_lap.csv"
    mock.vfsWrite(csvPath, csvContent)

    -- Load state fresh
    local state = loadStateFresh()
    local lap = require('lib.lap')

    -- Define some corners for the track
    state.trackCorners = {
        { number = 1, name = "Turn 1",    startPos = 0.10, endPos = 0.15 },
        { number = 2, name = "Hairpin",   startPos = 0.25, endPos = 0.32 },
        { number = 3, name = "Esses",     startPos = 0.42, endPos = 0.48 },
        { number = 4, name = "Bus Stop",  startPos = 0.58, endPos = 0.65 },
        { number = 5, name = "Final",     startPos = 0.78, endPos = 0.85 },
        { number = 6, name = "Last Turn", startPos = 0.92, endPos = 0.97 },
    }

    -- Load the CSV as the reference/best lap
    local refLap, warnings = state.loadCSV(csvPath)
    assert_true(refLap ~= nil, "should load reference CSV")
    state.setBestLap(refLap)
    assert_true(state.bestLap ~= nil, "bestLap should be set")

    -- Initialize state with first update
    mock.setCar({
        lapCount = 1,
        lapTimeMs = 1,
        splinePosition = 0.001,
        speedKmh = 200,
        gas = 1.0,
        brake = 0,
        clutch = 0,
        steer = 0,
        gear = 5,
        fuel = 50,
    })
    state.update(0.02, ac.getCar(0))

    -- Now replay the reference lap data through state.update
    -- Drive from position 0 to ~80% of the lap
    local targetPos = 0.80
    local dtFrame = 1 / 50  -- 50 Hz
    local targetSample = math.floor(targetPos * NUM_SAMPLES)

    for i = 1, targetSample do
        local t = i * LAP_TIME_SEC / NUM_SAMPLES
        local p = i / NUM_SAMPLES
        -- Reconstruct the same telemetry profile
        local phase = (p * 6) % 1
        local speed, throttle, brake, steer, gear
        if phase < 0.6 then
            speed = 200 + phase * 100
            throttle = 1.0
            brake = 0
            steer = 0
            gear = 5
        elseif phase < 0.7 then
            speed = 260 - (phase - 0.6) * 1200
            throttle = 0
            brake = 0.8  -- pedal position (mock uses pedal * 100 for bar)
            steer = 2
            gear = 4
        else
            speed = 120 + (phase - 0.7) * 300
            throttle = (phase - 0.7) * 3.33
            brake = 0
            steer = 15 * (1 - (phase - 0.7) * 3.33)
            gear = 3
        end
        speed = math.max(80, math.min(300, speed))

        mock.setCar({
            lapCount = 1,
            lapTimeMs = math.floor(t * 1000),
            splinePosition = p,
            speedKmh = speed,
            gas = throttle,
            brake = brake,
            clutch = 0,
            steer = steer,
            gear = gear,
            fuel = 50 - (p * 5),
        })
        state.update(dtFrame, ac.getCar(0))

        -- Manually save checkpoints at ~20%, ~40%, ~60% of the lap
        -- (auto-checkpoints won't fire because corners are too close together in this short lap)
        if (i == math.floor(0.20 * NUM_SAMPLES)) or
           (i == math.floor(0.40 * NUM_SAMPLES)) or
           (i == math.floor(0.60 * NUM_SAMPLES)) then
            state.saveCheckpoint(nil, false)
        end
    end

    -- Verify we have samples and position is around 80%
    local curLapLength = state.currentLap:length()
    assert_true(curLapLength > 50, "should have many samples, got: " .. curLapLength)
    assert_true(state.trackPosition > 0.7, "should be past 70%, at: " .. state.trackPosition)

    -- Check delta BEFORE checkpoint restore - should be near 0
    -- (we replayed the exact same timing as the reference)
    local deltaBefore = state.getDelta()
    assert_near(deltaBefore, 0, 1.0,
        "delta before restore should be near 0, got: " .. deltaBefore)

    -- Count how many checkpoints were created
    local cpCount = state.getCheckpointCount()
    assert_true(cpCount >= 3, "should have at least 3 checkpoints, got: " .. cpCount)

    -- Record the checkpoint count and current position
    local posBeforeJump = state.trackPosition

    -- Load checkpoint (first press = top of stack = most recent)
    ac._messages = {}
    state.loadCheckpoint()
    local posAfterFirst = state.trackPosition

    -- Second press within 1s (repeat) to go to next older checkpoint
    state.updateCheckpointDriveTimer(0.3)  -- 0.3s < 1s repeat window
    ac._messages = {}
    state.loadCheckpoint()
    local posAfterSecond = state.trackPosition

    -- The position should have gone backwards
    assert_true(posAfterSecond < posBeforeJump,
        string.format("should jump backwards: was %.3f, now %.3f", posBeforeJump, posAfterSecond))

    -- Now verify the critical thing: delta should still be ~0
    -- The currentLap was restored from checkpoint snapshot, and the time offset
    -- should be correct so that getDeltaVs returns near-zero
    local deltaAfter = state.getDelta()
    assert_near(deltaAfter, 0, 1.0,
        "delta after checkpoint restore should be near 0, got: " .. deltaAfter)

    -- Continue driving from the checkpoint position for a bit
    -- Replay the same reference data from the restored position onward
    --
    -- IMPORTANT: In AC, after teleport, car.lapTimeMs does NOT reset — it keeps
    -- ticking from wherever it was before the teleport. The lapTimeOffset corrects
    -- for this so that (car.lapTimeMs - lapTimeOffset) gives the correct elapsed time.
    --
    -- At the moment of checkpoint load:
    --   car.lapTimeMs was ~8000 (we were at 80% of a 10s lap)
    --   cp.lapTimeMs was ~4000 (checkpoint was at 40%)
    --   lapTimeOffset = 8000 - 4000 = 4000
    -- After teleport, AC timer keeps running from ~8000.
    -- For each subsequent frame at position p:
    --   AC timer = 8000 + (t_ref(p) - t_ref(restored_p)) * 1000
    --   correctedTime = AC_timer - offset = reference_time  ✓

    local restoredPos = state.trackPosition
    local startSample = math.floor(restoredPos * NUM_SAMPLES)
    -- Compute what AC's timer was at the moment of checkpoint load
    -- We were at ~80% (8000ms) and jumped to checkpoint pos
    local acTimerBase = math.floor(targetPos * LAP_TIME_MS)  -- ~8000
    local refTimeAtRestore = restoredPos * LAP_TIME_SEC  -- reference time at restored pos

    -- Drive 50 more samples (~1 second) from the restored position
    for i = startSample, math.min(startSample + 50, NUM_SAMPLES - 1) do
        local t_ref = i * LAP_TIME_SEC / NUM_SAMPLES
        local p = i / NUM_SAMPLES
        local phase = (p * 6) % 1
        local speed, throttle, brake, steer, gear
        if phase < 0.6 then
            speed = 200 + phase * 100
            throttle = 1.0
            brake = 0
            steer = 0
            gear = 5
        elseif phase < 0.7 then
            speed = 260 - (phase - 0.6) * 1200
            throttle = 0
            brake = 0.8
            steer = 2
            gear = 4
        else
            speed = 120 + (phase - 0.7) * 300
            throttle = (phase - 0.7) * 3.33
            brake = 0
            steer = 15 * (1 - (phase - 0.7) * 3.33)
            gear = 3
        end
        speed = math.max(80, math.min(300, speed))

        -- Simulate AC's timer: it continues ticking from where it was (acTimerBase)
        -- plus the real elapsed time since restore
        local elapsedSinceRestore = (t_ref - refTimeAtRestore) * 1000
        local acLapTimeMs = acTimerBase + math.floor(elapsedSinceRestore)

        mock.setCar({
            lapCount = 1,
            lapTimeMs = acLapTimeMs,
            splinePosition = p,
            speedKmh = speed,
            gas = throttle,
            brake = brake,
            clutch = 0,
            steer = steer,
            gear = gear,
            fuel = 50 - (p * 5),
        })
        state.update(dtFrame, ac.getCar(0))
    end

    -- After continuing to drive with the same timing, delta should still be ~0
    local deltaAfterDriving = state.getDelta()
    assert_near(deltaAfterDriving, 0, 1.0,
        "delta after continuing from checkpoint should be near 0, got: " .. deltaAfterDriving)

    -- Verify the currentLap has speed data that matches the reference at the current position
    local curSpeed = state.currentLap:speedAt(state.trackPosition)
    local refSpeed = state.bestLap:speedAt(state.trackPosition)
    assert_true(curSpeed ~= nil and curSpeed > 0, "current lap should have speed data")
    assert_true(refSpeed ~= nil and refSpeed > 0, "reference lap should have speed data")
    -- Speed values come from different sampling paths (CSV resampling vs direct mock),
    -- but should be in the same ballpark
    assert_near(curSpeed, refSpeed, 30,
        string.format("speeds should be similar: current=%.1f ref=%.1f", curSpeed, refSpeed))
end)

test("checkpoint restore does not break corner analysis data", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()
    ac._messages = {}
    ac._saveCalls = 0

    local NUM_SAMPLES = 500
    local LAP_TIME_SEC = 10
    local LAP_TIME_MS = LAP_TIME_SEC * 1000

    local csvContent = generateRealisticCSV(NUM_SAMPLES, LAP_TIME_SEC)
    local csvPath = "C:\\test_data\\corner_test.csv"
    mock.vfsWrite(csvPath, csvContent)

    local state = loadStateFresh()
    local lap = require('lib.lap')

    -- Set up corners
    state.trackCorners = {
        { number = 1, name = "Turn 1",   startPos = 0.10, endPos = 0.15 },
        { number = 2, name = "Hairpin",  startPos = 0.25, endPos = 0.32 },
        { number = 3, name = "Chicane",  startPos = 0.42, endPos = 0.48 },
        { number = 4, name = "Bus Stop", startPos = 0.58, endPos = 0.65 },
        { number = 5, name = "Final",    startPos = 0.78, endPos = 0.85 },
    }

    -- Load reference
    local refLap = state.loadCSV(csvPath)
    assert_true(refLap ~= nil, "should load reference CSV")
    state.setBestLap(refLap)

    -- Init state
    mock.setCar({
        lapCount = 1, lapTimeMs = 1, splinePosition = 0.001,
        speedKmh = 200, gas = 1.0, brake = 0, clutch = 0,
        steer = 0, gear = 5, fuel = 50,
    })
    state.update(0.02, ac.getCar(0))

    -- Drive to 70% replaying reference data
    local dtFrame = 1 / 50
    local targetSample = math.floor(0.70 * NUM_SAMPLES)
    for i = 1, targetSample do
        local t = i * LAP_TIME_SEC / NUM_SAMPLES
        local p = i / NUM_SAMPLES
        local phase = (p * 6) % 1
        local speed, throttle, brake, steer, gear
        if phase < 0.6 then
            speed = 200 + phase * 100
            throttle = 1.0
            brake = 0
            steer = 0
            gear = 5
        elseif phase < 0.7 then
            speed = 260 - (phase - 0.6) * 1200
            throttle = 0
            brake = 0.8
            steer = 2
            gear = 4
        else
            speed = 120 + (phase - 0.7) * 300
            throttle = (phase - 0.7) * 3.33
            brake = 0
            steer = 15 * (1 - (phase - 0.7) * 3.33)
            gear = 3
        end
        speed = math.max(80, math.min(300, speed))

        mock.setCar({
            lapCount = 1, lapTimeMs = math.floor(t * 1000),
            splinePosition = p, speedKmh = speed,
            gas = throttle, brake = brake, clutch = 0,
            steer = steer, gear = gear, fuel = 50 - (p * 5),
        })
        state.update(dtFrame, ac.getCar(0))
    end

    -- Manually save a checkpoint at current position (guaranteed)
    state.saveCheckpoint(nil, true)

    -- Verify currentLap has data for past corners
    -- Check that we can query telemetry at corner positions
    for _, c in ipairs(state.trackCorners) do
        if c.startPos < 0.70 then
            local curSpeed = state.currentLap:speedAt(c.startPos)
            local refSpeed = state.bestLap:speedAt(c.startPos)
            assert_true(curSpeed ~= nil and curSpeed > 0,
                "currentLap should have speed at corner " .. c.name .. " start")
            assert_true(refSpeed ~= nil and refSpeed > 0,
                "bestLap should have speed at corner " .. c.name .. " start")
        end
    end

    -- Load checkpoint (jumps back)
    state.loadCheckpoint()

    -- After restore, verify the lap snapshot still has corner data
    for _, c in ipairs(state.trackCorners) do
        if c.startPos < state.trackPosition then
            local curSpeed = state.currentLap:speedAt(c.startPos)
            assert_true(curSpeed ~= nil and curSpeed > 0,
                "after restore, currentLap should have speed at " .. c.name)
        end
    end

    -- Verify bestLap is unchanged (should be the original reference)
    assert_true(state.bestLap ~= nil, "bestLap should still exist after restore")
    assert_true(state.bestLap:length() > 100, "bestLap should have many samples")

    -- Verify bestLapCorners analysis still exists
    if state.bestLapCorners then
        for _, c in ipairs(state.trackCorners) do
            local analysis = state.bestLapCorners[c.number]
            -- bestLapCorners may or may not have data depending on corner analysis
            -- But the structure should not be corrupted
            if analysis then
                assert_true(type(analysis) == "table",
                    "corner analysis for " .. c.name .. " should be a table")
            end
        end
    end
end)

test("checkpoint stack discards entries above marker on new push", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')
    state.currentLap = lap.new("test_track", "test_car", "session")

    -- Push 5 checkpoints
    for i = 1, 5 do
        state.pushCheckpoint({
            carState = { mock = "state" .. i },
            lapSnapshot = state.currentLap:clone(),
            pos = i * 0.15, lapCount = 1, lapTimeMs = i * 10000,
        })
    end
    assert_equal(state.getCheckpointCount(), 5, "should have 5 checkpoints")

    mock.setCar({ lapCount = 1, lapTimeMs = 50000 })

    -- Load top of stack (most recent, pos=0.75)
    state.loadCheckpoint()

    -- Repeat press within 1s to advance to second (pos=0.60)
    state.updateCheckpointDriveTimer(0.3)
    state.loadCheckpoint()

    -- Repeat press to advance to third (pos=0.45)
    state.updateCheckpointDriveTimer(0.3)
    state.loadCheckpoint()
    -- Now marker is at index 3

    -- Wait >1s (not a repeat), then push a new checkpoint
    -- This should discard checkpoints 1 and 2 (more recent than marker=3)
    state.updateCheckpointDriveTimer(2.0)
    state.pushCheckpoint({
        carState = { mock = "new" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.50, lapCount = 1, lapTimeMs = 55000,
    })

    -- After discard: old indices 1,2 removed (were pos=0.75,0.60), new one pushed at front
    -- Remaining: new(0.50), old_3(0.45), old_4(0.30), old_5(0.15) = 4 checkpoints
    assert_equal(state.getCheckpointCount(), 4,
        "should have 4 checkpoints after discard+push, got: " .. state.getCheckpointCount())

    -- First in stack should be the new one
    local stack = state.getCheckpointStack()
    assert_near(stack[1].pos, 0.50, 0.01, "top should be new checkpoint at 0.50")
    assert_near(stack[2].pos, 0.45, 0.01, "second should be old index 3 at 0.45")
end)
