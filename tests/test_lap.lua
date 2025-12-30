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
    -- Note: brake is stored in bar (implementation detail, not tested here)
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

test("brake pedal fallback scales to bar", function()
    -- When cphys DLL is not available, car.brake (0-1) should be scaled to bar
    -- Convention: 100% pedal = 100 bar
    local l = lap.new("track", "car")
    
    -- No braking
    l:addSample({ gas = 1, brake = 0, clutch = 0, steer = 0, speedKmh = 200, gear = 5, splinePosition = 0.1, lapTimeMs = 1000, fuel = 50 })
    assert_equal(l.brake[1], 0, "0% pedal should be 0 bar")
    
    -- Light braking (30%)
    l:addSample({ gas = 0, brake = 0.3, clutch = 0, steer = 0, speedKmh = 180, gear = 4, splinePosition = 0.2, lapTimeMs = 2000, fuel = 50 })
    assert_equal(l.brake[2], 30, "30% pedal should be 30 bar")
    
    -- Full braking (100%)
    l:addSample({ gas = 0, brake = 1.0, clutch = 0, steer = 0, speedKmh = 100, gear = 3, splinePosition = 0.3, lapTimeMs = 3000, fuel = 50 })
    assert_equal(l.brake[3], 100, "100% pedal should be 100 bar")
    
    -- Half braking (50%)
    l:addSample({ gas = 0, brake = 0.5, clutch = 0, steer = 0, speedKmh = 150, gear = 4, splinePosition = 0.4, lapTimeMs = 4000, fuel = 50 })
    assert_equal(l.brake[4], 50, "50% pedal should be 50 bar")
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


suite("lap.accessors")

test("speedAt interpolates between samples", function()
     local l = lap.new("track", "car")
     
     -- Add samples at known positions
     l.pos = { 0.0, 0.25, 0.5, 0.75, 1.0 }
     l.speed = { 100, 150, 200, 150, 100 }
     
     -- Test exact positions
     assert_equal(l:speedAt(0.25), 150)
     assert_equal(l:speedAt(0.5), 200)
     
     -- Test interpolated position (between 0.25 and 0.5)
     local interpolated = l:speedAt(0.375)
     assert_near(interpolated, 175, 0.1, "Should interpolate to 175")
 end)
 
 test("speedAt returns nil for empty lap", function()
     local l = lap.new("track", "car")
     assert_nil(l:speedAt(0.5))
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


suite("lap.sparse")

test("addSparseSample skips unchanged values", function()
    local l = lap.new("track", "car")
    l:addSparseSample("brake_balance", 0.1, 0.5)
    l:addSparseSample("brake_balance", 0.2, 0.5)

    assert_table_length(l.sparse.brake_balance, 1, "Should store only one sample for unchanged values")
    assert_equal(l.sparse.brake_balance[1][2], 0.5)
end)

test("addSparseSample updates same-position value", function()
    local l = lap.new("track", "car")
    l:addSparseSample("brake_balance", 0.1, 0.5)
    l:addSparseSample("brake_balance", 0.1000001, 0.6)

    assert_table_length(l.sparse.brake_balance, 1, "Same-position samples should collapse to one")
    assert_equal(l.sparse.brake_balance[1][2], 0.6)
end)

test("getSparseAtPos returns last value before position", function()
    local l = lap.new("track", "car")
    l:addSparseSample("brake_balance", 0.1, 0.4)
    l:addSparseSample("brake_balance", 0.3, 0.6)

    assert_equal(l:getSparseAtPos("brake_balance", 0.1), 0.4)
    assert_equal(l:getSparseAtPos("brake_balance", 0.2), 0.4)
    assert_equal(l:getSparseAtPos("brake_balance", 0.35), 0.6)
end)

test("brakeBalanceAt falls back to sparse for sparse fields", function()
     local l = lap.new("track", "car")
     l:addSparseSample("brake_balance", 0.1, 0.4)
     l:addSparseSample("brake_balance", 0.3, 0.6)

     assert_equal(l:brakeBalanceAt(0.2), 0.4)
     assert_equal(l:brakeBalanceAt(0.35), 0.6)
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
     l.brake = { 0.0, 0.0, 3.0, 30.0, 80.0 }  -- Braking starts at 0.4 (> 5 bar threshold)
     
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
    assert_not_nil(lap.FLAGS.LIMITER_HIT)
    assert_not_nil(lap.FLAGS.WHEEL_SLIP)
    assert_not_nil(lap.FLAGS.LOCKUP_FL)
    assert_not_nil(lap.FLAGS.LOCKUP_FR)
    assert_not_nil(lap.FLAGS.LOCKUP_RL)
    assert_not_nil(lap.FLAGS.LOCKUP_RR)
    assert_not_nil(lap.FLAGS.OVERLAP)
    assert_not_nil(lap.FLAGS.OFFTRACK)
end)

test("flag constants are unique powers of 2", function()
    local flags = {
        lap.FLAGS.TC_ACTIVE,
        lap.FLAGS.LIMITER_HIT,
        lap.FLAGS.WHEEL_SLIP,
        lap.FLAGS.LOCKUP_FL,
        lap.FLAGS.LOCKUP_FR,
        lap.FLAGS.LOCKUP_RL,
        lap.FLAGS.LOCKUP_RR,
        lap.FLAGS.OVERLAP,
        lap.FLAGS.OFFTRACK,
    }
    
    -- Check each flag is a power of 2
    for _, flag in ipairs(flags) do
        assert_true(flag > 0, "Flag should be positive")
        assert_equal(bit.band(flag, flag - 1), 0, "Flag should be power of 2")
    end
    
    -- Check all flags are unique
    local seen = {}
    for _, flag in ipairs(flags) do
        assert_nil(seen[flag], "Flags should be unique")
        seen[flag] = true
    end
end)

test("hasFlagInRange detects flags", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3 }
    l.flags = { 0, lap.FLAGS.TC_ACTIVE, 0 }
    
    assert_true(l:hasFlagInRange(0.1, 0.3, lap.FLAGS.TC_ACTIVE))
    assert_true(not l:hasFlagInRange(0.1, 0.3, lap.FLAGS.LOCKUP_FL))
end)

test("hasFlagInRange handles wrap-around", function()
    local l = lap.new("track", "car")
    
    -- Samples at end and start of lap
    l.pos = { 0.95, 0.98, 0.02, 0.05 }
    l.flags = { 0, lap.FLAGS.TC_ACTIVE, lap.FLAGS.LIMITER_HIT, 0 }
    
    -- Range that wraps around (0.9 to 0.1)
    assert_true(l:hasFlagInRange(0.9, 0.1, lap.FLAGS.TC_ACTIVE), "Should find TC in wrap-around")
    assert_true(l:hasFlagInRange(0.9, 0.1, lap.FLAGS.LIMITER_HIT), "Should find limiter in wrap-around")
end)

test("countFlagInRange counts samples", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.flags = { lap.FLAGS.TC_ACTIVE, lap.FLAGS.TC_ACTIVE, 0, lap.FLAGS.TC_ACTIVE, 0 }
    
    assert_equal(l:countFlagInRange(0.1, 0.5, lap.FLAGS.TC_ACTIVE), 3)
    assert_equal(l:countFlagInRange(0.25, 0.45, lap.FLAGS.TC_ACTIVE), 1)
end)

test("hasLockupInRange detects wheel lockups", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3 }
    local combined = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_RR)
    l.flags = { 0, combined, 0 }
    
    local anyLockup, wheels = l:hasLockupInRange(0.1, 0.3)
    
    assert_true(anyLockup, "Should detect lockup")
    assert_not_nil(wheels)
    assert_true(wheels.fl, "Should detect FL lockup")
    assert_true(not wheels.fr, "Should not detect FR lockup")
    assert_true(not wheels.rl, "Should not detect RL lockup")
    assert_true(wheels.rr, "Should detect RR lockup")
