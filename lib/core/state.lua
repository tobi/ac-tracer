-- state.lua - Centralized game state
-- All state and persistence lives here. Other modules read from state.

local lap = require('lib.lap')
local settings = require('lib.core.settings')
local history_storage = require('lib.core.history')
local notification = require('lib.sound.notification')
local csv_export = require('lib.lap_csv_export')
local file_utils = require('lib.core.files')
local bg_writer = require('lib.core.background_writer')
local paths = require('lib.core.paths')

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

-- Reference lap (the manually selected or loaded comparison target)
state.bestLap = nil            -- lap: the reference lap (from CSV or manual selection)
state.bestLapCorners = {}      -- pre-computed corner analysis for bestLap

-- Best lap from current session only (not loaded from file)
state.bestInSession = nil      -- lap: fastest valid lap driven in this session

-- Best lap from all history (recentBest) - computed on load and lap completion
state.recentBest = nil         -- lap: fastest valid lap across all history

-- Best corners synthetic lap (built from best corner segments across all laps)
-- Cached and rebuilt when history changes or corners change
local bestCornersLap = nil     -- lap: synthetic lap from best corner segments
local bestCornersValid = false -- bool: whether cache is valid

-- Brake scale for charts (computed from max brake across relevant laps)
state.brakeScaleBar = 100      -- number: max bar value for brake charts (90 or 100)

-- Manual corner recording
state.cornerRecording = false
state.cornerRecordStart = nil
state.cornerRecordTime = nil

-- Checkpoint stack system (session-only, not persisted)
local checkpointStack = {}         -- Array of checkpoint entries, index 1 = most recent
local MAX_CHECKPOINTS = 20
local checkpointDriveTimer = 0     -- Seconds driving since last checkpoint load
local currentCheckpointMarker = nil -- Index of last-loaded checkpoint (bookmark into stack)
local CHECKPOINT_REPEAT_TIME = 1   -- Seconds within which a press is considered "repeat" (cycle)
local checkpointCallbacks = {}  -- Callbacks to notify on checkpoint load
local isLoadingCheckpoint = false  -- Flag to prevent onCarJumped from discarding lap during our restore
local lastCheckpointLoadTime = 0  -- Time when checkpoint was last loaded (for grace period)

-- Auto-checkpoint positions (computed from corners + bestLap)
local autoCheckpointPositions = nil  -- nil = needs recompute
local checkpointPrevPos = nil        -- Previous spline position for crossing detection

-- Lap time offset (corrects for AC not restoring lapTimeMs on teleport)
-- After checkpoint load: correctedTime = car.lapTimeMs - lapTimeOffset
local lapTimeOffset = 0

--------------------------------------------------------------------------------
-- Brake Beep System
--------------------------------------------------------------------------------

-- Beep countdown state
local brakeBeep = {
    nextBrakePos = nil,      -- Position of next brakepoint (0-1)
    lastBrakePos = nil,      -- Last brakepoint we processed (to avoid repeating)
    beepIndex = 0,           -- Which beep in countdown (0 = not started, 1-4 = beeps)
    lastBeepTime = 0,        -- Time of last beep (to prevent spam)
    beepPositions = {},      -- Positions for each beep trigger (calculated from ref lap)
    prevPos = nil,           -- Previous car position for robust crossing detection
}

-- Countdown interval (seconds before brakepoint, using ref lap timing)
-- 4 sounds: sound_1 at 1.5s, sound_2 at 1.0s, sound_3 at 0.5s, sound_4 at brakepoint (0s)
local BEEP_INTERVAL = 0.5  -- 0.5s between each beep
local BEEP_OFFSETS = { 1.5, 1.0, 0.5, 0 }  -- Time before brake point for each sound

--- Check if a position is inside a corner
---@param pos number Spline position (0-1)
---@param corners table Array of corner definitions
---@return table|nil Corner definition if inside, nil if not
local function getCornerAtPosition(pos, corners)
    if not corners then return nil end
    for _, c in ipairs(corners) do
        if c.startPos and c.endPos then
            local inside
            if c.startPos <= c.endPos then
                inside = pos >= c.startPos and pos <= c.endPos
            else
                -- Handle wrap-around corners
                inside = pos >= c.startPos or pos <= c.endPos
            end
            if inside then return c end
        end
    end
    return nil
end

--- Find the brakepoint (initial pedal application) inside each corner from a lap
--- Uses confirm-then-walkback: finds heavy braking, then walks back to first touch
--- Returns a sorted list of brakepoints with precomputed beep trigger positions
---@param lapData table Lap instance
---@param corners table Array of corner definitions
---@return table Array of {pos, cornerNum, beepPositions} sorted by position
local function findCornerBrakepoints(lapData, corners)
    if not lapData or lapData:length() < 10 then return {} end
    if not corners or #corners == 0 then return {} end

    -- Step 1: Find max brake pressure in each corner
    local cornerMaxBrake = {}  -- cornerNum -> max brake pressure
    for i = 1, lapData:length() do
        local brake = lapData.brake[i] or 0
        local pos = lapData.pos[i]
        if not pos then goto continue_max end

        local corner = getCornerAtPosition(pos, corners)
        if corner then
            local num = corner.number
            if not cornerMaxBrake[num] or brake > cornerMaxBrake[num] then
                cornerMaxBrake[num] = brake
            end
        end

        ::continue_max::
    end

    -- Step 2: Find where brake pressure first exceeds confirmation threshold in each corner
    -- Then walk back to find true initiation (first touch > 0.1 bar)
    local HEAVY_BRAKE_RATIO = 0.50  -- 50% of max brake pressure
    local MIN_BRAKE_THRESHOLD = settings.brakeThreshold()  -- Minimum to count as braking at all
    local ABSOLUTE_BRAKE_THRESHOLD = 20  -- Absolute minimum in bar (for race cars with high brake pressure)

    local cornerBrakepoints = {}  -- cornerNum -> {idx, pos} of brakepoint
    local wasUnderThreshold = {}  -- cornerNum -> was under threshold last sample

    for i = 1, lapData:length() do
        local brake = lapData.brake[i] or 0
        local pos = lapData.pos[i]
        if not pos then goto continue_find end

        local corner = getCornerAtPosition(pos, corners)
        if corner then
            local num = corner.number
            local maxBrake = cornerMaxBrake[num] or 0
            -- Heavy braking threshold: 50% of max, but at least the higher of MIN_BRAKE_THRESHOLD or ABSOLUTE_BRAKE_THRESHOLD
            local heavyThreshold = math.max(maxBrake * HEAVY_BRAKE_RATIO, math.max(MIN_BRAKE_THRESHOLD, ABSOLUTE_BRAKE_THRESHOLD))

            -- Initialize tracking for this corner
            if wasUnderThreshold[num] == nil then
                wasUnderThreshold[num] = true
            end

            if brake < heavyThreshold then
                wasUnderThreshold[num] = true
            elseif wasUnderThreshold[num] and brake >= heavyThreshold then
                -- First heavy brake application detected (confirmation point)
                wasUnderThreshold[num] = false

                -- Only record if we haven't recorded this corner yet
                if not cornerBrakepoints[num] then
                    -- Walk back to find true initiation (first touch > 0.1 bar)
                    local initiationIdx = i
                    for j = i - 1, 1, -1 do
                        if (lapData.brake[j] or 0) <= lap.BRAKE_INITIATION_BAR then
                            break  -- Found where pedal wasn't touched
                        end
                        initiationIdx = j
                    end
                    cornerBrakepoints[num] = lapData.pos[initiationIdx]
                end
            end
        end

        ::continue_find::
    end

    -- Convert to sorted array and precompute beep trigger positions
    local result = {}
    for cornerNum, brakePos in pairs(cornerBrakepoints) do
        local entry = {
            pos = brakePos,
            cornerNum = cornerNum,
            beepPositions = {},  -- Precomputed trigger positions for countdown sounds
        }

        -- Calculate beep positions based on ref lap timing
        local brakeTime = lapData:getTimeAtPos(brakePos)
        if brakeTime then
            for i, offset in ipairs(BEEP_OFFSETS) do
                if offset == 0 then
                    -- For the final beep (offset 0), use exact brake position
                    -- to avoid interpolation round-trip errors
                    entry.beepPositions[i] = brakePos
                else
                    local triggerTime = brakeTime - offset
                    if triggerTime >= 0 then
                        entry.beepPositions[i] = lapData:getPosAtTime(triggerTime)
                    end
                end
            end
        end
        table.insert(result, entry)
    end
    table.sort(result, function(a, b) return a.pos < b.pos end)

    return result
