-- Corner Analysis - All corner-specific logic
-- Analyzes corners in laps, tracks live corner data, compares to reference

local lap = require('lib.lap')
local scoring = require('lib.core.scoring')
local settings = require('lib.core.settings')
local extended_brake = require('lib.core.brake')
local theme = require('lib.ui.theme')
local ui_utils = require('lib.ui.utils')
local wedge = require('lib.ui.wedge')
local state = require('lib.core.state')

local corner_analysis = {}

--------------------------------------------------------------------------------
-- Pre-allocated vec2 objects for drawing (avoid allocations in hot loops)
--------------------------------------------------------------------------------

local _v1 = vec2()
local _v2 = vec2()
local _v3 = vec2()
local _v4 = vec2()
local _vp = vec2()

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

-- Thresholds accessed via settings accessors (live values)
local function getBrakeThreshold() return settings.brakeThreshold() end
local function getThrottleOnThreshold() return settings.throttleThreshold() end
local STEERING_CENTER_THRESHOLD = 0.042  -- ~15°

--------------------------------------------------------------------------------
-- Live Corner Tracking State
--------------------------------------------------------------------------------

local GEAR_SHIFT_IGNORE_TIME = 0.5  -- Seconds to ignore throttle around gear shifts (covers heel-toe blips)

local liveCorner = {
    cornerNum = 0,
    cornerInfo = nil,
    entrySpeed = nil,
    entryPos = nil,
    entryTime = nil,
    apexSpeed = nil,
    apexPos = nil,
    exitSpeed = nil,
    exitPos = nil,
    exitTime = nil,
    ghostEntryTime = nil,
    ghostExitTime = nil,
    passedApex = false,
    leftCorner = false,
    wasBraking = false,
    brakePos = nil,
    liftOffPos = nil,
    wasOnThrottle = false,
    speeds = {},
    maxSteeringDeg = 0,
    lastGear = nil,
    gearShiftTime = 0,
}

local lastLapCount = 0
local currentLapTime = 0
local ignoredCornerAfterJump = 0
local lastResetCounter = -1

-- Display state (last completed corner)
local displayData = nil
local displayScore = 0
local displayLap = nil      -- The lap data at time of corner exit (for flag analysis)
local lastCompletedResult = nil -- {cornerNum, score, timeDelta}

-- Live state for the tiny Lift -> Brake -> Turn -> Apex dot window.
local sequenceState = {
    cornerNum = 0,
    events = {
        { relevant = false, visible = false, delta = nil, flash = 0 },
        { relevant = false, visible = false, delta = nil, flash = 0 },
        { relevant = false, visible = false, delta = nil, flash = 0 },
        { relevant = false, visible = false, delta = nil, flash = 0 },
    },
    refLiftPos = nil,
    refBrakePos = nil,
    refTurnPos = nil,
    refTurnDirection = nil,
    refTurnThresholdDeg = nil,
    refApexPos = nil,
    entrySteerDeg = 0,
    turnCandidatePos = nil,
    turnCandidateTime = 0,
    apexRiseTime = 0,
}

local function clearSequence(cornerNum)
    sequenceState.cornerNum = cornerNum or 0
    for i = 1, 4 do
        local event = sequenceState.events[i]
        event.relevant, event.visible, event.delta, event.flash = false, false, nil, 0
    end
    sequenceState.refLiftPos = nil
    sequenceState.refBrakePos = nil
    sequenceState.refTurnPos = nil
    sequenceState.refTurnDirection = nil
    sequenceState.refTurnThresholdDeg = nil
    sequenceState.refApexPos = nil
    sequenceState.entrySteerDeg = 0
    sequenceState.turnCandidatePos = nil
    sequenceState.turnCandidateTime = 0
    sequenceState.apexRiseTime = 0
end

local function revealSequenceEvent(index, currentPos, referencePos)
    local event = sequenceState.events[index]
    if not event.relevant or event.visible or not currentPos or not referencePos then return end
    event.visible = true
    event.delta = referencePos and scoring.positionDeltaToMeters(currentPos, referencePos) or nil
    event.flash = 1
end

-- Recent corner scores (for delta bar display)
-- Array of {cornerNum, score, lapNumber}, max 10 entries
local recentCornerScores = {}
local MAX_RECENT_SCORES = 10

-- Frozen corner state (when viewing from telemetry)
local frozenCorner = {
    active = false,
    cornerNum = 0,
    lapNumber = 0,
    currentLap = nil,   -- The lap being analyzed
    referenceLap = nil, -- The reference lap for comparison
}

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function isSteeringCentered(steering)
    return math.abs(steering - 0.5) < STEERING_CENTER_THRESHOLD
end

local function resetLiveCorner()
    liveCorner.cornerNum = 0
    liveCorner.cornerInfo = nil
    liveCorner.entrySpeed = nil
    liveCorner.entryPos = nil
    liveCorner.entryTime = nil
    liveCorner.apexSpeed = nil
    liveCorner.apexPos = nil
    liveCorner.exitSpeed = nil
    liveCorner.exitPos = nil
    liveCorner.exitTime = nil
    liveCorner.ghostEntryTime = nil
    liveCorner.ghostExitTime = nil
    liveCorner.passedApex = false
    liveCorner.leftCorner = false
    liveCorner.wasBraking = false
    liveCorner.brakePos = nil
    liveCorner.liftOffPos = nil
    liveCorner.wasOnThrottle = false
    liveCorner.speeds = {}
    liveCorner.maxSteeringDeg = 0
    liveCorner.lastGear = nil
    liveCorner.gearShiftTime = 0
end

local function getCornerInfo(corners, cornerNum)
    if not corners then return nil end
    for _, c in ipairs(corners) do
        if c.number == cornerNum then return c end
    end
    return nil
end

local function getCornerAtPos(corners, pos)
     if not corners then return 0, nil end
     for _, c in ipairs(corners) do
         if c.startPos and c.endPos then
             if lap.isInRange(pos, c.startPos, c.endPos) then return c.number, c end
         end
     end
    return 0, nil
end

local captureRefSpeeds

--------------------------------------------------------------------------------
-- Corner Notes Analysis Functions
-- Each function analyzes one aspect and returns a note string or nil
--------------------------------------------------------------------------------

--- Compare steering wheel inputs between current and reference
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about steering difference, or nil if not significant
local function analyzeSteeringInput(data)
    if not data.steeringDelta then return nil end
    if math.abs(data.steeringDelta) <= 10 then return nil end  -- Only report > 10° difference

    local dir = data.steeringDelta > 0 and "more" or "less"
    return { text = string.format("%.0f° %s steering", math.abs(data.steeringDelta), dir), severity = "info" }
end

--- Compare gear usage between current and reference
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about gear difference, or nil if same gear
local function analyzeGearUsage(data)
    if not data.gearDelta or data.gearDelta == 0 then return nil end

    local diff = math.abs(data.gearDelta)
    local dir = data.gearDelta > 0 and "higher" or "lower"
    return { text = string.format("%d gear%s %s", diff, diff > 1 and "s" or "", dir), severity = "info" }
end

--- Analyze coasting distance vs reference (throttle lift to brake application)
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about coasting difference, or nil if similar
local function analyzeCoasting(data)
    if not data.currentLiftOffPos or not data.currentBrakePos then return nil end
    if not data.refLiftOffPos or not data.refBrakePos then return nil end

    local trackLen = ac.getSim().trackLengthM or 5000

    -- Calculate current coasting distance
    local currentCoastM = (data.currentBrakePos - data.currentLiftOffPos) * trackLen
    if currentCoastM < 0 then currentCoastM = currentCoastM + trackLen end

    -- Calculate reference coasting distance
    local refCoastM = (data.refBrakePos - data.refLiftOffPos) * trackLen
    if refCoastM < 0 then refCoastM = refCoastM + trackLen end

    -- Only report if significantly different from reference (> 15m)
    local diff = currentCoastM - refCoastM
    -- Coast distance is linear, but when one value lands near track-length (from
    -- start/finish wrapping), normalize to shortest signed difference for notes.
    if diff > trackLen * 0.5 then diff = diff - trackLen end
    if diff < -trackLen * 0.5 then diff = diff + trackLen end
    if math.abs(diff) < 15 then return nil end

    local dir = diff > 0 and "more" or "less"
    return { text = string.format("%.0fm %s coasting", math.abs(diff), dir), severity = "info" }
end

--- Helper to sample pedal traces from a lap in a position range
--- (Defined early so it can be used by setViewedCorner)
---@param lapData table Lap instance
---@param startPos number Start position
---@param endPos number End position
---@param numSamples number Number of samples
---@param maxBar number? Max brake pressure for normalization (default 100)
local function samplePedalTraces(lapData, startPos, endPos, numSamples, maxBar)
    if not lapData or lapData:length() == 0 then return nil end

    maxBar = maxBar or 100
    local traces = { throttle = {}, brake = {} }
    local posRange = endPos - startPos
    if posRange <= 0 then posRange = posRange + 1 end

    for i = 0, numSamples do
        local pos = startPos + (i / numSamples) * posRange
        if pos > 1 then pos = pos - 1 end
        local throttle = lapData:throttleAt(pos) or 0
        local brake = lapData:brakePercentAt(pos, maxBar) or 0
        table.insert(traces.throttle, throttle)
        table.insert(traces.brake, brake)
    end
    return traces
end

local function sampleSpeedTrace(lapData, startPos, endPos, numSamples)
    if not lapData or lapData:length() == 0 then return {} end
    local speeds = {}
    local posRange = endPos - startPos
    if posRange <= 0 then posRange = posRange + 1 end

    for i = 0, numSamples do
        local pos = startPos + (i / numSamples) * posRange
        if pos > 1 then pos = pos - 1 end
        local spd = lapData:speedAt(pos)
        if spd then
            table.insert(speeds, { pos = pos, speed = spd })
        end
    end
    return speeds
end

--- Analyze bad throttle during heavy braking (not just gear blips)
--- This detects throttle input during the brake zone that isn't heel-toe
---@param currentLap table Current lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about bad overlap, or nil if clean
local function analyzeBadBrakeZoneThrottle(currentLap, data)
    if not currentLap or not data.refStartPos or not data.refEndPos then return nil end
    if not data.currentBrakePos then return nil end  -- No brake point recorded

    local HEAVY_BRAKE_THRESHOLD = 30  -- 30 bar = heavy braking
    local THROTTLE_THRESHOLD = 0.3     -- 30% throttle = not just a blip
    local BLIP_DURATION = 0.5          -- 500ms = allow for heel-toe blips (longer threshold)

    local badOverlapSamples = 0
    local consecutiveBadSamples = 0
    local maxConsecutive = 0

    -- Look from corner start to brake point (the brake zone)
    local brakeZoneEnd = data.currentBrakePos
    -- Extend a bit past brake point to catch the main braking zone
    local searchEnd = math.min(data.refEndPos, brakeZoneEnd + 0.02)

    for i = 1, #currentLap.pos do
        local pos = currentLap.pos[i]
        if pos >= data.refStartPos and pos <= searchEnd then
            local brake = currentLap.brake[i] or 0
            local throttle = currentLap.throttle[i] or 0

            if brake >= HEAVY_BRAKE_THRESHOLD and throttle >= THROTTLE_THRESHOLD then
                consecutiveBadSamples = consecutiveBadSamples + 1
                badOverlapSamples = badOverlapSamples + 1
                if consecutiveBadSamples > maxConsecutive then
                    maxConsecutive = consecutiveBadSamples
                end
            else
                consecutiveBadSamples = 0
            end
        end
    end

    -- Convert max consecutive to duration (using lap sample rate)
    local maxDuration = maxConsecutive / lap.SAMPLE_RATE

    -- If the longest throttle period during heavy braking exceeds blip duration, it's bad
    if maxDuration > BLIP_DURATION then
        return {
            text = string.format("throttle while braking (%.1fs)", maxDuration),
            severity = "error"
        }
    end

    return nil
end

--- Analyze wheel lockups in corner
---@param currentLap table Current lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about lockups, or nil if none
local function analyzeLockups(currentLap, data)
    if not currentLap or not data.refStartPos or not data.refEndPos then return nil end

    local hasLockup, wheels = currentLap:hasLockupInRange(data.refStartPos, data.refEndPos)
    if not hasLockup then return nil end

    -- Build description of which wheels locked
    local locked = {}
    if wheels.fl then table.insert(locked, "FL") end
    if wheels.fr then table.insert(locked, "FR") end
    if wheels.rl then table.insert(locked, "RL") end
    if wheels.rr then table.insert(locked, "RR") end

    if #locked == 0 then return nil end

    -- Simplify output for common patterns
    local text
    if wheels.fl and wheels.fr and not wheels.rl and not wheels.rr then
        text = "front lockup"
    elseif wheels.rl and wheels.rr and not wheels.fl and not wheels.fr then
        text = "rear lockup"
    elseif #locked == 4 then
        text = "all wheels locked"
    else
        text = table.concat(locked, "+") .. " lockup"
    end
    return { text = text, severity = "error", wheels = wheels }