end)

test("getOverlapTimeInRange calculates time", function()
    local l = lap.new("track", "car")
    
    -- 5 samples at 60Hz = ~83ms
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.times = { 0, 1, 2, 3, 4 }
    l.flags = { lap.FLAGS.OVERLAP, lap.FLAGS.OVERLAP, lap.FLAGS.OVERLAP, 0, 0 }
    
    local overlapTime = l:getOverlapTimeInRange(0.1, 0.5)
    
    -- 3 samples * (1/SAMPLE_RATE) seconds
    local expectedTime = 3 / lap.SAMPLE_RATE
    assert_near(overlapTime, expectedTime, 0.01, "Should calculate overlap based on sample rate")
end)


suite("lap.FLAGS accessors")

test("hasFlags returns false for empty flags", function()
    local l = lap.new("track", "car")
    assert_true(not l:hasFlags())
    
    l.flags = {}
    assert_true(not l:hasFlags())
end)

test("hasFlags returns true when flags present", function()
    local l = lap.new("track", "car")
    l.flags = { 0, lap.FLAGS.TC_ACTIVE, 0 }
    assert_true(l:hasFlags())
end)

test("getFlagAt returns flag bitmask", function()
    local l = lap.new("track", "car")
    local combined = bit.bor(lap.FLAGS.TC_ACTIVE, lap.FLAGS.WHEEL_SLIP)
    l.flags = { 0, combined, lap.FLAGS.LIMITER_HIT }
    
    assert_equal(l:getFlagAt(1), 0)
    assert_equal(l:getFlagAt(2), combined)
    assert_equal(l:getFlagAt(3), lap.FLAGS.LIMITER_HIT)
    assert_equal(l:getFlagAt(999), 0, "Out of range should return 0")
end)

