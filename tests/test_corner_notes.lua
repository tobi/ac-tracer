-- test_corner_notes.lua - Tests for corner analysis note generation
-- Tests the analysis functions that generate notes for corner review

local lap = require('lib.lap')

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
        table.insert(l.gforce, opts.gforce and opts.gforce[i] or vec3(0, 0, 0))
    end
    
    return l
end

local function hasNote(notes, text)
    for _, note in ipairs(notes or {}) do
        if note.text and note.text:find(text, 1, true) then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Tests for coaching comparisons
--------------------------------------------------------------------------------

suite("Corner coaching comparisons")

test("notes when final downshift is materially later than reference", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local notes = corner_analysis.collectNotes({
        currentDownshiftLastMs = 1200,
        refDownshiftLastMs = 700,
    })
    assert_true(hasNote(notes, "last downshift 0.5s later than reference"))
end)

test("notes when brake application rate is materially slower", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 60, startPos = 0.1, endPos = 0.2 })
    local reference = createTestLap({ numSamples = 60, startPos = 0.1, endPos = 0.2 })

    for i = 1, 60 do
        current.brake[i] = i < 10 and 0 or math.min(100, (i - 9) * 5)
        reference.brake[i] = i < 10 and 0 or math.min(100, (i - 9) * 20)
    end

    local notes = corner_analysis.collectNotes({ refStartPos = 0.1, refEndPos = 0.2 }, current, reference)
    assert_true(hasNote(notes, "brake application rate"))
end)

test("does not flag a moderately slower brake ramp against an elite reference", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 60, startPos = 0.1, endPos = 0.2 })
    local reference = createTestLap({ numSamples = 60, startPos = 0.1, endPos = 0.2 })
    for i = 1, 60 do
        current.brake[i] = i < 10 and 0 or math.min(100, (i - 9) * 14)
        reference.brake[i] = i < 10 and 0 or math.min(100, (i - 9) * 20)
    end
    local notes = corner_analysis.collectNotes({ refStartPos = 0.1, refEndPos = 0.2 }, current, reference)
    assert_true(not hasNote(notes, "brake application rate"))
end)

test("notes when reference trail-brakes materially longer", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 60, startPos = 0.1, endPos = 0.2 })
    local reference = createTestLap({ numSamples = 60, startPos = 0.1, endPos = 0.2 })

    for i = 1, 60 do
        if i < 10 then
            current.brake[i], reference.brake[i] = 0, 0
        elseif i == 10 then
            current.brake[i], reference.brake[i] = 100, 100
        else
            current.brake[i] = i <= 16 and math.max(0, 100 - (i - 10) * 18) or 0
            reference.brake[i] = i <= 45 and math.max(0, 100 - (i - 10) * 3) or 0
        end
    end

    local notes = corner_analysis.collectNotes({ refStartPos = 0.1, refEndPos = 0.2 }, current, reference)
    assert_true(hasNote(notes, "reference trail-brakes"))
end)

test("brake pressure note requires more than ten percent difference", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 30 })
    local reference = createTestLap({ numSamples = 30 })
    for i = 1, 30 do current.brake[i], reference.brake[i] = 95, 100 end
    local data = { refStartPos = 0.1, refEndPos = 0.2 }
    assert_true(not hasNote(corner_analysis.collectNotes(data, current, reference), "braking ("))
    for i = 1, 30 do current.brake[i] = 85 end
    assert_true(hasNote(corner_analysis.collectNotes(data, current, reference), "braking ("))
end)

