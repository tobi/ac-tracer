-- test_scoring.lua - Tests for scoring.lua module

local scoring = require('lib.core.scoring')

--------------------------------------------------------------------------------
-- positionDeltaToMeters tests
--------------------------------------------------------------------------------

suite("scoring.positionDeltaToMeters")

test("converts position delta to meters", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local meters = scoring.positionDeltaToMeters(0.6, 0.5)
    assert_near(meters, 500, 1, "0.1 position delta should be 500m on 5000m track")
end)

test("handles wrap-around at start/finish", function()
    mock.setSim({ trackLengthM = 5000 })
    
    -- Current at 0.1, ref at 0.9 means we're 0.2 ahead (crossed finish)
    -- delta = 0.1 - 0.9 = -0.8, adjusted: -0.8 + 1 = 0.2 = 1000m
    local meters = scoring.positionDeltaToMeters(0.1, 0.9)
    assert_near(meters, 1000, 1, "Should handle wrap-around correctly")
end)

test("returns nil for missing values", function()
    assert_nil(scoring.positionDeltaToMeters(nil, 0.5))
    assert_nil(scoring.positionDeltaToMeters(0.5, nil))
    assert_nil(scoring.positionDeltaToMeters(nil, nil))
end)


--------------------------------------------------------------------------------
-- calculate (overall score) tests
--------------------------------------------------------------------------------

suite("scoring.calculate")

test("returns 0 for nil corner data", function()
    assert_equal(scoring.calculate(nil), 0)
end)

test("returns 100 for perfect matching", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local perfect = scoring.calculate({
        timeDelta = 0,
        exitSpeedDelta = 0,
        apexSpeedDelta = 0,
        currentBrakePos = 0.3,
        refBrakePos = 0.3,
        currentLiftOffPos = 0.35,
        refLiftOffPos = 0.35
    })
    assert_equal(perfect, 100)
end)

test("penalizes slower corner times", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local slow = scoring.calculate({
        timeDelta = 0.3,  -- 0.3s slower
        exitSpeedDelta = 0,
        apexSpeedDelta = 0
    })
    assert_true(slow < 100, "Slower corner should score below 100")
    assert_true(slow > 0, "Score should not be negative")
end)

test("rewards faster corner times", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local baseline = scoring.calculate({
        timeDelta = 0,
        exitSpeedDelta = 0,
        apexSpeedDelta = 0
    })
    
    local fast = scoring.calculate({
        timeDelta = -0.1,  -- 0.1s faster
        exitSpeedDelta = 0,
        apexSpeedDelta = 0
    })
    -- Faster corner should score higher than baseline
    assert_true(fast >= baseline, "Faster corner should score at least as high as baseline")
end)

test("caps score at 100", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local amazing = scoring.calculate({
        timeDelta = -0.5,
        exitSpeedDelta = 20,
        apexSpeedDelta = 20,
        currentBrakePos = 0.5,
        refBrakePos = 0.1,
        currentLiftOffPos = 0.5,
        refLiftOffPos = 0.1
    })
    assert_equal(amazing, 100, "Should cap at 100")
end)

test("prevents negative score", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local terrible = scoring.calculate({
        timeDelta = 10,
        exitSpeedDelta = -50,
        apexSpeedDelta = -50
    })
    assert_true(terrible >= 0, "Should not go below 0")
end)


--------------------------------------------------------------------------------
-- getBreakdown tests
--------------------------------------------------------------------------------

suite("scoring.getBreakdown")

test("returns nil for nil input", function()
    assert_nil(scoring.getBreakdown(nil))
end)

test("returns all component scores", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local breakdown = scoring.getBreakdown({
        timeDelta = 0.1,
        exitSpeedDelta = 5,
        apexSpeedDelta = 3,
        currentBrakePos = 0.3,
        refBrakePos = 0.28,
        currentLiftOffPos = 0.35,
        refLiftOffPos = 0.33
    })
    
    assert_not_nil(breakdown.time)
    assert_not_nil(breakdown.exit)
    assert_not_nil(breakdown.apex)
    assert_not_nil(breakdown.brake)
    assert_not_nil(breakdown.liftOff)
    assert_not_nil(breakdown.weights)
end)