end

--- Analyze traction control interventions
---@param currentLap table Current lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about TC, or nil if none
local function analyzeTractionControl(currentLap, data)
    if not currentLap or not data.refStartPos or not data.refEndPos then return nil end

    local tcCount = currentLap:countFlagInRange(data.refStartPos, data.refEndPos, lap.FLAGS.TC_ACTIVE)
    if tcCount == 0 then return nil end

    -- Convert samples to approximate duration (using lap sample rate)
    local tcDuration = tcCount / lap.SAMPLE_RATE
    if tcDuration < 1.0 then return nil end  -- Only report if > 1 second

    return { text = string.format("TC active %.1fs", tcDuration), severity = "info" }
end

--- Analyze offtrack excursions
---@param currentLap table Current lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about offtrack, or nil if none
local function analyzeOfftrack(currentLap, data)
    if not currentLap or not data.refStartPos or not data.refEndPos then return nil end

    local offtrackCount = currentLap:countFlagInRange(data.refStartPos, data.refEndPos, lap.FLAGS.OFFTRACK)
    if offtrackCount == 0 then return nil end

    -- Convert samples to approximate duration
    local offtrackDuration = offtrackCount / lap.SAMPLE_RATE
    if offtrackDuration < 0.1 then return nil end  -- Ignore very brief excursions

    return { text = string.format("off track %.1fs", offtrackDuration), severity = "error" }
end

--- Analyze rev limiter hits
---@param currentLap table Current lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about limiter, or nil if none
local function analyzeLimiter(currentLap, data)
    if not currentLap or not data.refStartPos or not data.refEndPos then return nil end

    local limiterCount = currentLap:countFlagInRange(data.refStartPos, data.refEndPos, lap.FLAGS.LIMITER_HIT)
    if limiterCount == 0 then return nil end

    -- Convert samples to approximate duration
    local limiterDuration = limiterCount / lap.SAMPLE_RATE
    if limiterDuration < 0.05 then return nil end  -- Ignore very brief hits

    return { text = "hit rev limiter", severity = "info" }
end

