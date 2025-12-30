-- Corner Analysis - All corner-specific logic
-- Analyzes corners in laps, tracks live corner data, compares to reference

local lap = require('lap')
local scoring = require('scoring')
local settings = require('app_settings')
local extended_brake = require('extended-brake')
local theme = require('theme')
local ui_utils = require('ui_utils')

local corner_analysis = {}

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

local GEAR_SHIFT_IGNORE_TIME = 0.15  -- Seconds to ignore throttle after gear shift

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

-- Display state (last completed corner)
local displayData = nil
local displayScore = 0
local displayLap = nil      -- The lap data at time of corner exit (for flag analysis)

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
    return { text = text, severity = "error" }
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
    if tcDuration < 1.0 then return nil end  -- Only warn for excessive TC (> 1 second)

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

    -- Find throttle application point in current lap (after apex)
    local apexPos = data.currentApexPos or ((data.refStartPos + data.refEndPos) / 2)
    local currentThrottlePos = nil
    local refThrottlePos = nil

    -- Search from apex to corner end for throttle application
    for i = 1, #currentLap.pos do
        local pos = currentLap.pos[i]
        if pos >= apexPos and pos <= data.refEndPos then
            if currentLap.throttle[i] and currentLap.throttle[i] >= THROTTLE_THRESHOLD then
                currentThrottlePos = pos
                break
            end
        end
    end

    for i = 1, #refLap.pos do
        local pos = refLap.pos[i]
        if pos >= apexPos and pos <= data.refEndPos then
            if refLap.throttle[i] and refLap.throttle[i] >= THROTTLE_THRESHOLD then
                refThrottlePos = pos
                break
            end
        end
    end

    if not currentThrottlePos or not refThrottlePos then return nil end

    local trackLen = ac.getSim().trackLengthM or 5000
    local diffM = (currentThrottlePos - refThrottlePos) * trackLen
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

    -- Only report if significant difference (> 5 bar)
    local diffBar = currentMaxBar - refMaxBar
    if math.abs(diffBar) < 5 then return nil end

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

--- Collect all corner notes by running analysis functions
---@param data table Corner comparison data
---@param currentLap table Current lap data (optional, for flag-based analysis)
---@param refLap table Reference lap data (optional, for comparisons)
---@return table Array of note tables {text, severity} (may be empty)
local function collectCornerNotes(data, currentLap, refLap)
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
        -- Reference gear
        refMinGear = reference.minGear,
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

local function onCornerExit(currentLap, referenceLap)
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

    corner_analysis.compare(cornerInfo, currentLap, referenceLap, {
        currentSpeeds = currentSpeeds,
        refSpeeds = refSpeeds,
        timeDeltaOverride = timeDelta,
    })

    -- Store snapshot of current lap for flag analysis (notes section)
    -- Note: This is still a reference, but flags don't change after capture
    displayLap = currentLap
end

--------------------------------------------------------------------------------
-- Live Corner Tracking: Update (call every frame)
--------------------------------------------------------------------------------

--- Update live corner tracking
---@param car table Car state from ac.getCar()
---@param currentLap table Current lap data
---@param referenceLap table Reference lap data
---@param corners table Array of corner definitions
function corner_analysis.update(car, currentLap, referenceLap, corners)
    if not car then return end
    
    -- Clear frozen corner state when car starts moving (above 30 km/h)
    if frozenCorner.active and car.speedKmh >= 30 then
        corner_analysis.clearFrozenCorner()
    end
    
    -- Reset on new lap
    if car.lapCount ~= lastLapCount then
        lastLapCount = car.lapCount
        resetLiveCorner()
        -- Clear displayed corner data from previous lap
        displayData = nil
        displayScore = 0
        displayLap = nil
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
    
    if cornerNum > 0 and cornerInfo then
        if liveCorner.cornerNum ~= cornerNum then
            -- Entering new corner
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
            elseif liveCorner.wasOnThrottle and not liveCorner.liftOffPos and not nearGearShift then
                liveCorner.liftOffPos = currentPos
            end

            -- Track brake point
            if isBraking and not liveCorner.brakePos then
                liveCorner.brakePos = currentPos
            end
            
            -- Apex speed: minimum in corner (track continuously)
            if currentSpeed < liveCorner.apexSpeed then
                liveCorner.apexSpeed = currentSpeed
                liveCorner.apexPos = currentPos
                -- Reset passedApex since we found a new min speed point
                liveCorner.passedApex = false
            else
                -- Speed is increasing, we've passed the min speed point
                liveCorner.passedApex = true
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
        onCornerExit(currentLap, referenceLap)
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

