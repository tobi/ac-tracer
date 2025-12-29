-- lap.lua - Unified lap data structure
-- All lap data uses this structure: in-game recording, CSV import, storage

local lap = {}
lap.__index = lap

-- Constants
lap.SAMPLE_RATE = 15  -- Hz (exported for other modules)
local STEERING_CAP = math.pi  -- 180 degrees in radians

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

--- Create a new empty lap
---@param track string Track ID
---@param car string Car ID
---@return table lap New lap instance
function lap.new(track, car, sessionId)
    return setmetatable({
        -- Metadata
        track = track or '',
        car = car or '',
        sessionId = sessionId or nil,  -- Identifies which session this lap belongs to
        completed = false,
        valid = true,
        time = 0,              -- milliseconds
        fuelLeftAtStart = 0,   -- liters
        lapNumberInSession = 0, -- Which lap number in this session (1, 2, 3...)
        
        -- Telemetry arrays (all synchronized, sampled at 15 Hz)
        throttle = {},         -- 0.0 to 1.0
        brake = {},            -- 0.0 to 1.0
        clutch = {},           -- 0.0 to 1.0 (inverted: 1.0 = pressed)
        steering = {},         -- 0.0 to 1.0 (normalized, 0.5 = straight)
        speed = {},            -- km/h
        pos = {},              -- spline position 0.0 to 1.0
        times = {},            -- seconds (elapsed lap time at each sample)
        tcActive = {},         -- boolean: traction control active
    }, lap)
end

--------------------------------------------------------------------------------
-- Steering Conversion
--------------------------------------------------------------------------------

--- Normalize steering angle to 0.0-1.0 range
---@param steerDeg number Steering angle in degrees
---@return number Normalized steering (0.5 = straight)
function lap.normalizeSteer(steerDeg)
    return math.clamp(0.5 - math.rad(steerDeg) / (2 * STEERING_CAP), 0, 1)
end

--- Convert normalized steering back to degrees
---@param steerNorm number Normalized steering (0.0 to 1.0)
---@return number Steering angle in degrees
function lap.steerToDegrees(steerNorm)
    return (0.5 - steerNorm) * 2 * STEERING_CAP * 180 / math.pi
end

--------------------------------------------------------------------------------
-- Recording
--------------------------------------------------------------------------------

--- Add a sample from current car state
---@param self table Lap instance
---@param car table Car state from ac.getCar()
function lap:addSample(car)
    table.insert(self.throttle, car.gas)
    table.insert(self.brake, car.brake)
    table.insert(self.clutch, 1 - car.clutch)  -- Invert: 1.0 = foot on pedal
    table.insert(self.steering, lap.normalizeSteer(car.steer))
    table.insert(self.speed, car.speedKmh)
    table.insert(self.pos, car.splinePosition)
    table.insert(self.times, car.lapTimeMs / 1000)  -- seconds
    table.insert(self.tcActive, car.tractionControlInAction or false)
end

--- Get number of samples in this lap
---@return number Sample count
function lap:length()
    return #self.pos
end

--------------------------------------------------------------------------------
-- Interpolation (Position-Based)
--------------------------------------------------------------------------------

--- Binary search to find indices surrounding a target position
---@param positions table Array of spline positions
---@param targetPos number Target position (0.0 to 1.0)
---@return number|nil lo Lower index
---@return number|nil hi Upper index
local function findIndicesAtPos(positions, targetPos)
    if not positions or #positions < 2 then return nil, nil end
    
    local lo, hi = 1, #positions
    while hi - lo > 1 do
        local mid = math.floor((lo + hi) / 2)
        if positions[mid] <= targetPos then
            lo = mid
        else
            hi = mid
        end
    end
    return lo, hi
end

