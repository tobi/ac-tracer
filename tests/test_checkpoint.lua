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