--- Analyze throttle application timing vs reference
---@param currentLap table Current lap data
---@param refLap table Reference lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about throttle timing, or nil if similar
local function analyzeThrottleTiming(currentLap, refLap, data)
    if not currentLap or not refLap then return nil end
    if not data.refStartPos or not data.refEndPos then return nil end

    local THROTTLE_THRESHOLD = 0.9  -- Consider "on throttle" at 90%
    local GEAR_SHIFT_WINDOW = 25    -- Samples to ignore around gear shifts (~0.5s at 50Hz)
    local SUSTAINED_SAMPLES = 10    -- Require throttle to stay high for ~200ms to count

    -- Helper to check if a gear shift occurred near index i in a lap
    local function isNearGearShift(lapData, i)
        if not lapData.gear or #lapData.gear < 2 then return false end
        local currentGear = lapData.gear[i]
        if not currentGear then return false end

        -- Check samples before and after for gear changes
        for j = math.max(1, i - GEAR_SHIFT_WINDOW), math.min(#lapData.gear, i + GEAR_SHIFT_WINDOW) do
            if lapData.gear[j] and lapData.gear[j] ~= currentGear then
                return true
            end
        end
        return false
    end

    -- Helper to check if throttle is sustained (not just a blip)
    local function isThrottleSustained(lapData, startIdx)
        local count = 0
        for i = startIdx, math.min(startIdx + SUSTAINED_SAMPLES - 1, #lapData.throttle) do
            if lapData.throttle[i] and lapData.throttle[i] >= THROTTLE_THRESHOLD then
                count = count + 1
            end
        end
        return count >= SUSTAINED_SAMPLES
    end

    -- Find throttle application point in current lap (after apex)
    local apexPos = data.currentApexPos or ((data.refStartPos + data.refEndPos) / 2)
    local currentThrottlePos = nil
    local refThrottlePos = nil

    -- Search from apex to corner end for sustained throttle application (ignoring gear shift blips)
    for i = 1, #currentLap.pos do
        local pos = currentLap.pos[i]
        if pos >= apexPos and pos <= data.refEndPos then
            if currentLap.throttle[i] and currentLap.throttle[i] >= THROTTLE_THRESHOLD then
                -- Skip if this is near a gear shift (likely a blip for rev matching)
                if not isNearGearShift(currentLap, i) and isThrottleSustained(currentLap, i) then
                    currentThrottlePos = pos
                    break
                end
            end
        end
    end

    for i = 1, #refLap.pos do
        local pos = refLap.pos[i]
        if pos >= apexPos and pos <= data.refEndPos then
            if refLap.throttle[i] and refLap.throttle[i] >= THROTTLE_THRESHOLD then
                -- Skip if this is near a gear shift (likely a blip for rev matching)
                if not isNearGearShift(refLap, i) and isThrottleSustained(refLap, i) then
                    refThrottlePos = pos
                    break
                end
            end
        end
    end

    if not currentThrottlePos or not refThrottlePos then return nil end

    local diffM = ui_utils.positionDeltaToMeters(currentThrottlePos, refThrottlePos)
    if not diffM then return nil end
    if math.abs(diffM) < 15 then return nil end  -- Ignore < 15m difference

    local dir = diffM < 0 and "early" or "late"
    return { text = string.format("throttle %.0fm %s", math.abs(diffM), dir), severity = "info" }
end

--- Analyze brake pressure difference
---@param currentLap table Current lap data
---@param refLap table Reference lap data
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about brake pressure, or nil if similar
local function analyzeBrakePressure(currentLap, refLap, data)
    if not currentLap or not refLap then return nil end
    if not data.refStartPos or not data.refEndPos then return nil end

    -- Find max brake pressure in corner for both laps (values are in bar)
    local currentMaxBar = 0
    local refMaxBar = 0

    for i = 1, #currentLap.pos do
        local pos = currentLap.pos[i]
        if pos >= data.refStartPos and pos <= data.refEndPos then
            local brake = currentLap.brake[i] or 0
            if brake > currentMaxBar then currentMaxBar = brake end
        end
    end

    for i = 1, #refLap.pos do
        local pos = refLap.pos[i]
        if pos >= data.refStartPos and pos <= data.refEndPos then
            local brake = refLap.brake[i] or 0
            if brake > refMaxBar then refMaxBar = brake end
        end
    end

    -- Only report if pressure differs by more than 10% from the reference.
    local diffBar = currentMaxBar - refMaxBar
    if refMaxBar <= 0 or math.abs(diffBar) / refMaxBar <= 0.10 then return nil end

    local dir = diffBar < 0 and "lighter" or "harder"
    return { text = string.format("%s braking (%.0f vs %.0f bar)", dir, currentMaxBar, refMaxBar), severity = "info" }
end

--- Analyze entry speed warning (significantly different from reference)
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about entry speed, or nil if similar
local function analyzeEntrySpeed(data)
    if not data.entrySpeedDelta then return nil end

    -- Only warn if > 10 km/h difference
    if math.abs(data.entrySpeedDelta) < 10 then return nil end

    local dir = data.entrySpeedDelta > 0 and "faster" or "slower"
    local displayDelta = ui_utils.speed(math.abs(data.entrySpeedDelta))
    return { text = string.format("entry %.0f %s %s", displayDelta, ui_utils.speedUnit(), dir), severity = "info" }
end

--- Analyze downshift reaction distance (brake to first downshift)
--- Flags slow reaction if distance is large
---@param data table Corner comparison data
---@return table|nil Note {text, severity} about slow downshift reaction, or nil if fast enough
local function analyzeDownshiftReaction(data)
    if not data.currentDownshiftDistanceM then return nil end

    local SLOW_REACTION_THRESHOLD_M = 5
    if data.currentDownshiftDistanceM <= SLOW_REACTION_THRESHOLD_M then
        return nil -- Fast enough, no warning needed
    end

    local text = string.format("downshift %.0fm after brake", data.currentDownshiftDistanceM)
    return { text = text, severity = "info" }
end

local function gforceComponents(sample)
    if not sample then return nil, nil end
    return sample.x or sample[1], sample.z or sample[3]
end

--- Find the start and shape of the committed steering build for a corner.
--- This deliberately uses steering only: imported reference laps (including the
--- real-driver MoTeC files) do not contain lateral G, so using G for one lap but
--- not the other biases the comparison.  A later comparison uses several
--- points on this ramp rather than trusting one threshold crossing.
local function detectTurnIn(lapData, startPos, endPos, apexPos)
    if not lapData or not lapData.pos or not lapData.steering then return nil, nil end
    local endSearch = apexPos or endPos
    local indices = {}
    for i = 1, #lapData.pos do
        if lap.isInRange(lapData.pos[i], startPos, endSearch) then indices[#indices + 1] = i end
    end
    if #indices < 8 then return nil, nil end

    local steer = {}
    for n, i in ipairs(indices) do
        -- Three-sample moving average removes encoder/CSV quantisation without
        -- moving the result materially at the 50 Hz recording rate.
        local sum, count = 0, 0
        for k = math.max(1, i - 1), math.min(#lapData.steering, i + 1) do
            sum = sum + lap.steerToDegrees(lapData.steering[k] or 0.5)
            count = count + 1
        end
        steer[n] = sum / count
    end

    -- Corner definitions include an approach, so this is normally straight-line
    -- steering. Keep it short so a genuinely early turn-in is not absorbed into
    -- the baseline.
    local baselineCount = math.max(3, math.min(10, math.floor(#indices * 0.10)))
    local baselineSteer = 0
    for n = 1, baselineCount do
        baselineSteer = baselineSteer + steer[n]
    end
    baselineSteer = baselineSteer / baselineCount

    local positivePeak, negativePeak = 0, 0
    for n = baselineCount + 1, #indices do
        local excursion = steer[n] - baselineSteer
        positivePeak = math.max(positivePeak, excursion)
        negativePeak = math.max(negativePeak, -excursion)
    end
    local direction = positivePeak >= negativePeak and 1 or -1
    local peak = math.max(positivePeak, negativePeak)
    if peak < 4 then return nil, nil end

    local directed = {}
    for n = 1, #indices do directed[n] = (steer[n] - baselineSteer) * direction end

    local noise = 0
    for n = 1, baselineCount do noise = math.max(noise, math.abs(directed[n])) end
    local onsetThreshold = math.max(0.75, noise + 0.35, peak * 0.06)
    local SUSTAINED = 4

    local function committedHalfCrossing()
        local threshold = peak * 0.50
        for n = baselineCount + 1, #indices - SUSTAINED + 1 do
            local ok = true
            for k = n, n + SUSTAINED - 1 do
                if directed[k] < threshold then ok = false break end
            end
            if ok then
                -- The input must continue developing after the crossing. This
                -- rejects a sizeable but brief correction on the approach.
                local lookEnd = math.min(#indices, n + 11)
                local held, total = 0, lookEnd - n + 1
                for k = n, lookEnd do
                    if directed[k] >= peak * 0.25 then held = held + 1 end
                end
                if total >= 4 and held / total >= 0.70 then return n end
            end
        end
        return nil
    end

    local p50 = committedHalfCrossing()
    if not p50 then return nil, nil end

    -- Locate lower commitment levels only within the continuous build which
    -- leads to that confirmed 50% point, never in an unrelated earlier wiggle.
    local function backtrackLevel(from, fraction)
        local threshold = peak * fraction
        local n = from
        while n > baselineCount + 1 and directed[n - 1] >= threshold do n = n - 1 end
        return n
    end
    local p25 = backtrackLevel(p50, 0.25)
    local p10 = backtrackLevel(p25, 0.10)

    -- Backtrack from established commitment through the same continuous ramp.
    -- A brief correction which returns to centre is therefore not selected.
    local onset = p25
    while onset > baselineCount + 1 and directed[onset - 1] > onsetThreshold do
        onset = onset - 1
    end
    if p10 < onset then onset = p10 end

    local i = indices[onset]
    local profile = {
        positions = {
            lapData.pos[indices[p10]],
            lapData.pos[indices[p25]],
            lapData.pos[indices[p50]],
        },
        direction = direction,
        peakSteeringDeg = peak,
    }
    return lapData.pos[i], i, profile
end

local function nearestIndexForPos(lapData, targetPos, startIndex)
    if not targetPos then return nil end
    local bestIndex, bestDistance
    for i = startIndex or 1, #lapData.pos do
        local distance = math.abs((lapData.pos[i] or 0) - targetPos)
        distance = math.min(distance, 1 - distance)
        if not bestDistance or distance < bestDistance then
            bestIndex, bestDistance = i, distance
        end
    end
    return bestIndex
end

local function lateralGMetrics(lapData, startPos, endPos, turnInIndex)
    if not lapData or not lapData.gforce or #lapData.gforce == 0 then return nil, nil end
    local peak = nil
    for i = 1, #lapData.pos do
        if lap.isInRange(lapData.pos[i], startPos, endPos) then
            local latG = gforceComponents(lapData.gforce[i])
            if latG ~= nil then peak = math.max(peak or 0, math.abs(latG)) end
        end
    end
    local turnInLatG = nil
    if turnInIndex then
        local latG = gforceComponents(lapData.gforce[turnInIndex])
        turnInLatG = latG and math.abs(latG) or nil
    end
    return peak, turnInLatG
end

--- Average combined braking/lateral acceleration in early and mid-corner phases.
local function combinedGripPhases(lapData, turnInIndex, apexPos)
    if not lapData or not turnInIndex or not lapData.gforce or #lapData.gforce == 0 then return nil, nil end
    local apexIndex = nearestIndexForPos(lapData, apexPos, turnInIndex)
    if not apexIndex or apexIndex <= turnInIndex + 1 then return nil, nil end
    local splitIndex = math.floor((turnInIndex + apexIndex) / 2)

    local function average(fromIndex, toIndex)
        local sum, count = 0, 0
        for i = fromIndex, toIndex do
            local latG, longG = gforceComponents(lapData.gforce[i])
            if latG ~= nil and longG ~= nil then
                local brakingG = math.max(0, -longG)
                sum = sum + math.sqrt(latG * latG + brakingG * brakingG)
                count = count + 1
            end
        end
        return count >= 2 and sum / count or nil
    end

    return average(turnInIndex, splitIndex), average(splitIndex + 1, apexIndex)
end

local function analyzeTurnIn(data)
    if not data.turnInDeltaM or math.abs(data.turnInDeltaM) < 3 then return nil end
    local direction = data.turnInDeltaM > 0 and "later" or "earlier"
    local qualifier = data.turnInConfidence == "low" and " (low confidence)" or ""
    return { text = string.format("turn-in %.0fm %s than reference%s", math.abs(data.turnInDeltaM), direction, qualifier), severity = "info" }
end

local function analyzeCombinedGrip(data, phase)
    local current = phase == "early" and data.currentCombinedGripEarly or data.currentCombinedGripMid
    local reference = phase == "early" and data.refCombinedGripEarly or data.refCombinedGripMid
    if not current or not reference or reference < 0.2 then return nil end
    local deficit = reference - current
    if deficit < 0.15 or current / reference >= 0.88 then return nil end
    return {
        text = string.format("%.2fg less combined grip %s corner", deficit, phase == "early" and "early" or "mid"),
        severity = "info"
    }
end

--- Compare completion timing of the downshift sequence with the reference.
local function analyzeLastDownshiftTiming(data)
    if not data.currentDownshiftLastMs or not data.refDownshiftLastMs then return nil end

    local diffMs = data.currentDownshiftLastMs - data.refDownshiftLastMs
    local LATE_THRESHOLD_MS = 300
    if diffMs < LATE_THRESHOLD_MS then return nil end

    return {
        text = string.format("last downshift %.1fs later than reference", diffMs / 1000),
        severity = "info"
    }
end

--- Measure how quickly brake pressure rises from initial application to 90% of peak.
local function brakeApplicationRate(lapData, startPos, endPos)
    if not lapData or not lapData.pos or not lapData.times then return nil end

    local peakBar = 0
    for i = 1, #lapData.pos do
        if lap.isInRange(lapData.pos[i], startPos, endPos) then
            peakBar = math.max(peakBar, lapData.brake[i] or 0)
        end
    end
    if peakBar < 20 then return nil end

    local onsetBar = math.max(5, peakBar * 0.1)
    local targetBar = peakBar * 0.9
    local onsetTime, targetTime
    for i = 1, #lapData.pos do
        if lap.isInRange(lapData.pos[i], startPos, endPos) then
            local pressure = lapData.brake[i] or 0
            if not onsetTime and pressure >= onsetBar then onsetTime = lapData.times[i] end
            if onsetTime and pressure >= targetBar then
                targetTime = lapData.times[i]
                break
            end
        end
    end

    if not onsetTime or not targetTime then return nil end
    local riseTime = targetTime - onsetTime
    if riseTime < 0.02 then riseTime = 0.02 end
    return (targetBar - onsetBar) / riseTime
end

--- Note a materially slower brake-pressure ramp than the reference.
local function analyzeBrakeApplicationRate(currentLap, refLap, data)
    if not data.refStartPos or not data.refEndPos then return nil end
    local currentRate = brakeApplicationRate(currentLap, data.refStartPos, data.refEndPos)
    local refRate = brakeApplicationRate(refLap, data.refStartPos, data.refEndPos)
    if not currentRate or not refRate or refRate < 50 then return nil end

    local ratio = currentRate / refRate
    -- Elite references can spike pressure extremely quickly. Only coach this
    -- when the driver's ramp is less than half as fast and clearly separated.
    if ratio >= 0.5 or refRate - currentRate < 100 then return nil end

    return {
        text = string.format("brake application rate %.0f%% slower than reference", (1 - ratio) * 100),
        severity = "info"
    }
end

--- Measure time spent releasing the brake after peak pressure.
local function trailBrakeDuration(lapData, startPos, endPos)
    if not lapData or not lapData.pos or not lapData.times then return nil end

    local peakBar, peakIndex = 0, nil
    for i = 1, #lapData.pos do
        if lap.isInRange(lapData.pos[i], startPos, endPos) then
            local pressure = lapData.brake[i] or 0
            if pressure > peakBar then
                peakBar, peakIndex = pressure, i
            end
        end
    end
    if not peakIndex or peakBar < 20 then return nil end

    local releaseBar = math.max(5, peakBar * 0.1)
    local releaseIndex = nil
    local belowCount = 0
    for i = peakIndex + 1, #lapData.pos do
        if not lap.isInRange(lapData.pos[i], startPos, endPos) then break end
        if (lapData.brake[i] or 0) <= releaseBar then
            belowCount = belowCount + 1
            if belowCount >= 3 then
                releaseIndex = i - 2
                break
            end
        else
            belowCount = 0
        end
    end
    if not releaseIndex then return nil end
    return math.max(0, (lapData.times[releaseIndex] or 0) - (lapData.times[peakIndex] or 0))
end

--- Note when the reference carries and releases brake pressure for longer.
local function analyzeReferenceTrailBraking(currentLap, refLap, data)
    if not data.refStartPos or not data.refEndPos then return nil end
    local currentDuration = trailBrakeDuration(currentLap, data.refStartPos, data.refEndPos)
    local refDuration = trailBrakeDuration(refLap, data.refStartPos, data.refEndPos)
    if not currentDuration or not refDuration then return nil end

    local diff = refDuration - currentDuration
    if diff < 0.3 or refDuration < currentDuration * 1.3 then return nil end

    return {
        text = string.format("reference trail-brakes %.1fs longer", diff),
        severity = "info"
    }
end

--- Collect all corner notes by running analysis functions
---@param data table Corner comparison data
---@param currentLap table Current lap data (optional, for flag-based analysis)
---@param refLap table Reference lap data (optional, for comparisons)
---@return table Array of note tables {text, severity} (may be empty)
function corner_analysis.collectNotes(data, currentLap, refLap)
    local notes = {}

    -- Helper to add note if not nil
    local function addNote(note)
        if note then table.insert(notes, note) end
    end


    -- Basic comparisons (data only)
    addNote(analyzeSteeringInput(data))
    addNote(analyzeGearUsage(data))
    addNote(analyzeCoasting(data))
    addNote(analyzeEntrySpeed(data))
    addNote(analyzeDownshiftReaction(data))
    addNote(analyzeLastDownshiftTiming(data))
    addNote(analyzeTurnIn(data))
    addNote(analyzeCombinedGrip(data, "early"))
    addNote(analyzeCombinedGrip(data, "mid"))

    -- Lap-based analysis (flags, pressure, timing)
    if currentLap then
        addNote(analyzeLockups(currentLap, data))
        addNote(analyzeTractionControl(currentLap, data))
        addNote(analyzeLimiter(currentLap, data))
        addNote(analyzeOfftrack(currentLap, data))
        addNote(analyzeBadBrakeZoneThrottle(currentLap, data))
    end

    -- Comparison analysis (needs both laps)
    if currentLap and refLap then
        addNote(analyzeThrottleTiming(currentLap, refLap, data))
        addNote(analyzeBrakePressure(currentLap, refLap, data))
        addNote(analyzeBrakeApplicationRate(currentLap, refLap, data))
        addNote(analyzeReferenceTrailBraking(currentLap, refLap, data))
    end

    return notes
end

--------------------------------------------------------------------------------
-- Corner Analysis: Analyze a single corner from a lap
--------------------------------------------------------------------------------

--- Analyze a single corner from a lap
---@param lapData table Lap instance
---@param cornerDef table Corner definition {number, startPos, endPos}
---@return table Corner analysis data
function corner_analysis.analyzeCorner(lapData, cornerDef)
    if not lapData or not cornerDef then return nil end

    -- Calculate apex dynamically for this specific lap (min speed point)
    local apexPos, apexSpeed = lapData:findApex(cornerDef.startPos, cornerDef.endPos)

    -- Entry speed: max speed before min speed point
    -- Exit speed: max speed after min speed point
    local entrySpeed = lapData:findEntrySpeed(cornerDef.startPos, cornerDef.endPos)
    local exitSpeed = lapData:findExitSpeed(cornerDef.startPos, cornerDef.endPos)

    -- Downshift timing (reaction time and total shift time)
    local downshiftFirstMs, downshiftLastMs, _, _, _, brakePos, firstDownshiftPos = lapData:findDownshiftDelay(
        cornerDef.startPos, cornerDef.endPos, settings.brakeThreshold())

    local downshiftDistanceM = nil
    if brakePos and firstDownshiftPos then
        downshiftDistanceM = math.abs(ui_utils.positionDeltaToMeters(firstDownshiftPos, brakePos) or 0)
    end

    local turnInPos, turnInIndex, turnInProfile = detectTurnIn(lapData, cornerDef.startPos, cornerDef.endPos, apexPos)
    local combinedGripEarly, combinedGripMid = combinedGripPhases(lapData, turnInIndex, apexPos)
    local peakLateralG, turnInLateralG = lateralGMetrics(lapData, cornerDef.startPos, cornerDef.endPos, turnInIndex)

    return {
        number = cornerDef.number,
        startPos = cornerDef.startPos,
        endPos = cornerDef.endPos,
        apexPos = apexPos,
        entrySpeed = entrySpeed,
        apexSpeed = apexSpeed,
        exitSpeed = exitSpeed,
        brakePos = lapData:findBrakePoint(cornerDef.startPos, cornerDef.endPos, settings.brakeThreshold()),
        liftOffPos = lapData:findLiftPoint(cornerDef.startPos, cornerDef.endPos, settings.throttleThreshold()),
        maxSteeringDeg = lapData:findMaxSteering(cornerDef.startPos, cornerDef.endPos),
        minGear = lapData:findMinGear(cornerDef.startPos, cornerDef.endPos),
        entryTime = lapData:getTimeAtPos(cornerDef.startPos),
        exitTime = lapData:getTimeAtPos(cornerDef.endPos),
        overlapTime = lapData:getOverlapTimeInRange(cornerDef.startPos, cornerDef.endPos),
        downshiftFirstMs = downshiftFirstMs,  -- Reaction time: brake to first downshift
        downshiftLastMs = downshiftLastMs,    -- Total shift time: brake to last downshift
        downshiftDistanceM = downshiftDistanceM,  -- Brake to first downshift distance
        turnInPos = turnInPos,
        turnInProfile = turnInProfile,
        combinedGripEarly = combinedGripEarly,
        combinedGripMid = combinedGripMid,
        peakLateralG = peakLateralG,
        turnInLateralG = turnInLateralG,
    }
end

--- Analyze all corners in a lap
---@param lapData table Lap instance
---@param corners table Array of corner definitions
---@return table Corner analysis indexed by corner number
function corner_analysis.analyzeLap(lapData, corners)
    if not lapData then return {} end
    if not corners then return {} end
    
    local analysis = {}
    for _, corner in ipairs(corners) do
        if corner.startPos and corner.endPos then
            analysis[corner.number] = corner_analysis.analyzeCorner(lapData, corner)
        end
    end
    return analysis
end

--- Compare two corner analyses (current vs reference)
---@param current table Current corner analysis
---@param reference table Reference corner analysis
---@return table Comparison with deltas
function corner_analysis.compareCorners(current, reference)
    if not current or not reference then return nil end

    local timeDelta = nil
    if current.entryTime and current.exitTime and reference.entryTime and reference.exitTime then
        local currentDuration = current.exitTime - current.entryTime
        local refDuration = reference.exitTime - reference.entryTime
        timeDelta = currentDuration - refDuration
    end

    -- Compare the 10%, 25% and 50% steering-build positions. Their median is
    -- resistant to one noisy threshold; their spread becomes confidence.
    local turnInDeltaM, turnInConfidence = nil, nil
    local currentTurnInMarker, referenceTurnInMarker = current.turnInPos, reference.turnInPos
    local currentProfile = current.turnInProfile and current.turnInProfile.positions
    local referenceProfile = reference.turnInProfile and reference.turnInProfile.positions
    if currentProfile and referenceProfile then
        local matches = {}
        for i = 1, 3 do
            if currentProfile[i] and referenceProfile[i] then
                matches[#matches + 1] = {
                    delta = scoring.positionDeltaToMeters(currentProfile[i], referenceProfile[i]),
                    currentPos = currentProfile[i],
                    referencePos = referenceProfile[i],
                }
            end
        end
        table.sort(matches, function(a, b) return a.delta < b.delta end)
        if #matches > 0 then
            local representative = matches[math.floor((#matches + 1) / 2)]
            turnInDeltaM = representative.delta
            currentTurnInMarker = representative.currentPos
            referenceTurnInMarker = representative.referencePos
            local spread = matches[#matches].delta - matches[1].delta
            turnInConfidence = (#matches >= 3 and spread <= 5) and "high"
                or (#matches >= 2 and spread <= 10) and "medium" or "low"
        end
    end
    if not turnInDeltaM and current.turnInPos and reference.turnInPos then
        turnInDeltaM = scoring.positionDeltaToMeters(current.turnInPos, reference.turnInPos)
        turnInConfidence = "low"
    end

    return {
        number = current.number,
        -- Reference data
        refEntrySpeed = reference.entrySpeed or 0,
        refApexSpeed = reference.apexSpeed or 0,
        refExitSpeed = reference.exitSpeed or 0,
        refApexPos = reference.apexPos,
        refStartPos = reference.startPos,
        refEndPos = reference.endPos,
        refBrakePos = reference.brakePos,
        refLiftOffPos = reference.liftOffPos,
        refMaxSteeringDeg = reference.maxSteeringDeg or 0,
        -- Current data
        currentEntrySpeed = current.entrySpeed,
        currentApexSpeed = current.apexSpeed,
        currentExitSpeed = current.exitSpeed,
        currentApexPos = current.apexPos,
        currentBrakePos = current.brakePos,
        currentLiftOffPos = current.liftOffPos,
        currentMaxSteeringDeg = current.maxSteeringDeg or 0,
        currentMinGear = current.minGear,
        currentOverlapTime = current.overlapTime or 0,
        -- Downshift timing (current)
        currentDownshiftFirstMs = current.downshiftFirstMs,
        currentDownshiftLastMs = current.downshiftLastMs,
        currentDownshiftDistanceM = current.downshiftDistanceM,
        -- Reference gear and downshift timing
        refMinGear = reference.minGear,
        refDownshiftFirstMs = reference.downshiftFirstMs,
        refDownshiftLastMs = reference.downshiftLastMs,
        refTurnInPos = referenceTurnInMarker,
        refCombinedGripEarly = reference.combinedGripEarly,
        refCombinedGripMid = reference.combinedGripMid,
        refPeakLateralG = reference.peakLateralG,
        refTurnInLateralG = reference.turnInLateralG,
        currentTurnInPos = currentTurnInMarker,
        currentCombinedGripEarly = current.combinedGripEarly,
        currentCombinedGripMid = current.combinedGripMid,
        currentPeakLateralG = current.peakLateralG,
        currentTurnInLateralG = current.turnInLateralG,
        turnInConfidence = turnInConfidence,
        -- Deltas
        timeDelta = timeDelta,
        entrySpeedDelta = current.entrySpeed and reference.entrySpeed and
                          (current.entrySpeed - reference.entrySpeed) or nil,
        apexSpeedDelta = current.apexSpeed and reference.apexSpeed and
                         (current.apexSpeed - reference.apexSpeed) or nil,
        exitSpeedDelta = current.exitSpeed and reference.exitSpeed and
                         (current.exitSpeed - reference.exitSpeed) or nil,
        steeringDelta = (current.maxSteeringDeg or 0) - (reference.maxSteeringDeg or 0),
        gearDelta = (current.minGear and reference.minGear) and (current.minGear - reference.minGear) or nil,
        refOverlapTime = reference.overlapTime or 0,
        turnInDeltaM = turnInDeltaM,
        combinedGripEarlyDelta = (current.combinedGripEarly and reference.combinedGripEarly) and
            (current.combinedGripEarly - reference.combinedGripEarly) or nil,
        combinedGripMidDelta = (current.combinedGripMid and reference.combinedGripMid) and
            (current.combinedGripMid - reference.combinedGripMid) or nil,
        peakLateralGDelta = (current.peakLateralG and reference.peakLateralG) and
            (current.peakLateralG - reference.peakLateralG) or nil,
    }
end

--- Compare two laps for a specific corner and build display data
---@param cornerDef table Corner definition
---@param currentLap table Current lap data
---@param referenceLap table Reference lap data
---@param opts table|nil Options: { currentSpeeds, refSpeeds, numSpeedSamples, numPedalSamples, timeDeltaOverride, apply }
---@return table|nil displayData
---@return number|nil score
function corner_analysis.compare(cornerDef, currentLap, referenceLap, opts)
    if not cornerDef or not currentLap or not referenceLap then return nil end
    if not cornerDef.startPos or not cornerDef.endPos then return nil end

    local currentAnalysis = corner_analysis.analyzeCorner(currentLap, cornerDef)
    local refAnalysis = corner_analysis.analyzeCorner(referenceLap, cornerDef)
    if not currentAnalysis or not refAnalysis then return nil end

    local data = corner_analysis.compareCorners(currentAnalysis, refAnalysis)
    if not data then return nil end
    -- Marker rendering needs the exact corner range to map spline positions
    -- into the graph. Keep it on every comparison path, including telemetry.
    data.cornerInfo = cornerDef

    local numSpeedSamples = opts and opts.numSpeedSamples or 50
    local numPedalSamples = opts and opts.numPedalSamples or 100

    local currentSpeeds = opts and opts.currentSpeeds or sampleSpeedTrace(currentLap, cornerDef.startPos, cornerDef.endPos, numSpeedSamples)
    local refSpeeds = opts and opts.refSpeeds or captureRefSpeeds(referenceLap, currentSpeeds)

    -- Calculate maxBar from both laps for consistent brake scaling
    local currentMaxBar = currentLap and currentLap:maxBrakeBars() or 100
    local refMaxBar = referenceLap and referenceLap:maxBrakeBars() or 100
    local maxBar = math.max(currentMaxBar, refMaxBar, 80) * 1.1  -- 10% headroom, minimum 80

    data.currentSpeeds = currentSpeeds
    data.refSpeeds = refSpeeds
    data.currentPedals = samplePedalTraces(currentLap, cornerDef.startPos, cornerDef.endPos, numPedalSamples, maxBar)
    data.refPedals = samplePedalTraces(referenceLap, cornerDef.startPos, cornerDef.endPos, numPedalSamples, maxBar)

    if opts and opts.timeDeltaOverride ~= nil then
        data.timeDelta = opts.timeDeltaOverride
    end

    local score = scoring.calculate(data)
    if not opts or opts.apply ~= false then
        displayData = data
        displayScore = score
    end

    return data, score
end

--- Set a specific corner for display (called from lap_telemetry when clicking a corner)
---@param cornerDef table Corner definition to display
---@param currentLap table Current lap data
---@param referenceLap table Reference lap data
function corner_analysis.setViewedCorner(cornerDef, currentLap, referenceLap)
    if not cornerDef or not currentLap or not referenceLap then return end

    local data = corner_analysis.compare(cornerDef, currentLap, referenceLap)
    if not data then return end

    -- Set frozen state (store lap refs for notes/flag analysis only)
    frozenCorner.active = true
    frozenCorner.cornerNum = cornerDef.number or 0
    frozenCorner.lapNumber = currentLap.lapNumberInSession or 0
    frozenCorner.currentLap = currentLap
    frozenCorner.referenceLap = referenceLap

    ac.log(string.format("AC Tracer: Viewing corner %d analysis from telemetry (lap %d)",
        frozenCorner.cornerNum, frozenCorner.lapNumber))
end

--- Clear frozen corner state (return to live tracking)
function corner_analysis.clearFrozenCorner()
    frozenCorner.active = false
    frozenCorner.cornerNum = 0
    frozenCorner.lapNumber = 0
    frozenCorner.currentLap = nil
    frozenCorner.referenceLap = nil
end

--- Check if viewing a frozen corner
function corner_analysis.isFrozen()
    return frozenCorner.active
end

--- Get the frozen corner number (0 if not frozen)
function corner_analysis.getFrozenCornerNum()
    return frozenCorner.active and frozenCorner.cornerNum or 0
end

--------------------------------------------------------------------------------
-- Live Corner Tracking: Called on corner exit
--------------------------------------------------------------------------------

--- Helper to capture reference speeds at specific positions
captureRefSpeeds = function(referenceLap, positions)
    local refSpeeds = {}
    for _, s in ipairs(positions) do
        local refSpd = referenceLap and referenceLap:speedAt(s.pos) or nil
        table.insert(refSpeeds, { pos = s.pos, speed = refSpd or s.speed })
    end
    return refSpeeds
end

local function onCornerExit(currentLap, referenceLap, car)
    if liveCorner.cornerNum == 0 then return end

    local cornerInfo = liveCorner.cornerInfo
    if not cornerInfo then return end
    if not currentLap then return end
    if not referenceLap then
        displayData = nil
        displayScore = 0
        displayLap = currentLap
        return
    end

    -- Calculate corner time delta
    local timeDelta = nil
    if liveCorner.entryTime and liveCorner.exitTime then
        local currentDuration = liveCorner.exitTime - liveCorner.entryTime
        if liveCorner.ghostEntryTime and liveCorner.ghostExitTime then
            local ghostDuration = liveCorner.ghostExitTime - liveCorner.ghostEntryTime
            timeDelta = currentDuration - ghostDuration
        end
    end

    local currentSpeeds = (#liveCorner.speeds >= 2) and liveCorner.speeds or nil
    local refSpeeds = currentSpeeds and captureRefSpeeds(referenceLap, currentSpeeds) or nil

    local completedData, score = corner_analysis.compare(cornerInfo, currentLap, referenceLap, {
        currentSpeeds = currentSpeeds,
        refSpeeds = refSpeeds,
        timeDeltaOverride = timeDelta,
    })

    -- Store snapshot of current lap for flag analysis (notes section)
    -- Note: This is still a reference, but flags don't change after capture
    displayLap = currentLap
    if completedData and score then
        lastCompletedResult = {
            cornerNum = cornerInfo.number,
            score = score,
            timeDelta = completedData.timeDelta,
        }
    end
    
    -- Store corner score with lap number for delta bar display
    if score and cornerInfo.number then
        local lapNumber = car and car.lapCount or (currentLap and currentLap.lapNumberInSession) or 0
        table.insert(recentCornerScores, 1, {
            cornerNum = cornerInfo.number,
            score = score,
            lapNumber = lapNumber
        })
        
        -- Keep only recent scores (oldest first, so we remove from end)
        while #recentCornerScores > MAX_RECENT_SCORES do
            table.remove(recentCornerScores)
        end
    end
end

--------------------------------------------------------------------------------
-- Live Corner Tracking: Update (call every frame)
--------------------------------------------------------------------------------

--- Update live corner tracking
---@param car table Car state from ac.getCar()
---@param currentLap table Current lap data
---@param referenceLap table Reference lap data
---@param corners table Array of corner definitions
---@param dt number|nil Frame delta time
function corner_analysis.update(car, currentLap, referenceLap, corners, dt)
    if not car then return end
    
    -- Clear frozen corner state when car starts moving (above 30 km/h)
    if frozenCorner.active and car.speedKmh >= 30 then
        corner_analysis.clearFrozenCorner()
    end
    
    -- Reset on new lap
    if car.lapCount ~= lastLapCount then
        lastLapCount = car.lapCount
        resetLiveCorner()
        clearSequence(0)
        -- Clear displayed corner data from previous lap
        displayData = nil
        displayScore = 0
        displayLap = nil
        lastCompletedResult = nil
        -- Clear corner scores from previous laps (keep only current lap scores)
        -- Remove scores that are from laps before the current one
        for i = #recentCornerScores, 1, -1 do
            if recentCornerScores[i].lapNumber < car.lapCount then
                table.remove(recentCornerScores, i)
            end
        end
    end
    
    currentLapTime = car.lapTimeMs / 1000
    
    local currentPos = car.splinePosition
    local currentSpeed = car.speedKmh
    local isBraking = extended_brake.getBrakePressureBar(car) >= getBrakeThreshold()
    local isFullThrottle = car.gas >= getThrottleOnThreshold()
    
    local normalizedSteering = lap.normalizeSteer(car.steer)
    local isCentered = isSteeringCentered(normalizedSteering)
    
    local wasInCorner = liveCorner.cornerNum > 0 and not liveCorner.leftCorner
    
    -- Check what corner we're in
    local cornerNum, cornerInfo = getCornerAtPos(corners, currentPos)

    -- A teleport can place the car halfway through a corner. Never score that
    -- fragment: keep the corner empty for this lap and resume once the car has
    -- fully left it. resetCounter covers resets; justJumped covers car-state loads.
    local resetCounter = car.resetCounter or 0
    local jumped = car.justJumped or (lastResetCounter >= 0 and resetCounter > lastResetCounter)
    lastResetCounter = resetCounter
    if jumped then
        resetLiveCorner()
        clearSequence(0)
        ignoredCornerAfterJump = cornerNum
    end
    if ignoredCornerAfterJump > 0 then
        if cornerNum == ignoredCornerAfterJump then
            return
        end
        ignoredCornerAfterJump = 0
    end
    
    if cornerNum > 0 and cornerInfo then
        if liveCorner.cornerNum ~= cornerNum then
            -- Entering new corner
            clearSequence(cornerNum)
            liveCorner.cornerNum = cornerNum
            liveCorner.cornerInfo = cornerInfo
            liveCorner.entrySpeed = currentSpeed
            liveCorner.entryPos = currentPos
            liveCorner.entryTime = currentLapTime
            liveCorner.ghostEntryTime = referenceLap and referenceLap:getTimeAtPos(currentPos) or nil
            liveCorner.ghostExitTime = nil
            liveCorner.apexSpeed = currentSpeed
            liveCorner.apexPos = currentPos
            liveCorner.exitSpeed = nil
            liveCorner.exitPos = nil
            liveCorner.exitTime = nil
            liveCorner.passedApex = false
            liveCorner.leftCorner = false
            liveCorner.wasBraking = false
            liveCorner.brakePos = nil
            liveCorner.liftOffPos = nil
            liveCorner.wasOnThrottle = false
            liveCorner.speeds = {}
            liveCorner.maxSteeringDeg = 0
            sequenceState.entrySteerDeg = car.steer or 0

            if referenceLap then
                local refAnalysis = corner_analysis.analyzeCorner(referenceLap, cornerInfo)
                if refAnalysis then
                    sequenceState.refLiftPos = refAnalysis.liftOffPos
                    sequenceState.refBrakePos = refAnalysis.brakePos
                    sequenceState.refApexPos = refAnalysis.apexPos

                    -- Lift is a distinct reference event only when it creates a
                    -- meaningful coast phase at least 10 m before braking.
                    if refAnalysis.liftOffPos and refAnalysis.brakePos then
                        local posDelta = refAnalysis.brakePos - refAnalysis.liftOffPos
                        if posDelta < 0 then posDelta = posDelta + 1 end
                        local coastMeters = posDelta * (ac.getSim().trackLengthM or 5000)
                        sequenceState.events[1].relevant = coastMeters >= 10
                    end
                    sequenceState.events[2].relevant = refAnalysis.brakePos ~= nil
                    sequenceState.events[4].relevant = refAnalysis.apexPos ~= nil
                    if refAnalysis.turnInProfile then
                        sequenceState.refTurnDirection = refAnalysis.turnInProfile.direction
                        sequenceState.refTurnThresholdDeg = math.max(4,
                            (refAnalysis.turnInProfile.peakSteeringDeg or 0) * 0.25)
                        sequenceState.refTurnPos = refAnalysis.turnInProfile.positions
                            and refAnalysis.turnInProfile.positions[2] or refAnalysis.turnInPos
                    else
                        sequenceState.refTurnPos = refAnalysis.turnInPos
                    end
                    sequenceState.events[3].relevant = sequenceState.refTurnPos ~= nil
                        and sequenceState.refTurnDirection ~= nil
                        and sequenceState.refTurnThresholdDeg ~= nil
                end
            end
        else
            -- In corner - track data
            table.insert(liveCorner.speeds, { pos = currentPos, speed = currentSpeed })

            -- Track max steering (absolute degrees)
            local steerDeg = math.abs(car.steer)
            if steerDeg > liveCorner.maxSteeringDeg then
                liveCorner.maxSteeringDeg = steerDeg
            end

            -- Track gear shifts (to filter out throttle lift during shifts)
            local currentGear = car.gear
            if liveCorner.lastGear and currentGear ~= liveCorner.lastGear then
                liveCorner.gearShiftTime = currentLapTime
            end
            liveCorner.lastGear = currentGear

            -- Check if we're near a recent gear shift
            local nearGearShift = (currentLapTime - liveCorner.gearShiftTime) < GEAR_SHIFT_IGNORE_TIME

            -- Track lift-off (ignore throttle dips during gear shifts)
            if isFullThrottle then
                liveCorner.wasOnThrottle = true
            elseif liveCorner.wasOnThrottle and not liveCorner.liftOffPos and not nearGearShift
                and not liveCorner.brakePos then
                liveCorner.liftOffPos = currentPos
                revealSequenceEvent(1, currentPos, sequenceState.refLiftPos)
            end

            -- Track brake point (first touch > 0.1 bar)
            -- For live tracking, we capture initial pedal application immediately
            local currentBrakeBar = extended_brake.getBrakePressureBar(car)
            if currentBrakeBar > lap.BRAKE_INITIATION_BAR and not liveCorner.brakePos then
                liveCorner.brakePos = currentPos
                revealSequenceEvent(2, currentPos, sequenceState.refBrakePos)
            end

            -- Confirm a sustained steering commitment in the reference corner's
            -- direction. This corresponds to the 25% steering-build point used
            -- for the completed turn-in comparison.
            if not sequenceState.events[3].visible and sequenceState.refTurnDirection
                and sequenceState.refTurnThresholdDeg then
                local directedSteer = ((car.steer or 0) - sequenceState.entrySteerDeg)
                    * sequenceState.refTurnDirection
                if directedSteer >= sequenceState.refTurnThresholdDeg then
                    if not sequenceState.turnCandidatePos then
                        sequenceState.turnCandidatePos = currentPos
                    end
                    sequenceState.turnCandidateTime = sequenceState.turnCandidateTime + (dt or 1 / 60)
                    if sequenceState.turnCandidateTime >= 0.08 then
                        revealSequenceEvent(3, sequenceState.turnCandidatePos, sequenceState.refTurnPos)
                    end
                else
                    sequenceState.turnCandidatePos = nil
                    sequenceState.turnCandidateTime = 0
                end
            end
            
            -- Apex speed: minimum in corner (track continuously)
            if currentSpeed < liveCorner.apexSpeed then
                liveCorner.apexSpeed = currentSpeed
                liveCorner.apexPos = currentPos
                -- Reset passedApex since we found a new min speed point
                liveCorner.passedApex = false
                sequenceState.apexRiseTime = 0
            else
                -- Speed is increasing, we've passed the min speed point
                liveCorner.passedApex = true
                local meaningfulSpeedDrop = liveCorner.entrySpeed and liveCorner.apexSpeed
                    and (liveCorner.entrySpeed - liveCorner.apexSpeed) >= 2
                if meaningfulSpeedDrop and not sequenceState.events[4].visible then
                    sequenceState.apexRiseTime = sequenceState.apexRiseTime + (dt or 1 / 60)
                    if sequenceState.apexRiseTime >= 0.10 then
                        revealSequenceEvent(4, liveCorner.apexPos, sequenceState.refApexPos)
                    end
                end
            end

            -- Entry speed: max speed before min speed point
            if not liveCorner.passedApex then
                if currentSpeed > liveCorner.entrySpeed then
                    liveCorner.entrySpeed = currentSpeed
                    liveCorner.entryPos = currentPos
                end
            end

            -- Exit speed: max speed after min speed point
            if liveCorner.passedApex then
                if liveCorner.exitSpeed == nil or currentSpeed > liveCorner.exitSpeed then
                    liveCorner.exitSpeed = currentSpeed
                    liveCorner.exitPos = currentPos
                end
            end
        end
    else
        -- Not in corner
        if liveCorner.cornerNum > 0 and not liveCorner.leftCorner then
            liveCorner.leftCorner = true
            liveCorner.exitTime = currentLapTime
            liveCorner.ghostExitTime = referenceLap and referenceLap:getTimeAtPos(currentPos) or nil
        end
    end
    
    -- Detect corner exit
    if wasInCorner and liveCorner.leftCorner then
        -- Flat-out corners might not produce a large enough speed trough for
        -- live confirmation; exiting the defined corner confirms their apex.
        revealSequenceEvent(4, liveCorner.apexPos, sequenceState.refApexPos)
        onCornerExit(currentLap, referenceLap, car)
    end
end

--------------------------------------------------------------------------------
-- Accessors
--------------------------------------------------------------------------------

--- Get current corner data (while in corner)
---@param referenceLap table Reference lap data
---@param corners table Array of corner definitions
function corner_analysis.getCurrentCornerData(referenceLap, corners)
    if liveCorner.cornerNum == 0 then return nil end
    
    local cornerInfo = getCornerInfo(corners, liveCorner.cornerNum)
    if not cornerInfo then return nil end
    
    local cornerTimeDelta = nil
    if liveCorner.leftCorner and liveCorner.entryTime and liveCorner.exitTime then
        local currentDuration = liveCorner.exitTime - liveCorner.entryTime
        if liveCorner.ghostEntryTime and liveCorner.ghostExitTime then
            local ghostDuration = liveCorner.ghostExitTime - liveCorner.ghostEntryTime
            cornerTimeDelta = currentDuration - ghostDuration
        end
    end
    
    local ghostEntrySpeed = referenceLap and referenceLap:speedAt(cornerInfo.startPos) or 0
    local ghostApexPos, ghostApexSpeed
    if referenceLap then
        ghostApexPos, ghostApexSpeed = referenceLap:findApex(cornerInfo.startPos, cornerInfo.endPos)
    else
        ghostApexPos, ghostApexSpeed = nil, 0
    end
    local ghostExitSpeed = referenceLap and referenceLap:speedAt(cornerInfo.endPos) or 0

    return {
        number = liveCorner.cornerNum,
        ghostEntrySpeed = ghostEntrySpeed,
        ghostApexSpeed = ghostApexSpeed,
        ghostExitSpeed = ghostExitSpeed,
        ghostApexPos = ghostApexPos,
        currentEntrySpeed = liveCorner.entrySpeed,
        currentApexSpeed = liveCorner.apexSpeed,
        currentExitSpeed = liveCorner.exitSpeed,
        entryPos = liveCorner.entryPos,
        apexPos = liveCorner.apexPos,
        exitPos = liveCorner.exitPos,
        entryDelta = liveCorner.entrySpeed and ghostEntrySpeed > 0 and 
                     (liveCorner.entrySpeed - ghostEntrySpeed) or nil,
        apexDelta = liveCorner.apexSpeed and ghostApexSpeed > 0 and 
                    (liveCorner.apexSpeed - ghostApexSpeed) or nil,
        exitDelta = liveCorner.exitSpeed and ghostExitSpeed > 0 and 
                    (liveCorner.exitSpeed - ghostExitSpeed) or nil,
        cornerTimeDelta = cornerTimeDelta,
        passedApex = liveCorner.passedApex,
        leftCorner = liveCorner.leftCorner,
        startPos = cornerInfo.startPos,
        endPos = cornerInfo.endPos
    }
end

function corner_analysis.getCurrentCornerNum()
    return liveCorner.cornerNum
end

function corner_analysis.getLastCompletedCorner()
    return displayData
end

--- Export the latest actually driven corner result for compact/remote displays.
---@return table|nil result {cornerNum, score, timeDelta}
function corner_analysis.getLastCompletedResult()
    return lastCompletedResult
end

function corner_analysis.justExitedCorner()
    return liveCorner.leftCorner
end

--------------------------------------------------------------------------------
-- UI Drawing
--------------------------------------------------------------------------------

--- Calculate speed range for corner graph (shared by drawing functions)
---@param currentSpeeds table Array of {pos, speed} samples
---@param refSpeeds table|nil Array of {pos, speed} reference samples
---@return number minSpeed Minimum speed for Y axis
---@return number maxSpeed Maximum speed for Y axis
---@return number speedRange Range for normalization
local function calculateSpeedRange(currentSpeeds, refSpeeds)
    local minSpeed, maxSpeed = math.huge, 0
    for i, s in ipairs(currentSpeeds) do
        minSpeed = math.min(minSpeed, s.speed)
        maxSpeed = math.max(maxSpeed, s.speed)
        if refSpeeds and refSpeeds[i] then
            minSpeed = math.min(minSpeed, refSpeeds[i].speed)
            maxSpeed = math.max(maxSpeed, refSpeeds[i].speed)
        end
    end
    local speedRange = maxSpeed - minSpeed
    minSpeed = minSpeed - speedRange * 0.15
    maxSpeed = maxSpeed + speedRange * 0.1
    speedRange = maxSpeed - minSpeed
    return minSpeed, maxSpeed, speedRange
end

--- Find apex (minimum speed) from sampled speed data
--- Returns the position and index of the minimum speed sample
---@param speeds table Array of {pos, speed} samples
---@return number|nil apexPos Position of minimum speed
---@return number|nil apexIdx Index of minimum speed sample
---@return number|nil apexSpeed Speed at apex
local function findSampledApex(speeds)
    if not speeds or #speeds < 2 then return nil, nil, nil end
    local minSpeed = math.huge
    local apexPos = nil
    local apexIdx = nil
    for i, s in ipairs(speeds) do
        if s.speed < minSpeed then
            minSpeed = s.speed
            apexPos = s.pos
            apexIdx = i
        end
    end
    return apexPos, apexIdx, minSpeed
end

local function drawFilledComparison(x, y, w, h, currentSpeeds, refSpeeds)
    if not currentSpeeds or #currentSpeeds < 2 then return end
    if not refSpeeds or #refSpeeds < 2 then return end

    local SPEED_TOLERANCE = 1

    local minSpeed, maxSpeed, speedRange = calculateSpeedRange(currentSpeeds, refSpeeds)
    if speedRange <= 0 then return end

    local numPoints = #currentSpeeds
    local bottomY = y + h

    -- Use position-based X coordinates from sampled data
    local startPos = currentSpeeds[1].pos
    local endPos = currentSpeeds[numPoints].pos
    local posRange = endPos - startPos
    if posRange <= 0 then posRange = posRange + 1 end  -- Handle wrap-around

    -- Pre-compute constants for position->X conversion (avoid per-iteration division)
    local posScale = w / posRange
    local hOverRange = h / speedRange

    -- Inline posToX calculation for performance
    -- posToX(pos) = x + ((pos - startPos + wrap) / posRange) * w
    -- where wrap = 1 if (pos - startPos) < 0, else 0

    -- Cache theme fill colors to avoid repeated table lookups
    local colorOnSpeed = theme.corner.onSpeedFill
    local colorFaster = theme.corner.fasterFill
    local colorSlower = theme.corner.slowerFill

    -- Pre-compute pixel-snapped X and Y for each point (computed once, used for both edges)
    local pointX = {}
    local pointY = {}
    for i = 1, numPoints do
        local s = currentSpeeds[i]
        local relPos = s.pos - startPos
        if relPos < 0 then relPos = relPos + 1 end
        pointX[i] = math.floor(x + relPos * posScale + 0.5)
        pointY[i] = bottomY - (s.speed - minSpeed) * hOverRange
    end

    -- Draw filled comparison using quads with shared snapped X coordinates
    -- Each quad's left X = pointX[i], right X = pointX[i+1] — no overlap, no gaps
    for i = 1, numPoints - 1 do
        local ref1 = refSpeeds[i] and refSpeeds[i].speed or currentSpeeds[i].speed
        local ref2 = refSpeeds[i + 1] and refSpeeds[i + 1].speed or currentSpeeds[i + 1].speed

        local speedDiff = (currentSpeeds[i].speed + currentSpeeds[i + 1].speed) * 0.5 - (ref1 + ref2) * 0.5
        local color
        if speedDiff > SPEED_TOLERANCE then
            color = colorFaster
        elseif speedDiff < -SPEED_TOLERANCE then
            color = colorSlower
        else
            color = colorOnSpeed
        end

        _v1:set(pointX[i], pointY[i])
        _v2:set(pointX[i + 1], pointY[i + 1])
        _v3:set(pointX[i + 1], bottomY)
        _v4:set(pointX[i], bottomY)
        ui.drawQuadFilled(_v1, _v2, _v3, _v4, color)
    end

    -- Draw reference speed line using position-based coordinates
    ui.pathClear()
    for i, s in ipairs(refSpeeds) do
        local relPos = s.pos - startPos
        if relPos < 0 then relPos = relPos + 1 end
        local px = x + relPos * posScale
        local py = bottomY - (s.speed - minSpeed) * hOverRange
        _vp:set(px, py)
        ui.pathLineTo(_vp)
    end
    ui.pathStroke(theme.text.primary, false, 2)
end


--- Draw direction indicator between solid (current) and dashed (ref) marker lines
--- Shows which way the marker should move to match reference
--- Draws a small arrow at the very top (on the border) pointing toward reference
---@param x1 number X position of current (solid) line
---@param x2 number X position of reference (dashed) line
---@param y number Y position (top of graph area / border line)
---@param color rgbm Arrow color
local function drawDirectionArrows(x1, x2, y, color)
    if not x1 or not x2 then return end

    local gap = x2 - x1  -- Positive = ref is to the right
    local dist = math.abs(gap)
    if dist < 12 then return end  -- Too close to show indicator

    local direction = gap > 0 and 1 or -1  -- 1 = right, -1 = left
    local midX = (x1 + x2) / 2

    -- Small arrow at very top, on the border line
    local arrowLen = math.min(4, dist / 5)
    local arrowHalfH = 2
    local arrowTipX = midX + direction * arrowLen
    local arrowBaseX = midX - direction * arrowLen

    -- Draw small filled triangle arrow on the border
    ui.pathClear()
    ui.pathLineTo(vec2(arrowBaseX, y - arrowHalfH))
    ui.pathLineTo(vec2(arrowTipX, y))
    ui.pathLineTo(vec2(arrowBaseX, y + arrowHalfH))
    ui.pathFillConvex(theme.withAlpha(color, 0.8))
end

local function drawMarkerLines(x, y, w, h, currentSpeeds, refSpeeds, data)
    if not currentSpeeds or #currentSpeeds < 2 then return end
    
    local numPoints = #currentSpeeds
    local startPos = currentSpeeds[1].pos
    local endPos = currentSpeeds[numPoints].pos
    local posRange = endPos - startPos
    if posRange <= 0 then posRange = posRange + 1 end  -- Handle wrap-around

    -- Use shared speed range calculation for consistency with filled graph
    local minSpeed, maxSpeed, speedRange = calculateSpeedRange(currentSpeeds, refSpeeds)
    if speedRange <= 0 then speedRange = 1 end

    -- Helper to convert position to X coordinate (same logic as drawFilledComparison)
    local function posToX(pos)
        if not pos then return nil end
        local relPos = pos - startPos
        if relPos < 0 then relPos = relPos + 1 end  -- Handle wrap-around
        local px = x + (relPos / posRange) * w
        if px >= x and px <= x + w then return px end
        return nil
    end

    local function speedToY(speed)
        return y + h - ((speed - minSpeed) / speedRange) * h
    end

    -- Apex/slowest-point marker lines intentionally hidden for now.

end

-- drawScoreGauge removed - now using wedge.drawGauge

--- Draw brake/throttle traces for a corner using captured pedal data
---@param data table|nil Optional comparison data with brake positions
local function drawPedalTraces(x, y, w, h, currentPedals, refPedals, data)
    -- Background
    ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), theme.bg.graph, 4)

    -- Draw horizontal grid lines at 25%, 50%, 75%
    for frac = 0.25, 0.75, 0.25 do
        local lineY = y + h * (1 - frac)
        ui.drawLine(vec2(x, lineY), vec2(x + w, lineY), rgbm(0.3, 0.3, 0.3, 0.3), 1)
    end

    -- Draw reference traces first (behind current) with filled areas
    if refPedals and #refPedals.throttle > 0 then
        -- Reference throttle then brake (throttle first so brake renders on top)
        ui_utils.drawTrace(x, y, w, h, refPedals.throttle, theme.ghost.throttle, { thickness = 2, filled = true })
        ui_utils.drawTrace(x, y, w, h, refPedals.brake, theme.ghost.brake, { thickness = 2, filled = true })
    end

    -- Draw current traces on top (throttle first so brake renders on top)
    if currentPedals and #currentPedals.throttle > 0 then
        ui_utils.drawTrace(x, y, w, h, currentPedals.throttle, theme.trace.throttle, { thickness = 2 })
        ui_utils.drawTrace(x, y, w, h, currentPedals.brake, theme.trace.brake, { thickness = 2 })
    end

    -- TEMPORARY: Brake point markers for verification
    if data and data.cornerInfo then
        local startPos = data.cornerInfo.startPos
        local endPos = data.cornerInfo.endPos
        local posRange = endPos - startPos
        if posRange <= 0 then posRange = posRange + 1 end

        local function posToX(pos)
            if not pos then return nil end
            local relPos = pos - startPos
            if relPos < 0 then relPos = relPos + 1 end
            local px = x + (relPos / posRange) * w
            if px >= x and px <= x + w then return px end
            return nil
        end

        -- Reference brake point (dashed white line)
        if data.refBrakePos then
            local refBrakeX = posToX(data.refBrakePos)
            if refBrakeX then
                ui_utils.drawDashedLine(vec2(refBrakeX, y), vec2(refBrakeX, y + h), rgbm(1, 1, 1, 0.7), 2, 5, 3)
            end
        end

        -- Current brake point (solid bright line)
        if data.currentBrakePos then
            local curBrakeX = posToX(data.currentBrakePos)
            if curBrakeX then
                ui.drawLine(vec2(curBrakeX, y), vec2(curBrakeX, y + h), rgbm(1, 1, 1, 1), 3)
            end
        end


        -- Turn-in markers: reference dashed cyan, current solid cyan.
        if data.refTurnInPos then
            local refTurnX = posToX(data.refTurnInPos)
            if refTurnX then
                ui_utils.drawDashedLine(vec2(refTurnX, y), vec2(refTurnX, y + h), rgbm(0.2, 0.8, 1, 0.75), 2, 4, 3)
            end
        end
        if data.currentTurnInPos then
            local curTurnX = posToX(data.currentTurnInPos)
            if curTurnX then
                ui.drawLine(vec2(curTurnX, y), vec2(curTurnX, y + h), rgbm(0.2, 0.8, 1, 1), 2)
            end
        end
    end

    -- Outline
    ui.drawRect(vec2(x, y), vec2(x + w, y + h), rgbm(0.4, 0.4, 0.4, 0.5), 4, 1)
end

--- Draw a top-down car diagram showing which tires locked up
---@param cx number Center X of the diagram
---@param cy number Center Y of the diagram
---@param wheels table {fl, fr, rl, rr} booleans
local function drawLockupDiagram(cx, cy, wheels)
    -- Car body dimensions
    local bodyW = 30
    local bodyH = 52
    local tireW = 8
    local tireH = 14
    local axleGap = 2  -- gap between tire and body edge

    local bx = cx - bodyW / 2
    local by = cy - bodyH / 2

    -- Colors
    local bodyColor = rgbm(0.35, 0.35, 0.4, 0.6)
    local bodyOutline = rgbm(0.5, 0.5, 0.55, 0.7)
    local axleColor = rgbm(0.45, 0.45, 0.5, 0.5)
    local tireDefault = rgbm(0.4, 0.4, 0.45, 0.7)
    local tireLockup = rgbm(1, 0.2, 0.2, 0.95)

    -- Axle lines (front and rear, connecting tires through body)
    local frontAxleY = by + tireH / 2 + 2
    local rearAxleY = by + bodyH - tireH / 2 - 2
    ui.drawLine(vec2(bx - axleGap - tireW, frontAxleY), vec2(bx + bodyW + axleGap + tireW, frontAxleY), axleColor, 2)
    ui.drawLine(vec2(bx - axleGap - tireW, rearAxleY), vec2(bx + bodyW + axleGap + tireW, rearAxleY), axleColor, 2)

    -- Car body (rounded rect)
    ui.drawRectFilled(vec2(bx, by), vec2(bx + bodyW, by + bodyH), bodyColor, 4)
    ui.drawRect(vec2(bx, by), vec2(bx + bodyW, by + bodyH), bodyOutline, 4, 1)

    -- Tire positions: FL, FR, RL, RR
    local tires = {
        { x = bx - axleGap - tireW, y = frontAxleY - tireH / 2, locked = wheels.fl },
        { x = bx + bodyW + axleGap, y = frontAxleY - tireH / 2, locked = wheels.fr },
        { x = bx - axleGap - tireW, y = rearAxleY - tireH / 2,  locked = wheels.rl },
        { x = bx + bodyW + axleGap, y = rearAxleY - tireH / 2,  locked = wheels.rr },
    }

    for _, t in ipairs(tires) do
        local color = t.locked and tireLockup or tireDefault
        ui.drawRectFilled(vec2(t.x, t.y), vec2(t.x + tireW, t.y + tireH), color, 2)
        ui.drawRect(vec2(t.x, t.y), vec2(t.x + tireW, t.y + tireH), bodyOutline, 2, 1)
    end
end

--- Main window rendering
function corner_analysis.draw(dt, currentLap, referenceLap, corners)
    local windowSize = ui.availableSpace()
    local padding = 8
    local panelX = windowSize.x * 0.68
    local graphWidth = panelX - padding * 2
    local graphY = 22
    local meterLabelHeight = 16  -- Space for meter annotations at bottom
    local pedalTraceHeight = 100  -- Height for brake/throttle traces
    local pedalTracePadding = 5   -- Padding between speed graph and pedal traces
    local graphHeight = windowSize.y - padding - graphY - meterLabelHeight - pedalTraceHeight - pedalTracePadding
    
    -- Fixed layout constants
    local topSectionH = 46  -- Compact top section for score card
    local lineH = 18

    -- Right panel dimensions
    local panelW = windowSize.x - panelX - padding
    local panelTopY = graphY  -- Start at same Y as graph for clean look
    local panelH = windowSize.y - panelTopY - padding

    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, theme.bg.window, 4)

    if displayData then
        -- Graph area background (left side when we have data)
        ui.drawRectFilled(
            vec2(padding, graphY),
            vec2(padding + graphWidth, graphY + graphHeight),
            theme.bg.graph,
            4
        )

        -- Right panel background and border (draw first so content appears on top)
        ui.drawRectFilled(vec2(panelX, panelTopY), vec2(panelX + panelW, panelTopY + panelH), theme.bg.panel, 4)
        ui.drawRect(vec2(panelX, panelTopY), vec2(panelX + panelW, panelTopY + panelH), theme.grid.major, 4, 1)

        -- Unified score card (score + delta together) - compact design
        local cardPadding = 6
        local cardX = panelX + cardPadding
        local cardY = panelTopY + cardPadding
        local cardW = panelW - cardPadding * 2
        local cardH = topSectionH - cardPadding * 2
        
        -- Determine colors based on score
        local scoreColor, cardBg
        if displayScore >= 100 then
            scoreColor = theme.corner.faster  -- Purple for perfect score!
            cardBg = rgbm(0.12, 0.06, 0.15, 0.9)
        elseif displayScore >= 80 then
            scoreColor = theme.delta.positive
            cardBg = rgbm(0.06, 0.15, 0.06, 0.9)
        elseif displayScore >= 60 then
            scoreColor = theme.score.fill
            cardBg = rgbm(0.15, 0.12, 0.02, 0.9)
        else
            scoreColor = theme.delta.negative
            cardBg = rgbm(0.15, 0.06, 0.06, 0.9)
        end
        
        -- Card background
        ui.drawRectFilled(vec2(cardX, cardY), vec2(cardX + cardW, cardY + cardH), cardBg, 6)
        ui.drawRect(vec2(cardX, cardY), vec2(cardX + cardW, cardY + cardH), theme.withAlpha(scoreColor, 0.5), 6, 1)
        
        -- Score fill bar at bottom of card
        local barH = 3
        local barY = cardY + cardH - barH - 3
        local barW = cardW - 12
        local fillW = (displayScore / 100) * barW
        ui.drawRectFilled(vec2(cardX + 6, barY), vec2(cardX + 6 + barW, barY + barH), theme.withAlpha(theme.score.bg, 0.3), 1)
        if fillW > 0 then
            ui.drawRectFilled(vec2(cardX + 6, barY), vec2(cardX + 6 + fillW, barY + barH), theme.withAlpha(scoreColor, 0.8), 1)
        end
        
        -- Score (left side, smaller font)
        local scoreText = tostring(math.floor(displayScore))
        ui.pushFont(ui.Font.Title)
        local scoreSize = ui.measureText(scoreText)
        local scoreX = cardX + 8
        local scoreY = cardY + (cardH - barH - 6 - scoreSize.y) / 2
        ui.setCursor(vec2(scoreX, scoreY))
        ui.pushStyleColor(ui.StyleColor.Text, scoreColor)
        ui.text(scoreText)
        ui.popStyleColor()
        ui.popFont()
        
        -- Delta time (right side, smaller, vertically centered above bar)
        if displayData.timeDelta then
            local sign = displayData.timeDelta >= 0 and "+" or ""
            local deltaColor = displayData.timeDelta >= 0 and theme.delta.negative or theme.delta.positive
            local deltaText = string.format("%s%.2fs", sign, displayData.timeDelta)
            ui.pushFont(ui.Font.Small)
            local deltaSize = ui.measureText(deltaText)
            local deltaX = cardX + cardW - deltaSize.x - 8
            local deltaY = cardY + (cardH - barH - 6 - deltaSize.y) / 2
            ui.setCursor(vec2(deltaX, deltaY))
            ui.pushStyleColor(ui.StyleColor.Text, deltaColor)
            ui.text(deltaText)
            ui.popStyleColor()
            ui.popFont()
        end

        -- Header text
        ui.setCursor(vec2(padding, 4))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        if frozenCorner.active then
            local lapText = frozenCorner.lapNumber > 0 and string.format(" from lap %d", frozenCorner.lapNumber) or ""
            ui.text(string.format("Focusing on corner %d%s", frozenCorner.cornerNum, lapText))
        else
            ui.text("Corner Speed & Position vs. Reference Lap")
        end
        ui.popStyleColor()
        ui.popFont()

        local statsY = panelTopY + topSectionH + 10
        -- Graph outline (blue for frozen, green for live)
        local outlineColor = frozenCorner.active
            and theme.corner.focusedBorder
            or theme.withAlpha(theme.delta.positive, 0.6)
        ui.drawRect(
            vec2(padding, graphY),
            vec2(padding + graphWidth, graphY + graphHeight),
            outlineColor, 4, 2
        )

        -- Graph content (filled comparison first, behind marker lines)
        drawFilledComparison(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds,
            displayData.refSpeeds
        )

        -- Draw marker lines AFTER filled comparison so they appear on top
        drawMarkerLines(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds, displayData.refSpeeds, displayData
        )

        -- Meter annotations at bottom
        if displayData.refStartPos and displayData.refEndPos then
            local trackLen = ac.getSim().trackLengthM or 5000
            local startM = displayData.refStartPos * trackLen
            local endM = displayData.refEndPos * trackLen
            local cornerLenM = endM - startM
            if cornerLenM < 0 then cornerLenM = cornerLenM + trackLen end

            -- Choose nice round intervals based on corner length (fewer labels)
            local interval = 50
            if cornerLenM > 300 then interval = 100
            elseif cornerLenM < 100 then interval = 25
            end

            local labelY = graphY + graphHeight + 2
            ui.pushFont(ui.Font.Small)
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)

            -- Draw 0m at start
            ui.setCursor(vec2(padding, labelY))
            ui.text("0m")

            -- Draw intermediate labels at round intervals
            local numLabels = math.floor(cornerLenM / interval)
            for i = 1, numLabels do
                local meters = i * interval
                local frac = meters / cornerLenM
                if frac < 0.95 then  -- Don't draw too close to end
                    local labelX = padding + 4 + (graphWidth - 8) * frac
                    local labelText = tostring(meters) .. "m"
                    local textW = ui.measureText(labelText).x
                    ui.setCursor(vec2(labelX - textW / 2, labelY))
                    ui.text(labelText)
                end
            end

            -- Draw total length at end
            local endText = string.format("%dm", math.floor(cornerLenM + 0.5))
            local endTextW = ui.measureText(endText).x
            ui.setCursor(vec2(padding + graphWidth - endTextW, labelY))
            ui.text(endText)

            ui.popStyleColor()
            ui.popFont()
        end
        
        -- Stats panel (styled like "At Cursor" in lap_telemetry)
        local panelPadding = 8
        local panelInnerX = panelX + panelPadding
        local valueX = panelX + 55

        -- Helper to draw a stat row
        local function drawStatRow(label, value, valueColor)
            ui.setCursor(vec2(panelInnerX, statsY))
            ui.pushFont(ui.Font.Small)
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
            ui.text(label)
            ui.popStyleColor()
            ui.sameLine(valueX)
            ui.pushStyleColor(ui.StyleColor.Text, valueColor or theme.text.primary)
            ui.text(value)
            ui.popStyleColor()
            ui.popFont()
            statsY = statsY + lineH
        end

        -- Helper to draw a note sentence with severity-based color
        local function drawNote(note)
            local color = theme.trace.fuel  -- Default: info (warm orange, same as fuel trace)
            if note.severity == "error" then
                color = theme.delta.negative  -- Error: red
            end

            ui.setCursor(vec2(panelInnerX, statsY))
            ui.pushFont(ui.Font.Small)
            ui.pushStyleColor(ui.StyleColor.Text, color)
            local noteWidth = math.max(40, panelW - panelPadding * 2)
            -- Wrap explicitly using measured word widths. This avoids CSP
            -- version/context differences in textWrapped() wrap coordinates
            -- when drawing in a manually positioned right-hand panel.
            local lines, line = {}, ""
            for word in tostring(note.text):gmatch("%S+") do
                local candidate = line == "" and word or (line .. " " .. word)
                if line ~= "" and ui.measureText(candidate).x > noteWidth then
                    lines[#lines + 1] = line
                    line = word
                else
                    line = candidate
                end
            end
            if line ~= "" then lines[#lines + 1] = line end
            if #lines == 0 then lines[1] = "" end
            for i, wrappedLine in ipairs(lines) do
                ui.setCursor(vec2(panelInnerX, statsY + (i - 1) * lineH))
                ui.text(wrappedLine)
            end
            ui.popStyleColor()
            ui.popFont()
            statsY = statsY + #lines * lineH
        end

        -- Helper to get delta color for speed (positive = faster = good)
        local function getSpeedDeltaColor(delta)
            if not delta then return theme.text.muted end
            if math.abs(delta) < 1 then return theme.text.primary end
            return delta > 0 and theme.delta.positive or theme.delta.negative
        end

        -- Helper to get delta color for position (positive = later = good for brake/lift)
        local function getPositionDeltaColor(meters)
            if not meters then return theme.text.muted end
            if math.abs(meters) < 3 then return theme.text.primary end
            return meters > 0 and theme.delta.positive or theme.delta.negative
        end

        -- Shared bar visualization helper
        local barMaxSpeed = 15  -- Max delta shown (km/h)
        local barMaxPos = 30    -- Max delta shown (meters)
        local barTotalW = panelW - panelPadding * 2 - 4
        local barH = 14
        local barSpacing = 2
        local labelW = 38

        local function drawBarValue(barStartX, barW, valueText, color)
            ui.pushFont(ui.Font.Small)
            local textSize = ui.measureText(valueText)
            local textPos = vec2(barStartX + barW - textSize.x - 4, statsY + 1)
            -- Small shadow keeps the value readable over fills and markers
            -- without reserving a separate value column.
            ui.drawText(valueText, vec2(textPos.x + 1, textPos.y + 1), rgbm(0, 0, 0, 0.9))
            ui.drawText(valueText, textPos, color)
            ui.popFont()
        end
        
        local function drawDeltaBar(label, delta, maxDelta, unit, invertColor, decimals)
            if delta == nil then return end
            
            local barW = barTotalW - labelW - 4
            local barStartX = panelInnerX + labelW + 4
            local centerX = barStartX + barW / 2
            
            -- Label
            ui.pushFont(ui.Font.Small)
            ui.setCursor(vec2(panelInnerX, statsY + 1))
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
            ui.text(label)
            ui.popStyleColor()
            ui.popFont()
            
            -- Bar background
            ui.drawRectFilled(
                vec2(barStartX, statsY),
                vec2(barStartX + barW, statsY + barH),
                rgbm(0.15, 0.15, 0.15, 0.8), 2
            )
            
            -- Center line
            ui.drawRectFilled(
                vec2(centerX - 0.5, statsY + 2),
                vec2(centerX + 0.5, statsY + barH - 2),
                rgbm(0.4, 0.4, 0.4, 0.6), 0
            )
            
            -- Delta fill
            if delta ~= 0 then
                local normalized = math.clamp(math.abs(delta) / maxDelta, 0, 1)
                local fillW = normalized * (barW / 2 - 2)
                local isPositive = invertColor and (delta < 0) or (delta > 0)
                local fillColor = isPositive and theme.delta.positive or theme.delta.negative
                
                if delta > 0 then
                    ui.drawRectFilled(
                        vec2(centerX, statsY + 2),
                        vec2(centerX + fillW, statsY + barH - 2),
                        fillColor, 1
                    )
                else
                    ui.drawRectFilled(
                        vec2(centerX - fillW, statsY + 2),
                        vec2(centerX, statsY + barH - 2),
                        fillColor, 1
                    )
                end
            end
            
            -- Value text, right-aligned inside the full-width bar.
            local sign = delta >= 0 and "+" or ""
            local valueText = string.format("%s%." .. tostring(decimals or 0) .. "f%s", sign, delta, unit)
            local valueColor = delta > 0 and theme.delta.positive or (delta < 0 and theme.delta.negative or theme.text.muted)
            if invertColor then
                valueColor = delta < 0 and theme.delta.positive or (delta > 0 and theme.delta.negative or theme.text.muted)
            end
            drawBarValue(barStartX, barW, valueText, valueColor)
            
            statsY = statsY + barH + barSpacing
        end
        
        -- SPEED section
        drawDeltaBar("Entry", displayData.entrySpeedDelta, barMaxSpeed, "kmh", false)
        drawDeltaBar("Apex", displayData.apexSpeedDelta, barMaxSpeed, "kmh", false)
        drawDeltaBar("Exit", displayData.exitSpeedDelta, barMaxSpeed, "kmh", false)
        
        statsY = statsY + 6
        
        -- Position bar helper. Position is signed relative to the reference:
        -- early is negative/yellow, late is positive/red, and +/-2 m is green.
        local function drawPositionBar(label, meters, maxMeters)
            if meters == nil then return end
            
            local barW = barTotalW - labelW - 4
            local barStartX = panelInnerX + labelW + 4
            local centerX = barStartX + barW / 2
            
            -- Label
            ui.pushFont(ui.Font.Small)
            ui.setCursor(vec2(panelInnerX, statsY + 1))
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
            ui.text(label)
            ui.popStyleColor()
            ui.popFont()
            
            -- Bar background
            ui.drawRectFilled(
                vec2(barStartX, statsY),
                vec2(barStartX + barW, statsY + barH),
                rgbm(0.15, 0.15, 0.15, 0.8), 2
            )

            -- Green target zone: matching the reference within two metres.
            local targetHalfW = math.min(barW / 2 - 2, (2 / maxMeters) * (barW / 2 - 2))
            ui.drawRectFilled(
                vec2(centerX - targetHalfW, statsY + 2),
                vec2(centerX + targetHalfW, statsY + barH - 2),
                rgbm(0.20, 0.70, 0.20, 0.45), 1
            )
            
            -- Center line (reference position) - more visible dashed style
            ui.drawLine(
                vec2(centerX, statsY + 1),
                vec2(centerX, statsY + barH - 1),
                rgbm(0.6, 0.6, 0.6, 0.9), 2
            )
            
            -- Position marker (vertical line)
            local onTarget = math.abs(meters) <= 2
            local markerColor = onTarget and theme.delta.positive
                or (meters > 0 and theme.delta.negative or rgbm(1, 0.78, 0.12, 1))
            local normalized = math.clamp(meters / maxMeters, -1, 1)
            local markerX = centerX + normalized * (barW / 2 - 2)
            ui.drawLine(
                vec2(markerX, statsY + 1),
                vec2(markerX, statsY + barH - 1),
                markerColor, 3
            )
            
            -- Compact signed value leaves more room for the actual bar.
            local valueText = string.format("%+.0fm", meters)
            
            drawBarValue(barStartX, barW, valueText, markerColor)
            
            statsY = statsY + barH + barSpacing
        end
        
        -- POSITION section (signed metres; marker color communicates direction)
        local brakeMeters, liftOffMeters = scoring.getMeterDeltas(displayData)
        drawPositionBar("Lift", liftOffMeters, barMaxPos)
        drawPositionBar("Brake", brakeMeters, barMaxPos)
        drawPositionBar("Turn", displayData.turnInDeltaM, barMaxPos)
        
        -- Apex position delta
        if displayData.currentApexPos and displayData.refApexPos then
            local apexMeters = scoring.positionDeltaToMeters(displayData.currentApexPos, displayData.refApexPos)
            drawPositionBar("Apex", apexMeters, barMaxPos)
        end
        statsY = statsY + 6
        drawDeltaBar("Grip E", displayData.combinedGripEarlyDelta, 0.5, "g", false, 2)
        drawDeltaBar("Grip M", displayData.combinedGripMidDelta, 0.5, "g", false, 2)

        -- Get lap data (use frozen lap data if viewing from telemetry, or displayLap for live)
        local liveLap, refLap
        if frozenCorner.active then
            liveLap = frozenCorner.currentLap
            refLap = frozenCorner.referenceLap
        else
            -- Use displayLap which was captured at corner exit time
            -- This ensures we have the correct lap data even if a new lap started
            liveLap = displayLap or currentLap
            refLap = referenceLap
        end

        -- NOTES section (only shown if there are significant observations)
        local notes = corner_analysis.collectNotes(displayData, liveLap, refLap)
        local maxNotes = 5  -- Keep the new technique observations visible

        -- Draw notes section if we have any valid notes
        if notes and #notes > 0 then
            -- Count valid notes (those with actual text)
            local validNotes = {}
            for _, note in ipairs(notes) do
                if note and note.text and note.text ~= "" then
                    table.insert(validNotes, note)
                    if #validNotes >= maxNotes then break end  -- Limit notes
                end
            end

            -- Only draw section if there are valid notes
            if #validNotes > 0 then
                statsY = statsY + 6
                
                -- Notes header
                ui.setCursor(vec2(panelInnerX, statsY))
                ui_utils.textFont("Notes", ui.Font.Main, theme.text.primary)
                statsY = statsY + 18
                
                for _, note in ipairs(validNotes) do
                    drawNote(note)
                end
            end
        end

        -- Lockup diagram: find wheels data from lockup note
        local lockupWheels = nil
        if notes then
            for _, note in ipairs(notes) do
                if note and note.wheels then
                    lockupWheels = note.wheels
                    break
                end
            end
        end
        if lockupWheels then
            statsY = statsY + 8
            local diagramCx = panelInnerX + panelW / 2
            local diagramCy = statsY + 30
            drawLockupDiagram(diagramCx, diagramCy, lockupWheels)
            statsY = diagramCy + 34
        end

        -- Draw pedal traces at bottom (same width as speed graph above) - uses captured snapshot data
        local pedalY = graphY + graphHeight + meterLabelHeight + pedalTracePadding

        if displayData.currentPedals or displayData.refPedals then
            drawPedalTraces(padding, pedalY, graphWidth, pedalTraceHeight,
                displayData.currentPedals, displayData.refPedals, displayData)
        end
    else
        -- Empty state: full-width centered message
        local emptyAreaW = windowSize.x - padding * 2
        local emptyAreaH = windowSize.y - graphY - padding

        -- Draw a subtle full-width background
        ui.drawRectFilled(
            vec2(padding, graphY),
            vec2(padding + emptyAreaW, graphY + emptyAreaH),
            theme.bg.graph,
            4
        )

        -- Center the message
        local hasRef = referenceLap and referenceLap:length() > 10
        local message = hasRef and "Waiting for corner exit..." or "Load a reference lap first"
        ui.pushFont(ui.Font.Main)
        local textSize = ui.measureText(message)
        local textX = padding + (emptyAreaW - textSize.x) / 2
        local textY = graphY + (emptyAreaH - textSize.y) / 2
        ui.setCursor(vec2(textX, textY))
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        ui.text(message)
        ui.popStyleColor()
        ui.popFont()
    end
end

function corner_analysis.reset()
    displayData = nil
    displayScore = 0
    displayLap = nil
    lastCompletedResult = nil
    resetLiveCorner()
    corner_analysis.clearFrozenCorner()
    recentCornerScores = {}
end

--- Draw a tiny Lift -> Brake -> Turn -> Apex sequence.
--- Dot color is a continuous position delta gradient:
--- early = blue, within +/-2 m = green, late = red.
function corner_analysis.drawSequenceDots(dt)
    local size = ui.availableSpace()
    local width = math.max(1, size.x)
    local height = math.max(1, size.y)

    ui.drawRectFilled(vec2(0, 0), vec2(width, height), rgbm(0.055, 0.055, 0.065, 0.92), 5)
    ui.drawRect(vec2(0, 0), vec2(width, height), rgbm(0.3, 0.3, 0.35, 0.45), 5, 1)

    local early = { r = 0.20, g = 0.55, b = 1.00 }
    local target = { r = 0.25, g = 1.00, b = 0.35 }
    local late = { r = 1.00, g = 0.25, b = 0.25 }
    local exact = { r = 0.72, g = 0.30, b = 1.00 }
    local function mix(a, b, t, alpha)
        return rgbm(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            alpha or 1)
    end
    local function colorFor(delta)
        if delta == nil then return rgbm(0.35, 0.35, 0.38, 0.65) end
        -- Same displayed metre (rounds to 0 m) gets a distinct perfect-match color.
        if math.abs(delta) < 0.5 then
            return rgbm(exact.r, exact.g, exact.b, 1)
        end
        if delta < -2 then
            local t = math.clamp((-delta - 2) / 8, 0, 1)
            return mix(target, early, t)
        elseif delta > 2 then
            local t = math.clamp((delta - 2) / 8, 0, 1)
            return mix(target, late, t)
        end
        return rgbm(target.r, target.g, target.b, 1)
    end

    local result = corner_analysis.getLastCompletedResult()
    -- Always reserve the score/delta area. Previously the first corner's dots
    -- used the full width, then jumped closer together as soon as a result
    -- appeared. Keeping this geometry fixed makes all four lights stay put.
    local resultReserve = math.min(96, math.max(66, width * 0.47))
    local dotsRightEdge = width - resultReserve
    local cy = height * 0.5
    local radius = math.max(3.5, math.min(6, height * 0.19))
    local left = math.max(radius + 7, dotsRightEdge * 0.12)
    local right = math.min(dotsRightEdge - radius - 7, dotsRightEdge * 0.88)
    local gap = (right - left) / 3
    local labels = { "L", "B", "T", "A" }

    ui.drawLine(vec2(left, cy), vec2(right, cy), rgbm(0.35, 0.35, 0.38, 0.35), 1)
    for i = 1, 4 do
        local center = vec2(left + gap * (i - 1), cy)
        local event = sequenceState.events[i]
        if event.visible then
            local settled = colorFor(event.delta)
            local flash = math.clamp(event.flash or 0, 0, 1)
            local color = mix(
                { r = settled.r, g = settled.g, b = settled.b },
                { r = 1, g = 1, b = 1 },
                flash * 0.72)
            local glow = 0.10 + flash * 0.28
            ui.drawCircleFilled(center, radius + 3 + flash * 1.5,
                rgbm(color.r, color.g, color.b, glow), 18)
            ui.drawCircleFilled(center, radius + 1.5,
                rgbm(color.r, color.g, color.b, 0.24 + flash * 0.18), 18)
            ui.drawCircleFilled(center, radius, color, 18)
            ui.drawCircle(center, radius, rgbm(1, 1, 1, 0.22 + flash * 0.35), 18, 1)
            event.flash = math.max(0, flash - (dt or 1 / 60) * 4.5)
        else
            if event.relevant then
                -- A relevant event has not happened yet.
                ui.drawCircle(center, radius, rgbm(0.42, 0.42, 0.46, 0.30), 18, 1)
            else
                -- Irrelevant techniques are neutral, light-gray filled dots.
                ui.drawCircleFilled(center, radius, rgbm(0.68, 0.68, 0.72, 0.52), 18)
                ui.drawCircle(center, radius, rgbm(0.9, 0.9, 0.92, 0.28), 18, 1)
            end
        end

        -- Keep the sequence identifiable without adding external labels or
        -- changing its fixed geometry. A dark glyph reads clearly on active
        -- colors; inactive lights use a restrained light-gray glyph.
        local labelColor = event.visible
            and rgbm(0.025, 0.025, 0.03, 0.88)
            or rgbm(0.82, 0.82, 0.86, event.relevant and 0.55 or 0.78)
        ui.dwriteDrawTextClipped(labels[i], math.max(6, radius * 1.55),
            center - vec2(radius, radius), center + vec2(radius, radius),
            0.5, 0.5, false, labelColor)
    end

    if result then
        local separatorX = dotsRightEdge + 1
        ui.drawLine(vec2(separatorX, 5), vec2(separatorX, height - 5),
            rgbm(0.42, 0.42, 0.46, 0.28), 1)

        local score = math.floor((result.score or 0) + 0.5)
        local scoreText = tostring(score)
        local scoreColor = score >= 80 and theme.delta.positive
            or (score >= 60 and rgbm(1, 0.78, 0.12, 1) or theme.delta.negative)
        ui.pushFont(ui.Font.Main)
        local scoreSize = ui.measureText(scoreText)
        local scorePos = vec2(separatorX + 7, (height - scoreSize.y) * 0.5)
        ui.drawText(scoreText, scorePos, scoreColor)
        ui.popFont()

        if result.timeDelta ~= nil then
            local deltaText = string.format("%+.2fs", result.timeDelta)
            local deltaColor = math.abs(result.timeDelta) < 0.005 and theme.text.muted
                or (result.timeDelta < 0 and theme.delta.positive or theme.delta.negative)
            ui.pushFont(ui.Font.Small)
            local deltaSize = ui.measureText(deltaText)
            local deltaX = math.min(width - deltaSize.x - 5, scorePos.x + scoreSize.x + 8)
            ui.drawText(deltaText, vec2(deltaX, (height - deltaSize.y) * 0.5), deltaColor)
            ui.popFont()
        end
    end
end

--- Reset live tracking after a teleport while keeping the last complete result.
function corner_analysis.onTeleport(pos)
    -- Keep displayData frozen (shows last corner result)
    -- Reset live corner tracking state
    resetLiveCorner()
    -- Clear recent corner scores (they're now invalid since we teleported)
    recentCornerScores = {}
    -- Clear frozen corner state if any
    corner_analysis.clearFrozenCorner()
    
    -- Reset lap count tracking to match restored state
    -- This prevents false "new lap" detection on next update
    local car = ac.getCar(0)
    if car then
        lastLapCount = car.lapCount
    end

    local _, corner = getCornerAtPos(state.trackCorners, pos or -1)
    ignoredCornerAfterJump = corner and corner.number or 0
    ac.log(string.format("AC Tracer: Corner analysis reset after teleport at pos %.3f", pos or 0))
end

--- Get recent corner scores (for delta bar display)
---@return table Array of {cornerNum, score, lapNumber}
function corner_analysis.getRecentCornerScores()
    return recentCornerScores
end

--------------------------------------------------------------------------------
return corner_analysis