--- Get interpolated value at a specific track position
---@param field string Field name ('throttle', 'brake', 'speed', etc.)
---@param targetPos number Spline position (0.0 to 1.0)
---@return number|nil Interpolated value
function lap:getValueAtPos(field, targetPos)
    local data = self[field]
    if not data or #data < 2 then return nil end
    
    local lo, hi = findIndicesAtPos(self.pos, targetPos)
    if not lo then return nil end
    
    local p1, p2 = self.pos[lo], self.pos[hi]
    local v1, v2 = data[lo], data[hi]
    
    -- Handle edge case
    if p1 == p2 then return v1 end
    
    -- Linear interpolation
    local t = math.clamp((targetPos - p1) / (p2 - p1), 0, 1)
    return v1 + (v2 - v1) * t
end

--- Get interpolated lap time at a specific track position (in seconds)
---@param targetPos number Spline position (0.0 to 1.0)
---@return number|nil Time in seconds
function lap:getTimeAtPos(targetPos)
    local lo, hi = findIndicesAtPos(self.pos, targetPos)
    if not lo then return nil end
    
    local p1, p2 = self.pos[lo], self.pos[hi]
    
    -- If we have actual time data, use it
    if self.times and #self.times >= hi then
        local t1, t2 = self.times[lo], self.times[hi]
        if p1 == p2 then return t1 end
        local t = math.clamp((targetPos - p1) / (p2 - p1), 0, 1)
        return t1 + (t2 - t1) * t
    end
    
    -- Fallback: derive time from sample index (for in-game recorded laps)
    if p1 == p2 then
        return (lo - 1) / lap.SAMPLE_RATE
    end
    
    local t = math.clamp((targetPos - p1) / (p2 - p1), 0, 1)
    local index = lo + t * (hi - lo)
    return (index - 1) / lap.SAMPLE_RATE
end

--- Get time delta vs reference lap at current position
---@param refLap table Reference lap instance
---@param currentPos number Current spline position
---@return number Delta in seconds (positive = slower than reference)
function lap:getDeltaVs(refLap, currentPos)
    if not refLap then return 0 end
    
    local currentTime = self:getTimeAtPos(currentPos)
    local refTime = refLap:getTimeAtPos(currentPos)
    
    if not currentTime or not refTime then return 0 end
    
    return currentTime - refTime
end

--------------------------------------------------------------------------------
-- Trace Extraction
--------------------------------------------------------------------------------

--- Get traces for display, matched to specified positions
---@param positions table Array of spline positions to match
---@return table|nil traces { throttle={}, brake={}, clutch={}, steering={}, speed={} }
function lap:getTracesAt(positions)
    if not positions or #positions < 1 then return nil end
    
    local traces = {
        throttle = {},
        brake = {},
        clutch = {},
        steering = {},
        speed = {}
    }
    
    for i = 1, #positions do
        local pos = positions[i]
        table.insert(traces.throttle, self:getValueAtPos('throttle', pos) or 0)
        table.insert(traces.brake, self:getValueAtPos('brake', pos) or 0)
        table.insert(traces.clutch, self:getValueAtPos('clutch', pos) or 0)
        table.insert(traces.steering, self:getValueAtPos('steering', pos) or 0.5)
        table.insert(traces.speed, self:getValueAtPos('speed', pos) or 0)
    end
    
    return traces
end

--------------------------------------------------------------------------------
-- Corner Analysis Helpers
--------------------------------------------------------------------------------

--- Find brake point in a position range (first significant brake application)
---@param startPos number Start of search range
---@param endPos number End of search range
---@param threshold number Brake threshold (default 0.03)
---@return number|nil Spline position of brake point
function lap:findBrakePoint(startPos, endPos, threshold)
    threshold = threshold or 0.03
    
    for i = 1, #self.pos do
        local pos = self.pos[i]
        -- Handle wrap-around
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end
        
        if inRange and self.brake[i] > threshold then
            return pos
        end
    end
    return nil
end

--- Find throttle lift point in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@param onThreshold number Throttle "on" threshold (default 0.10)
---@param offThreshold number Throttle "off" threshold (default 0.08)
---@return number|nil Spline position of lift point
function lap:findLiftPoint(startPos, endPos, onThreshold, offThreshold)
    onThreshold = onThreshold or 0.10
    offThreshold = offThreshold or 0.08
    
    local wasOnThrottle = false
    
    for i = 1, #self.pos do
        local pos = self.pos[i]
        -- Handle wrap-around
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end
        
        if inRange then
            local throttle = self.throttle[i]
            if throttle >= onThreshold then
                wasOnThrottle = true
            elseif wasOnThrottle and throttle < offThreshold then
                return pos
            end
        end
    end
    return nil