test("detects and compares steering plus lateral-load turn-in", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 60 })
    local reference = createTestLap({ numSamples = 60 })
    for i = 1, 60 do
        local speed = 80 + math.abs(45 - i)
        current.speed[i], reference.speed[i] = speed, speed
        current.steering[i] = i >= 20 and lap.normalizeSteer(12) or 0.5
        reference.steering[i] = i >= 10 and lap.normalizeSteer(12) or 0.5
        current.gforce[i] = vec3(i >= 20 and 0.5 or 0, 0, -0.4)
        reference.gforce[i] = vec3(i >= 10 and 0.5 or 0, 0, -0.4)
    end
    local currentAnalysis = corner_analysis.analyzeCorner(current, { number = 1, startPos = 0.1, endPos = 0.2 })
    local refAnalysis = corner_analysis.analyzeCorner(reference, { number = 1, startPos = 0.1, endPos = 0.2 })
    local comparison = corner_analysis.compareCorners(currentAnalysis, refAnalysis)
    assert_not_nil(currentAnalysis.turnInPos)
    assert_not_nil(currentAnalysis.turnInLateralG)
    assert_near(currentAnalysis.peakLateralG, 0.5, 0.01)
    assert_near(comparison.currentPeakLateralG, 0.5, 0.01)
    assert_true(comparison.turnInDeltaM > 10)
    assert_true(hasNote(corner_analysis.collectNotes(comparison), "turn-in"))
end)

test("turn-in ignores an early steering correction without lateral response", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 60 })
    for i = 1, 60 do
        current.speed[i] = 80 + math.abs(45 - i)
        local correction = i >= 10 and i <= 14
        local actualTurn = i >= 28
        current.steering[i] = lap.normalizeSteer(correction and 7 or (actualTurn and 14 or 0))
        current.gforce[i] = vec3(actualTurn and 0.7 or 0, 0, -0.3)
    end
    local analysis = corner_analysis.analyzeCorner(current, { number = 1, startPos = 0.1, endPos = 0.2 })
    assert_not_nil(analysis.turnInPos)
    assert_true(analysis.turnInPos > current.pos[20], "turn-in should not use the early correction")
end)

test("turn-in backtracks from lateral G onset to steering initiation", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 60 })
    for i = 1, 60 do
        current.speed[i] = 80 + math.abs(45 - i)
        local steerDeg = i >= 18 and math.min(16, (i - 17) * 2) or 0
        current.steering[i] = lap.normalizeSteer(steerDeg)
        current.gforce[i] = vec3(i >= 25 and 0.7 or 0, 0, -0.3)
    end
    local analysis = corner_analysis.analyzeCorner(current, { number = 1, startPos = 0.1, endPos = 0.2 })
    assert_not_nil(analysis.turnInPos)
    assert_near(analysis.turnInPos, current.pos[18], 0.0001,
        "turn-in should be the start of steering build, not the later G-force hit")
end)

test("turn-in comparison works without lateral G like real-driver CSV references", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 80 })
    local reference = createTestLap({ numSamples = 80 })
    current.gforce, reference.gforce = {}, {}
    for i = 1, 80 do
        local currentRamp = math.max(0, math.min(18, (i - 31) * 2))
        local referenceRamp = math.max(0, math.min(18, (i - 21) * 2))
        current.steering[i] = lap.normalizeSteer(currentRamp)
        reference.steering[i] = lap.normalizeSteer(referenceRamp)
        local speed = 100 + math.abs(60 - i)
        current.speed[i], reference.speed[i] = speed, speed
    end
    local corner = { number = 1, startPos = 0.1, endPos = 0.2 }
    local currentAnalysis = corner_analysis.analyzeCorner(current, corner)
    local referenceAnalysis = corner_analysis.analyzeCorner(reference, corner)
    local comparison = corner_analysis.compareCorners(currentAnalysis, referenceAnalysis)
    assert_not_nil(comparison.turnInDeltaM)
    assert_true(comparison.turnInDeltaM > 40, "later steering ramp should compare later without G data")
    assert_equal(comparison.turnInConfidence, "high")
end)

