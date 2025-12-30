-- test_lap.lua - Tests for lap.lua module

local lap = require('lap')

suite("lap.new")

test("creates empty lap with metadata", function()
    local l = lap.new("test_track", "test_car", "session_123")
    
    assert_equal(l.track, "test_track")
    assert_equal(l.car, "test_car")
    assert_equal(l.sessionId, "session_123")
    assert_equal(l.completed, false)
    assert_equal(l.valid, true)
    assert_equal(l.time, 0)
    assert_type(l.throttle, "table")
    assert_type(l.brake, "table")
    assert_type(l.pos, "table")
end)

test("isEmpty returns true for new lap", function()
    local l = lap.new("track", "car")
    assert_true(l:isEmpty())
end)

test("length returns 0 for new lap", function()
    local l = lap.new("track", "car")
    assert_equal(l:length(), 0)
end)


suite("lap.addSample")

test("adds sample from car state", function()
    local l = lap.new("track", "car")
    local car = {
        gas = 0.8,
        brake = 0.3,
        clutch = 0.0,
        steer = 15,  -- degrees
        speedKmh = 150,
        gear = 4,
        splinePosition = 0.25,
        lapTimeMs = 15000,
        fuel = 45,
    }
    
    l:addSample(car)
    
    assert_equal(l:length(), 1)
    assert_equal(l.throttle[1], 0.8)
    assert_equal(l.brake[1], 0.3)  -- Mock returns car.brake directly
    assert_equal(l.clutch[1], 1.0)  -- Inverted: 1 - 0 = 1
    assert_equal(l.speed[1], 150)
    assert_equal(l.gear[1], 4)
    assert_equal(l.pos[1], 0.25)
    assert_equal(l.times[1], 15)  -- ms to seconds
end)

test("steering is normalized to 0-1", function()
    local l = lap.new("track", "car")
    
    -- Straight (0 degrees)
    l:addSample({ gas = 0, brake = 0, clutch = 0, steer = 0, speedKmh = 100, gear = 3, splinePosition = 0.1, lapTimeMs = 1000, fuel = 50 })
    assert_near(l.steering[1], 0.5, 0.01, "Straight should be 0.5")
    
    -- Left turn (positive degrees)
    l:addSample({ gas = 0, brake = 0, clutch = 0, steer = 90, speedKmh = 100, gear = 3, splinePosition = 0.2, lapTimeMs = 2000, fuel = 50 })
    assert_true(l.steering[2] < 0.5, "Left turn should be < 0.5")
    
    -- Right turn (negative degrees)
    l:addSample({ gas = 0, brake = 0, clutch = 0, steer = -90, speedKmh = 100, gear = 3, splinePosition = 0.3, lapTimeMs = 3000, fuel = 50 })
    assert_true(l.steering[3] > 0.5, "Right turn should be > 0.5")
end)


suite("lap.normalizeSteer / lap.steerToDegrees")

test("normalizeSteer converts degrees to 0-1", function()
    assert_near(lap.normalizeSteer(0), 0.5, 0.001, "0° should be 0.5")
    assert_true(lap.normalizeSteer(90) < 0.5, "90° should be < 0.5")
    assert_true(lap.normalizeSteer(-90) > 0.5, "-90° should be > 0.5")
end)

test("steerToDegrees converts back", function()
    local deg = 45
    local norm = lap.normalizeSteer(deg)
    local back = lap.steerToDegrees(norm)
    assert_near(back, deg, 0.1, "Round-trip should preserve value")
end)


suite("lap.getValueAtPos")

test("interpolates between samples", function()
    local l = lap.new("track", "car")
    
    -- Add samples at known positions
    l.pos = { 0.0, 0.25, 0.5, 0.75, 1.0 }
    l.speed = { 100, 150, 200, 150, 100 }
    
    -- Test exact positions
    assert_equal(l:getValueAtPos('speed', 0.25), 150)
    assert_equal(l:getValueAtPos('speed', 0.5), 200)
    
    -- Test interpolated position (between 0.25 and 0.5)
    local interpolated = l:getValueAtPos('speed', 0.375)
    assert_near(interpolated, 175, 0.1, "Should interpolate to 175")
end)

test("returns nil for empty lap", function()
    local l = lap.new("track", "car")
    assert_nil(l:getValueAtPos('speed', 0.5))
end)


suite("lap.getTimeAtPos")