end

--- Find maximum steering angle in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@return number Maximum steering in degrees (absolute value)
function lap:findMaxSteering(startPos, endPos)
    local maxDeg = 0
    
    for i = 1, #self.pos do
        local pos = self.pos[i]
        -- Handle wrap-around
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end
        
        if inRange then
            local deg = math.abs(lap.steerToDegrees(self.steering[i]))
            if deg > maxDeg then
                maxDeg = deg
            end
        end
    end
    return maxDeg
end

--- Find apex (minimum speed point) in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@return number|nil apexPos Position of minimum speed
---@return number|nil apexSpeed Speed at apex
function lap:findApex(startPos, endPos)
    local minSpeed = math.huge
    local apexPos = nil
    
    for i = 1, #self.pos do
        local pos = self.pos[i]
        -- Handle wrap-around
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end
        
        if inRange then
            local speed = self.speed[i]
            if speed and speed < minSpeed then
                minSpeed = speed
                apexPos = pos
            end
        end
    end
    
    if apexPos then
        return apexPos, minSpeed
    end
    return nil, nil
end

--------------------------------------------------------------------------------
-- Serialization
--------------------------------------------------------------------------------

--- Serialize lap for storage (uses stringify if available)
---@return string Serialized data
function lap:serialize()
    local data = {
        track = self.track,
        car = self.car,
        sessionId = self.sessionId,
        completed = self.completed,
        valid = self.valid,
        time = self.time,
        fuelLeftAtStart = self.fuelLeftAtStart,
        lapNumberInSession = self.lapNumberInSession,
        throttle = self.throttle,
        brake = self.brake,
        clutch = self.clutch,
        steering = self.steering,
        speed = self.speed,
        pos = self.pos,
        times = self.times,  -- Actual elapsed time at each sample
    }
    return stringify(data)
end

--- Deserialize lap from storage
---@param data string Serialized lap data
---@return table|nil Lap instance
function lap.deserialize(data)
    if not data or data == '' then return nil end
    
    local ok, parsed = pcall(function() 
        return type(data) == 'string' and stringify.parse(data) or data
    end)
    
    if not ok or not parsed then return nil end
    return setmetatable(parsed, lap)
end

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------

--- Check if lap has complete track coverage
---@return boolean True if lap covers from ~0% to ~99% of track
function lap:isComplete()
    if #self.pos < 10 then return false end
    
    local minPos, maxPos = 1, 0
    for i = 1, #self.pos do
        local p = self.pos[i]
        if p < minPos then minPos = p end
        if p > maxPos then maxPos = p end
    end
    
    return minPos < 0.05 and maxPos > 0.95
end

--------------------------------------------------------------------------------
-- CSV Import
--------------------------------------------------------------------------------

-- Column mapping configurations for different CSV sources
-- Each source can have multiple alternative column names (first match wins)
local CSV_COLUMN_MAPPINGS = {
    -- Time column (required)
    time = { "time" },

    -- Position/distance columns (at least one required)
    pos = { "lap progression" },           -- 0-1 spline position (AC exports)
    distance = { "distance" },             -- meters from lap start (real car exports)

    -- Speed columns (in order of preference)
    speed = { "ground speed", "corr speed", "wheel speed avg" },

    -- Input columns
    throttle = { "driver throttle pos", "throttle pos" },
    clutch = { "clutch pos" },
    steering = { "steering angle" },

    -- Brake: prefer pressure over pedal position for accuracy
    brakePressure = { "brake pressure f", "brake pressure fr", "p_f_brake" },
    brakePos = { "brake pos" },  -- fallback only
}

