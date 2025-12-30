-- state.lua - Centralized game state
-- All state and persistence lives here. Other modules read from state.

local lap = require('lap')
local settings = require('app_settings')
local history_storage = require('history_storage')

local state = {}

--------------------------------------------------------------------------------
-- State Structure
--------------------------------------------------------------------------------

-- Session info (set once at start)
state.track = nil              -- string: track ID
state.car = nil                -- string: car ID
state.sessionId = nil          -- string: unique ID for this session

-- Track data
state.trackCorners = {}        -- array of corner definitions

-- Current position (updated every frame)
state.lapNumber = 0            -- number: current lap count
state.trackPosition = 0        -- number: spline position 0.0-1.0

-- Lap data
state.currentLap = nil         -- lap: being recorded
-- state.history is now a reference to history_storage.laps (persisted session laps)
-- CSV-loaded laps are added to history but marked with csvSource (not persisted)

-- Reference lap
state.bestLap = nil            -- lap: current reference for ghost comparison
state.bestLapCorners = {}      -- pre-computed corner analysis for bestLap

-- Brake scale for charts (computed from max brake across relevant laps)
state.brakeScaleBar = 100      -- number: max bar value for brake charts (90 or 100)

-- Manual corner recording
state.cornerRecording = false
state.cornerRecordStart = nil
state.cornerRecordTime = nil

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SAMPLE_RATE = lap.SAMPLE_RATE
local TAP_THRESHOLD = 1.0
local MAX_SAMPLES = 36000  -- ~10 minutes at 60Hz (36000 samples)

-- state.history is a reference to history_storage.laps
state.history = history_storage.laps

-- Timing
local sampleTimer = 0
local initialized = false

-- TimeShift/Rewind detection
local lastRewindTime = 0       -- os.preciseClock() when last rewind occurred
local REWIND_GRACE_PERIOD = 1.0  -- Seconds to consider a jump as rewind-related
local preRewindLapCount = 0    -- Lap count before entering rewind
local preRewindPosition = 0    -- Spline position before entering rewind

-- Global time tracking (for rewind-aware timing)
local sessionTime = 0          -- Accumulated session time (affected by rewind)
local lastRawDt = 0            -- Last raw dt received
local timeOffset = 0           -- Accumulated offset from rewinds
local lastUpdateClock = 0      -- os.preciseClock() at last update
local timeFrozen = false       -- True when time is frozen (car stopped, engine off)

--------------------------------------------------------------------------------
-- Storage Keys
--------------------------------------------------------------------------------

local function getStorageKey(suffix)
    local trackId = state.track or 'unknown'
    return 'ac_tracer_' .. trackId:gsub("[/\\:]", "_") .. '_' .. suffix
end

local CORNERS_DIR = __dirname .. "/corners"

--- Get corner CSV path for current track
local function getCornersPath()
    if not state.track then return nil end
    return CORNERS_DIR .. "/" .. state.track:gsub("[/\\:]", "_") .. ".csv"
end

--------------------------------------------------------------------------------
-- Brake Scale Computation
--------------------------------------------------------------------------------

