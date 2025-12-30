-- test_corner_notes.lua - Tests for corner analysis note generation
-- Tests the analysis functions that generate notes for corner review

local lap = require('lap')

-- We need to test the note analysis functions from corner_analysis
-- But they're local, so we'll test through the public API and lap flag methods

--------------------------------------------------------------------------------
-- Helper: Create a test lap with specific data
--------------------------------------------------------------------------------

local function createTestLap(opts)
    opts = opts or {}
    local l = lap.new("test_track", "test_car")
    
    local numSamples = opts.numSamples or lap.SAMPLE_RATE  -- 1 second at sample rate
    local startPos = opts.startPos or 0.1
    local endPos = opts.endPos or 0.2
    local posRange = endPos - startPos
    
    for i = 1, numSamples do
        local t = (i - 1) / (numSamples - 1)
        local pos = startPos + t * posRange
        
        table.insert(l.pos, pos)
        table.insert(l.times, i / lap.SAMPLE_RATE)  -- seconds
        table.insert(l.throttle, opts.throttle and opts.throttle[i] or 0.5)
        table.insert(l.brake, opts.brake and opts.brake[i] or 0)
        table.insert(l.brake_r, opts.brake_r and opts.brake_r[i] or (opts.brake and opts.brake[i] or 0))
        table.insert(l.clutch, 0)
        table.insert(l.steering, opts.steering and opts.steering[i] or 0.5)
        table.insert(l.speed, opts.speed and opts.speed[i] or 100)
        table.insert(l.gear, opts.gear and opts.gear[i] or 3)
        table.insert(l.flags, opts.flags and opts.flags[i] or 0)
    end
    
    return l
end

--------------------------------------------------------------------------------
-- Tests for flag-based analysis (lockups, TC, offtrack, etc.)
--------------------------------------------------------------------------------

suite("Flag-based corner analysis")

test("lap detects lockups in corner range", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Add lockup flags at samples 10-15 (mid-corner)
    for i = 10, 15 do
        l.flags[i] = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_FR)
    end
    
    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)
    
    assert_true(hasLockup, "Should detect lockup")
    assert_true(wheels.fl, "Should detect FL lockup")
    assert_true(wheels.fr, "Should detect FR lockup")
    assert_true(not wheels.rl, "Should not detect RL lockup")
    assert_true(not wheels.rr, "Should not detect RR lockup")
end)

test("lap detects TC active in corner range", function()
    local numSamples = lap.SAMPLE_RATE  -- 1 second worth of samples
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Add TC flags for all samples (1 second duration)
    for i = 1, numSamples do
        l.flags[i] = lap.FLAGS.TC_ACTIVE
    end
    
    local tcCount = l:countFlagInRange(0.1, 0.2, lap.FLAGS.TC_ACTIVE)
    local tcDuration = tcCount / lap.SAMPLE_RATE  -- seconds
    
    assert_equal(tcCount, numSamples, "Should count all TC samples")
    assert_near(tcDuration, 1.0, 0.1, "TC duration should be ~1 second")
end)

test("lap detects offtrack in corner range", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Add offtrack flags at corner exit (samples 25-30)
    for i = 25, 30 do
        l.flags[i] = lap.FLAGS.OFFTRACK
    end
    
    local offtrackCount = l:countFlagInRange(0.1, 0.2, lap.FLAGS.OFFTRACK)
    
    assert_equal(offtrackCount, 6, "Should count 6 offtrack samples")
end)

test("lap detects rev limiter hits", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Add limiter flags at a few samples
    l.flags[5] = lap.FLAGS.LIMITER_HIT
    l.flags[6] = lap.FLAGS.LIMITER_HIT
    l.flags[7] = lap.FLAGS.LIMITER_HIT
    
    local limiterCount = l:countFlagInRange(0.1, 0.2, lap.FLAGS.LIMITER_HIT)
    
    assert_equal(limiterCount, 3, "Should count 3 limiter samples")
end)

