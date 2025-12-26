-- state.lua - Centralized game state
-- All state and persistence lives here. Other modules read from state.

local lap = require('lap')

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
state.history = {}             -- array[lap]: completed laps (max 20, persisted)
state.historyReferences = {}   -- array[lap]: external CSVs loaded for comparison

-- Reference lap
state.bestLap = nil            -- lap: current reference for ghost comparison
state.bestLapCorners = {}      -- pre-computed corner analysis for bestLap

-- Manual corner recording
state.cornerRecording = false
state.cornerRecordStart = nil
state.cornerRecordTime = nil

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SAMPLE_RATE = lap.SAMPLE_RATE
local MAX_HISTORY = 20
local TAP_THRESHOLD = 1.0

-- Timing
local sampleTimer = 0
local initialized = false

--------------------------------------------------------------------------------
-- Storage Keys
--------------------------------------------------------------------------------

local function getStorageKey(suffix)
    local trackId = state.track or 'unknown'
    return 'traces_' .. trackId:gsub("[/\\:]", "_") .. '_' .. suffix
end

local CORNERS_CSV_PATH = __dirname .. "/tracks/corners.csv"

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
    -- Renumber corners
    for i, corner in ipairs(result) do
        corner.number = i
        if corner.name and corner.name:match("^Corner %d+$") then
            corner.name = "Corner " .. i
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