function corner_analysis.justExitedCorner()
    return liveCorner.leftCorner
end

--------------------------------------------------------------------------------
-- UI Drawing
--------------------------------------------------------------------------------

local function drawFilledComparison(x, y, w, h, currentSpeeds, refSpeeds)
    if not currentSpeeds or #currentSpeeds < 2 then return end
    if not refSpeeds or #refSpeeds < 2 then return end

    local SPEED_TOLERANCE = 1

    -- Calculate speed range from captured data (no live state queries)
    local minSpeed, maxSpeed = math.huge, 0
    for i, s in ipairs(currentSpeeds) do
        minSpeed = math.min(minSpeed, s.speed)
        maxSpeed = math.max(maxSpeed, s.speed)
        if refSpeeds[i] then
            minSpeed = math.min(minSpeed, refSpeeds[i].speed)
            maxSpeed = math.max(maxSpeed, refSpeeds[i].speed)
        end
    end

    local speedRange = maxSpeed - minSpeed
    minSpeed = minSpeed - speedRange * 0.15
    maxSpeed = maxSpeed + speedRange * 0.1
    speedRange = maxSpeed - minSpeed

    if speedRange <= 0 then return end

    local numPoints = #currentSpeeds
    local bottomY = y + h

    -- Draw filled comparison using captured data
    for i = 1, numPoints - 1 do
        local s1 = currentSpeeds[i]
        local s2 = currentSpeeds[i + 1]
        local ref1 = refSpeeds[i] and refSpeeds[i].speed or s1.speed
        local ref2 = refSpeeds[i + 1] and refSpeeds[i + 1].speed or s2.speed
        local x1 = x + (i - 1) / (numPoints - 1) * w
        local x2 = x + i / (numPoints - 1) * w
        local curY1 = y + h - ((s1.speed - minSpeed) / speedRange) * h
        local curY2 = y + h - ((s2.speed - minSpeed) / speedRange) * h
        local avgCurSpeed = (s1.speed + s2.speed) / 2
        local avgRefSpeed = (ref1 + ref2) / 2
        local speedDiff = avgCurSpeed - avgRefSpeed
        local color
        if math.abs(speedDiff) <= SPEED_TOLERANCE then
            color = theme.corner.onSpeed
        elseif speedDiff > 0 then
            color = theme.corner.faster
        else
            color = theme.corner.slower
        end
        ui.pathClear()
        ui.pathLineTo(vec2(x1, curY1))
        ui.pathLineTo(vec2(x2, curY2))
        ui.pathLineTo(vec2(x2, bottomY))
        ui.pathLineTo(vec2(x1, bottomY))
        ui.pathFillConvex(color)
    end

    -- Draw reference speed line using captured data
    ui.pathClear()
    for i, s in ipairs(refSpeeds) do
        local px = x + (i - 1) / (numPoints - 1) * w
        local py = y + h - ((s.speed - minSpeed) / speedRange) * h
        ui.pathLineTo(vec2(px, py))
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