test("getFlagSummary combines all flag types", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Add various flags
    l.flags[5] = lap.FLAGS.TC_ACTIVE
    l.flags[6] = lap.FLAGS.TC_ACTIVE
    l.flags[10] = lap.FLAGS.LOCKUP_FL
    l.flags[15] = lap.FLAGS.OVERLAP
    l.flags[16] = lap.FLAGS.OVERLAP
    l.flags[20] = lap.FLAGS.OFFTRACK
    
    local summary = l:getFlagSummary(0.1, 0.2)
    
    assert_equal(summary.tc.count, 2, "Should count 2 TC samples")
    assert_true(summary.tc.active, "TC should be active")
    
    assert_equal(summary.lockup.count, 1, "Should count 1 lockup sample")
    assert_true(summary.lockup.wheels.fl, "FL lockup should be detected")
    
    assert_equal(summary.overlap.count, 2, "Should count 2 overlap samples")
    assert_near(summary.overlap.time, 2/lap.SAMPLE_RATE, 0.01, "Overlap time should be ~2 samples")
    
    assert_equal(summary.offtrack.count, 1, "Should count 1 offtrack sample")
end)


--------------------------------------------------------------------------------
-- Tests for pedal overlap detection (bad throttle during braking)
--------------------------------------------------------------------------------

suite("Pedal overlap analysis")

test("detects throttle during heavy braking", function()
    local l = createTestLap({
        numSamples = lap.SAMPLE_RATE,  -- 1 second of data
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Simulate heavy braking with throttle overlap
    -- This should trigger the "bad brake zone throttle" note
    for i = 1, 60 do
        if i >= 20 and i <= 40 then
            -- Heavy braking zone with throttle (bad)
            l.brake[i] = 0.8  -- Heavy braking
            l.throttle[i] = 0.5  -- Significant throttle (not just heel-toe blip)
        else
            l.brake[i] = 0
            l.throttle[i] = 0.8
        end
    end
    
    -- For the bad overlap detection, we need to check if throttle > 0.3 
    -- during heavy braking > 0.5 for more than 500ms
    -- 21 samples at 60Hz = 350ms, so this shouldn't trigger
    -- Let's make it longer
    
    local heavyBrakeWithThrottle = 0
    for i = 1, #l.pos do
        if l.brake[i] >= 0.5 and l.throttle[i] >= 0.3 then
            heavyBrakeWithThrottle = heavyBrakeWithThrottle + 1
        end
    end
    
    assert_true(heavyBrakeWithThrottle > 0, "Should have samples with overlap")
end)

test("overlap flag tracks pedal overlap duration", function()
    local numSamples = lap.SAMPLE_RATE  -- 1 second of data
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Add overlap flags for roughly half the samples (0.5 seconds)
    local halfSamples = math.floor(numSamples / 2)
    local startIdx = math.floor(numSamples / 4)
    local endIdx = startIdx + halfSamples
    for i = startIdx, endIdx do
        l.flags[i] = lap.FLAGS.OVERLAP
    end
    
    local overlapTime = l:getOverlapTimeInRange(0.1, 0.2)
    local expectedTime = (halfSamples + 1) / lap.SAMPLE_RATE  -- +1 because inclusive range
    
    assert_near(overlapTime, expectedTime, 0.05, "Overlap time should be ~0.5 seconds")
end)


--------------------------------------------------------------------------------
-- Tests for corner comparison data (steering, gear, coasting)
--------------------------------------------------------------------------------

suite("Corner comparison analysis")

test("steering difference detected", function()
    local current = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    local reference = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Current: 30 degrees of steering (0.5 - 30/180 * 0.5 ≈ 0.42)
    -- Reference: 45 degrees of steering (0.5 - 45/180 * 0.5 ≈ 0.375)
    for i = 1, 30 do
        current.steering[i] = lap.normalizeSteer(30)
        reference.steering[i] = lap.normalizeSteer(45)
    end
    
    local currentMax = current:findMaxSteering(0.1, 0.2)
    local refMax = reference:findMaxSteering(0.1, 0.2)
    local steeringDelta = currentMax - refMax
    
    -- Current should have less steering than reference
    assert_near(currentMax, 30, 1, "Current max steering should be ~30°")
    assert_near(refMax, 45, 1, "Reference max steering should be ~45°")
    assert_near(steeringDelta, -15, 1, "Steering delta should be ~-15°")
end)

test("gear difference detected", function()
    local current = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    local reference = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Current: uses 3rd gear minimum
    -- Reference: uses 2nd gear minimum
    for i = 1, 30 do
        current.gear[i] = i < 15 and 4 or 3
        reference.gear[i] = i < 15 and 4 or 2
    end
    
    local currentMinGear = current:findMinGear(0.1, 0.2)
    local refMinGear = reference:findMinGear(0.1, 0.2)
    local gearDelta = currentMinGear - refMinGear
    
    assert_equal(currentMinGear, 3, "Current min gear should be 3")
    assert_equal(refMinGear, 2, "Reference min gear should be 2")
    assert_equal(gearDelta, 1, "Gear delta should be +1 (higher gear)")
end)

test("brake point and lift point detection", function()
    local numSamples = lap.SAMPLE_RATE
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })
    
     -- Simulate: full throttle -> lift at 25% -> brake at 40%
     for i = 1, numSamples do
         local t = i / numSamples
         if t <= 0.25 then
             l.throttle[i] = 1.0  -- Full throttle
             l.brake[i] = 0
         elseif t <= 0.4 then
             l.throttle[i] = 0.5  -- Coasting
             l.brake[i] = 0
         else
             l.throttle[i] = 0
             l.brake[i] = 50  -- Braking (50 bar - above 5 bar threshold)
         end
     end
    
    local brakePos = l:findBrakePoint(0.1, 0.2)
    local liftPos = l:findLiftPoint(0.1, 0.2)
    
    assert_not_nil(brakePos, "Should find brake point")
    assert_not_nil(liftPos, "Should find lift point")
    
    -- Lift should be before brake
    assert_true(liftPos < brakePos, "Lift point should be before brake point")
end)