end

-- Cache for corner brakepoints (recalculated when lap or corners change)
local cachedBrakepoints = nil
local cachedBrakepointsLap = nil
local cachedBrakepointsCorners = nil

--- Invalidate brakepoint cache (called when corners change)
local function invalidateBrakepointCache()
    cachedBrakepoints = nil
    cachedBrakepointsLap = nil
    cachedBrakepointsCorners = nil
end

--- Ensure brakepoint cache is up to date
---@param lapData table Lap instance
local function ensureBrakepointCache(lapData)
    if not lapData or lapData:length() < 10 then
        cachedBrakepoints = {}
        return
    end

    -- Recalculate if lap or corners changed
    if cachedBrakepointsLap ~= lapData or cachedBrakepointsCorners ~= state.trackCorners then
        cachedBrakepoints = findCornerBrakepoints(lapData, state.trackCorners)
        cachedBrakepointsLap = lapData
        cachedBrakepointsCorners = state.trackCorners
    end
end

--- Find the next brakepoint from a lap after the given position
---@param lapData table Lap instance
---@param currentPos number Current spline position (0-1)
---@return table|nil Brakepoint entry {pos, cornerNum, beepPositions}, or nil if not found
local function findNextBrakepoint(lapData, currentPos)
    ensureBrakepointCache(lapData)

    if not cachedBrakepoints or #cachedBrakepoints == 0 then return nil end

    -- Find the next brakepoint ahead of current position
    local best = nil
    local bestDistance = 2  -- > 1 means we haven't found anything

    for _, bp in ipairs(cachedBrakepoints) do
        local distance = bp.pos - currentPos
        if distance < 0 then distance = distance + 1 end

        -- Only consider brakepoints ahead of us (small buffer to avoid the one we just passed)
        if distance > 0.005 and distance < bestDistance then
            bestDistance = distance
            best = bp
        end
    end

    return best
end

--- Check if a target position was crossed from prevPos to currentPos.
--- Handles wrap-around at start/finish.
---@param prevPos number|nil
---@param currentPos number
---@param targetPos number
---@return boolean
local function hasCrossedPosition(prevPos, currentPos, targetPos)
    if not prevPos then return false end
    if prevPos <= currentPos then
        return targetPos > prevPos and targetPos <= currentPos
    else
        -- Wrapped around 1.0 -> 0.0
        return targetPos > prevPos or targetPos <= currentPos
    end
end

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SAMPLE_RATE = lap.SAMPLE_RATE
local TAP_THRESHOLD = 1.0
local MAX_SAMPLES = 30000  -- ~10 minutes at 50Hz

-- state.history is a reference to history_storage.laps
state.history = history_storage.laps

-- Timing
local sampleTimer = 0
local initialized = false

--------------------------------------------------------------------------------
-- Storage Keys
--------------------------------------------------------------------------------

local function getStorageKey(suffix)
    local trackId = state.track or 'unknown'
    return 'ac_tracer_' .. trackId:gsub("[/\\:]", "_") .. '_' .. suffix
end

--- Get corner CSV path for current track (new unified location)
local function getCornersPath()
    if not state.track then return nil end
    return paths.cornersFile(state.track)
end

--- Get old corner CSV path for migration
local function getOldCornersPath()
    if not state.track then return nil end
    return __dirname .. "/corners/" .. state.track:gsub("[/\\:]", "_") .. ".csv"
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
-- Comparison Lap System
--------------------------------------------------------------------------------

--- Update recentBest from history (call after history changes)
local function updateRecentBest()
    local fastest = nil
    for _, lapData in ipairs(state.history) do
        if lapData.valid and lapData.time and lapData.time > 0 then
            if not fastest or lapData.time < fastest.time then
                fastest = lapData
            end
        end
    end
    state.recentBest = fastest
end

--- Invalidate bestCorners cache (call when history or corners change)
function state.invalidateBestCorners()
    bestCornersValid = false
    bestCornersLap = nil
end

