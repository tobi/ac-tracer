-- test_state.lua - Integration tests for state.lua

local lap = require('lib.lap')

local function withState(testFn, options)
    options = options or {}
    local original = {
        state = package.loaded['lib.core.state'],
        settings = package.loaded['lib.core.settings'],
        history_storage = package.loaded['lib.core.history'],
        notification = package.loaded['sounds/notification'],
        csv_export = package.loaded['lib.lap.csv_export'],
        file_utils = package.loaded['lib.core.files'],
        io_open = io.open,
        io_createDir = io.createDir,
    }

    local settings = { mode = "reference" }
    settings.comparisonMode = function() return settings.mode end
    settings.speedDropThreshold = function() return 5 end
    settings.brakeThreshold = function() return 5 end
    settings.throttleThreshold = function() return 0.9 end
    settings.brakeBeepMode = function() return "off" end

    local history_storage = { laps = {} }
    history_storage.setTrackCar = function(track, car)
        history_storage.track = track
        history_storage.car = car
    end
    history_storage.load = function() return false end
    history_storage.save = function() end
    history_storage.add = function() end
    history_storage.getFastestFromSession = function() return nil end
    history_storage.getLapsFromSession = function() return {} end
    history_storage.getLapsNotFromSession = function() return {} end

    package.loaded['lib.core.settings'] = settings
    package.loaded['lib.core.history'] = history_storage
    package.loaded['sounds/notification'] = { init = function() end, playSave = function() end, playLoad = function() end }
    package.loaded['lib.lap.csv_export'] = { saveLap = function() return "path" end }
    package.loaded['lib.core.files'] = { scanCSVFiles = function() return {} end, formatLapTime = function() return "" end }
    package.loaded['lib.core.state'] = nil

    io.open = options.ioOpen or function() return nil end
    io.createDir = options.ioCreateDir or function() return true end

    local state = require('lib.core.state')
    testFn(state, settings, history_storage)

    package.loaded['lib.core.state'] = original.state
    package.loaded['lib.core.settings'] = original.settings
    package.loaded['lib.core.history'] = original.history_storage
    package.loaded['sounds/notification'] = original.notification
    package.loaded['lib.lap.csv_export'] = original.csv_export
    package.loaded['lib.core.files'] = original.file_utils
    io.open = original.io_open
    io.createDir = original.io_createDir
end

suite("state")

test("init sets session and history reference", function()
    withState(function(state, settings, history_storage)
        local car = ac.getCar(0)
        car.idValue = "car_test"
        state.init(car)

        assert_equal(state.track, "test_track")
        assert_equal(state.car, "car_test")
        assert_not_nil(state.sessionId)
        assert_equal(history_storage.track, "test_track")
        assert_equal(history_storage.car, "car_test")
        assert_not_nil(state.currentLap)
        assert_equal(state.history, history_storage.laps)
    end)
end)

test("getComparisonLap respects comparisonMode", function()
    withState(function(state, settings)
        local lapA = lap.new("track", "car", "s1")
        local lapB = lap.new("track", "car", "s1")
        local lapC = lap.new("track", "car", "s1")
        local lapD = lap.new("track", "car", "s1")

        state.bestLap = lapA
        state.bestInSession = lapB
        state.recentBest = lapC
        state.getBestCornersLap = function() return lapD end

        settings.mode = "reference"
        assert_equal(state.getComparisonLap(), lapA)

        settings.mode = "sessionBest"
        assert_equal(state.getComparisonLap(), lapB)

        settings.mode = "recentBest"
        assert_equal(state.getComparisonLap(), lapC)

        settings.mode = "bestCorners"
        assert_equal(state.getComparisonLap(), lapD)

        settings.mode = "off"
        assert_nil(state.getComparisonLap())
    end)
end)

test("updateBrakeScale uses headroom and rounding", function()
    withState(function(state)
        state.history = {}
        state.bestLap = { maxBrakeBars = function() return 120 end }
        state.currentLap = { maxBrakeBars = function() return 80 end }

        state.updateBrakeScale()
        assert_equal(state.brakeScaleBar, 140)
    end)
end)

test("corner CRUD updates trackCorners", function()
    local fakeWriter = {
        write = function() end,
        close = function() end,
    }

    withState(function(state)
        state.track = "test_track"
        state.trackCorners = {}

        local num = state.insertCorner(0.1, 0.2)
        assert_equal(num, 1)
        assert_equal(state.getCornerCount(), 1)

        local updated = state.updateCorner(1, { name = "T1", startPos = 0.12 })
        assert_true(updated)
        assert_equal(state.trackCorners[1].name, "T1")
        assert_near(state.trackCorners[1].startPos, 0.12, 0.0001)

        local deleted = state.deleteCorner(1)
        assert_true(deleted)
        assert_equal(state.getCornerCount(), 0)
    end, {
        ioOpen = function(path, mode)
            if mode == "r" then return nil end
            return fakeWriter
        end,
        ioCreateDir = function() return true end,
    })
end)

test("ghost accessors read from comparison lap", function()
    withState(function(state, settings)
        local ghostLap = {
            getTimeAtPos = function(_, pos) return pos * 10 end,
            findMaxSteering = function() return 15 end,
            findBrakePoint = function() return 0.2 end,
            findLiftPoint = function() return 0.15 end,
            findApex = function() return 0.25, 100 end,
        }

        state.bestLap = ghostLap
        settings.mode = "reference"

        assert_near(state.getGhostTimeAtPos(0.2), 2.0, 0.001)
        assert_equal(state.getGhostMaxSteeringInRange(0.1, 0.2), 15)
        assert_equal(state.getGhostBrakePointInRange(0.1, 0.2), 0.2)
        assert_equal(state.getGhostLiftPointInRange(0.1, 0.2), 0.15)
        local apexPos, apexSpeed = state.getGhostApexInRange(0.1, 0.2)
        assert_equal(apexPos, 0.25)
        assert_equal(apexSpeed, 100)
    end)
end)