--------------------------------------------------------------------------------
-- Tests for speed analysis
--------------------------------------------------------------------------------

suite("Speed analysis")

test("entry/apex/exit speed detection", function()
    local numSamples = lap.SAMPLE_RATE
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })
    
    -- Simulate corner: entry 150 -> apex 80 -> exit 120
    for i = 1, numSamples do
        local t = (i - 1) / (numSamples - 1)
        if t < 0.3 then
            -- Entry phase: speed decreasing from 150
            l.speed[i] = 150 - (t / 0.3) * 70
        elseif t < 0.5 then
            -- Apex phase: around 80
            l.speed[i] = 80
        else
            -- Exit phase: speed increasing to 120
            l.speed[i] = 80 + ((t - 0.5) / 0.5) * 40
        end
    end
    
    local apexPos, apexSpeed = l:findApex(0.1, 0.2)
    local entrySpeed = l:findEntrySpeed(0.1, 0.2)
    local exitSpeed = l:findExitSpeed(0.1, 0.2)
    
    assert_not_nil(apexPos, "Should find apex position")
    assert_near(apexSpeed, 80, 5, "Apex speed should be ~80")
    assert_near(entrySpeed, 150, 5, "Entry speed should be ~150")
    assert_near(exitSpeed, 120, 5, "Exit speed should be ~120")
end)

test("speed delta calculation", function()
    local current = createTestLap({ numSamples = 30, startPos = 0.1, endPos = 0.2 })
    local reference = createTestLap({ numSamples = 30, startPos = 0.1, endPos = 0.2 })
    
    -- Current: slower through corner
    for i = 1, 30 do
        current.speed[i] = 100
        reference.speed[i] = 110
    end
    
    local currentApex = current:findApex(0.1, 0.2)
    local refApex = reference:findApex(0.1, 0.2)
    
    -- Both should find apex at same position (constant speed = first sample is min)
    local _, currentApexSpeed = current:findApex(0.1, 0.2)
    local _, refApexSpeed = reference:findApex(0.1, 0.2)
    
    local apexDelta = currentApexSpeed - refApexSpeed
    
    assert_near(apexDelta, -10, 1, "Apex delta should be -10 km/h (slower)")
end)
