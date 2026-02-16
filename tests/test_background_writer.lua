-- test_background_writer.lua - Tests for background_writer.lua module

suite("background_writer")

-- Helper to reset module state between tests
local function resetModule()
    package.loaded['lib.core.background_writer'] = nil
    mock.resetVfs()
end

-- Helper to create a mock car object for addSample
local function mockCar(opts)
    opts = opts or {}
    return {
        lapTimeMs = opts.time or 0,
        splinePosition = opts.pos or 0,
        speedKmh = opts.speed or 100,
        gas = opts.throttle or 0.5,
        brake = opts.brake or 0,
        gear = opts.gear or 3,
        clutch = 1 - (opts.clutch or 0),  -- Inverted in lap.lua
        steer = opts.steer or 0,
        fuel = opts.fuel or 50,
        acceleration = vec3(opts.gLat or 0, 0, opts.gLong or 0),
        wheels = {
            [0] = { slip = 0, ndSlip = 0, suspensionTravel = 0 },
            [1] = { slip = 0, ndSlip = 0, suspensionTravel = 0 },
            [2] = { slip = 0, ndSlip = 0, suspensionTravel = 0 },
            [3] = { slip = 0, ndSlip = 0, suspensionTravel = 0 },
        },
        tractionControlInAction = false,
        isEngineLimiterOn = false,
        wheelsOutside = 0,
    }
end

test("paths.sanitize removes invalid characters", function()
    resetModule()
    local paths = require('lib.core.paths')

    -- Test basic sanitization
    assert_equal(paths.sanitize("simple"), "simple")
    assert_equal(paths.sanitize("has spaces"), "has_spaces")
    assert_equal(paths.sanitize("has:colons"), "has_colons")
    assert_equal(paths.sanitize("has/slashes"), "has_slashes")
    assert_equal(paths.sanitize("has\\backslashes"), "has_backslashes")
    assert_equal(paths.sanitize('has"quotes'), "has_quotes")
    assert_equal(paths.sanitize("has<>pipes|"), "has_pipes_")

    -- Test multiple underscores get collapsed
    assert_equal(paths.sanitize("too___many___underscores"), "too_many_underscores")

    -- Test empty/nil returns default
    assert_equal(paths.sanitize(""), "unknown")
    assert_equal(paths.sanitize(nil), "unknown")
end)

test("formatLapTime produces correct format", function()
    resetModule()
    local bg_writer = require('lib.core.background_writer')
    
    -- Test various lap times
    assert_equal(bg_writer._testExports.formatLapTime(60000), "1-00.000")  -- 1 minute exactly
    assert_equal(bg_writer._testExports.formatLapTime(90123), "1-30.123")  -- 1:30.123
    assert_equal(bg_writer._testExports.formatLapTime(112577), "1-52.577") -- 1:52.577
    assert_equal(bg_writer._testExports.formatLapTime(0), "0-00.000")      -- zero
    assert_equal(bg_writer._testExports.formatLapTime(-1), "0-00.000")     -- negative
end)

test("buildFilename creates timestamp-laptime format", function()
    resetModule()
    local bg_writer = require('lib.core.background_writer')

    -- Create a mock lap object
    local mockLap = {
        track = "test_track",
        car = "test_car",
        time = 112577,  -- 1:52.577
    }

    local filename = bg_writer._testExports.buildFilename(mockLap)

    -- Should be timestamp-laptime (track and car are in directory path)
    assert_true(filename:match("%-1%-52%.577$"), "Filename should end with lap time")
    assert_true(not filename:match("test_track"), "Filename should NOT contain track name")
    assert_true(not filename:match("test_car"), "Filename should NOT contain car name (car is in dir)")
end)

test("getSaveDir returns paths.autosaveDir", function()
    resetModule()

    -- Mock environment variable
    local originalGetenv = os.getenv
    os.getenv = function(name)
        if name == "USERPROFILE" then return "C:\\Users\\TestUser" end
        return originalGetenv(name)
    end

    -- Reset paths module too so it picks up mock env
    package.loaded['lib.core.paths'] = nil

    local bg_writer = require('lib.core.background_writer')
    local dir = bg_writer.getSaveDir("test_track", "test_car")

    assert_equal(dir, "C:\\Users\\TestUser\\Documents\\ac-tracer\\data\\test_track\\test_car\\autosave\\")

    os.getenv = originalGetenv
end)