--- Compute brake scale from relevant laps
--- Takes max brake across bestLap, currentLap, adds 11%, rounds up to nearest 10
--- Result is either 90 or 100 (minimum 90)
local function computeBrakeScale()
    local maxBar = 0
    
    -- Check bestLap
    if state.bestLap then
        local best = state.bestLap:maxBrakeBars()
        if best > maxBar then maxBar = best end
    end
    
    -- Check currentLap
    if state.currentLap then
        local current = state.currentLap:maxBrakeBars()
        if current > maxBar then maxBar = current end
    end
    
    -- Check history (first few laps)
    for i = 1, math.min(5, #state.history) do
        local histLap = state.history[i]
        if histLap then
            local hist = histLap:maxBrakeBars()
            if hist > maxBar then maxBar = hist end
        end
    end
    
    -- Add 11% headroom and round up to nearest 10
    local withHeadroom = maxBar * 1.11
    local rounded = math.ceil(withHeadroom / 10) * 10
    
    -- Minimum 90, typical max 100 (but allow higher for race cars)
    return math.max(90, rounded)
end

--- Update brake scale (call when bestLap changes or periodically)
function state.updateBrakeScale()
    state.brakeScaleBar = computeBrakeScale()
end

--------------------------------------------------------------------------------
-- Persistence: Corners (CSV format)
--------------------------------------------------------------------------------

--- Check if two corners overlap
local function cornersOverlap(c1, c2)
    if not c1.startPos or not c1.endPos or not c2.startPos or not c2.endPos then
        return false
    end
    -- Handle wrap-around (corners spanning 0)
    local s1, e1 = c1.startPos, c1.endPos
    local s2, e2 = c2.startPos, c2.endPos
    
    -- Simple overlap check (assumes no wrap-around for simplicity)
    if e1 >= s1 and e2 >= s2 then
        return not (e1 < s2 or e2 < s1)
    end
    -- If one wraps around, consider them potentially overlapping
    return true
end

--- Remove overlapping corners, keeping only distinct ones
local function removeOverlappingCorners(corners)
    local result = {}
    for _, corner in ipairs(corners) do
        local overlaps = false
        for _, existing in ipairs(result) do
            if cornersOverlap(corner, existing) then
                overlaps = true
                break
            end
        end
        if not overlaps then
            table.insert(result, corner)
        end
    end
    return result
end

--- Escape CSV field (handle commas, quotes, newlines)
local function escapeCSV(str)
    if not str then return "" end
    if str:find('[,"\n]') then
        return '"' .. str:gsub('"', '""') .. '"'
    end
    return str
end

--- Parse CSV line into fields
local function parseCSVLine(line)
    local fields = {}
    local field = ""
    local inQuotes = false
    
    for i = 1, #line do
        local c = line:sub(i, i)
        if inQuotes then
            if c == '"' then
                if line:sub(i + 1, i + 1) == '"' then
                    field = field .. '"'
                    -- Skip next quote (handled by loop increment)
                else
                    inQuotes = false
                end
            else
                field = field .. c
            end
        else
            if c == '"' then
                inQuotes = true
            elseif c == ',' then
                table.insert(fields, field)
                field = ""
            else
                field = field .. c
            end
        end
    end
    table.insert(fields, field)
    return fields
end

--- Save corners to per-track CSV file (corners/<track>.csv)
local function saveCornersToFile()
    local path = getCornersPath()
    if not path then
        ac.log("AC Tracer: Cannot save corners - no track path")
        return false
    end
    if not state.trackCorners or #state.trackCorners == 0 then
        ac.log("AC Tracer: Cannot save corners - no corners defined")
        return false
    end

    -- Remove overlapping corners before saving
    state.trackCorners = removeOverlappingCorners(state.trackCorners)

    -- Ensure corners directory exists
    io.createDir(CORNERS_DIR)

    -- Write CSV for this track only
    local f = io.open(path, "w")
    if not f then
        ac.log("AC Tracer: Failed to open " .. path .. " for writing")
        return false
    end

    -- Header (no track column since each file is per-track)
    f:write("name,start,end\n")

    -- Write corners
    for _, corner in ipairs(state.trackCorners) do
        if corner.startPos and corner.endPos then
            local name = corner.name or ("Corner " .. corner.number)
            f:write(string.format("%s,%.6f,%.6f\n",
                escapeCSV(name),
                corner.startPos,
                corner.endPos
            ))
            ac.log(string.format("AC Tracer: Writing corner %d: %s", corner.number, name))
        end
    end

    f:close()
    ac.log("AC Tracer: Saved " .. #state.trackCorners .. " corners to " .. path)
    return true
end

--- Load corners from per-track CSV file (corners/<track>.csv)
local function loadCornersFromFile()
    local path = getCornersPath()
    if not path then return false end

    local f = io.open(path, "r")
    if not f then return false end

    state.trackCorners = {}
    local cornerNum = 0
    local firstLine = true

    for line in f:lines() do
        if firstLine then
            firstLine = false  -- Skip header
        elseif line ~= "" then
            local fields = parseCSVLine(line)
            -- New format: name,start,end (no track column)
            if #fields >= 3 then
                local startPos = tonumber(fields[2])
                local endPos = tonumber(fields[3])

                if startPos and endPos then
                    cornerNum = cornerNum + 1
                    table.insert(state.trackCorners, {
                        number = cornerNum,
                        startPos = startPos,
                        endPos = endPos,
                        name = fields[1] ~= "" and fields[1] or ("Corner " .. cornerNum)
                    })
                end
            end
        end
    end

    f:close()

    if #state.trackCorners > 0 then
        ac.log("AC Tracer: Loaded " .. #state.trackCorners .. " corners from " .. path)
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Persistence: Best Lap
--------------------------------------------------------------------------------

--- Save best lap to ac.storage
local function saveBestLap()
    if not state.bestLap then return end
    
    local key = getStorageKey('bestlap')
    ac.storage[key] = state.bestLap:serialize()
    ac.storage[getStorageKey('bestlap_time')] = tostring(state.bestLap.time)
    ac.log("AC Tracer: Saved best lap to storage")
end

--- Load best lap from ac.storage
local function loadBestLap()
    local key = getStorageKey('bestlap')
    local data = ac.storage[key]
    if not data then return false end
    
    local loaded = lap.deserialize(data)
    if loaded and loaded:length() > 10 then
        state.bestLap = loaded
        ac.log("AC Tracer: Loaded best lap from storage")
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Persistence: History (delegated to history_storage module)
--------------------------------------------------------------------------------

-- History is now managed by history_storage module
-- state.history is a reference to history_storage.laps
local function saveHistory()
    history_storage.save()
end

local function loadHistory()
    local success = history_storage.load()
    -- Update the reference since history_storage.laps may have been reassigned
    state.history = history_storage.laps
    return success
end

-- Auto-Detection: Corners from Best Lap
--------------------------------------------------------------------------------

local function isSteeringCentered(steeringNorm)
    return math.abs(steeringNorm - 0.5) < 0.042  -- ~15°
end

--- Auto-detect corners from a lap's telemetry
---@param lapData table Lap instance
---@return table Array of corner definitions
local function autoDetectCorners(lapData)
    if not lapData or lapData:length() < 30 then return {} end

    -- Detection parameters from centralized config
    local SPEED_DROP_THRESHOLD = settings.speedDropThreshold
    local BRAKE_THRESHOLD = settings.brakeThreshold
    local THROTTLE_ON_THRESHOLD = settings.throttleThreshold
    local LEAD_DISTANCE = 50
    local EXIT_TIME = 2.0
    local EXIT_TIME_THROTTLE_ONLY = 5.0

    local trackLength = ac.getSim().trackLengthM or 5000
    local leadSpline = LEAD_DISTANCE / trackLength

    local corners = {}
    local i = 1
    local cornerNum = 0
    local numSamples = lapData:length()

    while i < numSamples do
        local brake = lapData.brake[i]
        local pos = lapData.pos[i]
        local speed = lapData.speed[i]

        if brake >= BRAKE_THRESHOLD then
            local brakePos = pos
            local entryIdx = i
            local maxSpeedBeforeBrake = speed

            -- Look back for entry point
            local j = i - 1
            while j >= 1 do
                if lapData.speed[j] > maxSpeedBeforeBrake then
                    maxSpeedBeforeBrake = lapData.speed[j]
                end
                local posDiff = brakePos - lapData.pos[j]
                if posDiff < 0 then posDiff = posDiff + 1 end
                if posDiff >= leadSpline then
                    entryIdx = j
                    break
                end
                j = j - 1
            end

            -- Find apex (minimum speed)
            local apexIdx = i
            local apexSpeed = speed
            local k = i + 1
            while k <= numSamples do
                if lapData.speed[k] < apexSpeed then
                    apexSpeed = lapData.speed[k]
                    apexIdx = k
                end
                if lapData.speed[k] > apexSpeed * 1.3 then break end
                k = k + 1
            end

            -- Check if qualifies as corner
            local speedDrop = (maxSpeedBeforeBrake - apexSpeed) / maxSpeedBeforeBrake
            if speedDrop >= SPEED_DROP_THRESHOLD and maxSpeedBeforeBrake > 50 then
                -- Find exit
                local exitIdx = apexIdx
                local exitConditionStart = nil
                local throttleOnlyStart = nil
                local apexTime = (apexIdx - 1) / lap.SAMPLE_RATE

                for m = apexIdx, numSamples do
                    local sTime = (m - 1) / lap.SAMPLE_RATE
                    local sThrottle = lapData.throttle[m]
                    local sSteering = lapData.steering[m]

                    if isSteeringCentered(sSteering) and sThrottle >= THROTTLE_ON_THRESHOLD then
                        if not exitConditionStart then exitConditionStart = sTime end
                        if (sTime - exitConditionStart) >= EXIT_TIME then
                            exitIdx = m
                            break
                        end
                    else
                        exitConditionStart = nil
                    end

                    if sThrottle >= THROTTLE_ON_THRESHOLD then
                        if not throttleOnlyStart then throttleOnlyStart = sTime end
                        if (sTime - throttleOnlyStart) >= EXIT_TIME_THROTTLE_ONLY then
                            exitIdx = m
                            break
                        end
                    else
                        throttleOnlyStart = nil
                    end

                    if (sTime - apexTime) > 15 then
                        exitIdx = m
                        break
                    end
                end

                -- Smart merge check
                local shouldMerge = false
                if #corners > 0 then
                    local prevCorner = corners[#corners]
                    local hadStraight = false
                    for idx = prevCorner.endIdx or 1, entryIdx do
                        if idx <= numSamples then
                            local steering = lapData.steering[idx]
                            local throttle = lapData.throttle[idx]
                            if isSteeringCentered(steering) and throttle >= THROTTLE_ON_THRESHOLD then
                                hadStraight = true
                                break
                            end
                        end
                    end
                    if not hadStraight then
                        shouldMerge = true
                        prevCorner.endIdx = exitIdx
                        prevCorner.endPos = lapData.pos[exitIdx]
                        -- Track apex speed for corner detection quality (not stored in final corner)
                        if apexSpeed < (prevCorner.apexSpeed or 999) then
                            prevCorner.apexSpeed = apexSpeed
                        end
                    end
                end

                if not shouldMerge then
                    cornerNum = cornerNum + 1
                    local name = "Corner " .. cornerNum
                    if ac.getTrackSectorName then
                        local sectorName = ac.getTrackSectorName(lapData.pos[apexIdx])
                        if sectorName and sectorName ~= "" and not sectorName:match("^Sector %d+$") then
                            name = sectorName
                        end
                    end

                    table.insert(corners, {
                        number = cornerNum,
                        startPos = lapData.pos[entryIdx],
                        endPos = lapData.pos[exitIdx],
                        name = name,
                        endIdx = exitIdx,
                        apexSpeed = apexSpeed
                    })
                end

                i = exitIdx + 1
            else
                i = i + 1
            end
        else
            i = i + 1
        end
    end

    -- Clean up internal fields
    for _, c in ipairs(corners) do
        c.endIdx = nil
        c.apexSpeed = nil
    end

    ac.log("AC Tracer: Auto-detected " .. #corners .. " corners from lap")
    return corners
end

-- Track if we've auto-detected for this best lap
local lastAutoDetectLap = nil

--- Update auto-detected corners when best lap changes
local function updateAutoDetectedCorners()
    -- Only auto-detect if no manual corners are defined
    if state.trackCorners and #state.trackCorners > 0 then
        return  -- Manual corners exist, don't overwrite
    end
    
    -- Only auto-detect if we have a best lap
    if not state.bestLap then
        return
    end
    
    -- Only auto-detect once per best lap
    if lastAutoDetectLap == state.bestLap then
        return
    end
    
    lastAutoDetectLap = state.bestLap
    state.trackCorners = autoDetectCorners(state.bestLap)
end

--------------------------------------------------------------------------------
-- Lap Discard Helper (must be before state.init for callback access)
--------------------------------------------------------------------------------

-- Track previous state for detecting resets/teleports
local prevInPit = false
local prevPosition = 0
local prevLapTimeMs = 0
local prevResetCounter = 0

--- Discard current lap and start fresh
local lastDiscardTime = 0
local function discardCurrentLap()
    -- Only log if we haven't discarded in the last second (avoid spam)
    local now = os.clock()
    local shouldLog = (now - lastDiscardTime) > 1.0 and state.currentLap and state.currentLap:length() > 10
    lastDiscardTime = now

    state.currentLap = lap.new(state.track, state.car, state.sessionId)
    state.currentLap.fuelLeftAtStart = ac.getCar(0).fuel or 0
    lap.resetOverlapTracking()  -- Reset overlap detection state

    if shouldLog then
        ac.log("AC Tracer: Discarded current lap (teleport/pit/reset)")
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

--- Initialize state for current session
---@param car table Car state from ac.getCar()
function state.init(car)
    if initialized then return end
    
    -- Seed random for unique session IDs
    math.randomseed(os.time() + os.clock() * 1000)
    
    state.track = ac.getTrackID()
    state.car = car:id()
    
    -- Try to load existing session ID from storage to persist across reloads
    local sim = ac.getSim()
    local sessionKey = getStorageKey('current_session_id')
    local storedSessionId = ac.storage[sessionKey]
    -- Include session index to distinguish between Practice/Qualy/Race in the same event
    local currentTrackCar = state.track .. "_" .. state.car .. "_" .. tostring(sim.currentSessionIndex or 0)
    
    if storedSessionId then
        local parts = {}
        for part in string.gmatch(storedSessionId, "([^|]+)") do
            table.insert(parts, part)
        end
        -- parts[1] = sessionId, parts[2] = track_car_index
        if parts[2] == currentTrackCar then
            state.sessionId = parts[1]
            ac.log("AC Tracer: Resumed session ID " .. state.sessionId .. " for " .. currentTrackCar)
        else
            ac.log("AC Tracer: Stored session ID was for " .. tostring(parts[2]) .. ", but we are now in " .. currentTrackCar)
        end
    end
    
    if not state.sessionId then
        state.sessionId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
        ac.storage[sessionKey] = state.sessionId .. "|" .. currentTrackCar
        ac.log("AC Tracer: Generated new session ID " .. state.sessionId .. " for " .. currentTrackCar)
    end
    
    state.lapNumber = car.lapCount
    state.trackPosition = car.splinePosition
    
    ac.log("AC Tracer: Session ID: " .. state.sessionId)
    
    -- Load corners from file
    loadCornersFromFile()
    
    -- Load best lap and history
    loadBestLap()
    loadHistory()
    
    -- Auto-detect corners if no manual corners and we have a best lap
    updateAutoDetectedCorners()
    
    -- Initialize current lap
    state.currentLap = lap.new(state.track, state.car, state.sessionId)
    state.currentLap.fuelLeftAtStart = car.fuel

    -- Register TimeShift/rewind detection callback
    -- This fires when the car teleports (including during rewind)
    ac.onCarJumped(0, function()
        local now = os.preciseClock()
        local timeSinceLastRewind = now - lastRewindTime
        local car = ac.getCar(0)
        if not car then return end

        -- If enough time has passed since last rewind, this is likely a teleport (pit, reset)
        -- and we should discard the lap. But if it's within the grace period, it's a rewind
        -- and we should prune data instead.
        if timeSinceLastRewind > REWIND_GRACE_PERIOD then
            -- Long gap = new teleport event, discard lap
            discardCurrentLap()
            ac.log("AC Tracer: Car jumped (teleport), discarding lap")
        else
            -- Short gap = rewind in progress
            local carPos = car.splinePosition
            local carLapCount = car.lapCount

            -- Detect rewind past start/finish:
            -- 1. Lap count decremented (most reliable)
            -- 2. Position jumped from <0.2 to >0.8 (backwards over line)
            local lapDecremented = carLapCount < preRewindLapCount
            local positionJumpedBack = preRewindPosition < 0.2 and carPos > 0.8

            if (lapDecremented or positionJumpedBack) and #state.history > 0 then
                -- Pop the most recent lap from history
                local restoredLap = table.remove(state.history, 1)
                history_storage.laps = state.history  -- Keep in sync

                -- Restore it as current lap and prune to current position
                state.currentLap = restoredLap
                state.currentLap.completed = false  -- No longer completed
                local pruned = state.currentLap:pruneToPosition(carPos)

                -- Estimate time offset based on pruned samples (60Hz sample rate)
                -- Also account for the time from the restored lap that was removed
                local estimatedTimeOffset = pruned / lap.SAMPLE_RATE
                if restoredLap.time and restoredLap.time > 0 then
                    -- Add the full lap time that was "un-completed"
                    estimatedTimeOffset = estimatedTimeOffset + (restoredLap.time / 1000)
                end
                state.applyTimeOffset(estimatedTimeOffset)

                -- Update lap count to match
                state.lapNumber = carLapCount

                ac.log(string.format("AC Tracer: Rewind past start/finish (lap %d->%d), restored lap, pruned %d samples to pos %.3f",
                    preRewindLapCount, carLapCount, pruned, carPos))
            elseif state.currentLap then
                -- Normal rewind within the lap
                local pruned = state.currentLap:pruneToPosition(carPos)
                if pruned > 0 then
                    -- Estimate and apply time offset based on pruned samples
                    local estimatedTimeOffset = pruned / lap.SAMPLE_RATE
                    state.applyTimeOffset(estimatedTimeOffset)

                    ac.log(string.format("AC Tracer: Rewind detected, pruned %d samples to pos %.3f",
                        pruned, carPos))
                end
            end
        end

        lastRewindTime = now
    end)

    initialized = true
    ac.log('Traces: State initialized for ' .. state.track)
end

--------------------------------------------------------------------------------
-- Update Loop
--------------------------------------------------------------------------------

--- Update state (call from script.update)
---@param dt number Delta time in seconds
---@param car table Car state from ac.getCar()
function state.update(dt, car)
    if not car then return end

    -- Initialize on first run
    state.init(car)

    local sim = ac.getSim()

    -- Skip if paused or in replay mode (TimeShift rewind)
    if sim.isPaused then return end
    if sim.isReplayActive then
        -- During replay/rewind, track state so we can detect rewind past start/finish
        lastRewindTime = os.preciseClock()
        preRewindLapCount = car.lapCount
        preRewindPosition = car.splinePosition
        return
    end

    -- Update global time tracking
    lastRawDt = dt

    -- Optionally freeze time when car is stationary
    local shouldFreezeTime = car.speedKmh < 1
    if shouldFreezeTime then
        timeFrozen = true
        -- Don't increment sessionTime when frozen
    else
        timeFrozen = false
        sessionTime = sessionTime + dt
    end

    lastUpdateClock = os.preciseClock()

    -- Detect state for teleport/pit checks
    local inPit = car.isInPitlane or car.isInPit
    local resetDetected = (car.resetCounter or 0) > prevResetCounter
    local bigPositionJump = math.abs(car.splinePosition - prevPosition) > 0.3 and prevPosition > 0
    local crossingStartFinish = prevPosition > 0.9 and car.splinePosition < 0.1
    
    -- Check lap completion FIRST (before any discard logic)
    -- This prevents the lap reset from triggering discard when a lap completes normally
    if car.lapCount > state.lapNumber then
        ac.log(string.format("AC Tracer: Lap count changed %d -> %d, currentLap samples: %d",
            state.lapNumber, car.lapCount, state.currentLap and state.currentLap:length() or 0))

        -- Save lap if we have data (lap 0->1 is the out-lap, typically partial)
        if state.currentLap and state.currentLap:length() > 10 then
            -- Finalize completed lap
            state.currentLap.completed = true
            state.currentLap.valid = car.isLastLapValid
            state.currentLap.time = car.previousLapTimeMs
            state.currentLap.lapNumberInSession = state.lapNumber  -- Lap number in this session
            
            -- Add to history (most recent first)
            history_storage.add(state.currentLap)
            state.history = history_storage.laps  -- Update reference
            
            ac.log(string.format("Traces: Lap completed - time: %.3fs, valid: %s, samples: %d, sessionId: %s", 
                state.currentLap.time / 1000, tostring(state.currentLap.valid), state.currentLap:length(),
                tostring(state.currentLap.sessionId)))
            
            -- Update best lap if this is faster and valid
            if state.currentLap.valid and state.currentLap.time > 0 then
                if not state.bestLap or state.currentLap.time < state.bestLap.time then
                    state.bestLap = state.currentLap
                    state.bestLapCorners = state.analyzeCorners(state.currentLap)
                    saveBestLap()
                    updateAutoDetectedCorners()
                    state.updateBrakeScale()
                    ac.log('Traces: New best lap: ' .. (state.currentLap.time / 1000) .. 's')
                end
            end
            
            -- Update brake scale after each completed lap (even if not best)
            state.updateBrakeScale()
        end
        
        -- Reset for new lap
        state.currentLap = lap.new(state.track, state.car, state.sessionId)
        state.currentLap.fuelLeftAtStart = car.fuel
        state.lapNumber = car.lapCount
        lap.resetOverlapTracking()  -- Reset overlap detection state
    end
    
    -- Now check for abnormal discards (teleport, pit entry, session reset)
    -- Only if we didn't just complete a lap (lap number already updated above)
    local lapTimeReset = car.lapTimeMs < prevLapTimeMs - 1000 and car.lapTimeMs < 1000  -- Lap time went backwards significantly
    
    -- Entering pits (wasn't in pit, now in pit)
    if (inPit and not prevInPit) or resetDetected then
        discardCurrentLap()
    end
    
    -- Teleport detection (big position jump without crossing start/finish)
    if bigPositionJump and not crossingStartFinish and not resetDetected then
        discardCurrentLap()
    end
    
    -- Session/lap reset detection: lap time went to 0 but lap count didn't increment
    -- This happens on session restart, ESC to pits, etc.
    if lapTimeReset and car.lapCount == state.lapNumber and not resetDetected then
        discardCurrentLap()
    end
    
    prevInPit = inPit
    prevPosition = car.splinePosition
    prevLapTimeMs = car.lapTimeMs
    prevResetCounter = car.resetCounter or 0
    
    -- Sample at 60 Hz
    sampleTimer = sampleTimer + dt
    if sampleTimer >= 1 / SAMPLE_RATE then
        sampleTimer = sampleTimer - 1 / SAMPLE_RATE
        
        -- Ensure current lap exists
        if not state.currentLap then
            state.currentLap = lap.new(state.track, state.car, state.sessionId)
            state.currentLap.fuelLeftAtStart = car.fuel
        end
        
        -- Add sample if valid (and not in pits) and under max limit
        if car.lapTimeMs > 0 and car.splinePosition >= 0 and not inPit then
            if state.currentLap:length() < MAX_SAMPLES then
                state.currentLap:addSample(car)
            end
        end
    end
    
    -- Update position
    state.trackPosition = car.splinePosition
end

--------------------------------------------------------------------------------
-- Ghost/Best Lap API
--------------------------------------------------------------------------------

--- Get current delta vs best lap
---@return number Delta in seconds (positive = slower)
function state.getDelta()
    if not state.currentLap or not state.bestLap then return 0 end
    return state.currentLap:getDeltaVs(state.bestLap, state.trackPosition)
end

--- Get ghost steering at current position
---@return number|nil Steering in degrees
function state.getGhostSteering()
    if not state.bestLap then return nil end
    return state.bestLap:steeringDegAt(state.trackPosition)
end

--- Get ghost traces for display positions
---@param positions table Array of spline positions
---@return table|nil Traces { throttle={}, brake={}, ... }
function state.getGhostTraces(positions)
    if not state.bestLap then return nil end
    return state.bestLap:getTracesAt(positions)
end

--- Check if we have a best lap
---@return boolean
function state.hasBestLap()
    return state.bestLap ~= nil and state.bestLap:length() > 10
end

--- Get best lap time in seconds
---@return number|nil
function state.getBestLapTime()
    if not state.bestLap then return nil end
    return state.bestLap.time / 1000
end

--- Get best lap data
---@return table|nil
function state.getBestLap()
    return state.bestLap
end

--- Get fastest lap from current session only
---@return table|nil lap, number|nil index
function state.getFastestSessionLap()
    return history_storage.getFastestFromSession(state.sessionId)
end

--- Get laps from current session
---@return table Array of {lap, index} pairs
function state.getCurrentSessionLaps()
    return history_storage.getLapsFromSession(state.sessionId)
end

--- Get laps from previous sessions
---@return table Array of {lap, index} pairs
function state.getPreviousSessionLaps()
    return history_storage.getLapsNotFromSession(state.sessionId)
end

--- Set best lap directly
---@param lapData table Lap instance
function state.setBestLap(lapData)
    state.bestLap = lapData
    state.bestLapCorners = state.analyzeCorners(lapData)
    saveBestLap()
    updateAutoDetectedCorners()
    state.updateBrakeScale()
end

--- Reset best lap
function state.resetBestLap()
    state.bestLap = nil
    state.bestLapCorners = {}
    ac.storage[getStorageKey('bestlap')] = nil
    ac.storage[getStorageKey('bestlap_time')] = nil
    ac.log("AC Tracer: Reset best lap")
end

--- Get ghost value at position (for corner analysis)
---@param field string Field name
---@param pos number Spline position
--- Get ghost time at position
---@param pos number Spline position
---@return number|nil Time in seconds
function state.getGhostTimeAtPos(pos)
    if not state.bestLap then return nil end
    return state.bestLap:getTimeAtPos(pos)
end

--- Get max steering in range from best lap
---@param startPos number
---@param endPos number
---@return number Degrees
function state.getGhostMaxSteeringInRange(startPos, endPos)
    if not state.bestLap then return 0 end
    return state.bestLap:findMaxSteering(startPos, endPos)
end

--- Get brake point in range from best lap
---@param startPos number
---@param endPos number
---@return number|nil
function state.getGhostBrakePointInRange(startPos, endPos)
    if not state.bestLap then return nil end
    return state.bestLap:findBrakePoint(startPos, endPos)
end

--- Get lift-off point in range from best lap
---@param startPos number
---@param endPos number
---@return number|nil
function state.getGhostLiftPointInRange(startPos, endPos)
    if not state.bestLap then return nil end
    return state.bestLap:findLiftPoint(startPos, endPos)
end

--- Get apex (minimum speed point) in range from best lap
---@param startPos number
---@param endPos number
---@return number|nil apexPos
---@return number|nil apexSpeed
function state.getGhostApexInRange(startPos, endPos)
    if not state.bestLap then return nil, nil end
    return state.bestLap:findApex(startPos, endPos)
end

--------------------------------------------------------------------------------
-- Time Management (rewind-aware)
--------------------------------------------------------------------------------

--- Get the current session time (affected by rewinds)
--- This time is continuous and doesn't jump backwards on rewind
---@return number Session time in seconds
function state.time()
    return sessionTime
end

--- Get the last dt value (adjusted for any time corrections)
---@return number Delta time in seconds
function state.dt()
    return lastRawDt
end

--- Check if time is currently frozen
---@return boolean
function state.isTimeFrozen()
    return timeFrozen
end

--- Apply a time offset (used when rewind is detected)
--- This adjusts the session time backwards
---@param offset number Time to subtract (positive = rewind)
function state.applyTimeOffset(offset)
    timeOffset = timeOffset + offset
    sessionTime = math.max(0, sessionTime - offset)
    ac.log(string.format("AC Tracer: Applied time offset %.3fs, new sessionTime: %.3fs", offset, sessionTime))
end

--- Reset time tracking (called on session change or major reset)
function state.resetTime()
    sessionTime = 0
    lastRawDt = 0
    timeOffset = 0
    lastUpdateClock = os.preciseClock()
    timeFrozen = false
    ac.log("AC Tracer: Time tracking reset")
end

--------------------------------------------------------------------------------
-- Corner Management
--------------------------------------------------------------------------------

--- Analyze corners for a lap
---@param lapData table Lap instance
---@return table Corner analysis data
function state.analyzeCorners(lapData)
    if not lapData or not state.trackCorners then return {} end

    local analysis = {}
    for _, corner in ipairs(state.trackCorners) do
        if corner.startPos and corner.endPos then
            -- Find apex dynamically for this lap
            local apexPos, apexSpeed = lapData:findApex(corner.startPos, corner.endPos)
            analysis[corner.number] = {
                entrySpeed = lapData:speedAt(corner.startPos),
                apexPos = apexPos,
                apexSpeed = apexSpeed,
                exitSpeed = lapData:speedAt(corner.endPos),
                brakePos = lapData:findBrakePoint(corner.startPos, corner.endPos, settings.brakeThreshold),
                liftOffPos = lapData:findLiftPoint(corner.startPos, corner.endPos, settings.throttleThreshold),
                maxSteeringDeg = lapData:findMaxSteering(corner.startPos, corner.endPos)
            }
        end
    end
    return analysis
end

--- Get corner at a specific position
---@param pos number Spline position
---@return table|nil Corner definition
function state.getCornerAt(pos)
    for _, c in ipairs(state.trackCorners) do
        -- Skip corners with nil positions (placeholders for numbering)
        if c.startPos and c.endPos then
            local inside
            if c.startPos <= c.endPos then
                inside = pos >= c.startPos and pos <= c.endPos
            else
                inside = pos >= c.startPos or pos <= c.endPos
            end
            if inside then
                return c
            end
        end
    end
    return nil
end

--- Check if position is in a corner
---@param pos number Spline position
---@return number Corner number or 0
function state.isInCorner(pos)
    local c = state.getCornerAt(pos)
    return c and c.number or 0
end

--- Get corner info by number
---@param num number Corner number
---@return table|nil Corner definition
function state.getCornerInfo(num)
    for _, c in ipairs(state.trackCorners) do
        if c.number == num then
            return c
        end
    end
    return nil
end

--- Get corner numbers for array of positions
---@param positions table Array of spline positions
---@return table Array of corner numbers (0 for not in corner)
function state.getCornersForPositions(positions)
    if not positions or #positions < 1 then return nil end
    local result = {}
    for i = 1, #positions do
        result[i] = state.isInCorner(positions[i])
    end
    return result
end

--- Has manual corners defined
---@return boolean
function state.hasCorners()
    return state.trackCorners and #state.trackCorners > 0
end

--- Get corner count
---@return number
function state.getCornerCount()
    return state.trackCorners and #state.trackCorners or 0
end

--- Clear all corners
function state.clearCorners()
    state.trackCorners = {}
    saveCornersToFile()
    ac.log("AC Tracer: Cleared corners")
end

--- Save corners to file
---@return boolean
function state.saveCornersToFile()
    return saveCornersToFile()
end

--- Update a corner's properties
---@param cornerNum number Corner number (1-based)
---@param updates table Fields to update (startPos, endPos, name, etc.)
--- Use false values to clear/skip positions (nil means don't change)
function state.updateCorner(cornerNum, updates)
    for _, corner in ipairs(state.trackCorners) do
        if corner.number == cornerNum then
            -- Handle startPos (false = clear to nil, number = set, nil = no change)
            if updates.startPos == false then
                corner.startPos = nil
            elseif updates.startPos ~= nil then
                corner.startPos = updates.startPos
            end
            -- Handle endPos
            if updates.endPos == false then
                corner.endPos = nil
            elseif updates.endPos ~= nil then
                corner.endPos = updates.endPos
            end
            -- Handle name (empty string = clear)
            if updates.name ~= nil then
                corner.name = (updates.name ~= "") and updates.name or nil
            end
            ac.log(string.format("Traces: Updated corner %d", cornerNum))
            return true
        end
    end
    return false
end

--- Delete a corner by number
---@param cornerNum number Corner number (1-based)
function state.deleteCorner(cornerNum)
    for i, corner in ipairs(state.trackCorners) do
        if corner.number == cornerNum then
            table.remove(state.trackCorners, i)
            -- Renumber remaining corners
            for j = i, #state.trackCorners do
                state.trackCorners[j].number = j
                -- Update default name if it matches old number pattern
                if state.trackCorners[j].name and state.trackCorners[j].name:match("^Corner %d+$") then
                    state.trackCorners[j].name = "Corner " .. j
                end
            end
            ac.log(string.format("Traces: Deleted corner %d", cornerNum))
            saveCornersToFile()
            return true
        end
    end
    return false
end

--- Insert a new corner at position
---@param startPos number Start position (0.0-1.0)
---@param endPos number End position (0.0-1.0)
---@return number Corner number of the new corner
function state.insertCorner(startPos, endPos)
    local newCorner = {
        number = #state.trackCorners + 1,
        startPos = startPos,
        endPos = endPos,
        name = "Corner " .. (#state.trackCorners + 1)
    }

    table.insert(state.trackCorners, newCorner)
    saveCornersToFile()
    ac.log(string.format("Traces: Inserted corner %d at %.2f-%.2f", newCorner.number, startPos, endPos))
    return newCorner.number
end

--------------------------------------------------------------------------------
-- Manual Corner Recording
--------------------------------------------------------------------------------

--- Start recording a corner
---@param pos number Current spline position
function state.startCornerRecording(pos)
    state.cornerRecording = true
    state.cornerRecordStart = pos
    state.cornerRecordTime = os.clock()
end

--- Stop recording a corner
---@param pos number Current spline position
---@return boolean True if corner was recorded (not skipped)
function state.stopCornerRecording(pos)
    if not state.cornerRecording then return false end
    
    local holdDuration = os.clock() - state.cornerRecordTime
    
    if holdDuration < TAP_THRESHOLD then
        -- Tap = skip (add empty corner for numbering)
        table.insert(state.trackCorners, {
            number = #state.trackCorners + 1,
            startPos = nil,
            endPos = nil
        })
        ac.log("AC Tracer: Skipped corner #" .. #state.trackCorners)
    else
        -- Hold = record corner
        local startPos = state.cornerRecordStart
        local endPos = pos

        table.insert(state.trackCorners, {
            number = #state.trackCorners + 1,
            startPos = startPos,
            endPos = endPos
        })
        ac.log("AC Tracer: Recorded corner #" .. #state.trackCorners)
    end

    saveCornersToFile()

    state.cornerRecording = false
    state.cornerRecordStart = nil
    state.cornerRecordTime = nil
    
    return holdDuration >= TAP_THRESHOLD
end

--- Check if currently recording
---@return boolean
function state.isRecordingCorner()
    return state.cornerRecording
end

--------------------------------------------------------------------------------
-- CSV Loading
--------------------------------------------------------------------------------

--- Load lap from CSV (does not add to history - just returns the lap)
---@param filePath string Path to CSV file
---@return table|nil Loaded lap
---@return table|nil warnings Array of warning messages
function state.loadCSV(filePath)
    local trackLength = ac.getSim().trackLengthM
    local loaded, warnings = lap.fromCSV(filePath, state.track, state.car, trackLength)
    if loaded then
        ac.log(string.format("AC Tracer: Loaded CSV lap (%.3fs, %d samples)",
            loaded.time / 1000, loaded:length()))
    end
    return loaded, warnings
end

--- Load CSV and set as reference (best) lap
---@param filePath string Path to CSV file
---@return boolean Success
---@return table|nil warnings Array of warning messages
function state.loadCSVAsBest(filePath)
    local loaded, warnings = state.loadCSV(filePath)
    if loaded then
        state.setBestLap(loaded)
        return true, warnings
    end
    return false, warnings
end

return state