--- Save corners to CSV file (all tracks in one file)
local function saveCornersToFile()
    if not state.track then return false end
    if not state.trackCorners or #state.trackCorners == 0 then return false end
    
    -- Remove overlapping corners before saving
    state.trackCorners = removeOverlappingCorners(state.trackCorners)
    
    -- Read existing CSV (for other tracks)
    local otherTrackCorners = {}
    local f = io.open(CORNERS_CSV_PATH, "r")
    if f then
        local firstLine = true
        for line in f:lines() do
            if firstLine then
                firstLine = false  -- Skip header
            elseif line ~= "" then
                local fields = parseCSVLine(line)
                if #fields >= 4 and fields[1] ~= state.track then
                    -- Keep corners from other tracks
                    table.insert(otherTrackCorners, {
                        track = fields[1],
                        name = fields[2],
                        startPos = fields[3],
                        endPos = fields[4]
                    })
                end
            end
        end
        f:close()
    end
    
    -- Write new CSV with header
    f = io.open(CORNERS_CSV_PATH, "w")
    if not f then
        ac.log("Traces: Failed to open corners.csv for writing")
        return false
    end
    
    -- Header
    f:write("track,name,start,end\n")
    
    -- Write corners for current track
    for _, corner in ipairs(state.trackCorners) do
        if corner.startPos and corner.endPos then
            f:write(string.format("%s,%s,%.6f,%.6f\n",
                escapeCSV(state.track),
                escapeCSV(corner.name or ("Corner " .. corner.number)),
                corner.startPos,
                corner.endPos
            ))
        end
    end
    
    -- Write corners from other tracks
    for _, c in ipairs(otherTrackCorners) do
        f:write(string.format("%s,%s,%s,%s\n", 
            escapeCSV(c.track), 
            escapeCSV(c.name), 
            c.startPos, 
            c.endPos
        ))
    end
    
    f:close()
    ac.log("Traces: Saved " .. #state.trackCorners .. " corners to corners.csv")
    return true
end

--- Load corners from CSV file
local function loadCornersFromFile()
    if not state.track then return false end
    
    local f = io.open(CORNERS_CSV_PATH, "r")
    if not f then return false end
    
    state.trackCorners = {}
    local cornerNum = 0
    local firstLine = true
    
    for line in f:lines() do
        if firstLine then
            firstLine = false  -- Skip header
        elseif line ~= "" then
            local fields = parseCSVLine(line)
            if #fields >= 4 and fields[1] == state.track then
                local startPos = tonumber(fields[3])
                local endPos = tonumber(fields[4])
                
                if startPos and endPos then
                    cornerNum = cornerNum + 1
                    local apexPos = (startPos + endPos) / 2
                    if endPos < startPos then
                        apexPos = (startPos + endPos + 1) / 2
                        if apexPos >= 1 then apexPos = apexPos - 1 end
                    end
                    
                    table.insert(state.trackCorners, {
                        number = cornerNum,
                        startPos = startPos,
                        endPos = endPos,
                        apexPos = apexPos,
                        name = fields[2] ~= "" and fields[2] or ("Corner " .. cornerNum)
                    })
                end
            end
        end
    end
    
    f:close()
    
    if #state.trackCorners > 0 then
        ac.log("Traces: Loaded " .. #state.trackCorners .. " corners from corners.csv for " .. state.track)
        return true
    end
    return false
end

--- Save corners to ac.storage
local function saveCornersToStorage()
    local key = getStorageKey('corners')
    if state.trackCorners and #state.trackCorners > 0 then
        local pairs = {}
        for _, c in ipairs(state.trackCorners) do
            if c.startPos and c.endPos then
                table.insert(pairs, {c.startPos, c.endPos})
            else
                table.insert(pairs, {})
            end
        end
        ac.storage[key] = stringify(pairs)
    else
        ac.storage[key] = nil
    end
end

--- Load corners from ac.storage
local function loadCornersFromStorage()
    local key = getStorageKey('corners')
    local data = ac.storage[key]
    if not data then return false end
    
    local ok, pairs = pcall(function() return stringify.parse(data) end)
    if not ok or not pairs then return false end
    
    state.trackCorners = {}
    for i, pair in ipairs(pairs) do
        if pair and #pair == 2 then
            local startPos, endPos = pair[1], pair[2]
            local apexPos = (startPos + endPos) / 2
            if endPos < startPos then
                apexPos = (startPos + endPos + 1) / 2
                if apexPos >= 1 then apexPos = apexPos - 1 end
            end
            table.insert(state.trackCorners, {
                number = i,
                startPos = startPos,
                endPos = endPos,
                apexPos = apexPos,
                name = "Corner " .. i
            })
        end
    end
    
    ac.log("Traces: Loaded " .. #state.trackCorners .. " corners from storage")
    return true
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
    ac.log("Traces: Saved best lap to storage")
end

--- Load best lap from ac.storage
local function loadBestLap()
    local key = getStorageKey('bestlap')
    local data = ac.storage[key]
    if not data then return false end
    
    local loaded = lap.deserialize(data)
    if loaded and loaded:length() > 10 then
        state.bestLap = loaded
        ac.log("Traces: Loaded best lap from storage")
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Persistence: History
--------------------------------------------------------------------------------

--- Save history to ac.storage
local function saveHistory()
    if not state.history or #state.history == 0 then 
        ac.log("Traces: No history to save")
        return 
    end
    
    local serialized = {}
    for i, lapData in ipairs(state.history) do
        if i <= MAX_HISTORY then
            local ser = lapData:serialize()
            if ser then
                table.insert(serialized, ser)
            else
                ac.log("Traces: Failed to serialize lap " .. i)
            end
        end
    end
    
    local key = getStorageKey('history')
    local dataToSave = stringify(serialized)
    ac.storage[key] = dataToSave
    ac.log("Traces: Saved " .. #serialized .. " laps to history (key: " .. key .. ", size: " .. #dataToSave .. " bytes)")
end

--- Load history from ac.storage
local function loadHistory()
    local key = getStorageKey('history')
    ac.log("Traces: Loading history with key: " .. key)
    local data = ac.storage[key]
    if not data then 
        ac.log("Traces: No history data found in storage")
        return false 
    end
    
    ac.log("Traces: Found history data, parsing...")
    local ok, serialized = pcall(function() return stringify.parse(data) end)
    if not ok or not serialized then 
        ac.log("Traces: Failed to parse history data")
        return false 
    end
    
    ac.log("Traces: Parsed " .. #serialized .. " entries, deserializing...")
    state.history = {}
    for i, lapStr in ipairs(serialized) do
        local loaded = lap.deserialize(lapStr)
        if loaded and loaded:length() > 10 then
            table.insert(state.history, loaded)
        else
            ac.log("Traces: Failed to load lap " .. i)
        end
    end
    
    ac.log("Traces: Loaded " .. #state.history .. " laps from history")
    return #state.history > 0
end

--------------------------------------------------------------------------------
-- Auto-Detection: Corners from Best Lap
--------------------------------------------------------------------------------

-- Detection parameters
local SPEED_DROP_THRESHOLD = 0.25
local BRAKE_THRESHOLD = 0.15
local THROTTLE_ON_THRESHOLD = 0.7
local LEAD_DISTANCE = 50
local EXIT_TIME = 2.0
local EXIT_TIME_THROTTLE_ONLY = 5.0
local STEERING_CENTER_THRESHOLD = 0.042  -- ~15°

local function isSteeringCentered(steeringNorm)
    return math.abs(steeringNorm - 0.5) < STEERING_CENTER_THRESHOLD
end

--- Auto-detect corners from a lap's telemetry
---@param lapData table Lap instance
---@return table Array of corner definitions
local function autoDetectCorners(lapData)
    if not lapData or lapData:length() < 30 then return {} end

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
                        if apexSpeed < (prevCorner.apexSpeed or 999) then
                            prevCorner.apexPos = lapData.pos[apexIdx]
                            prevCorner.apexSpeed = apexSpeed
                        end
                    end
                end

                if not shouldMerge then
                    cornerNum = cornerNum + 1
                    table.insert(corners, {
                        number = cornerNum,
                        startPos = lapData.pos[entryIdx],
                        endPos = lapData.pos[exitIdx],
                        apexPos = lapData.pos[apexIdx],
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

    ac.log("Traces: Auto-detected " .. #corners .. " corners from lap")
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
-- Initialization
--------------------------------------------------------------------------------

--- Initialize state for current session
---@param car table Car state from ac.getCar()
function state.init(car)
    if initialized then return end
    
    state.track = ac.getTrackID()
    state.car = car.id
    state.sessionId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    state.lapNumber = car.lapCount
    state.trackPosition = car.splinePosition
    
    ac.log("Traces: Session ID: " .. state.sessionId)
    
    -- Load corners (file first, then storage)
    if not loadCornersFromFile() then
        loadCornersFromStorage()
    end
    
    -- Load best lap and history
    loadBestLap()
    loadHistory()
    
    -- Auto-detect corners if no manual corners and we have a best lap
    updateAutoDetectedCorners()
    
    -- Initialize current lap
    state.currentLap = lap.new(state.track, state.car, state.sessionId)
    state.currentLap.fuelLeftAtStart = car.fuel
    
    initialized = true
    ac.log('Traces: State initialized for ' .. state.track)
end

--------------------------------------------------------------------------------
-- Update Loop
--------------------------------------------------------------------------------

-- Track previous state for detecting resets/teleports
local prevInPit = false
local prevPosition = 0
local prevLapTimeMs = 0

--- Discard current lap and start fresh
local function discardCurrentLap()
    state.currentLap = lap.new(state.track, state.car, state.sessionId)
    state.currentLap.fuelLeftAtStart = ac.getCar(0).fuel or 0
    ac.log("Traces: Discarded current lap (teleport/pit/reset)")
end

--- Update state (call from script.update)
---@param dt number Delta time in seconds
---@param car table Car state from ac.getCar()
function state.update(dt, car)
    if not car then return end
    
    -- Initialize on first run
    state.init(car)
    
    -- Skip if paused
    if ac.getSim().isPaused then return end
    
    -- Detect state for teleport/pit checks
    local inPit = car.isInPitlane or car.isInPit
    local bigPositionJump = math.abs(car.splinePosition - prevPosition) > 0.3 and prevPosition > 0
    local crossingStartFinish = prevPosition > 0.9 and car.splinePosition < 0.1
    
    -- Check lap completion FIRST (before any discard logic)
    -- This prevents the lap reset from triggering discard when a lap completes normally
    if car.lapCount > state.lapNumber then
        if state.lapNumber > 0 and state.currentLap and state.currentLap:length() > 10 then
            -- Finalize completed lap
            state.currentLap.completed = true
            state.currentLap.valid = car.isLastLapValid
            state.currentLap.time = car.previousLapTimeMs
            state.currentLap.lapNumberInSession = state.lapNumber  -- Lap number in this session
            
            -- Add to history (most recent first)
            table.insert(state.history, 1, state.currentLap)
            while #state.history > MAX_HISTORY do
                table.remove(state.history)
            end
            saveHistory()
            
            ac.log(string.format("Traces: Lap completed - time: %.3fs, valid: %s, samples: %d", 
                state.currentLap.time / 1000, tostring(state.currentLap.valid), state.currentLap:length()))
            
            -- Update best lap if this is faster and valid
            if state.currentLap.valid and state.currentLap.time > 0 then
                if not state.bestLap or state.currentLap.time < state.bestLap.time then
                    state.bestLap = state.currentLap
                    state.bestLapCorners = state.analyzeCorners(state.currentLap)
                    saveBestLap()
                    updateAutoDetectedCorners()
                    ac.log('Traces: New best lap: ' .. (state.currentLap.time / 1000) .. 's')
                end
            end
        end
        
        -- Reset for new lap
        state.currentLap = lap.new(state.track, state.car, state.sessionId)
        state.currentLap.fuelLeftAtStart = car.fuel
        state.lapNumber = car.lapCount
    end
    
    -- Now check for abnormal discards (teleport, pit entry, session reset)
    -- Only if we didn't just complete a lap (lap number already updated above)
    local lapTimeReset = car.lapTimeMs < prevLapTimeMs - 1000 and car.lapTimeMs < 1000  -- Lap time went backwards significantly
    
    -- Entering pits (wasn't in pit, now in pit)
    if inPit and not prevInPit then
        discardCurrentLap()
    end
    
    -- Teleport detection (big position jump without crossing start/finish)
    if bigPositionJump and not crossingStartFinish then
        discardCurrentLap()
    end
    
    -- Session/lap reset detection: lap time went to 0 but lap count didn't increment
    -- This happens on session restart, ESC to pits, etc.
    if lapTimeReset and car.lapCount == state.lapNumber then
        discardCurrentLap()
    end
    
    prevInPit = inPit
    prevPosition = car.splinePosition
    prevLapTimeMs = car.lapTimeMs
    
    -- Sample at 15 Hz
    sampleTimer = sampleTimer + dt
    if sampleTimer >= 1 / SAMPLE_RATE then
        sampleTimer = sampleTimer - 1 / SAMPLE_RATE
        
        -- Ensure current lap exists
        if not state.currentLap then
            state.currentLap = lap.new(state.track, state.car, state.sessionId)
            state.currentLap.fuelLeftAtStart = car.fuel
        end
        
        -- Add sample if valid (and not in pits)
        if car.lapTimeMs > 0 and car.splinePosition >= 0 and not inPit then
            state.currentLap:addSample(car)
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
    local steerNorm = state.bestLap:getValueAtPos('steering', state.trackPosition)
    if not steerNorm then return nil end
    return lap.steerToDegrees(steerNorm)
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
    if not state.history or #state.history == 0 then return nil, nil end
    if not state.sessionId then return nil, nil end
    
    local fastest = nil
    local fastestIdx = nil
    for i, lapData in ipairs(state.history) do
        -- Only consider laps from current session
        if lapData.sessionId == state.sessionId and 
           lapData.valid and lapData.time and lapData.time > 0 then
            if not fastest or lapData.time < fastest.time then
                fastest = lapData
                fastestIdx = i
            end
        end
    end
    return fastest, fastestIdx
end

--- Get laps from current session
---@return table Array of {lap, index} pairs
function state.getCurrentSessionLaps()
    local laps = {}
    if not state.history or #state.history == 0 then return laps end
    if not state.sessionId then return laps end
    
    for i, lapData in ipairs(state.history) do
        if lapData.sessionId == state.sessionId then
            table.insert(laps, {lap = lapData, index = i})
        end
    end
    return laps
end

--- Get laps from previous sessions
---@return table Array of {lap, index} pairs
function state.getPreviousSessionLaps()
    local laps = {}
    if not state.history or #state.history == 0 then return laps end
    
    for i, lapData in ipairs(state.history) do
        if lapData.sessionId ~= state.sessionId then
            table.insert(laps, {lap = lapData, index = i})
        end
    end
    return laps
end

--- Set best lap directly
---@param lapData table Lap instance
function state.setBestLap(lapData)
    state.bestLap = lapData
    state.bestLapCorners = state.analyzeCorners(lapData)
    saveBestLap()
    updateAutoDetectedCorners()
end

--- Reset best lap
function state.resetBestLap()
    state.bestLap = nil
    state.bestLapCorners = {}
    ac.storage[getStorageKey('bestlap')] = nil
    ac.storage[getStorageKey('bestlap_time')] = nil
    ac.log("Traces: Reset best lap")
end

--- Get ghost value at position (for corner analysis)
---@param field string Field name
---@param pos number Spline position
---@return number|nil
function state.getGhostValueAt(field, pos)
    if not state.bestLap then return nil end
    return state.bestLap:getValueAtPos(field, pos)
end

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
-- Corner Management
--------------------------------------------------------------------------------

--- Analyze corners for a lap
---@param lapData table Lap instance
---@return table Corner analysis data
function state.analyzeCorners(lapData)
    if not lapData or not state.trackCorners then return {} end
    
    local analysis = {}
    for _, corner in ipairs(state.trackCorners) do
        analysis[corner.number] = {
            entrySpeed = lapData:getValueAtPos('speed', corner.startPos),
            apexSpeed = lapData:getValueAtPos('speed', corner.apexPos),
            exitSpeed = lapData:getValueAtPos('speed', corner.endPos),
            brakePos = lapData:findBrakePoint(corner.startPos, corner.apexPos),
            liftOffPos = lapData:findLiftPoint(corner.startPos, corner.apexPos),
            maxSteeringDeg = lapData:findMaxSteering(corner.startPos, corner.endPos)
        }
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
    saveCornersToStorage()
    ac.log("Traces: Cleared corners")
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
            -- Recalculate apex (only if both positions exist)
            if corner.startPos and corner.endPos then
                local apexPos = (corner.startPos + corner.endPos) / 2
                if corner.endPos < corner.startPos then
                    apexPos = (corner.startPos + corner.endPos + 1) / 2
                    if apexPos >= 1 then apexPos = apexPos - 1 end
                end
                corner.apexPos = apexPos
            else
                corner.apexPos = nil
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
            saveCornersToStorage()
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
    local apexPos = (startPos + endPos) / 2
    if endPos < startPos then
        apexPos = (startPos + endPos + 1) / 2
        if apexPos >= 1 then apexPos = apexPos - 1 end
    end
    
    local newCorner = {
        number = #state.trackCorners + 1,
        startPos = startPos,
        endPos = endPos,
        apexPos = apexPos,
        name = "Corner " .. (#state.trackCorners + 1)
    }
    
    table.insert(state.trackCorners, newCorner)
    saveCornersToStorage()
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
            endPos = nil,
            apexPos = nil
        })
        ac.log("Traces: Skipped corner #" .. #state.trackCorners)
    else
        -- Hold = record corner
        local startPos = state.cornerRecordStart
        local endPos = pos
        local apexPos = (startPos + endPos) / 2
        if endPos < startPos then
            apexPos = (startPos + endPos + 1) / 2
            if apexPos >= 1 then apexPos = apexPos - 1 end
        end
        
        table.insert(state.trackCorners, {
            number = #state.trackCorners + 1,
            startPos = startPos,
            endPos = endPos,
            apexPos = apexPos
        })
        ac.log("Traces: Recorded corner #" .. #state.trackCorners)
    end
    
    saveCornersToStorage()
    
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

--- Load lap from CSV and add to references
---@param filePath string Path to CSV file
---@return table|nil Loaded lap
function state.loadCSV(filePath)
    local loaded = lap.fromCSV(filePath, state.track, state.car)
    if loaded then
        table.insert(state.historyReferences, loaded)
        return loaded
    end
    return nil
end

--- Load CSV and set as best lap
---@param filePath string Path to CSV file
---@return boolean Success
function state.loadCSVAsBest(filePath)
    local loaded = lap.fromCSV(filePath, state.track, state.car)
    if loaded then
        state.setBestLap(loaded)
        table.insert(state.historyReferences, loaded)
        return true
    end
    return false
end

return state