test("queueLapSave rejects lap with too few samples", function()
    resetModule()
    local bg_writer = require('lib.core.background_writer')
    local lap = require('lib.lap')
    
    -- Create a lap with very few samples
    local shortLap = lap.new()
    shortLap.track = "test_track"
    shortLap.car = "test_car"
    shortLap.time = 60000
    
    -- Add only 10 samples (below 100 minimum)
    for i = 1, 10 do
        shortLap:addSample(mockCar({
            time = i * 100,
            pos = i / 100,
            speed = 100,
        }))
    end
    
    local result = bg_writer.queueLapSave(shortLap)
    assert_equal(result, false, "Should reject lap with too few samples")
end)

test("queueLapSave rejects lap with no time", function()
    resetModule()
    local bg_writer = require('lib.core.background_writer')
    local lap = require('lib.lap')
    
    local invalidLap = lap.new()
    invalidLap.track = "test_track"
    invalidLap.car = "test_car"
    invalidLap.time = 0  -- No valid lap time
    
    -- Add enough samples
    for i = 1, 150 do
        invalidLap:addSample(mockCar({
            time = i * 100,
            pos = i / 1000,
            speed = 100,
        }))
    end
    
    local result = bg_writer.queueLapSave(invalidLap)
    assert_equal(result, false, "Should reject lap with no valid time")
end)

test("queueLapSave rejects nil lap", function()
    resetModule()
    local bg_writer = require('lib.core.background_writer')
    
    local result = bg_writer.queueLapSave(nil)
    assert_equal(result, false, "Should reject nil lap")
end)

test("queueLapSave accepts valid lap and creates files", function()
    resetModule()

    -- Mock environment variable
    local originalGetenv = os.getenv
    os.getenv = function(name)
        if name == "USERPROFILE" then return "C:\\Users\\TestUser" end
        return originalGetenv(name)
    end

    -- Reset paths module too
    package.loaded['lib.core.paths'] = nil

    local bg_writer = require('lib.core.background_writer')
    local lap = require('lib.lap')

    -- Create a valid lap
    local validLap = lap.new()
    validLap.track = "test_track"
    validLap.car = "test_car"
    validLap.time = 90000  -- 1:30.000

    -- Add enough samples (>100)
    for i = 1, 150 do
        validLap:addSample(mockCar({
            time = i * 100,
            pos = i / 1000,
            speed = 100 + (i % 50),
            throttle = 0.5,
            brake = (i % 20 == 0) and 0.8 or 0,
            gear = 3 + (i % 3),
        }))
    end

    local result = bg_writer.queueLapSave(validLap, { includeJSON = false })
    assert_equal(result, true, "Should accept valid lap")

    -- Check that autosave directory was created under data/{track}/{car}/autosave/
    assert_true(io.dirExists("C:/Users/TestUser/Documents/ac-tracer/data/test_track/test_car/autosave"),
        "Autosave directory should be created")

    os.getenv = originalGetenv
end)

test("duplicate lap detection prevents double saves", function()
    resetModule()
    
    -- Mock environment variable
    local originalGetenv = os.getenv
    os.getenv = function(name)
        if name == "USERPROFILE" then return "C:\\Users\\TestUser" end
        return originalGetenv(name)
    end
    
    local bg_writer = require('lib.core.background_writer')
    local lap = require('lib.lap')
    
    -- Create a valid lap
    local validLap = lap.new()
    validLap.track = "test_track"
    validLap.car = "test_car"
    validLap.time = 95000
    
    for i = 1, 150 do
        validLap:addSample(mockCar({
            time = i * 100,
            pos = i / 1000,
            speed = 100,
        }))
    end
    
    -- First save should succeed
    local result1 = bg_writer.queueLapSave(validLap, { includeJSON = false })
    assert_equal(result1, true, "First save should succeed")
    
    -- Second save of same lap should be rejected
    local result2 = bg_writer.queueLapSave(validLap, { includeJSON = false })
    assert_equal(result2, false, "Duplicate save should be rejected")
    
    os.getenv = originalGetenv
end)