test("hasFlagAt checks specific flag", function()
    local l = lap.new("track", "car")
    local combined = bit.bor(lap.FLAGS.TC_ACTIVE, lap.FLAGS.WHEEL_SLIP)
    l.flags = { combined }
    
    assert_true(l:hasFlagAt(1, lap.FLAGS.TC_ACTIVE))
    assert_true(l:hasFlagAt(1, lap.FLAGS.WHEEL_SLIP))
    assert_true(not l:hasFlagAt(1, lap.FLAGS.LIMITER_HIT))
end)

test("flagsToNames converts bitmask to names", function()
    local combined = bit.bor(lap.FLAGS.TC_ACTIVE, lap.FLAGS.LOCKUP_FL, lap.FLAGS.OVERLAP)
    local names = lap.flagsToNames(combined)
    
    assert_equal(#names, 3)
    
    -- Check names are present (order may vary)
    local nameSet = {}
    for _, name in ipairs(names) do nameSet[name] = true end
    
    assert_true(nameSet["TC"], "Should have TC")
    assert_true(nameSet["Lockup FL"], "Should have Lockup FL")
    assert_true(nameSet["Overlap"], "Should have Overlap")
end)

test("flagsToNames returns empty for zero", function()
    local names = lap.flagsToNames(0)
    assert_equal(#names, 0)
    
    names = lap.flagsToNames(nil)
    assert_equal(#names, 0)
end)

test("combineFlags merges multiple flags", function()
    local combined = lap.combineFlags(
        lap.FLAGS.TC_ACTIVE,
        lap.FLAGS.LIMITER_HIT,
        lap.FLAGS.WHEEL_SLIP
    )
    
    assert_true(bit.band(combined, lap.FLAGS.TC_ACTIVE) ~= 0)
    assert_true(bit.band(combined, lap.FLAGS.LIMITER_HIT) ~= 0)
    assert_true(bit.band(combined, lap.FLAGS.WHEEL_SLIP) ~= 0)
    assert_true(bit.band(combined, lap.FLAGS.OVERLAP) == 0)
end)

test("hasAnyLockup detects any wheel lockup", function()
    assert_true(lap.hasAnyLockup(lap.FLAGS.LOCKUP_FL))
    assert_true(lap.hasAnyLockup(lap.FLAGS.LOCKUP_FR))
    assert_true(lap.hasAnyLockup(lap.FLAGS.LOCKUP_RL))
    assert_true(lap.hasAnyLockup(lap.FLAGS.LOCKUP_RR))
    
    local combined = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_RR)
    assert_true(lap.hasAnyLockup(combined))
    
    assert_true(not lap.hasAnyLockup(lap.FLAGS.TC_ACTIVE))
    assert_true(not lap.hasAnyLockup(0))
    assert_true(not lap.hasAnyLockup(nil))
end)

test("getFlagSummary returns complete summary", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.times = { 0, 1, 2, 3, 4 }
    l.flags = {
        lap.FLAGS.TC_ACTIVE,
        bit.bor(lap.FLAGS.TC_ACTIVE, lap.FLAGS.LOCKUP_FL),
        lap.FLAGS.OVERLAP,
        lap.FLAGS.OVERLAP,
        0
    }
    
    local summary = l:getFlagSummary(0.1, 0.5)
    
    assert_equal(summary.tc.count, 2, "Should count 2 TC samples")
    assert_true(summary.tc.active, "TC should be active")
    
    assert_equal(summary.lockup.count, 1, "Should count 1 lockup sample")
    assert_true(summary.lockup.active, "Lockup should be active")
    assert_true(summary.lockup.wheels.fl, "FL lockup should be true")
    assert_true(not summary.lockup.wheels.fr, "FR lockup should be false")
    
    assert_equal(summary.overlap.count, 2, "Should count 2 overlap samples")
    assert_near(summary.overlap.time, 2/lap.SAMPLE_RATE, 0.001, "Should calculate overlap time")
    
    assert_equal(summary.limiter.count, 0, "Should count 0 limiter samples")
    assert_true(not summary.limiter.active, "Limiter should not be active")
end)

test("getFlagSummary handles empty flags", function()
    local l = lap.new("track", "car")
    l.pos = { 0.1, 0.2, 0.3 }
    l.flags = {}
    
    local summary = l:getFlagSummary(0.1, 0.3)
    
    assert_equal(summary.tc.count, 0)
    assert_true(not summary.tc.active)
    assert_equal(summary.lockup.count, 0)
    assert_true(not summary.lockup.active)
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


--------------------------------------------------------------------------------
-- Brake in Bar Tests
--------------------------------------------------------------------------------

suite("lap.brake in bar")

test("maxBrakeBars returns max brake pressure", function()
    local l = lap.new("track", "car")
    
    l.brake = { 0, 20, 50, 80, 30 }  -- Max is 80 bar
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    
    assert_equal(l:maxBrakeBars(), 80)
end)

test("maxBrakeBars returns 80 minimum for empty lap", function()
    local l = lap.new("track", "car")
    assert_equal(l:maxBrakeBars(), 80)
end)

test("maxBrakeBars caches value for completed laps", function()
    local l = lap.new("track", "car")
    l.brake = { 50, 100, 75 }
    l.pos = { 0.1, 0.5, 0.9 }
    l.completed = true
    
    -- First call computes and caches
    assert_equal(l:maxBrakeBars(), 100)
    
    -- Modify brake array (shouldn't affect cached value)
    l.brake[2] = 200
    
    -- Should return cached value
    assert_equal(l:maxBrakeBars(), 100)
end)

test("maxBrakeBars does not cache for incomplete laps", function()
    local l = lap.new("track", "car")
    l.brake = { 50, 100, 75 }
    l.pos = { 0.1, 0.5, 0.9 }
    l.completed = false
    
    assert_equal(l:maxBrakeBars(), 100)
    
    -- Add higher brake value
    l.brake[4] = 120
    l.pos[4] = 0.95
    
    -- Should recompute for incomplete lap
    assert_equal(l:maxBrakeBars(), 120)
end)

test("findBrakePoint works with bar values", function()
    local l = lap.new("track", "car")
    
    -- Brake values in bar (typical race car: 0-120 bar)
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.brake = { 0, 0, 3, 40, 90 }  -- Light touch at 0.3 (3 bar), real braking at 0.4 (40 bar)
    
    -- With threshold 5 bar, should find 0.4 (first sample > 5 bar)
    local brakePos = l:findBrakePoint(0.1, 0.5, 5)
    assert_equal(brakePos, 0.4, "Should find brake at 0.4 with 5 bar threshold")
    
    -- With threshold 2 bar, should find 0.3 (light touch)
    local brakePos2 = l:findBrakePoint(0.1, 0.5, 2)
    assert_equal(brakePos2, 0.3, "Should find brake at 0.3 with 2 bar threshold")
end)

test("findBrakePoint with high threshold ignores light braking", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.1, 0.2, 0.3, 0.4, 0.5 }
    l.brake = { 0, 2, 4, 6, 8 }  -- All light braking (< 10 bar)
    
    -- With threshold 10 bar, should find nothing
    local brakePos = l:findBrakePoint(0.1, 0.5, 10)
    assert_nil(brakePos, "Should not find brake with 10 bar threshold")
end)

test("brakeAt returns brake in bar", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.0, 0.5, 1.0 }
    l.brake = { 0, 80, 0 }  -- Peak braking at mid-corner
    
    -- Exact positions
    assert_equal(l:brakeAt(0.5), 80)
    
    -- Interpolated
    local interpBrake = l:brakeAt(0.25)  -- Between 0 and 80
    assert_near(interpBrake, 40, 1, "Should interpolate brake to ~40 bar")
end)

test("brakePercentAt normalizes to maxBar", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.0, 0.5, 1.0 }
    l.brake = { 0, 80, 0 }
    
    -- With default 100 bar scale
    assert_equal(l:brakePercentAt(0.5), 0.8, "80 bar / 100 = 0.8")
    assert_equal(l:brakePercentAt(0.0), 0, "0 bar / 100 = 0")
    
    -- With custom scale (e.g., road car with 50 bar max)
    assert_equal(l:brakePercentAt(0.5, 50), 1.0, "80 bar / 50 = clamped to 1.0")
    
    -- With race car scale (120 bar)
    assert_near(l:brakePercentAt(0.5, 120), 0.667, 0.01, "80 bar / 120 = ~0.67")
end)

test("convenience accessors work", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.0, 0.25, 0.5, 0.75, 1.0 }
    l.brake = { 0, 30, 90, 60, 0 }
    l.throttle = { 1, 0.5, 0, 0.5, 1 }
    l.clutch = { 0, 0.2, 0.5, 0.2, 0 }
    l.steering = { 0.5, 0.4, 0.3, 0.4, 0.5 }
    l.speed = { 200, 150, 100, 130, 180 }
    l.gear = { 5, 4, 3, 4, 5 }
    
    -- Test all accessors at 0.5
    assert_equal(l:brakeAt(0.5), 90)
    assert_equal(l:throttleAt(0.5), 0)
    assert_equal(l:clutchAt(0.5), 0.5)
    assert_equal(l:steeringAt(0.5), 0.3)
    assert_equal(l:speedAt(0.5), 100)
    assert_equal(l:gearAt(0.5), 3)
end)