test("includes meter deltas", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local breakdown = scoring.getBreakdown({
        currentBrakePos = 0.3,
        refBrakePos = 0.28,
        currentLiftOffPos = 0.35,
        refLiftOffPos = 0.33
    })
    
    assert_not_nil(breakdown.brakeMeters)
    assert_not_nil(breakdown.liftOffMeters)
    assert_true(breakdown.brakeMeters > 0, "Should be positive (braked later)")
    assert_true(breakdown.liftOffMeters > 0, "Should be positive (lifted later)")
end)

test("handles missing position data", function()
    local breakdown = scoring.getBreakdown({
        timeDelta = 0,
        exitSpeedDelta = 0
    })
    
    assert_nil(breakdown.brakeMeters)
    assert_nil(breakdown.liftOffMeters)
end)


--------------------------------------------------------------------------------
-- getMeterDeltas tests
--------------------------------------------------------------------------------

suite("scoring.getMeterDeltas")

test("returns brake and lift-off deltas in meters", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local brakeM, liftM = scoring.getMeterDeltas({
        currentBrakePos = 0.3,
        refBrakePos = 0.28,
        currentLiftOffPos = 0.35,
        refLiftOffPos = 0.33
    })
    
    assert_not_nil(brakeM)
    assert_not_nil(liftM)
    assert_near(brakeM, 100, 1, "Brake should be ~100m later")
    assert_near(liftM, 100, 1, "Lift should be ~100m later")
end)

test("returns nil for missing data", function()
    local brakeM, liftM = scoring.getMeterDeltas({
        timeDelta = 0,
        exitSpeedDelta = 0
    })
    
    assert_nil(brakeM)
    assert_nil(liftM)
end)


--------------------------------------------------------------------------------
-- getCoastDistances tests
--------------------------------------------------------------------------------

suite("scoring.getCoastDistances")

test("calculates coast distance", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local currentCoast, refCoast, delta = scoring.getCoastDistances({
        currentLiftOffPos = 0.30,
        currentBrakePos = 0.32,
        refLiftOffPos = 0.30,
        refBrakePos = 0.32
    })
    
    -- 0.02 * 5000 = 100m coast
    assert_near(currentCoast, 100, 1, "Should calculate ~100m coast")
    assert_near(refCoast, 100, 1, "Reference should also be ~100m")
    assert_near(delta, 0, 0.1, "Delta should be 0 (same)")
end)

test("returns nil for missing position data", function()
    local currentCoast, refCoast, delta = scoring.getCoastDistances({
        timeDelta = 0,
        exitSpeedDelta = 0
    })
    
    assert_nil(currentCoast)
    assert_nil(refCoast)
    assert_nil(delta)
end)

test("calculates coast delta", function()
    mock.setSim({ trackLengthM = 5000 })
    
    local currentCoast, refCoast, delta = scoring.getCoastDistances({
        currentLiftOffPos = 0.30,
        currentBrakePos = 0.34,  -- 200m coast
        refLiftOffPos = 0.30,
        refBrakePos = 0.32       -- 100m coast
    })
    
    assert_near(currentCoast, 200, 1)
    assert_near(refCoast, 100, 1)
    assert_near(delta, 100, 1, "Delta should be 100m more coasting")
end)

test("normalizes coast delta across wrap-around artifacts", function()
    mock.setSim({ trackLengthM = 5000 })

    -- Current coast wraps heavily (4950m), reference is short (50m).
    -- Raw delta would be +4900m, but normalized shortest signed delta is -100m.
    local currentCoast, refCoast, delta = scoring.getCoastDistances({
        currentLiftOffPos = 0.01,
        currentBrakePos = 0.00,
        refLiftOffPos = 0.99,
        refBrakePos = 0.00
    })

    assert_near(currentCoast, 4950, 1)
    assert_near(refCoast, 50, 1)
    assert_near(delta, -100, 1, "Should normalize to shortest signed delta")
end)


--------------------------------------------------------------------------------
-- configure tests
--------------------------------------------------------------------------------

suite("scoring.configure")

test("updates weight configuration", function()
    -- Get original weights
    local original = scoring.getBreakdown({}).weights.time
    
    -- Change weights
    scoring.configure({ time_weight = 0.5 })
    
    local updated = scoring.getBreakdown({}).weights.time
    assert_equal(updated, 0.5)
    
    -- Restore defaults
    scoring.configure({ time_weight = 0.40 })
end)