-- Unit conversions based on CSV unit row
local UNIT_CONVERSIONS = {
    speed = {
        ["m/s"] = 3.6,      -- to km/h
        ["km/h"] = 1.0,
        ["mph"] = 1.60934,  -- to km/h
    },
    distance = {
        ["m"] = 1.0,
        ["km"] = 1000.0,
        ["ft"] = 0.3048,
    },
    time = {
        ["s"] = 1.0,
        ["ms"] = 0.001,
        ["min"] = 60.0,
    },
}

--- Parse CSV header row and find column indices
---@param line string Header row
---@return table indices Column indices by key
---@return table headers Raw header names by index
local function parseHeader(line)
    local indices = {}
    local headers = {}
    local fieldIdx = 1
    local fieldStart = 1
    local inQuotes = false
    local len = #line

    for i = 1, len + 1 do
        local c = i <= len and line:sub(i, i) or ","
        if c == '"' then
            inQuotes = not inQuotes
        elseif c == ',' and not inQuotes then
            local field = line:sub(fieldStart, i - 1):gsub('^"', ''):gsub('"$', ''):lower()
            headers[fieldIdx] = field

            -- Match against all mapping targets
            for key, targets in pairs(CSV_COLUMN_MAPPINGS) do
                if not indices[key] then
                    for _, target in ipairs(targets) do
                        if field == target then
                            indices[key] = fieldIdx
                            break
                        end
                    end
                end
            end

            fieldIdx = fieldIdx + 1
            fieldStart = i + 1
        end
    end

    return indices, headers
end

--- Parse CSV unit row and extract units for each column
---@param line string Unit row
---@param headers table Header names by index
---@return table units Unit string by header name
local function parseUnits(line, headers)
    local units = {}
    local fieldIdx = 1
    local fieldStart = 1
    local inQuotes = false
    local len = #line

    for i = 1, len + 1 do
        local c = i <= len and line:sub(i, i) or ","
        if c == '"' then
            inQuotes = not inQuotes
        elseif c == ',' and not inQuotes then
            local unit = line:sub(fieldStart, i - 1):gsub('^"', ''):gsub('"$', ''):lower()
            if headers[fieldIdx] then
                units[headers[fieldIdx]] = unit
            end
            fieldIdx = fieldIdx + 1
            fieldStart = i + 1
        end
    end

    return units
end

--- Extract fields from a data row
---@param line string Data row
---@param indices table Column indices to extract
---@return table fields Field values by key
local function extractFields(line, indices)
    local maxIdx = 0
    for _, idx in pairs(indices) do
        if idx and idx > maxIdx then maxIdx = idx end
    end

    local results = {}
    local fieldIdx = 1
    local fieldStart = 1
    local inQuotes = false
    local len = #line

    for i = 1, len + 1 do
        local c = i <= len and line:sub(i, i) or ","
        if c == '"' then
            inQuotes = not inQuotes
        elseif c == ',' and not inQuotes then
            for key, idx in pairs(indices) do
                if idx == fieldIdx then
                    local field = line:sub(fieldStart, i - 1):gsub('^"', ''):gsub('"$', '')
                    results[key] = field
                end
            end
            fieldIdx = fieldIdx + 1
            fieldStart = i + 1
            if fieldIdx > maxIdx then break end
        end
    end
    return results
end