test("steeringDegAt converts to degrees", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.0, 0.5, 1.0 }
    l.steering = { 0.5, 0.25, 0.75 }  -- straight, left, right
    
    assert_near(l:steeringDegAt(0.0), 0, 1, "0.5 norm = 0 degrees")
    assert_true(l:steeringDegAt(0.5) > 0, "0.25 norm = positive degrees (left)")
    assert_true(l:steeringDegAt(1.0) < 0, "0.75 norm = negative degrees (right)")
end)

test("getTracesAt returns brake in bar", function()
    local l = lap.new("track", "car")
    
    l.pos = { 0.0, 0.25, 0.5, 0.75, 1.0 }
    l.brake = { 0, 30, 90, 60, 0 }
    l.throttle = { 1, 0.5, 0, 0.5, 1 }
    l.clutch = { 0, 0, 0, 0, 0 }
    l.steering = { 0.5, 0.5, 0.5, 0.5, 0.5 }
    l.speed = { 200, 150, 100, 130, 180 }
    
    local traces = l:getTracesAt({ 0.25, 0.5, 0.75 })
    
    assert_equal(traces.brake[1], 30, "Brake at 0.25 should be 30 bar")
    assert_equal(traces.brake[2], 90, "Brake at 0.5 should be 90 bar")
    assert_equal(traces.brake[3], 60, "Brake at 0.75 should be 60 bar")
end)