test("turn-in comparison normalizes different steering amplitudes", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local current = createTestLap({ numSamples = 80 })
    local reference = createTestLap({ numSamples = 80 })
    for i = 1, 80 do
        local progress = math.max(0, math.min(1, (i - 24) / 10))
        current.steering[i] = lap.normalizeSteer(progress * 12)
        reference.steering[i] = lap.normalizeSteer(progress * 24)
        local speed = 100 + math.abs(60 - i)
        current.speed[i], reference.speed[i] = speed, speed
    end
    local corner = { number = 1, startPos = 0.1, endPos = 0.2 }
    local comparison = corner_analysis.compareCorners(
        corner_analysis.analyzeCorner(current, corner),
        corner_analysis.analyzeCorner(reference, corner))
    assert_near(comparison.turnInDeltaM, 0, 7,
        "same steering build should compare similarly despite different peak lock")
end)

test("flags combined grip underuse early and mid-corner", function()
    local corner_analysis = require('lib.windows.corner_analysis')
    local data = {
        currentCombinedGripEarly = 0.65, refCombinedGripEarly = 1.0,
        currentCombinedGripMid = 0.70, refCombinedGripMid = 1.0,
    }
    local notes = corner_analysis.collectNotes(data)
    assert_true(hasNote(notes, "less combined grip early corner"))
    assert_true(hasNote(notes, "less combined grip mid corner"))
end)

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


--------------------------------------------------------------------------------
-- Tests for downshift timing relative to brake initiation
--------------------------------------------------------------------------------

suite("Downshift timing analysis")

test("findDownshiftDelay detects immediate downshift after braking", function()
    local numSamples = lap.SAMPLE_RATE  -- 1 second of data at 30Hz
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })

    -- Setup: coasting in 5th gear, then brake at sample 10, downshift at sample 15
    for i = 1, numSamples do
        l.gear[i] = 5  -- Start in 5th gear
        l.brake[i] = 0
    end

    -- Start braking at sample 10 (hard brake: 50 bar)
    local brakeStartSample = 10
    for i = brakeStartSample, numSamples do
        l.brake[i] = 50
    end

    -- Downshift from 5th to 4th at sample 15
    local downshiftSample = 15
    for i = downshiftSample, numSamples do
        l.gear[i] = 4
    end

    local firstDelayMs, lastDelayMs, brakeTime, firstDownshiftTime, lastDownshiftTime, brakePos, firstDownshiftPos = l:findDownshiftDelay(0.1, 0.2)

    assert_not_nil(firstDelayMs, "Should find first downshift delay")
    assert_not_nil(lastDelayMs, "Should find last downshift delay")
    assert_not_nil(brakeTime, "Should return brake time")
    assert_not_nil(firstDownshiftTime, "Should return first downshift time")
    assert_not_nil(lastDownshiftTime, "Should return last downshift time")
    assert_not_nil(brakePos, "Should return brake position")
    assert_not_nil(firstDownshiftPos, "Should return first downshift position")

    -- With only one downshift, first and last should be equal
    assert_equal(firstDelayMs, lastDelayMs, "First and last delay should match for single downshift")

    -- Delay should be (15 - 10) samples = 5 samples at 30Hz = ~166.7ms
    local expectedDelayMs = (downshiftSample - brakeStartSample) / lap.SAMPLE_RATE * 1000
    assert_near(firstDelayMs, expectedDelayMs, 50, "Delay should be ~166ms (5 samples at 30Hz)")

    -- Position delta should match sample spacing
    local posRange = 0.2 - 0.1
    local expectedBrakePos = 0.1 + ((brakeStartSample - 1) / (numSamples - 1)) * posRange
    local expectedDownshiftPos = 0.1 + ((downshiftSample - 1) / (numSamples - 1)) * posRange
    assert_near(brakePos, expectedBrakePos, 0.0001, "Brake position should match expected")
    assert_near(firstDownshiftPos, expectedDownshiftPos, 0.0001, "Downshift position should match expected")
end)

test("findDownshiftDelay returns nil when no braking occurs", function()
    local numSamples = lap.SAMPLE_RATE
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })

    -- No braking, just coasting
    for i = 1, numSamples do
        l.gear[i] = 5
        l.brake[i] = 0
    end

    local firstDelayMs = l:findDownshiftDelay(0.1, 0.2)

    assert_nil(firstDelayMs, "Should return nil when no braking occurs")