local function drawMarkerLines(x, y, w, h, currentSpeeds, data)
    if not currentSpeeds or #currentSpeeds < 2 then return end
    local startPos = currentSpeeds[1].pos
    local endPos = currentSpeeds[#currentSpeeds].pos
    local posRange = endPos - startPos
    if posRange <= 0 then posRange = 1 end

    local function posToX(pos)
        if not pos then return nil end
        local px = x + ((pos - startPos) / posRange) * w
        if px >= x and px <= x + w then return px end
        return nil
    end

    -- Reference apex line (dashed yellow) - slowest speed point
    local refApexX = posToX(data.refApexPos)
    if refApexX then
        ui_utils.drawDashedLine(vec2(refApexX, y), vec2(refApexX, y + h), theme.marker.apexRef, 2, 5, 3)
    end

    -- Current apex line (solid yellow) - slowest speed point
    local curApexX = posToX(data.currentApexPos)
    if curApexX then
        ui.drawLine(vec2(curApexX, y), vec2(curApexX, y + h), theme.marker.apex, 3)
    end

    -- Draw direction arrow at top border (between solid and dashed lines)
    drawDirectionArrows(curApexX, refApexX, y, theme.marker.apex)
end

local function drawScoreGauge(cx, cy, radius, score)
    local startAngle = math.rad(-225)
    local endAngle = math.rad(45)
    local totalArc = endAngle - startAngle
    local segments = 32
    ui.pathClear()
    for i = 0, segments do
        local angle = startAngle + (i / segments) * totalArc
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(theme.score.bg, false, 8)

    local scoreAngle = startAngle + (score / 100) * totalArc
    ui.pathClear()
    for i = 0, segments do
        local angle = startAngle + (i / segments) * (scoreAngle - startAngle)
        if angle > scoreAngle then break end
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(theme.score.fill, false, 8)

    ui.pushFont(ui.Font.Title)
    local scoreText = tostring(math.floor(score))
    local textWidth = ui.measureText(scoreText).x
    ui.setCursor(vec2(cx - textWidth / 2, cy - 12))
    ui.pushStyleColor(ui.StyleColor.Text, theme.score.fill)
    ui.text(scoreText)
    ui.popStyleColor()
    ui.popFont()
end

--- Draw brake/throttle traces for a corner using captured pedal data
local function drawPedalTraces(x, y, w, h, currentPedals, refPedals)
    -- Background
    ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), theme.bg.graph, 4)

    -- Draw horizontal grid lines at 25%, 50%, 75%
    for frac = 0.25, 0.75, 0.25 do
        local lineY = y + h * (1 - frac)
        ui.drawLine(vec2(x, lineY), vec2(x + w, lineY), rgbm(0.3, 0.3, 0.3, 0.3), 1)
    end

    -- Draw reference traces first (behind current) using captured data
    if refPedals and #refPedals.throttle > 0 then
        local numPoints = #refPedals.throttle

        -- Reference throttle (ghost)
        ui.pathClear()
        for i, throttle in ipairs(refPedals.throttle) do
            local px = x + ((i - 1) / (numPoints - 1)) * w
            local py = y + h - throttle * h
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(theme.ghost.throttle, false, 2)

        -- Reference brake (ghost)
        ui.pathClear()
        for i, brake in ipairs(refPedals.brake) do
            local px = x + ((i - 1) / (numPoints - 1)) * w
            local py = y + h - brake * h
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(theme.ghost.brake, false, 2)
    end

    -- Draw current traces using captured data
    if currentPedals and #currentPedals.throttle > 0 then
        local numPoints = #currentPedals.throttle

        -- Current throttle
        ui.pathClear()
        for i, throttle in ipairs(currentPedals.throttle) do
            local px = x + ((i - 1) / (numPoints - 1)) * w
            local py = y + h - throttle * h
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(theme.trace.throttle, false, 2)

        -- Current brake
        ui.pathClear()
        for i, brake in ipairs(currentPedals.brake) do
            local px = x + ((i - 1) / (numPoints - 1)) * w
            local py = y + h - brake * h
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(theme.trace.brake, false, 2)
    end

    -- Outline
    ui.drawRect(vec2(x, y), vec2(x + w, y + h), rgbm(0.4, 0.4, 0.4, 0.5), 4, 1)
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
    local topSectionH = 100  -- First 100px for delta time and score
    local gaugeRadius = 25
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

        -- Top section: Delta time and Score gauge, evenly spaced and centered
        local topCenterY = panelTopY + topSectionH / 2
        local quarterW = panelW / 4

        -- Delta time (centered in left half of right panel)
        if displayData.timeDelta then
            local deltaCenterX = panelX + quarterW
            local sign = displayData.timeDelta >= 0 and "+" or ""
            local deltaColor = displayData.timeDelta >= 0 and theme.delta.negative or theme.delta.positive
            local deltaText = string.format("%s%.2fs", sign, displayData.timeDelta)
            ui.pushFont(ui.Font.Title)
            local textSize = ui.measureText(deltaText)
            ui.setCursor(vec2(deltaCenterX - textSize.x / 2, topCenterY - textSize.y / 2))
            ui.pushStyleColor(ui.StyleColor.Text, deltaColor)
            ui.text(deltaText)
            ui.popStyleColor()
            ui.popFont()
        end

        -- Score gauge (centered in right half of right panel)
        local gaugeCenterX = panelX + quarterW * 3
        drawScoreGauge(gaugeCenterX, topCenterY, gaugeRadius, displayScore)

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

        -- Draw marker lines FIRST (behind other graphics)
        drawMarkerLines(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds, displayData
        )

        -- Graph content (filled comparison on top of markers) - uses captured snapshot data
        drawFilledComparison(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds,
            displayData.refSpeeds
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
            ui.text(note.text)
            ui.popStyleColor()
            ui.popFont()
            statsY = statsY + lineH
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

        -- SPEED section header
        ui.setCursor(vec2(panelInnerX, statsY))
        ui_utils.textFont("Speed", ui.Font.Main, theme.text.primary)
        statsY = statsY + 20
        ui.drawLine(vec2(panelX + 4, statsY), vec2(panelX + panelW - 4, statsY), theme.grid.line, 1)
        statsY = statsY + 6

        -- Speed deltas
        local entryDelta = displayData.entrySpeedDelta
        local apexDelta = displayData.apexSpeedDelta
        local exitDelta = displayData.exitSpeedDelta

        drawStatRow("Entry", entryDelta and ui_utils.speedDeltaDisplay(entryDelta, true) or "—", getSpeedDeltaColor(entryDelta))
        drawStatRow("Apex", apexDelta and ui_utils.speedDeltaDisplay(apexDelta, true) or "—", getSpeedDeltaColor(apexDelta))
        drawStatRow("Exit", exitDelta and ui_utils.speedDeltaDisplay(exitDelta, true) or "—", getSpeedDeltaColor(exitDelta))

        statsY = statsY + 8

        -- POSITION section header
        ui.setCursor(vec2(panelInnerX, statsY))
        ui_utils.textFont("Position", ui.Font.Main, theme.text.primary)
        statsY = statsY + 20
        ui.drawLine(vec2(panelX + 4, statsY), vec2(panelX + panelW - 4, statsY), theme.grid.line, 1)
        statsY = statsY + 6

        -- Position deltas
        local brakeMeters, liftOffMeters = scoring.getMeterDeltas(displayData)

        if brakeMeters then
            local dir = brakeMeters >= 0 and "later" or "earlier"
            drawStatRow("Brake", string.format("%.0fm %s", math.abs(brakeMeters), dir), getPositionDeltaColor(brakeMeters))
        end
        if liftOffMeters then
            local dir = liftOffMeters >= 0 and "later" or "earlier"
            drawStatRow("Lift", string.format("%.0fm %s", math.abs(liftOffMeters), dir), getPositionDeltaColor(liftOffMeters))
        end
        if displayData.currentApexPos and displayData.refApexPos then
            local apexMeters = (displayData.currentApexPos - displayData.refApexPos) * (ac.getSim().trackLengthM or 5000)
            local dir = apexMeters >= 0 and "later" or "earlier"
            drawStatRow("Apex", string.format("%.0fm %s", math.abs(apexMeters), dir), theme.text.primary)
        end

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
        local notes = collectCornerNotes(displayData, liveLap, refLap)

        -- Draw notes section if we have any valid notes
        if notes and #notes > 0 then
            -- Count valid notes (those with actual text)
            local validNotes = {}
            for _, note in ipairs(notes) do
                if note and note.text and note.text ~= "" then
                    table.insert(validNotes, note)
                end
            end

            -- Only draw section if there are valid notes
            if #validNotes > 0 then
                -- NOTES section header
                ui.setCursor(vec2(panelInnerX, statsY))
                ui_utils.textFont("Notes", ui.Font.Main, theme.text.primary)
                statsY = statsY + 20
                ui.drawLine(vec2(panelX + 4, statsY), vec2(panelX + panelW - 4, statsY), theme.grid.line, 1)
                statsY = statsY + 6

                for _, note in ipairs(validNotes) do
                    drawNote(note)
                end
            end
        end

        -- Draw pedal traces at bottom (same width as speed graph above) - uses captured snapshot data
        local pedalY = graphY + graphHeight + meterLabelHeight + pedalTracePadding

        if displayData.currentPedals or displayData.refPedals then
            drawPedalTraces(padding, pedalY, graphWidth, pedalTraceHeight,
                displayData.currentPedals, displayData.refPedals)
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
    resetLiveCorner()
    corner_analysis.clearFrozenCorner()
end

return corner_analysis
