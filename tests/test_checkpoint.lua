-- test_checkpoint.lua - Tests for checkpoint and delta outlap behavior

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

test("auto-saves checkpoint on lap completion when none exists", function()
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

test("does not auto-save when checkpoint already exists", function()
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

    -- First completion creates checkpoint
    mock.setCar({ lapCount = car.lapCount + 1, previousLapTimeMs = 90000 })
    state.update(0.1, ac.getCar(0))
    assert_true(state.hasCheckpoint(), "checkpoint should exist")
    assert_equal(ac._saveCalls, 1, "checkpoint should be saved once")

    -- Next completion should not overwrite
    mock.setCar({ lapCount = car.lapCount + 2, previousLapTimeMs = 89000 })
    state.update(0.1, ac.getCar(0))
    assert_equal(ac._saveCalls, 1, "checkpoint should not be saved again")
end)

--------------------------------------------------------------------------------
-- Checkpoint Load Lap Count Tests
--------------------------------------------------------------------------------

suite("checkpoint load lap count")

test("keeps current car lap count on load", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    mock.resetCar()
    mock.clearStorage()

    local state = loadStateFresh()
    local lap = require('lib.lap')

    state.currentLap = lap.new("test_track", "test_car", "session")

    state.checkpoint = {
        carState = { mock = "car_state" },
        lapSnapshot = state.currentLap:clone(),
        pos = 0.25,
        lapCount = 3,
        lapTimeMs = 10000,
    }

    mock.setCar({ lapCount = 5, lapTimeMs = 20000 })
    state.loadCheckpoint()

    assert_equal(state.lapNumber, 5, "lap number should follow current car")
end)

--------------------------------------------------------------------------------
-- Delta Bar Outlap Tests
--------------------------------------------------------------------------------

suite("delta bar outlap")

test("shows OUTLAP when lap count is zero", function()
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

    mock.setCar({ lapCount = 0, lapTimeMs = 10000, splinePosition = 0.2 })
    delta_bar.draw(0.1, reference, reference, 0.2, nil)

    local found = false
    for _, text in ipairs(ui._textLog or {}) do
        if text == "OUTLAP" then
            found = true
            break
        end
    end
    assert_true(found, "delta bar should show OUTLAP")
end)