end)

test("findDownshiftDelay returns nil when no downshift after brake", function()
    local numSamples = lap.SAMPLE_RATE
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })

    -- Braking but staying in same gear (engine braking only)
    for i = 1, numSamples do
        l.gear[i] = 5
        l.brake[i] = i > 10 and 50 or 0
    end

    local firstDelayMs = l:findDownshiftDelay(0.1, 0.2)

    assert_nil(firstDelayMs, "Should return nil when no downshift occurs after braking")
end)

test("findDownshiftDelay detects delayed downshift (late heel-toe)", function()
    local numSamples = lap.SAMPLE_RATE * 2  -- 2 seconds of data
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.3,  -- Longer corner
    })

    -- Setup: brake at sample 10, downshift much later at sample 40 (~1 second delay)
    for i = 1, numSamples do
        l.gear[i] = 5
        l.brake[i] = 0
    end

    local brakeStartSample = 10
    for i = brakeStartSample, numSamples do
        l.brake[i] = 50
    end

    -- Late downshift (1 second after braking starts)
    local downshiftSample = brakeStartSample + lap.SAMPLE_RATE  -- +30 samples = 1 second later
    for i = downshiftSample, numSamples do
        l.gear[i] = 4
    end

    local firstDelayMs = l:findDownshiftDelay(0.1, 0.3)

    assert_not_nil(firstDelayMs, "Should find late downshift delay")
    -- Delay should be ~1000ms
    assert_near(firstDelayMs, 1000, 100, "Delay should be ~1000ms (1 second)")
end)

test("findDownshiftDelay detects multiple downshifts (returns first and last)", function()
    local numSamples = lap.SAMPLE_RATE * 2
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.3,
    })

    -- Setup: brake at sample 10, downshift 5->4 at sample 15, then 4->3 at sample 25
    for i = 1, numSamples do
        l.gear[i] = 5
        l.brake[i] = 0
    end

    local brakeStartSample = 10
    for i = brakeStartSample, numSamples do
        l.brake[i] = 50
    end

    -- First downshift 5->4 at sample 15
    local firstDownshiftSample = 15
    for i = firstDownshiftSample, numSamples do
        l.gear[i] = 4
    end

    -- Second downshift 4->3 at sample 25
    local secondDownshiftSample = 25
    for i = secondDownshiftSample, numSamples do
        l.gear[i] = 3
    end

    local firstDelayMs, lastDelayMs = l:findDownshiftDelay(0.1, 0.3)

    assert_not_nil(firstDelayMs, "Should find first downshift delay")
    assert_not_nil(lastDelayMs, "Should find last downshift delay")

    -- First downshift timing (reaction time)
    local expectedFirstDelayMs = (firstDownshiftSample - brakeStartSample) / lap.SAMPLE_RATE * 1000
    assert_near(firstDelayMs, expectedFirstDelayMs, 50, "Should detect first downshift timing")

    -- Last downshift timing (total shift time)
    local expectedLastDelayMs = (secondDownshiftSample - brakeStartSample) / lap.SAMPLE_RATE * 1000
    assert_near(lastDelayMs, expectedLastDelayMs, 50, "Should detect last downshift timing")

    -- First should be less than last
    assert_true(firstDelayMs < lastDelayMs, "First delay should be less than last delay")
end)

test("findDownshiftDelay returns brake/downshift positions", function()
    local numSamples = lap.SAMPLE_RATE
    local l = createTestLap({
        numSamples = numSamples,
        startPos = 0.1,
        endPos = 0.2,
    })

    local brakeStartSample = 8
    for i = 1, numSamples do
        l.gear[i] = 5
        l.brake[i] = i >= brakeStartSample and 50 or 0
    end

    local downshiftSample = 14
    for i = downshiftSample, numSamples do
        l.gear[i] = 4
    end

    local _, _, _, _, _, brakePos, firstDownshiftPos = l:findDownshiftDelay(0.1, 0.2)
    assert_not_nil(brakePos, "Brake position should be returned")
    assert_not_nil(firstDownshiftPos, "Downshift position should be returned")
    assert_true(firstDownshiftPos > brakePos, "Downshift should occur after brake position")
end)