test("interpolates time at position", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.0, 0.25, 0.5, 0.75, 1.0 }
    l.times = { 0, 20, 45, 70, 90 }  -- seconds
    
    assert_equal(l:getTimeAtPos(0.25), 20)
    assert_equal(l:getTimeAtPos(0.5), 45)
    
    -- Interpolated
    local t = l:getTimeAtPos(0.375)  -- Between 0.25 (20s) and 0.5 (45s)
    assert_near(t, 32.5, 0.1)
end)


suite("lap.getDeltaVs")

test("calculates time delta vs reference", function()
    local current = lap.new("track", "car")
    current.pos = { 0.0, 0.5, 1.0 }
    current.times = { 0, 50, 100 }  -- 100s lap
    
    local reference = lap.new("track", "car")
    reference.pos = { 0.0, 0.5, 1.0 }
    reference.times = { 0, 45, 90 }  -- 90s lap (faster)
    
    -- At position 0.5: current=50s, ref=45s, delta=+5s (slower)
    local delta = current:getDeltaVs(reference, 0.5)
    assert_near(delta, 5, 0.1, "Should be 5s slower")
end)


suite("lap.findBrakePoint")

test("finds first brake application", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.brake = { 0.0, 0.0, 0.05, 0.3, 0.8 }  -- Braking starts at 0.4 (> 0.1 threshold)
    
    local brakePos = l:findBrakePoint(0.1, 0.5)
    assert_equal(brakePos, 0.4, "Should find brake at 0.4")
end)

test("returns nil if no braking in range", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3 }
    l.brake = { 0.0, 0.0, 0.0 }
    
    local brakePos = l:findBrakePoint(0.1, 0.3)
    assert_nil(brakePos)
end)


suite("lap.findApex")

test("finds minimum speed point", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.15, 0.2, 0.25, 0.3 }
    l.speed = { 150, 120, 80, 100, 140 }  -- Apex at 0.2 (80 km/h)
    
    local apexPos, apexSpeed = l:findApex(0.1, 0.3)
    assert_equal(apexPos, 0.2)
    assert_equal(apexSpeed, 80)
end)


suite("lap.findMaxSteering")

test("finds maximum steering angle in range", function()
    local l = lap.new("track", "car")
    
    -- Steering normalized: 0.5 = straight, lower = left, higher = right
    l.pos = { 0.1, 0.2, 0.3, 0.4 }
    l.steering = { 0.5, 0.3, 0.2, 0.4 }  -- Max deviation from 0.5 is at 0.3 (0.2)
    
    local maxSteer = l:findMaxSteering(0.1, 0.4)
    assert_true(maxSteer > 0, "Should find non-zero steering")
end)


suite("lap.findMinGear")

test("finds minimum gear in corner", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.gear = { 5, 4, 3, 3, 4 }  -- Downshifts to 3rd
    
    local minGear = l:findMinGear(0.1, 0.5)
    assert_equal(minGear, 3)
end)


suite("lap.FLAGS")

test("flag constants are defined", function()
    assert_not_nil(lap.FLAGS.TC_ACTIVE)
    assert_not_nil(lap.FLAGS.LOCKUP_FL)
    assert_not_nil(lap.FLAGS.OVERLAP)
end)

test("hasFlagInRange detects flags", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3 }
    l.flags = { 0, lap.FLAGS.TC_ACTIVE, 0 }
    
    assert_true(l:hasFlagInRange(0.1, 0.3, lap.FLAGS.TC_ACTIVE))
    assert_true(not l:hasFlagInRange(0.1, 0.3, lap.FLAGS.LOCKUP_FL))
end)


suite("lap.pruneToPosition")

test("removes samples after position", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.speed = { 100, 110, 120, 130, 140 }
    l.throttle = { 0.5, 0.6, 0.7, 0.8, 0.9 }
    l.brake = { 0, 0, 0, 0, 0 }
    l.brake_r = { 0, 0, 0, 0, 0 }
    l.clutch = { 0, 0, 0, 0, 0 }
    l.steering = { 0.5, 0.5, 0.5, 0.5, 0.5 }
    l.gear = { 3, 3, 3, 3, 3 }
    l.times = { 1, 2, 3, 4, 5 }
    l.fuel = { 50, 50, 50, 50, 50 }
    l.gforce = {}
    l.flags = { 0, 0, 0, 0, 0 }
    
    local removed = l:pruneToPosition(0.25)
    
    assert_equal(removed, 3, "Should remove 3 samples")
    assert_equal(l:length(), 2)
    assert_equal(l.pos[2], 0.2)
end)