test("realistic race car braking profile", function()
    local l = lap.new("track", "car")
    
    -- Simulate approach to corner: full throttle -> brake -> apex -> exit
    l.pos = { 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28 }
    l.brake = { 0, 0, 4, 70, 95, 100, 85, 50, 20, 0 }  -- GT3 braking ~100 bar peak (4 bar = trail)
    l.throttle = { 1.0, 1.0, 0.9, 0, 0, 0, 0, 0.2, 0.5, 0.8 }
    l.speed = { 280, 275, 260, 220, 180, 150, 130, 125, 135, 160 }
    
    -- Find brake point (> 5 bar threshold, ignores 4 bar trail brake)
    local brakePos = l:findBrakePoint(0.10, 0.28, 5)
    assert_equal(brakePos, 0.16, "Brake point should be at 0.16 (first > 5 bar)")
    
    -- Max brake
    assert_equal(l:maxBrakeBars(), 100, "Max brake should be 100 bar")
    
    -- Brake percentage at peak
    assert_equal(l:brakePercentAt(0.20, 100), 1.0, "100 bar at 100 bar scale = 100%")
    assert_near(l:brakePercentAt(0.20, 120), 0.833, 0.01, "100 bar at 120 bar scale = ~83%")
end)

test("road car braking profile (lower pressure)", function()
    local l = lap.new("track", "car")
    
    -- Road cars have lower brake pressure (typically 30-60 bar max)
    l.pos = { 0.10, 0.12, 0.14, 0.16, 0.18, 0.20 }
    l.brake = { 0, 0, 3, 25, 40, 35 }  -- Road car ~40 bar peak
    
    -- Find brake point (> 5 bar threshold)
    local brakePos = l:findBrakePoint(0.10, 0.20, 5)
    assert_equal(brakePos, 0.16, "Brake point should be at 0.16 (first > 5 bar)")
    
    -- Max brake returns 80 minimum (for chart scaling), even though actual max is 40
    assert_equal(l:maxBrakeBars(), 80, "Max brake returns 80 minimum for chart scaling")
    
    -- With road car scale (50 bar), 40 bar = 80%
    assert_equal(l:brakePercentAt(0.18, 50), 0.8)
end)