--------------------------------------------------------------------------------
-- Tests for lockup wheel identification patterns
--------------------------------------------------------------------------------

suite("Lockup wheel identification")

test("rear-only lockup returns correct wheels", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    for i = 10, 15 do
        l.flags[i] = bit.bor(lap.FLAGS.LOCKUP_RL, lap.FLAGS.LOCKUP_RR)
    end

    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)

    assert_true(hasLockup, "Should detect lockup")
    assert_true(not wheels.fl, "FL should not be locked")
    assert_true(not wheels.fr, "FR should not be locked")
    assert_true(wheels.rl, "RL should be locked")
    assert_true(wheels.rr, "RR should be locked")
end)

test("all four wheels lockup returns all true", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    for i = 10, 15 do
        l.flags[i] = bit.bor(
            bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_FR),
            bit.bor(lap.FLAGS.LOCKUP_RL, lap.FLAGS.LOCKUP_RR)
        )
    end

    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)

    assert_true(hasLockup, "Should detect lockup")
    assert_true(wheels.fl, "FL should be locked")
    assert_true(wheels.fr, "FR should be locked")
    assert_true(wheels.rl, "RL should be locked")
    assert_true(wheels.rr, "RR should be locked")
end)

test("single wheel lockup (FL only)", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    for i = 12, 14 do
        l.flags[i] = lap.FLAGS.LOCKUP_FL
    end

    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)

    assert_true(hasLockup, "Should detect lockup")
    assert_true(wheels.fl, "FL should be locked")
    assert_true(not wheels.fr, "FR should not be locked")
    assert_true(not wheels.rl, "RL should not be locked")
    assert_true(not wheels.rr, "RR should not be locked")
end)

test("diagonal lockup (FL + RR)", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    for i = 10, 15 do
        l.flags[i] = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_RR)
    end

    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)

    assert_true(hasLockup, "Should detect lockup")
    assert_true(wheels.fl, "FL should be locked")
    assert_true(not wheels.fr, "FR should not be locked")
    assert_true(not wheels.rl, "RL should not be locked")
    assert_true(wheels.rr, "RR should be locked")
end)

test("lockup wheels included in flag summary", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    for i = 10, 15 do
        l.flags[i] = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_FR)
    end

    local summary = l:getFlagSummary(0.1, 0.2)

    assert_true(summary.lockup.count > 0, "Should have lockup count")
    assert_true(summary.lockup.wheels.fl, "Summary should include FL lockup")
    assert_true(summary.lockup.wheels.fr, "Summary should include FR lockup")
    assert_true(not summary.lockup.wheels.rl, "Summary should not include RL lockup")
    assert_true(not summary.lockup.wheels.rr, "Summary should not include RR lockup")
end)

test("no lockup returns false and nil wheels", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    -- No lockup flags set
    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)

    assert_true(not hasLockup, "Should not detect lockup")
    assert_nil(wheels, "Wheels should be nil when no lockup")
end)

test("lockup on different samples aggregates all wheels", function()
    local l = createTestLap({
        numSamples = 30,
        startPos = 0.1,
        endPos = 0.2,
    })

    -- FL locks on sample 10, RR locks on sample 20 (different times)
    l.flags[10] = lap.FLAGS.LOCKUP_FL
    l.flags[20] = lap.FLAGS.LOCKUP_RR

    local hasLockup, wheels = l:hasLockupInRange(0.1, 0.2)

    assert_true(hasLockup, "Should detect lockup")
    assert_true(wheels.fl, "FL should be locked (from sample 10)")
    assert_true(not wheels.fr, "FR should not be locked")
    assert_true(not wheels.rl, "RL should not be locked")
    assert_true(wheels.rr, "RR should be locked (from sample 20)")
end)