--- Load lap from MoTeC CSV file
--- Supports both AC sim exports (with Lap Progression) and real car exports (with Distance)
---@param filePath string Path to CSV file
---@param track string Track ID
---@param car string Car ID
---@param trackLength number|nil Track length in meters (required for distance-based CSVs)
---@return table|nil Lap instance
---@return table|nil warnings Array of warning messages
function lap.fromCSV(filePath, track, car, trackLength)
    local SAMPLE_INTERVAL = 1 / lap.SAMPLE_RATE
    local warnings = {}

    local f = io.open(filePath, "r")
    if not f then
        ac.log("lap.fromCSV: Failed to open " .. filePath)
        return nil, {"Failed to open file: " .. filePath}
    end

    -- Parse metadata and find header row
    local indices = nil
    local headers = nil
    local units = nil
    local sampleRate = nil
    local skipUntil = 0
    local lineNum = 0
    local headerLineNum = 0

    for line in f:lines() do
        lineNum = lineNum + 1

        -- Extract sample rate from metadata
        if line:find('"Sample Rate"') then
            local rate = line:match('"Sample Rate","([%d%.]+)"')
            if rate then
                sampleRate = tonumber(rate)
            end
        end

        -- Find header row (contains Time column)
        if line:find('"Time"') and (line:find('"Lap Progression"') or line:find('"Distance"')) then
            indices, headers = parseHeader(line)
            headerLineNum = lineNum
            break
        end
    end

    if not indices or not indices.time then
        f:close()
        ac.log("lap.fromCSV: Could not find required Time column")
        return nil, {"Could not find required Time column"}
    end

    -- Check for position/distance data
    local useDistance = false
    if not indices.pos then
        if indices.distance then
            useDistance = true
            if not trackLength then
                f:close()
                ac.log("lap.fromCSV: CSV uses Distance but no track length provided")
                return nil, {"CSV uses Distance instead of Lap Progression - track length required"}
            end
        else
            f:close()
            ac.log("lap.fromCSV: Could not find position or distance column")
            return nil, {"Could not find Lap Progression or Distance column"}
        end
    end

    -- Parse unit row (immediately after header)
    f:seek("set", 0)
    lineNum = 0
    for line in f:lines() do
        lineNum = lineNum + 1
        if lineNum == headerLineNum + 1 then
            units = parseUnits(line, headers)
            skipUntil = lineNum + 1  -- Skip blank line after units
            break
        end
    end

    -- Validate required units
    local timeUnit = units and units["time"]
    local distanceUnit = units and (units["distance"] or units["lap progression"])

    if not timeUnit then
        table.insert(warnings, "WARNING: CSV missing time units - assuming seconds")
        timeUnit = "s"
    end
    if useDistance and not distanceUnit then
        table.insert(warnings, "WARNING: CSV missing distance units - assuming meters")
        distanceUnit = "m"
    end

    -- Warn about high sample rate
    if sampleRate and sampleRate > 15 then
        table.insert(warnings, string.format(
            "WARNING: CSV sample rate (%.1f Hz) exceeds 15 Hz - data will be downsampled",
            sampleRate))
    end

    -- Determine brake source (prefer pressure over position)
    local useBrakePressure = indices.brakePressure ~= nil
    local brakeKey = useBrakePressure and "brakePressure" or "brakePos"
    local brakePressureMax = 0  -- Track max for normalization

    if useBrakePressure then
        ac.log("lap.fromCSV: Using brake pressure data")
    elseif indices.brakePos then
        ac.log("lap.fromCSV: Using brake pedal position (pressure not available)")
    else
        table.insert(warnings, "WARNING: No brake data column found")
    end

    -- Get unit conversion factors
    local speedUnit = nil
    for _, colName in ipairs(CSV_COLUMN_MAPPINGS.speed) do
        if units and units[colName] then
            speedUnit = units[colName]
            break
        end
    end
    local speedFactor = speedUnit and UNIT_CONVERSIONS.speed[speedUnit] or 3.6  -- default m/s to km/h
    local timeFactor = UNIT_CONVERSIONS.time[timeUnit] or 1.0
    local distanceFactor = UNIT_CONVERSIONS.distance[distanceUnit] or 1.0

    -- Parse data
    f:seek("set", 0)
    lineNum = 0

    local l = lap.new(track or '', car or '')
    local lastSampleTime = -SAMPLE_INTERVAL
    local steeringCap = math.pi

    local firstTime = nil
    local firstDistance = nil
    local finishTime = nil
    local lastPos = nil
    local crossedFinish = false

    -- First pass: find max brake pressure for normalization (if using pressure)
    if useBrakePressure then
        for line in f:lines() do
            lineNum = lineNum + 1
            if lineNum > skipUntil and line ~= "" and not line:match("^%s*$") then
                local fields = extractFields(line, indices)
                local pressure = tonumber(fields.brakePressure) or 0
                if pressure > brakePressureMax then
                    brakePressureMax = pressure
                end
            end
        end
        if brakePressureMax == 0 then brakePressureMax = 1 end  -- Prevent div by zero
        ac.log(string.format("lap.fromCSV: Max brake pressure: %.2f bar", brakePressureMax))

        -- Reset for second pass
        f:seek("set", 0)
        lineNum = 0
    end

    for line in f:lines() do
        lineNum = lineNum + 1

        if lineNum > skipUntil and line ~= "" and not line:match("^%s*$") then
            local fields = extractFields(line, indices)
            local time = tonumber(fields.time)

            if time then
                time = time * timeFactor  -- Convert to seconds
                if not firstTime then firstTime = time end

                if time >= lastSampleTime + SAMPLE_INTERVAL then
                    local pos

                    if useDistance then
                        -- Convert distance to lap progression (0-1)
                        local distance = tonumber(fields.distance) or 0
                        distance = distance * distanceFactor  -- Convert to meters
                        if not firstDistance then firstDistance = distance end
                        local lapDistance = distance - firstDistance
                        pos = lapDistance / trackLength
                        -- Handle wrap-around for distance
                        if pos > 1 then pos = pos - math.floor(pos) end
                    else
                        pos = tonumber(fields.pos)
                        if pos and pos > 1 then pos = pos / 100 end
                    end

                    if pos then
                        -- Detect finish line crossing (position wraps from high to low)
                        if lastPos and lastPos > 0.9 and pos < 0.1 then
                            finishTime = time
                            crossedFinish = true
                            break  -- Stop at finish line
                        end

                        lastSampleTime = time
                        lastPos = pos

                        local speed = tonumber(fields.speed) or 0
                        local throttle = tonumber(fields.throttle) or 0
                        local clutch = tonumber(fields.clutch) or 0
                        local steering = tonumber(fields.steering) or 0

                        -- Get brake value (pressure normalized or position)
                        local brake = 0
                        if useBrakePressure then
                            local pressure = tonumber(fields.brakePressure) or 0
                            brake = pressure / brakePressureMax  -- Normalize to 0-1
                        elseif indices.brakePos then
                            brake = tonumber(fields.brakePos) or 0
                            if brake > 1 then brake = brake / 100 end
                        end

                        -- Normalize 0-100 to 0-1
                        if throttle > 1 then throttle = throttle / 100 end
                        if clutch > 1 then clutch = clutch / 100 end

                        -- Convert speed to km/h
                        speed = speed * speedFactor

                        -- Normalize steering
                        local steerNorm = math.clamp(0.5 - math.rad(steering) / (2 * steeringCap), 0, 1)

                        local sampleTime = time - firstTime  -- Time since lap start
                        table.insert(l.times, sampleTime)
                        table.insert(l.pos, pos)
                        table.insert(l.throttle, throttle)
                        table.insert(l.brake, brake)
                        table.insert(l.clutch, 1 - clutch)
                        table.insert(l.steering, steerNorm)
                        table.insert(l.speed, speed)
                    end
                end
            end
        end
    end

    f:close()

    if #l.pos < 10 then
        ac.log("lap.fromCSV: Not enough data points (" .. #l.pos .. ")")
        return nil, {"Not enough data points: " .. #l.pos}
    end

    l.completed = crossedFinish
    local endTime = finishTime or lastSampleTime
    l.time = (endTime - (firstTime or 0)) * 1000  -- ms

    -- Log warnings
    for _, warn in ipairs(warnings) do
        ac.log("lap.fromCSV: " .. warn)
    end

    ac.log(string.format("lap.fromCSV: Loaded %d samples (%.3fs, finish detected: %s)",
        #l.pos, l.time / 1000, crossedFinish and "yes" or "no"))
    ac.log(string.format("lap.fromCSV: pos range [%.4f - %.4f], times range [%.3f - %.3f]s",
        l.pos[1], l.pos[#l.pos], l.times[1], l.times[#l.times]))

    return l, #warnings > 0 and warnings or nil
end

return lap