suite("lap.serialize/deserialize roundtrip")

test("roundtrip preserves all fields", function()
    -- Create a lap with all fields populated
    local original = lap.new("test_track", "test_car", "session_abc")
    original.completed = true
    original.valid = true
    original.time = 92345
    original.fuelLeftAtStart = 48.5
    original.lapNumberInSession = 3
    
    -- Dense arrays (10 samples)
    original.pos = { 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9 }
    original.times = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 }
    original.throttle = { 1.0, 0.9, 0.5, 0.0, 0.0, 0.0, 0.3, 0.7, 0.9, 1.0 }
    original.brake = { 0, 0, 20, 80, 100, 90, 50, 10, 0, 0 }
    original.brake_r = { 0, 0, 18, 75, 95, 85, 45, 8, 0, 0 }
    original.clutch = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    original.steering = { 0.5, 0.5, 0.45, 0.35, 0.3, 0.32, 0.4, 0.48, 0.5, 0.5 }
    original.speed = { 280, 270, 240, 180, 120, 100, 110, 150, 200, 250 }
    original.gear = { 6, 6, 5, 4, 3, 3, 4, 4, 5, 5 }
    
    -- Flags (bitmask per sample)
    original.flags = { 0, 0, 0, lap.FLAGS.TC_ACTIVE, lap.FLAGS.LOCKUP_FL, 0, 0, 0, 0, 0 }
    
    -- Sparse fields
    original.sparse = {
        fuel = { {0.0, 48.5}, {0.5, 47.2}, {0.9, 46.1} },
        brake_balance = { {0.0, 0.58} },
        tc_slip = { {0.0, 3} },
        tc_gain = { {0.0, 7} },
    }
    
    -- G-force vectors
    original.gforce = {}
    for i = 1, 10 do
        original.gforce[i] = vec3((i-5) * 0.2, 0, (i > 5) and -0.5 or 0.3)
    end
    
    -- CSV source metadata (simulating imported lap)
    original.csvSource = {
        throttle = "Throttle Pos",
        brake = "Brake Pressure F",
        speed = "Ground Speed",
        gear = "gear_pos",
    }
    
    -- Serialize and deserialize
    local serialized = original:serialize()
    assert_type(serialized, "string", "Serialized data should be string")
    assert_true(#serialized > 100, "Serialized data should have content")
    
    local restored = lap.deserialize(serialized)
    assert_not_nil(restored, "Deserialize should return lap")
    
    -- Check metadata
    assert_equal(restored.track, original.track, "track mismatch")
    assert_equal(restored.car, original.car, "car mismatch")
    assert_equal(restored.sessionId, original.sessionId, "sessionId mismatch")
    assert_equal(restored.completed, original.completed, "completed mismatch")
    assert_equal(restored.valid, original.valid, "valid mismatch")
    assert_equal(restored.time, original.time, "time mismatch")
    assert_equal(restored.fuelLeftAtStart, original.fuelLeftAtStart, "fuelLeftAtStart mismatch")
    assert_equal(restored.lapNumberInSession, original.lapNumberInSession, "lapNumberInSession mismatch")
    
    -- Check dense arrays
    assert_equal(#restored.pos, #original.pos, "pos length mismatch")
    assert_equal(#restored.times, #original.times, "times length mismatch")
    assert_equal(#restored.throttle, #original.throttle, "throttle length mismatch")
    assert_equal(#restored.brake, #original.brake, "brake length mismatch")
    assert_equal(#restored.brake_r, #original.brake_r, "brake_r length mismatch")
    assert_equal(#restored.clutch, #original.clutch, "clutch length mismatch")
    assert_equal(#restored.steering, #original.steering, "steering length mismatch")
    assert_equal(#restored.speed, #original.speed, "speed length mismatch")
    assert_equal(#restored.gear, #original.gear, "gear length mismatch")
    assert_equal(#restored.flags, #original.flags, "flags length mismatch")
    
    for i = 1, #original.pos do
        assert_near(restored.pos[i], original.pos[i], 0.0001, "pos[" .. i .. "] mismatch")
        assert_near(restored.times[i], original.times[i], 0.0001, "times[" .. i .. "] mismatch")
        assert_near(restored.throttle[i], original.throttle[i], 0.0001, "throttle[" .. i .. "] mismatch")
        assert_near(restored.brake[i], original.brake[i], 0.0001, "brake[" .. i .. "] mismatch")
        assert_near(restored.brake_r[i], original.brake_r[i], 0.0001, "brake_r[" .. i .. "] mismatch")
        assert_near(restored.clutch[i], original.clutch[i], 0.0001, "clutch[" .. i .. "] mismatch")
        assert_near(restored.steering[i], original.steering[i], 0.0001, "steering[" .. i .. "] mismatch")
        assert_near(restored.speed[i], original.speed[i], 0.0001, "speed[" .. i .. "] mismatch")
        assert_equal(restored.gear[i], original.gear[i], "gear[" .. i .. "] mismatch")
        assert_equal(restored.flags[i], original.flags[i], "flags[" .. i .. "] mismatch")
    end
    
    -- Check sparse fields
    assert_not_nil(restored.sparse, "sparse table should exist")
    assert_not_nil(restored.sparse.fuel, "sparse.fuel should exist")
    assert_not_nil(restored.sparse.brake_balance, "sparse.brake_balance should exist")
    assert_not_nil(restored.sparse.tc_slip, "sparse.tc_slip should exist")
    assert_not_nil(restored.sparse.tc_gain, "sparse.tc_gain should exist")
    
    assert_equal(#restored.sparse.fuel, #original.sparse.fuel, "sparse.fuel length mismatch")
    
    for i = 1, #original.sparse.fuel do
        assert_near(restored.sparse.fuel[i][1], original.sparse.fuel[i][1], 0.0001, "sparse.fuel[" .. i .. "].pos mismatch")
        assert_near(restored.sparse.fuel[i][2], original.sparse.fuel[i][2], 0.0001, "sparse.fuel[" .. i .. "].value mismatch")
    end
    
    -- Check accessor functions work on restored lap
    assert_near(restored:throttleAt(0.25), 0.25, 0.1, "throttleAt interpolation should work")
    assert_near(restored:brakeAt(0.4), 100, 5, "brakeAt interpolation should work")
    assert_near(restored:gearAt(0.35), 4, 1, "gearAt interpolation should work")
    assert_near(restored:fuelAt(0.6), 47.2, 0.5, "fuelAt sparse lookup should work")
    
    -- Check csvSource preserved
    assert_not_nil(restored.csvSource, "csvSource should exist")
    assert_equal(restored.csvSource.throttle, original.csvSource.throttle, "csvSource.throttle mismatch")
    assert_equal(restored.csvSource.gear, original.csvSource.gear, "csvSource.gear mismatch")
end)

test("deserialize handles empty/nil data", function()
    assert_nil(lap.deserialize(nil), "nil should return nil")
    assert_nil(lap.deserialize(""), "empty string should return nil")
    assert_nil(lap.deserialize("invalid json"), "invalid data should return nil")
end)

test("serialize produces compact output for sparse fuel", function()
    local l = lap.new("track", "car")
    
    -- Add 100 samples
    l.pos = {}
    l.times = {}
    l.throttle = {}
    l.brake = {}
    l.brake_r = {}
    l.clutch = {}
    l.steering = {}
    l.speed = {}
    l.gear = {}
    
    for i = 1, 100 do
        table.insert(l.pos, i / 100)
        table.insert(l.times, i)
        table.insert(l.throttle, 0.5)
        table.insert(l.brake, 0)
        table.insert(l.brake_r, 0)
        table.insert(l.clutch, 0)
        table.insert(l.steering, 0.5)
        table.insert(l.speed, 150)
        table.insert(l.gear, 4)
    end
    
    -- Add sparse fuel (only 3 changes for 100 samples)
    l.sparse = {
        fuel = { {0.0, 50}, {0.5, 48}, {1.0, 46} },
        brake_balance = {},
        tc_slip = {},
        tc_gain = {},
    }
    
    local serialized = l:serialize()
    
    -- Verify serialized data is reasonably sized
    assert_true(#serialized < 10000, "Serialized data should be reasonably compact")
    
    -- Verify we can still access fuel at any position
    local restored = lap.deserialize(serialized)
    assert_near(restored:fuelAt(0.25), 50, 0.1, "fuel at 0.25 should be ~50")
    assert_near(restored:fuelAt(0.75), 48, 0.1, "fuel at 0.75 should be ~48")
end)