--- Build the best corners synthetic lap from best corner segments
--- Excludes the reference lap so you can compare against truly different data
---@return table|nil Synthetic lap or nil if not enough data
local function buildBestCornersLap()
    if not state.trackCorners or #state.trackCorners == 0 then
        return nil
    end
    
    -- Need at least 2 completed laps (excluding reference) to build best corners
    local candidateLaps = {}
    for _, lapData in ipairs(state.history) do
        if lapData.valid and lapData.time and lapData.time > 0 and lapData ~= state.bestLap then
            table.insert(candidateLaps, lapData)
        end
    end
    
    if #candidateLaps < 1 then
        return nil
    end
    
    -- For each corner, find the lap with the fastest corner time
    local bestCornerLaps = {}  -- cornerNum -> {lap, cornerTime}
    
    for _, corner in ipairs(state.trackCorners) do
        if corner.startPos and corner.endPos then
            local bestTime = nil
            local bestLapForCorner = nil
            
            for _, lapData in ipairs(candidateLaps) do
                -- Calculate corner time for this lap
                local entryTime = lapData:getTimeAtPos(corner.startPos)
                local exitTime = lapData:getTimeAtPos(corner.endPos)
                
                if entryTime and exitTime then
                    local cornerTime = exitTime - entryTime
                    if cornerTime > 0 and (not bestTime or cornerTime < bestTime) then
                        bestTime = cornerTime
                        bestLapForCorner = lapData
                    end
                end
            end
            
            if bestLapForCorner then
                bestCornerLaps[corner.number] = {
                    lap = bestLapForCorner,
                    cornerTime = bestTime,
                    startPos = corner.startPos,
                    endPos = corner.endPos
                }
            end
        end
    end
    
    -- Build synthetic lap by splicing together best corner segments
    -- For positions not in a corner, use the overall fastest lap (recentBest)
    local baseLap = state.recentBest or candidateLaps[1]
    if not baseLap then return nil end
    
    -- Create a new lap structure
    local synthetic = lap.new(state.track, state.car, "synthetic_best_corners")
    synthetic.time = 0  -- Will be computed
    synthetic.valid = true
    synthetic.completed = true
    
    -- Sample at the same rate as the base lap
    local numSamples = baseLap:length()
    if numSamples < 10 then return nil end
    
    -- For each sample, determine which lap to use based on position
    for i = 1, numSamples do
        local pos = baseLap.pos[i]
        if not pos then goto continue end
        
        -- Find which corner (if any) this position is in
        local cornerNum = nil
        for _, corner in ipairs(state.trackCorners) do
            if corner.startPos and corner.endPos then
                local inside
                if corner.startPos <= corner.endPos then
                    inside = pos >= corner.startPos and pos <= corner.endPos
                else
                    inside = pos >= corner.startPos or pos <= corner.endPos
                end
                if inside then
                    cornerNum = corner.number
                    break
                end
            end
        end
        
        -- Get the source lap for this sample
        local sourceLap = baseLap
        if cornerNum and bestCornerLaps[cornerNum] then
            sourceLap = bestCornerLaps[cornerNum].lap
        end
        
        -- Copy data from source lap at this position
        table.insert(synthetic.throttle, sourceLap:throttleAt(pos))
        table.insert(synthetic.brake, sourceLap:brakeAt(pos))
        table.insert(synthetic.brake_r, sourceLap:brakeRearAt(pos))
        table.insert(synthetic.clutch, sourceLap:clutchAt(pos))
        table.insert(synthetic.steering, sourceLap:steeringAt(pos))
        table.insert(synthetic.speed, sourceLap:speedAt(pos))
        table.insert(synthetic.gear, math.floor(sourceLap:gearAt(pos) + 0.5))
        table.insert(synthetic.pos, pos)
        table.insert(synthetic.times, sourceLap:getTimeAtPos(pos) or (i / lap.SAMPLE_RATE))
        table.insert(synthetic.flags, 0)  -- No flags for synthetic lap
        
        ::continue::
    end
    
    -- Compute total time from times array
    if #synthetic.times > 1 then
        synthetic.time = (synthetic.times[#synthetic.times] - synthetic.times[1]) * 1000
    end
    
    ac.log(string.format("AC Tracer: Built best corners lap with %d samples, %.3fs",
        synthetic:length(), synthetic.time / 1000))
    
    return synthetic
end

--- Get the best corners lap (cached, rebuilt if invalid)
---@return table|nil Synthetic lap
function state.getBestCornersLap()
    if not bestCornersValid then
        bestCornersLap = buildBestCornersLap()
        bestCornersValid = true
    end
    return bestCornersLap
end

--- Get the current comparison lap based on comparison mode
--- This is what traces, delta bar, and corner analysis compare against
---@return table|nil The lap to compare against
function state.getComparisonLap()
    local mode = settings.comparisonMode()
    
    if mode == "off" then
        return nil
    elseif mode == "sessionBest" then
        return state.bestInSession
    elseif mode == "recentBest" then
        return state.recentBest
    elseif mode == "bestCorners" then
        return state.getBestCornersLap()
    else  -- "reference" (default)
        return state.bestLap
    end
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
    local i = 1
    
    while i <= #line do
        local c = line:sub(i, i)
        if inQuotes then
            if c == '"' then
                if line:sub(i + 1, i + 1) == '"' then
                    field = field .. '"'
                    i = i + 2  -- Skip both quotes
                else
                    inQuotes = false
                    i = i + 1
                end
            else
                field = field .. c
                i = i + 1
            end
        else
            if c == '"' then
                inQuotes = true
                i = i + 1
            elseif c == ',' then
                table.insert(fields, field)
                field = ""
                i = i + 1
            else
                field = field .. c
                i = i + 1
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

    -- Ensure track directory exists
    paths.ensureTrackDir(state.track)

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
    invalidateBrakepointCache()  -- Corners changed, recalculate brakepoints
    state.invalidateAutoCheckpoints()  -- Corners changed, recalculate auto-checkpoint positions
    return true
end

--- Migrate corners from old location (__dirname/corners/) to new (data/{track}/)
local function migrateCornersIfNeeded()
    local oldPath = getOldCornersPath()
    local newPath = getCornersPath()
    if not oldPath or not newPath then return end

    local fOld = io.open(oldPath, "r")
    if not fOld then return end

    -- Check if new path already exists
    local fNew = io.open(newPath, "r")
    if fNew then
        fNew:close()
        fOld:close()
        return  -- Already migrated
    end

    local content = fOld:read("*a")
    fOld:close()

    if content and #content > 0 then
        paths.ensureTrackDir(state.track)
        local out = io.open(newPath, "w")
        if out then
            out:write(content)
            out:close()
            ac.log("AC Tracer: Migrated corners from " .. oldPath .. " to " .. newPath)
        end
    end
end

--- Load corners from per-track CSV file (data/{track}/corners.csv)
local function loadCornersFromFile()
    local path = getCornersPath()
    if not path then return false end

    -- Try migration from old location first
    migrateCornersIfNeeded()

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
        invalidateBrakepointCache()  -- Corners loaded, recalculate brakepoints
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

--- Auto-load fastest lap from the references folder for the current track/car
--- Called on session init when no best lap was restored from storage
local function loadFastestReferenceFromDisk()
    if not state.track or not state.car then return false end

    local refsDir = paths.referencesDir(state.track, state.car)
    if not io.dirExists(refsDir) then return false end

    local files = io.scanDir(refsDir, "*.csv")
    if not files or #files == 0 then return false end

    -- Pick the fastest by parsed lap time from filename
    local bestPath, bestTime = nil, nil
    for _, filename in ipairs(files) do
        local ms = file_utils.parseLapTimeFromFilename(filename)
        if ms and (not bestTime or ms < bestTime) then
            bestTime = ms
            bestPath = refsDir .. filename
        end
    end

    -- Fallback: if nothing had a parseable time, just use the first file
    if not bestPath then
        bestPath = refsDir .. files[1]
    end

    local trackLength = ac.getSim().trackLengthM
    local loaded = lap.fromCSV(bestPath, state.track, state.car, trackLength)
    if loaded and loaded:length() > 10 then
        state.bestLap = loaded
        ac.log("AC Tracer: Auto-loaded fastest reference: " .. bestPath)
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Persistence: History (delegated to history_storage module)
--------------------------------------------------------------------------------

-- History is now session-only in-memory (past laps live on disk as CSV)
-- state.history is a reference to history_storage.laps

-- Auto-Detection: Corners from Best Lap
--------------------------------------------------------------------------------

local function isSteeringCentered(steeringNorm)
    return math.abs(steeringNorm - 0.5) < 0.042  -- ~15°
end

--- Auto-detect corners from a lap's telemetry
--- Detects both braking zones AND lift-off corners with lateral G
---@param lapData table Lap instance
---@return table Array of corner definitions
local function autoDetectCorners(lapData)
    if not lapData or lapData:length() < 30 then return {} end

    -- Detection parameters from centralized config
    local SPEED_DROP_THRESHOLD = settings.speedDropThreshold()
    local BRAKE_THRESHOLD = settings.brakeThreshold()
    local THROTTLE_ON_THRESHOLD = settings.throttleThreshold()
    local LEAD_DISTANCE = 50
    local EXIT_TIME = 0.3           -- Short exit - detect more corners
    local EXIT_TIME_THROTTLE_ONLY = 0.8  -- Short throttle-only exit
    
    -- Lift-off corner detection parameters
    local LIFT_THROTTLE_THRESHOLD = 0.7  -- Throttle below this = lifting
    local LIFT_LAT_G_THRESHOLD = 0.5     -- Minimum lateral G to qualify as corner (lowered from 0.8)
    local LIFT_DURATION_MIN = 0.2        -- Minimum lift duration in seconds (lowered from 0.3)

    local trackLength = ac.getSim().trackLengthM or 5000
    local leadSpline = LEAD_DISTANCE / trackLength

    local corners = {}
    local i = 1
    local numSamples = lapData:length()
    
    -- Helper to check if position is inside any existing corner
    local function isInsideCorner(pos)
        for _, c in ipairs(corners) do
            if c.startPos <= c.endPos then
                if pos >= c.startPos and pos <= c.endPos then return true end
            else
                -- Handle wrap-around
                if pos >= c.startPos or pos <= c.endPos then return true end
            end
        end
        return false
    end
    
    -- Helper to find exit point from a given index
    local function findExitIdx(startIdx, apexIdx)
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
                    return m
                end
            else
                exitConditionStart = nil
            end

            if sThrottle >= THROTTLE_ON_THRESHOLD then
                if not throttleOnlyStart then throttleOnlyStart = sTime end
                if (sTime - throttleOnlyStart) >= EXIT_TIME_THROTTLE_ONLY then
                    return m
                end
            else
                throttleOnlyStart = nil
            end

            if (sTime - apexTime) > 15 then
                return m
            end
        end
        return exitIdx
    end
    
    -- Helper to get lateral G at index
    local function getLatG(idx)
        if lapData.gforce and lapData.gforce[idx] then
            return math.abs(lapData.gforce[idx].x)
        end
        return 0
    end

    -- Pass 1: Detect braking zones
    while i < numSamples do
        local brake = lapData.brake[i]
        local pos = lapData.pos[i]
        local speed = lapData.speed[i]

        if brake >= BRAKE_THRESHOLD then
            -- Found confirmation point, now walk back to find true initiation (> 0.1 bar)
            local initiationIdx = i
            for j = i - 1, 1, -1 do
                if (lapData.brake[j] or 0) <= lap.BRAKE_INITIATION_BAR then
                    break  -- Found where pedal wasn't touched
                end
                initiationIdx = j
            end

            local brakePos = lapData.pos[initiationIdx]
            local entryIdx = initiationIdx
            local maxSpeedBeforeBrake = lapData.speed[initiationIdx] or speed

            -- Look back for entry point (from initiation, not confirmation)
            local j = initiationIdx - 1
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
                local exitIdx = findExitIdx(entryIdx, apexIdx)

                table.insert(corners, {
                    startPos = lapData.pos[entryIdx],
                    endPos = lapData.pos[exitIdx],
                    endIdx = exitIdx,
                    apexSpeed = apexSpeed,
                    type = "brake"
                })

                i = exitIdx + 1
            else
                i = i + 1
            end
        else
            i = i + 1
        end
    end

    -- Pass 2: Detect lift-off corners (throttle lift + lateral G)
    -- Only if we have g-force data
    if lapData.gforce and #lapData.gforce > 0 then
        i = 1
        while i < numSamples do
            local throttle = lapData.throttle[i]
            local latG = getLatG(i)
            local pos = lapData.pos[i]
            
            -- Check for lift with significant lateral G, not already in a corner
            if throttle < LIFT_THROTTLE_THRESHOLD and latG >= LIFT_LAT_G_THRESHOLD and not isInsideCorner(pos) then
                local liftStartIdx = i
                local liftStartTime = (i - 1) / lap.SAMPLE_RATE
                
                -- Find apex (minimum speed during lift)
                local apexIdx = i
                local apexSpeed = lapData.speed[i]
                local maxLatG = latG
                local liftEndIdx = i
                
                -- Scan forward while lifting or turning
                local k = i + 1
                while k <= numSamples do
                    local kThrottle = lapData.throttle[k]
                    local kLatG = getLatG(k)
                    local kTime = (k - 1) / lap.SAMPLE_RATE
                    
                    -- Still in corner if throttle < threshold OR significant lateral G
                    if kThrottle < LIFT_THROTTLE_THRESHOLD or kLatG >= LIFT_LAT_G_THRESHOLD * 0.5 then
                        if lapData.speed[k] < apexSpeed then
                            apexSpeed = lapData.speed[k]
                            apexIdx = k
                        end
                        if kLatG > maxLatG then
                            maxLatG = kLatG
                        end
                        liftEndIdx = k
                        k = k + 1
                    else
                        break
                    end
                end
                
                local liftDuration = (liftEndIdx - liftStartIdx) / lap.SAMPLE_RATE
                
                -- Qualify if sustained lift with good lateral G
                if liftDuration >= LIFT_DURATION_MIN and maxLatG >= LIFT_LAT_G_THRESHOLD then
                    -- Look back for entry point
                    local entryIdx = liftStartIdx
                    local maxSpeedBefore = lapData.speed[liftStartIdx]
                    local j = liftStartIdx - 1
                    while j >= 1 do
                        if lapData.speed[j] > maxSpeedBefore then
                            maxSpeedBefore = lapData.speed[j]
                        end
                        local posDiff = lapData.pos[liftStartIdx] - lapData.pos[j]
                        if posDiff < 0 then posDiff = posDiff + 1 end
                        if posDiff >= leadSpline then
                            entryIdx = j
                            break
                        end
                        j = j - 1
                    end
                    
                    local exitIdx = findExitIdx(entryIdx, apexIdx)
                    
                    -- Only add if not overlapping with existing corners
                    local startPos = lapData.pos[entryIdx]
                    local endPos = lapData.pos[exitIdx]
                    if not isInsideCorner(startPos) and not isInsideCorner(endPos) then
                        table.insert(corners, {
                            startPos = startPos,
                            endPos = endPos,
                            endIdx = exitIdx,
                            apexSpeed = apexSpeed,
                            type = "lift"
                        })
                    end
                    
                    i = liftEndIdx + 1
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    
    -- Sort corners by start position
    table.sort(corners, function(a, b) return a.startPos < b.startPos end)
    
    -- Assign corner numbers and names
    for idx, c in ipairs(corners) do
        c.number = idx
        local name = "Corner " .. idx
        if ac.getTrackSectorName then
            -- Find apex position for sector name lookup
            local apexPos = (c.startPos + c.endPos) / 2
            if c.endPos < c.startPos then
                apexPos = c.startPos + (c.endPos + 1 - c.startPos) / 2
                if apexPos > 1 then apexPos = apexPos - 1 end
            end
            local sectorName = ac.getTrackSectorName(apexPos)
            if sectorName and sectorName ~= "" and not sectorName:match("^Sector %d+$") then
                name = sectorName
            end
        end
        c.name = name
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
    
    -- Set track/car for history storage (must be before loading)
    history_storage.setTrackCar(state.track, state.car)
    
    -- Load corners from file
    loadCornersFromFile()
    
    -- Load best lap from ac.storage (fast restore cache)
    -- If none cached, fall back to the fastest CSV in the references folder
    if not loadBestLap() then
        loadFastestReferenceFromDisk()
    end
    -- History is session-only now (past laps live on disk as CSV)
    state.history = history_storage.laps
    
    -- Auto-detect corners if no manual corners and we have a best lap
    updateAutoDetectedCorners()
    
    -- Initialize current lap
    state.currentLap = lap.new(state.track, state.car, state.sessionId)
    state.currentLap.fuelLeftAtStart = car.fuel

    -- Register car jump callback
    -- This fires when the car teleports (pit entry, reset, ESC to pits, etc.)
    -- Skip if this is our own checkpoint restore
    ac.onCarJumped(0, function()
        -- Skip if we're in the process of loading a checkpoint
        -- Use a time-based grace period since the callback might fire slightly after
        local now = os.preciseClock()
        if isLoadingCheckpoint or (now - lastCheckpointLoadTime) < 0.5 then
            ac.log("AC Tracer: Car jumped during checkpoint load - ignoring")
            return
        end

        -- Any external jump should discard current lap
        discardCurrentLap()
        ac.log("AC Tracer: Car jumped (teleport/reset), discarding lap")
    end)

    -- Initialize notification sounds
    notification.init()

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

    -- Skip if paused or in replay mode
    if sim.isPaused or sim.isReplayActive then return end

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
            
            -- Update recentBest and invalidate bestCorners cache
            updateRecentBest()
            state.invalidateBestCorners()
            
            ac.log(string.format("Traces: Lap completed - time: %.3fs, valid: %s, samples: %d, sessionId: %s", 
                state.currentLap.time / 1000, tostring(state.currentLap.valid), state.currentLap:length(),
                tostring(state.currentLap.sessionId)))
            
            -- Update best lap if this is faster and valid
            if state.currentLap.valid and state.currentLap.time > 0 then
                -- Update bestInSession (session-only best, never from file)
                if not state.bestInSession or state.currentLap.time < state.bestInSession.time then
                    state.bestInSession = state.currentLap
                    ac.log('Traces: New best in session: ' .. (state.currentLap.time / 1000) .. 's')
                end
                
                -- Update overall bestLap if this is faster
                if not state.bestLap or state.currentLap.time < state.bestLap.time then
                    state.bestLap = state.currentLap
                    state.bestLapCorners = state.analyzeCorners(state.currentLap)
                    saveBestLap()
                    updateAutoDetectedCorners()
                    state.updateBrakeScale()
                    state.invalidateAutoCheckpoints()
                    ac.log('Traces: New best lap: ' .. (state.currentLap.time / 1000) .. 's')
                end
            end
            
            -- Update brake scale after each completed lap (even if not best)
            state.updateBrakeScale()
            
            -- Auto-save to laps/ directory if enabled (non-blocking background write)
            if settings.autoSaveEnabled() then
                bg_writer.queueLapSave(state.currentLap, {
                    includeJSON = settings.autoSaveIncludeMD(),
                    referenceLap = state.bestLap,
                    trackCorners = state.trackCorners or {},
                })
            end
        end
        
        -- Reset for new lap
        state.currentLap = lap.new(state.track, state.car, state.sessionId)
        state.currentLap.fuelLeftAtStart = car.fuel
        state.lapNumber = car.lapCount
        lap.resetOverlapTracking()  -- Reset overlap detection state
        lapTimeOffset = 0  -- Reset time offset for new lap

        -- Auto-save a checkpoint at start/finish (silent, pushes to stack)
        state.saveCheckpoint(nil, false)
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
    
    -- Sample at configured rate (default 30 Hz)
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
                -- Pass time offset for checkpoint restore correction
                state.currentLap:addSample(car, lapTimeOffset)
            end
        end
    end
    
    -- Update position
    state.trackPosition = car.splinePosition
    
    -- Checkpoint stack: update drive timer and check auto-checkpoint positions
    -- NOTE: prevPosition was already updated to car.splinePosition above (line ~1343),
    -- so we use the saved previous value captured before that update.
    state.updateCheckpointDriveTimer(dt)
    if checkpointPrevPos then
        state.checkAutoCheckpoints(checkpointPrevPos, car.splinePosition, car, nil)
    end
    checkpointPrevPos = car.splinePosition

    -- Brake beep system (uses comparison lap for position-based triggers)
    local brakeBeepEnabled = settings.brakeBeepMode() == "on"
    local beepLap = state.getComparisonLap()
    if brakeBeepEnabled and car.speedKmh > 30 and beepLap and beepLap:length() > 10 then
        local currentPos = car.splinePosition
        local prevPos = brakeBeep.prevPos
        -- Prime initial target if needed.
        if not brakeBeep.nextBrakePos then
            local nextBp = findNextBrakepoint(beepLap, currentPos)
            brakeBeep.nextBrakePos = nextBp and nextBp.pos or nil
            brakeBeep.beepPositions = nextBp and nextBp.beepPositions or {}
            brakeBeep.beepIndex = 0
        end

        -- Check position-based triggers (beep when we cross each trigger position)
        if brakeBeep.nextBrakePos and brakeBeep.beepPositions then
            local now = os.clock()
            for i = 1, 4 do
                local triggerPos = brakeBeep.beepPositions[i]
                if triggerPos and brakeBeep.beepIndex < i then
                    -- Trigger only when we actually cross the trigger position this frame.
                    if hasCrossedPosition(prevPos, currentPos, triggerPos) then
                        -- Time check to prevent double-beeps
                        if (now - brakeBeep.lastBeepTime) > 0.1 then
                            notification.playCountdownSound(i)
                            brakeBeep.beepIndex = i
                            brakeBeep.lastBeepTime = now
                        end
                        break
                    end
                end
            end
        end

        -- After processing triggers, advance to next brakepoint if we've passed current one.
        if brakeBeep.nextBrakePos then
            local distToBrake = brakeBeep.nextBrakePos - currentPos
            if distToBrake < 0 then distToBrake = distToBrake + 1 end
            local crossedBrakepoint = hasCrossedPosition(prevPos, currentPos, brakeBeep.nextBrakePos)
            if distToBrake > 0.5 or crossedBrakepoint then
                brakeBeep.lastBrakePos = brakeBeep.nextBrakePos
                local nextBp = findNextBrakepoint(beepLap, currentPos)
                brakeBeep.nextBrakePos = nextBp and nextBp.pos or nil
                brakeBeep.beepPositions = nextBp and nextBp.beepPositions or {}
                brakeBeep.beepIndex = 0
            end
        end
        brakeBeep.prevPos = currentPos
    else
        -- Reset beep state when disabled or car is slow
        brakeBeep.nextBrakePos = nil
        brakeBeep.beepIndex = 0
        brakeBeep.beepPositions = {}
        brakeBeep.prevPos = nil
    end
    
    -- Process background file writes (non-blocking, one chunk per frame)
    bg_writer.update()
end

--------------------------------------------------------------------------------
-- Ghost/Comparison Lap API
--------------------------------------------------------------------------------

--- Get current delta vs comparison lap
---@return number Delta in seconds (positive = slower)
function state.getDelta()
    local compLap = state.getComparisonLap()
    if not state.currentLap or not compLap then return 0 end
    return state.currentLap:getDeltaVs(compLap, state.trackPosition)
end

--- Get ghost steering at current position (from comparison lap)
---@return number|nil Steering in degrees
function state.getGhostSteering()
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    return compLap:steeringDegAt(state.trackPosition)
end

--- Get ghost gear at current position (from comparison lap)
---@return number|nil Gear number
function state.getGhostGear()
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    return math.floor(compLap:gearAt(state.trackPosition) + 0.5)  -- Round to nearest integer
end

--- Get ghost traces for display positions (from comparison lap)
---@param positions table Array of spline positions
---@return table|nil Traces { throttle={}, brake={}, ... }
function state.getGhostTraces(positions)
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    -- Use 100 bar normalization to match extended_brake.getNormalizedBrake()
    return compLap:getTracesAt(positions, 100)
end

--- Check if we have a comparison lap
---@return boolean
function state.hasComparisonLap()
    local compLap = state.getComparisonLap()
    return compLap ~= nil and compLap:length() > 10
end

--- Check if we have a best/reference lap (for backwards compatibility)
---@return boolean
function state.hasBestLap()
    return state.bestLap ~= nil and state.bestLap:length() > 10
end

--- Get comparison lap time in seconds
---@return number|nil
function state.getComparisonLapTime()
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    return compLap.time / 1000
end

--- Get best/reference lap time in seconds (for backwards compatibility)
---@return number|nil
function state.getBestLapTime()
    if not state.bestLap then return nil end
    return state.bestLap.time / 1000
end

--- Get best/reference lap data
---@return table|nil
function state.getBestLap()
    return state.bestLap
end

--- Get fastest lap from current session only (from history)
---@return table|nil lap, number|nil index
function state.getFastestSessionLap()
    return history_storage.getFastestFromSession(state.sessionId)
end

--- Get best lap driven in this session (not loaded from file)
--- This is updated live and cached, so it's faster than getFastestSessionLap
---@return table|nil
function state.getBestInSession()
    return state.bestInSession
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
    state.invalidateAutoCheckpoints()
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
--- Get ghost time at position (from comparison lap)
---@param pos number Spline position
---@return number|nil Time in seconds
function state.getGhostTimeAtPos(pos)
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    return compLap:getTimeAtPos(pos)
end

--- Get max steering in range from comparison lap
---@param startPos number
---@param endPos number
---@return number Degrees
function state.getGhostMaxSteeringInRange(startPos, endPos)
    local compLap = state.getComparisonLap()
    if not compLap then return 0 end
    return compLap:findMaxSteering(startPos, endPos)
end

--- Get brake point in range from comparison lap
---@param startPos number
---@param endPos number
---@return number|nil
function state.getGhostBrakePointInRange(startPos, endPos)
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    return compLap:findBrakePoint(startPos, endPos)
end

--- Get lift-off point in range from comparison lap
---@param startPos number
---@param endPos number
---@return number|nil
function state.getGhostLiftPointInRange(startPos, endPos)
    local compLap = state.getComparisonLap()
    if not compLap then return nil end
    return compLap:findLiftPoint(startPos, endPos)
end

--- Get apex (minimum speed point) in range from comparison lap
---@param startPos number
---@param endPos number
---@return number|nil apexPos
---@return number|nil apexSpeed
function state.getGhostApexInRange(startPos, endPos)
    local compLap = state.getComparisonLap()
    if not compLap then return nil, nil end
    return compLap:findApex(startPos, endPos)
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
                brakePos = lapData:findBrakePoint(corner.startPos, corner.endPos, settings.brakeThreshold()),
                liftOffPos = lapData:findLiftPoint(corner.startPos, corner.endPos, settings.throttleThreshold()),
                maxSteeringDeg = lapData:findMaxSteering(corner.startPos, corner.endPos)
            }
        end
    end
    return analysis
end

-- Corner lookup cache (memoization)
local _lastCornerPos = nil
local _lastCornerResult = nil
local _lastCornerCornersRef = nil

--- Get corner at a specific position
--- Cached: returns cached result if position unchanged and corners haven't changed
---@param pos number Spline position
---@return table|nil Corner definition
function state.getCornerAt(pos)
    -- Cache check: if same position and corners reference unchanged
    if _lastCornerPos == pos and _lastCornerCornersRef == state.trackCorners then
        return _lastCornerResult
    end

    local result = nil
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
                result = c
                break
            end
        end
    end

    -- Cache the result
    _lastCornerPos = pos
    _lastCornerResult = result
    _lastCornerCornersRef = state.trackCorners

    return result
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

-- Corners for positions cache (memoization)
local _cornersPosCache = nil
local _cornersPosPosCount = nil
local _cornersPosPosFirst = nil
local _cornersPosPosLast = nil
local _cornersPosCorners = nil

--- Get corner numbers for array of positions
--- Cached: returns cached result if positions content and corners unchanged
---@param positions table Array of spline positions
---@return table Array of corner numbers (0 for not in corner)
function state.getCornersForPositions(positions)
    if not positions or #positions < 1 then return nil end

    -- Cache check: verify positions content by checking length and bounds
    local posCount = #positions
    local posFirst = positions[1]
    local posLast = positions[posCount]

    if _cornersPosCache
        and _cornersPosCorners == state.trackCorners
        and _cornersPosPosCount == posCount
        and _cornersPosPosFirst == posFirst
        and _cornersPosPosLast == posLast then
        return _cornersPosCache
    end

    local result = {}
    -- Optimize: instead of calling isInCorner (which calls getCornerAt) for each,
    -- do a direct loop with cached corner result
    local lastCorner = nil
    local lastCornerStart = nil
    local lastCornerEnd = nil
    local lastCornerNum = 0

    for i = 1, posCount do
        local pos = positions[i]
        local cornerNum = 0

        -- Quick check if still in last corner (common for sequential positions)
        if lastCorner then
            local inside
            if lastCornerStart <= lastCornerEnd then
                inside = pos >= lastCornerStart and pos <= lastCornerEnd
            else
                inside = pos >= lastCornerStart or pos <= lastCornerEnd
            end
            if inside then
                cornerNum = lastCornerNum
            else
                lastCorner = nil
            end
        end

        -- If not in cached corner, search all corners
        if cornerNum == 0 then
            for _, c in ipairs(state.trackCorners) do
                if c.startPos and c.endPos then
                    local inside
                    if c.startPos <= c.endPos then
                        inside = pos >= c.startPos and pos <= c.endPos
                    else
                        inside = pos >= c.startPos or pos <= c.endPos
                    end
                    if inside then
                        cornerNum = c.number
                        lastCorner = c
                        lastCornerStart = c.startPos
                        lastCornerEnd = c.endPos
                        lastCornerNum = c.number
                        break
                    end
                end
            end
        end

        result[i] = cornerNum
    end

    -- Cache the result
    _cornersPosCache = result
    _cornersPosPosCount = posCount
    _cornersPosPosFirst = posFirst
    _cornersPosPosLast = posLast
    _cornersPosCorners = state.trackCorners

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
-- Checkpoint System (Save/Load State)
--------------------------------------------------------------------------------

--- Register a callback to be called when checkpoint is loaded
--- Callback receives (pos) where pos is the restored track position
---@param callback function Callback function(pos)
function state.onCheckpointLoad(callback)
    if type(callback) == 'function' then
        table.insert(checkpointCallbacks, callback)
    end
end

--- Internal: notify all checkpoint callbacks
local function notifyCheckpointCallbacks(pos)
    for _, cb in ipairs(checkpointCallbacks) do
        local ok, err = pcall(cb, pos)
        if not ok then
            ac.log("AC Tracer: Checkpoint callback error: " .. tostring(err))
        end
    end
end

-- Pending trace history to be captured when async save completes
local pendingTraceHistory = nil

--- Find the next corner ahead of a track position
---@param pos number Spline position (0.0 to 1.0)
---@return table|nil Corner definition of the next corner
local function getNextCorner(pos)
    if not state.trackCorners or #state.trackCorners == 0 then return nil end
    local best = nil
    local bestDist = 2
    for _, c in ipairs(state.trackCorners) do
        if c.startPos then
            local dist = c.startPos - pos
            if dist < 0 then dist = dist + 1 end
            if dist > 0 and dist < bestDist then
                bestDist = dist
                best = c
            end
        end
    end
    return best
end

--- Compute auto-checkpoint positions: 2 seconds before every corner entry
--- Uses bestLap timing to find the track position that is 2s before each corner start
---@return table Array of spline positions
local function computeAutoCheckpointPositions()
    local positions = {}
    -- Always include start/finish
    table.insert(positions, 0.0)

    if state.trackCorners and #state.trackCorners >= 1 and state.bestLap
        and state.bestLap.time and state.bestLap.time > 0 then
        local lapTimeSec = state.bestLap.time / 1000

        -- Build list of corner exit times for proximity filtering
        local exitTimes = {}
        for _, c in ipairs(state.trackCorners) do
            if c.endPos then
                local t = state.bestLap:timeAt(c.endPos)
                if t then table.insert(exitTimes, t) end
            end
        end

        for _, c in ipairs(state.trackCorners) do
            if c.startPos then
                local cornerTime = state.bestLap:timeAt(c.startPos)
                if cornerTime then
                    local targetTime = cornerTime - 2
                    if targetTime < 0 then targetTime = targetTime + lapTimeSec end

                    -- Skip if within 5s of any corner exit (too tight between corners)
                    local tooClose = false
                    for _, exitTime in ipairs(exitTimes) do
                        local gap = targetTime - exitTime
                        -- Handle wrap-around
                        if gap < -lapTimeSec / 2 then gap = gap + lapTimeSec end
                        if gap > lapTimeSec / 2 then gap = gap - lapTimeSec end
                        if gap >= 0 and gap < 5 then
                            tooClose = true
                            break
                        end
                    end

                    if not tooClose then
                        local cpPos = state.bestLap:getPosAtTime(targetTime)
                        if cpPos then
                            table.insert(positions, cpPos)
                        end
                    end
                end
            end
        end
    end

    return positions
end

--- Invalidate auto-checkpoint positions (call when corners or bestLap change)
function state.invalidateAutoCheckpoints()
    autoCheckpointPositions = nil
end

--- Find checkpoint in stack near a position (within threshold)
---@param pos number Spline position
---@param threshold number|nil Distance threshold (default 0.005)
---@return number|nil Index of nearby checkpoint
local function findNearbyCheckpoint(pos, threshold)
    threshold = threshold or 0.005
    for i, cp in ipairs(checkpointStack) do
        local dist = math.abs(cp.pos - pos)
        if dist > 0.5 then dist = 1 - dist end
        if dist < threshold then
            return i
        end
    end
    return nil
end

--- Insert checkpoint into stack (sorted by position, replacing nearby, capping at max)
---@param checkpoint table Checkpoint entry
local function insertIntoStack(checkpoint)
    -- If marker is set, discard all checkpoints more recent than it
    -- (marker is "top of stack" from user's perspective)
    if currentCheckpointMarker and currentCheckpointMarker > 1 then
        for _ = 1, currentCheckpointMarker - 1 do
            table.remove(checkpointStack, 1)
        end
    end

    -- Replace nearby checkpoint if one exists at roughly the same position
    local existing = findNearbyCheckpoint(checkpoint.pos)
    if existing then
        table.remove(checkpointStack, existing)
    end

    -- Insert at front (most recent = index 1)
    table.insert(checkpointStack, 1, checkpoint)

    -- Cap at MAX_CHECKPOINTS (remove oldest = last)
    while #checkpointStack > MAX_CHECKPOINTS do
        table.remove(checkpointStack, #checkpointStack)
    end

    -- Clear marker — new checkpoint is now the top
    currentCheckpointMarker = nil
end

--- Build the checkpoint message string (e.g. "Checkpoint 2/5: Bus Stop")
---@param idx number Checkpoint index
---@param pos number Spline position of the checkpoint
---@return string Message string
local function checkpointMessage(idx, pos)
    local msg = string.format("Checkpoint %d/%d", idx, #checkpointStack)
    local nextCorner = getNextCorner(pos)
    if nextCorner and nextCorner.name then
        msg = msg .. ": " .. nextCorner.name
    end
    return msg
end

--- Save current state as a checkpoint and push to stack (async car state capture)
---@param traceHistory table|nil Trace history to save (pass from ac-tracer.lua)
---@param notify boolean|nil Whether to show toast/sound (default true)
function state.saveCheckpoint(traceHistory, notify)
    if not ac.isCarResetAllowed() then
        ac.log("AC Tracer: Cannot save checkpoint - car reset not allowed in this session")
        return false
    end
    if notify == nil then notify = true end

    -- Deep-copy trace history NOW so it's captured at save time
    if traceHistory then
        pendingTraceHistory = {}
        for field, arr in pairs(traceHistory) do
            pendingTraceHistory[field] = {}
            for i = 1, #arr do
                pendingTraceHistory[field][i] = arr[i]
            end
        end
    end

    -- Capture car state asynchronously
    ac.saveCarStateAsync(function(err, carStateBlob)
        if err or not carStateBlob then
            ac.log("AC Tracer: Failed to save car state: " .. tostring(err))
            pendingTraceHistory = nil
            return
        end

        local car = ac.getCar(0)
        if not car then
            pendingTraceHistory = nil
            return
        end

        local checkpoint = {
            carState = carStateBlob,
            lapSnapshot = state.currentLap and state.currentLap:clone() or nil,
            pos = car.splinePosition,
            lapCount = car.lapCount,
            lapTimeMs = car.lapTimeMs,
            traceSnapshot = pendingTraceHistory,
        }
        pendingTraceHistory = nil

        insertIntoStack(checkpoint)

        if notify and notify ~= "silent" then
            notification.playSave()
        end
    end)

    return true
end

--- Load next checkpoint from stack (cycles through on repeated presses)
--- After driving for 10+ seconds, reloads the same checkpoint instead of advancing.
---@return boolean success True if checkpoint was loaded
function state.loadCheckpoint()
    if #checkpointStack == 0 then
        ac.log("AC Tracer: No checkpoints to load")
        return false
    end

    if not ac.isCarResetAllowed() then
        ac.log("AC Tracer: Cannot load checkpoint - car reset not allowed in this session")
        return false
    end

    -- Repeat press = within 1 second of last load (using drive timer, which
    -- tracks real driving time since last checkpoint load)
    local isRepeat = currentCheckpointMarker ~= nil
        and checkpointDriveTimer <= CHECKPOINT_REPEAT_TIME

    local loadIndex
    if isRepeat then
        -- Repeat press: go to next older checkpoint (deeper in stack)
        loadIndex = currentCheckpointMarker + 1
        if loadIndex > #checkpointStack then
            loadIndex = 1  -- wrap around
        end
    else
        -- Non-repeat press: go to marker if set, otherwise top of stack
        loadIndex = currentCheckpointMarker or 1
    end

    -- Clamp index
    if loadIndex < 1 or loadIndex > #checkpointStack then
        loadIndex = 1
    end

    local cp = checkpointStack[loadIndex]

    -- Set flags to prevent onCarJumped from discarding our restored state
    isLoadingCheckpoint = true
    lastCheckpointLoadTime = os.preciseClock()

    -- Restore car state
    ac.loadCarState(cp.carState, cp.carState, 0, 30)
    isLoadingCheckpoint = false

    -- Get current car state after teleport
    local car = ac.getCar(0)

    -- Calculate lap time offset
    if car and cp.lapTimeMs then
        lapTimeOffset = car.lapTimeMs - cp.lapTimeMs
    else
        lapTimeOffset = 0
    end

    -- Restore plugin state
    if cp.lapSnapshot then
        state.currentLap = cp.lapSnapshot:clone()
    end

    -- Update lap tracking
    local currentLapCount = cp.lapCount
    if car then
        currentLapCount = car.lapCount
    end
    state.lapNumber = currentLapCount
    state.trackPosition = cp.pos

    -- Reset overlap tracking
    lap.resetOverlapTracking()

    -- Invalidate position-based caches
    _lastCornerPos = nil
    _lastCornerResult = nil
    _cornersPosCache = nil

    -- Notify registered callbacks
    notifyCheckpointCallbacks(cp.pos)

    -- Show message with index and next corner name
    local msg = checkpointMessage(loadIndex, cp.pos)
    ac.setMessage(msg, "")
    notification.playLoad()

    ac.log(string.format("AC Tracer: Loaded checkpoint %d/%d at pos %.3f",
        loadIndex, #checkpointStack, cp.pos))

    -- Set marker to the checkpoint we just loaded
    currentCheckpointMarker = loadIndex
    checkpointDriveTimer = 0

    return true
end

--- Move checkpoint by a distance in meters along the track
---@param meters number Distance to move (positive = forward, negative = backward)
---@return boolean success
function state.moveCheckpoint(meters)
    if #checkpointStack == 0 then
        ac.log("AC Tracer: No checkpoint to move")
        return false
    end

    if not ac.isCarResetAllowed() then
        ac.log("AC Tracer: Cannot move checkpoint - car reset not allowed")
        return false
    end

    -- Use marker (last loaded checkpoint), or first in stack
    local idx = currentCheckpointMarker or 1
    if idx < 1 or idx > #checkpointStack then idx = 1 end

    -- First load the checkpoint to teleport car there
    currentCheckpointMarker = idx
    if not state.loadCheckpoint() then
        return false
    end

    local cp = checkpointStack[idx]
    if not cp then return false end

    -- Convert meters to spline offset
    local trackLength = ac.getSim().trackLengthM or 5000
    local splineOffset = meters / trackLength

    -- Calculate new spline position
    local newPos = cp.pos + splineOffset
    if newPos > 1 then newPos = newPos - 1 end
    if newPos < 0 then newPos = newPos + 1 end

    -- Get world position and direction at the new spline position
    local worldPos = ac.trackProgressToWorldCoordinate(newPos)
    local aheadPos = newPos + 0.0001
    if aheadPos > 1 then aheadPos = aheadPos - 1 end
    local worldAhead = ac.trackProgressToWorldCoordinate(aheadPos)
    local dir = (worldAhead - worldPos):normalize()

    -- Move car to new position
    physics.setCarPosition(0, worldPos, dir)

    -- Update checkpoint spline position
    cp.pos = newPos

    -- Re-save car state at new position
    ac.saveCarStateAsync(function(err, carStateBlob)
        if err or not carStateBlob then
            ac.log("AC Tracer: Failed to re-save checkpoint after move: " .. tostring(err))
            return
        end
        cp.carState = carStateBlob
        local car = ac.getCar(0)
        if car then
            cp.lapTimeMs = car.lapTimeMs
        end
        -- Re-sort stack since position changed
        table.sort(checkpointStack, function(a, b) return a.pos < b.pos end)
        ac.log(string.format("AC Tracer: Checkpoint moved %+dm to pos %.3f", meters, newPos))
    end)

    ac.setMessage("Checkpoint", string.format("Moved %+d m", meters))
    return true
end

--- Check if any checkpoints exist
---@return boolean
function state.hasCheckpoint()
    return #checkpointStack > 0
end

--- Get the number of checkpoints in the stack
---@return number
function state.getCheckpointCount()
    return #checkpointStack
end

--- Clear all checkpoints
function state.clearCheckpoint()
    checkpointStack = {}
    currentCheckpointMarker = nil
    checkpointDriveTimer = 0
    ac.log("AC Tracer: Checkpoints cleared")
end

--- Get trace history snapshot from the last loaded checkpoint
---@return table|nil The trace history snapshot, or nil if none
function state.getCheckpointTraceHistory()
    local idx = currentCheckpointMarker or 1
    if idx >= 1 and idx <= #checkpointStack then
        local cp = checkpointStack[idx]
        if cp and cp.traceSnapshot then
            return cp.traceSnapshot
        end
    end
    -- Fallback: first checkpoint with a snapshot
    for _, cp in ipairs(checkpointStack) do
        if cp.traceSnapshot then
            return cp.traceSnapshot
        end
    end
    return nil
end

--- Get the lap time offset (for correcting delta after checkpoint load)
---@return number Offset in milliseconds (0 if no checkpoint was loaded)
function state.getLapTimeOffset()
    return lapTimeOffset
end

--- Reset the lap time offset (call when starting a new lap normally)
function state.resetLapTimeOffset()
    lapTimeOffset = 0
end

--- Update checkpoint drive timer (call from update loop)
---@param dt number Delta time in seconds
function state.updateCheckpointDriveTimer(dt)
    if currentCheckpointMarker then
        checkpointDriveTimer = checkpointDriveTimer + dt
    end
end

--- Check auto-checkpoint positions and save when car crosses them at full throttle
---@param prevPos number|nil Previous spline position
---@param curPos number Current spline position
---@param car table Car state (needs .gas for throttle check)
---@param traceHistory table|nil Trace history for snapshot
function state.checkAutoCheckpoints(prevPos, curPos, car, traceHistory)
    if not prevPos or not car then return end

    -- Compute positions lazily
    if not autoCheckpointPositions then
        autoCheckpointPositions = computeAutoCheckpointPositions()
    end

    for _, targetPos in ipairs(autoCheckpointPositions) do
        if hasCrossedPosition(prevPos, curPos, targetPos) then
            -- Only checkpoint if throttle is full (on a straight, not already braking)
            if car.gas >= 0.95 then
                state.saveCheckpoint(traceHistory, "silent")
            end
        end
    end
end

--- Reset checkpoint marker (next press goes to top of stack)
function state.resetCheckpointIndex()
    currentCheckpointMarker = nil
end

--- Push a checkpoint entry directly into the stack (for testing)
---@param checkpoint table Checkpoint entry with at minimum { carState, pos }
function state.pushCheckpoint(checkpoint)
    insertIntoStack(checkpoint)
end

--- Get the checkpoint stack (for testing/inspection)
---@return table Array of checkpoint entries
function state.getCheckpointStack()
    return checkpointStack
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

--------------------------------------------------------------------------------
-- Autosave reference on exit
--------------------------------------------------------------------------------

--- Autosave fastest session lap if it beats the loaded reference for this track
function state.autosaveReferenceIfFaster()
    local reference = state.bestLap
    if not reference or not reference.csvSource then
        return false
    end
    if reference.track and state.track and reference.track ~= state.track then
        return false
    end

    local candidate = state.bestInSession
    if not candidate or not candidate.valid or not candidate.time or candidate.time <= 0 then
        return false
    end

    if reference.time and candidate.time >= reference.time then
        return false
    end

    local filename = csv_export.buildAutosaveFilename(state.track, candidate.time)
    paths.ensureDirs(state.track, state.car)
    local path, err = csv_export.saveLap(candidate, {
        directory = paths.referencesDir(state.track, state.car),
        filename = filename,
    })
    if path then
        file_utils.invalidateCache()
        ac.log("AC Tracer: Autosaved reference lap to " .. path)
        return true
    end

    ac.log("AC Tracer: Autosave failed: " .. tostring(err))
    return false
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

--------------------------------------------------------------------------------
-- Background Writer API
--------------------------------------------------------------------------------

--- Get status of background file writing
---@return number pending Number of pending jobs
---@return boolean active True if currently writing
function state.getAutoSaveStatus()
    return bg_writer.getStatus()
end

--- Get the auto-save directory path
---@return string Path to %APPDATA%/ac-tracer/laps/
function state.getAutoSaveDir()
    return bg_writer.getSaveDir()
end

--- Flush all pending auto-save jobs (for clean shutdown)
function state.flushAutoSave()
    bg_writer.flush()
end

return state
