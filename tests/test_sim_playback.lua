-- test_sim_playback.lua - Unit tests for simulation playback logic

-- Setup mock environment
local mock = require('tests.mock_ac')

suite("Simulation Playback")

--------------------------------------------------------------------------------
-- Mock lap for testing
--------------------------------------------------------------------------------

local function createMockLap(duration_seconds, sample_count)
    sample_count = sample_count or 100
    local lap = {
        time = duration_seconds * 1000,  -- milliseconds
        track = "test_track",
        car = "test_car",
        throttle = {},
        brake = {},
        steering = {},
        speed = {},
        gear = {},
        pos = {},
        times = {},
    }

    -- Generate sample data
    for i = 1, sample_count do
        local t = (i - 1) / (sample_count - 1)  -- 0 to 1
        lap.throttle[i] = math.sin(t * math.pi * 2) * 0.5 + 0.5  -- 0-1 oscillating
        lap.brake[i] = math.max(0, math.sin(t * math.pi * 4) * 50)  -- 0-50 bar
        lap.steering[i] = 0.5 + math.sin(t * math.pi * 3) * 0.3  -- 0.2-0.8
        lap.speed[i] = 100 + math.sin(t * math.pi * 2) * 50  -- 50-150 km/h
        lap.gear[i] = math.floor(t * 5) + 1  -- 1-6
        lap.pos[i] = t  -- 0 to 1 linear
        lap.times[i] = t * duration_seconds  -- 0 to duration
    end

    -- Add accessor methods
    function lap:length() return #self.throttle end

    function lap:throttleAt(pos)
        return self:interpolate(self.throttle, pos)
    end

    function lap:brakeAt(pos)
        return self:interpolate(self.brake, pos)
    end

    function lap:steeringAt(pos)
        return self:interpolate(self.steering, pos)
    end

    function lap:speedAt(pos)
        return self:interpolate(self.speed, pos)
    end

    function lap:gearAt(pos)
        return math.floor(self:interpolate(self.gear, pos) + 0.5)
    end

    function lap:timeAt(pos)
        return self:interpolate(self.times, pos)
    end

    function lap:interpolate(arr, pos)
        if #arr == 0 then return 0 end
        local idx = pos * (#arr - 1) + 1
        local i = math.floor(idx)
        local f = idx - i
        if i < 1 then return arr[1] end
        if i >= #arr then return arr[#arr] end
        return arr[i] + (arr[i + 1] - arr[i]) * f
    end

    return lap
end

--------------------------------------------------------------------------------
-- Playback State Tests
--------------------------------------------------------------------------------

test("playback state initializes correctly", function()
    local playback = {
        lap = nil,
        position = 0,
        playing = false,
        speed = 1.0,
        time = 0,
        lapTime = 0,
    }

    assert_equal(playback.position, 0)
    assert_equal(playback.playing, false)
    assert_equal(playback.speed, 1.0)
    assert_equal(playback.time, 0)
    assert_nil(playback.lap)
end)

test("loading lap sets playback state", function()
    local mockLap = createMockLap(90)  -- 90 second lap

    local playback = {
        lap = nil,
        position = 0.5,  -- Start mid-lap
        playing = true,
        speed = 2.0,
        time = 45,
        lapTime = 0,
    }

    -- Simulate loadLap behavior
    playback.lap = mockLap
    playback.position = 0
    playback.time = 0
    playback.lapTime = mockLap.time / 1000
    playback.playing = false

    assert_not_nil(playback.lap)
    assert_equal(playback.position, 0)
    assert_equal(playback.time, 0)
    assert_equal(playback.lapTime, 90)
    assert_equal(playback.playing, false)
end)

--------------------------------------------------------------------------------
-- Seek Functions Tests
--------------------------------------------------------------------------------

test("seekToPosition clamps to valid range", function()
    local mockLap = createMockLap(90)

    local playback = {
        lap = mockLap,
        position = 0,
        time = 0,
        lapTime = 90,
    }

    -- Simulate seekToPosition
    local function seekToPosition(pos)
        playback.position = math.max(0, math.min(1, pos))
        if playback.lap then
            playback.time = playback.lap:timeAt(playback.position)
        end
    end

    -- Test normal seek
    seekToPosition(0.5)
    assert_near(playback.position, 0.5, 0.001)
    assert_near(playback.time, 45, 1)  -- ~45 seconds at 50%

    -- Test clamp to 0
    seekToPosition(-0.5)
    assert_equal(playback.position, 0)

    -- Test clamp to 1
    seekToPosition(1.5)
    assert_equal(playback.position, 1)
end)

test("seekByTime advances correctly", function()
    local mockLap = createMockLap(90)

    local playback = {
        lap = mockLap,
        position = 0,
        time = 0,
        lapTime = 90,
    }

    local function seekToPosition(pos)
        playback.position = math.max(0, math.min(1, pos))
        if playback.lap then
            playback.time = playback.lap:timeAt(playback.position)
        end
    end

    local function seekByTime(deltaSeconds)
        playback.time = math.max(0, playback.time + deltaSeconds)
        if playback.lapTime > 0 then
            playback.time = math.min(playback.time, playback.lapTime)
            seekToPosition(playback.time / playback.lapTime)
        end
    end

    -- Seek forward 10 seconds
    seekByTime(10)
    assert_near(playback.time, 10, 0.1)
    assert_near(playback.position, 10/90, 0.01)

    -- Seek forward another 20 seconds
    seekByTime(20)
    assert_near(playback.time, 30, 0.1)

    -- Seek backward 15 seconds
    seekByTime(-15)
    assert_near(playback.time, 15, 0.1)

    -- Try to seek before start
    seekByTime(-100)
    assert_equal(playback.time, 0)
    assert_equal(playback.position, 0)

    -- Try to seek past end
    seekByTime(200)
    assert_equal(playback.time, 90)
    assert_equal(playback.position, 1)
end)

--------------------------------------------------------------------------------
-- Update Playback Tests
--------------------------------------------------------------------------------

test("updatePlayback advances time when playing", function()
    local mockLap = createMockLap(90)

    local playback = {
        lap = mockLap,
        position = 0,
        playing = true,
        speed = 1.0,
        time = 0,
        lapTime = 90,
    }

    local function updatePlayback(dt)
        if not playback.lap or not playback.playing then return end

        playback.time = playback.time + (dt * playback.speed)

        if playback.time >= playback.lapTime then
            playback.time = 0  -- Loop
        end

        -- Find position at current time
        local lapData = playback.lap
        local times = lapData.times
        for i = 1, #times - 1 do
            if times[i + 1] > playback.time then
                local frac = (playback.time - times[i]) / (times[i + 1] - times[i])
                playback.position = lapData.pos[i] + (lapData.pos[i + 1] - lapData.pos[i]) * frac
                break
            end
        end
    end

    -- Simulate 1 second at 60fps
    for i = 1, 60 do
        updatePlayback(1/60)
    end

    assert_near(playback.time, 1.0, 0.02)
    assert_near(playback.position, 1/90, 0.01)
end)

test("updatePlayback respects speed multiplier", function()
    local mockLap = createMockLap(90)

    local playback = {
        lap = mockLap,
        position = 0,
        playing = true,
        speed = 2.0,  -- 2x speed
        time = 0,
        lapTime = 90,
    }

    local function updatePlayback(dt)
        if not playback.lap or not playback.playing then return end
        playback.time = playback.time + (dt * playback.speed)
        if playback.time >= playback.lapTime then
            playback.time = 0
        end
    end

    -- Simulate 1 second at 2x speed
    updatePlayback(1.0)

    assert_near(playback.time, 2.0, 0.001)  -- Should be 2 seconds of lap time
end)

test("updatePlayback does nothing when paused", function()
    local mockLap = createMockLap(90)

    local playback = {
        lap = mockLap,
        position = 0.5,
        playing = false,  -- Paused
        speed = 1.0,
        time = 45,
        lapTime = 90,
    }

    local function updatePlayback(dt)
        if not playback.lap or not playback.playing then return end
        playback.time = playback.time + (dt * playback.speed)
    end

    local initialTime = playback.time
    local initialPos = playback.position

    -- Simulate time passing
    updatePlayback(10.0)

    assert_equal(playback.time, initialTime)
    assert_equal(playback.position, initialPos)
end)

test("updatePlayback loops at lap end", function()
    local mockLap = createMockLap(90)

    local playback = {
        lap = mockLap,
        position = 0.99,
        playing = true,
        speed = 1.0,
        time = 89,  -- Near end
        lapTime = 90,
    }

    local function updatePlayback(dt)
        if not playback.lap or not playback.playing then return end
        playback.time = playback.time + (dt * playback.speed)
        if playback.time >= playback.lapTime then
            playback.time = 0  -- Loop
        end
    end

    -- Advance past end
    updatePlayback(5.0)

    assert_equal(playback.time, 0)  -- Should have looped
end)

test("updatePlayback does nothing without lap", function()
    local playback = {
        lap = nil,
        position = 0,
        playing = true,
        speed = 1.0,
        time = 0,
        lapTime = 0,
    }

    local function updatePlayback(dt)
        if not playback.lap or not playback.playing then return end
        playback.time = playback.time + (dt * playback.speed)
    end

    updatePlayback(10.0)

    assert_equal(playback.time, 0)  -- Should not change
end)

--------------------------------------------------------------------------------
-- Speed Control Tests
--------------------------------------------------------------------------------

test("speed multipliers work correctly", function()
    local speeds = {0.25, 0.5, 1.0, 2.0}

    for _, speed in ipairs(speeds) do
        local playback = {
            lap = createMockLap(100),
            playing = true,
            speed = speed,
            time = 0,
            lapTime = 100,
        }

        local function updatePlayback(dt)
            if not playback.lap or not playback.playing then return end
            playback.time = playback.time + (dt * playback.speed)
        end

        -- Simulate 10 seconds of real time
        updatePlayback(10.0)

        local expectedLapTime = 10.0 * speed
        assert_near(playback.time, expectedLapTime, 0.001,
            string.format("Speed %.2fx: expected %.2f, got %.2f",
                speed, expectedLapTime, playback.time))
    end
end)

--------------------------------------------------------------------------------
-- Mock Lap Accessor Tests
--------------------------------------------------------------------------------

test("mock lap accessors interpolate correctly", function()
    local lap = createMockLap(90, 100)

    -- Test at start
    assert_near(lap:timeAt(0), 0, 0.1)
    assert_near(lap.pos[1], 0, 0.001)

    -- Test at end
    assert_near(lap:timeAt(1), 90, 0.1)
    assert_near(lap.pos[#lap.pos], 1, 0.001)

    -- Test mid-point
    assert_near(lap:timeAt(0.5), 45, 1)

    -- Test values are in valid ranges
    for p = 0, 1, 0.1 do
        local throttle = lap:throttleAt(p)
        local brake = lap:brakeAt(p)
        local steering = lap:steeringAt(p)
        local speed = lap:speedAt(p)
        local gear = lap:gearAt(p)

        assert_true(throttle >= 0 and throttle <= 1,
            string.format("Throttle %.2f out of range at pos %.2f", throttle, p))
        assert_true(brake >= 0,
            string.format("Brake %.2f out of range at pos %.2f", brake, p))
        assert_true(steering >= 0 and steering <= 1,
            string.format("Steering %.2f out of range at pos %.2f", steering, p))
        assert_true(speed >= 0,
            string.format("Speed %.2f out of range at pos %.2f", speed, p))
        assert_true(gear >= 1 and gear <= 6,
            string.format("Gear %d out of range at pos %.2f", gear, p))
    end
end)

--------------------------------------------------------------------------------
-- Position to Time Mapping Tests
--------------------------------------------------------------------------------

test("position and time stay synchronized", function()
    local mockLap = createMockLap(90, 100)

    local playback = {
        lap = mockLap,
        position = 0,
        time = 0,
        lapTime = 90,
    }

    local function seekToPosition(pos)
        playback.position = math.max(0, math.min(1, pos))
        if playback.lap then
            playback.time = playback.lap:timeAt(playback.position)
        end
    end

    -- Test various positions
    local testPositions = {0, 0.25, 0.5, 0.75, 1.0}
    for _, pos in ipairs(testPositions) do
        seekToPosition(pos)

        local expectedTime = pos * 90
        assert_near(playback.time, expectedTime, 1,
            string.format("Position %.2f should give time ~%.1f, got %.1f",
                pos, expectedTime, playback.time))
    end
end)
