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
        
        -- Telemetry arrays (all synchronized, sampled at 15 Hz)
        throttle = {},         -- 0.0 to 1.0
        brake = {},            -- 0.0 to 1.0
        clutch = {},           -- 0.0 to 1.0 (inverted: 1.0 = pressed)
        steering = {},         -- 0.0 to 1.0 (normalized, 0.5 = straight)
        speed = {},            -- km/h
        pos = {},              -- spline position 0.0 to 1.0
        times = {},            -- seconds (elapsed lap time at each sample)
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
---@param threshold number Brake threshold (default 0.15)
---@return number|nil Spline position of brake point
function lap:findBrakePoint(startPos, endPos, threshold)
    threshold = threshold or 0.15
    
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
---@param onThreshold number Throttle "on" threshold (default 0.7)
---@param offThreshold number Throttle "off" threshold (default 0.5)
---@return number|nil Spline position of lift point
function lap:findLiftPoint(startPos, endPos, onThreshold, offThreshold)
    onThreshold = onThreshold or 0.7
    offThreshold = offThreshold or 0.5
    
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

--- Load lap from MoTeC CSV file
---@param filePath string Path to CSV file
---@param track string Track ID
---@param car string Car ID
---@return table|nil Lap instance
function lap.fromCSV(filePath, track, car)
    local SAMPLE_INTERVAL = 1 / lap.SAMPLE_RATE
    
    local f = io.open(filePath, "r")
    if not f then
        ac.log("lap.fromCSV: Failed to open " .. filePath)
        return nil
    end
    
    -- Find header row
    local indices = nil
    local skipUntil = 0
    local lineNum = 0
    
    for line in f:lines() do
        lineNum = lineNum + 1
        
        if line:find('"Time"') and line:find('"Lap Progression"') then
            -- Parse header
            local exactTargets = {
                time = "time",
                pos = "lap progression", 
                speed = "ground speed",
                throttle = "driver throttle pos",
                brake = "brake pos",
                clutch = "clutch pos",
                steering = "steering angle"
            }
            
            indices = {}
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
                    for key, target in pairs(exactTargets) do
                        if not indices[key] and field == target then
                            indices[key] = fieldIdx
                        end
                    end
                    fieldIdx = fieldIdx + 1
                    fieldStart = i + 1
                end
            end
            
            skipUntil = lineNum + 2
            break
        end
    end
    
    if not indices or not indices.time or not indices.pos then
        f:close()
        ac.log("lap.fromCSV: Could not find required columns")
        return nil
    end
    
    -- Parse data
    f:seek("set", 0)
    lineNum = 0
    
    local l = lap.new(track or '', car or '')
    local lastSampleTime = -SAMPLE_INTERVAL
    local steeringCap = math.pi
    
    -- Helper to extract fields
    local function extractFields(line, idxs)
        local maxIdx = 0
        for _, idx in pairs(idxs) do
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
                for key, idx in pairs(idxs) do
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
    
    local firstTime = nil
    local finishTime = nil
    local lastPos = nil
    local crossedFinish = false
    
    for line in f:lines() do
        lineNum = lineNum + 1
        
        if lineNum > skipUntil and line ~= "" and not line:match("^%s*$") then
            local fields = extractFields(line, indices)
            local time = tonumber(fields.time)
            
            if time then
                if not firstTime then firstTime = time end
                
                if time >= lastSampleTime + SAMPLE_INTERVAL then
                    local pos = tonumber(fields.pos)
                    if pos then
                        if pos > 1 then pos = pos / 100 end
                        
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
                        local brake = tonumber(fields.brake) or 0
                        local clutch = tonumber(fields.clutch) or 0
                        local steering = tonumber(fields.steering) or 0
                        
                        -- Normalize 0-100 to 0-1
                        if throttle > 1 then throttle = throttle / 100 end
                        if brake > 1 then brake = brake / 100 end
                        if clutch > 1 then clutch = clutch / 100 end
                        
                        -- Convert m/s to km/h
                        speed = speed * 3.6
                        
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
        return nil
    end
    
    -- Note: We keep data in time order, not sorted by position.
    -- For a normal lap, positions naturally increase from 0 to ~1.
    -- The times array preserves actual elapsed time at each sample.
    -- Times start at 0 for the first sample - no normalization needed.
    -- Delta calculations will be correct as long as both laps have consistent time=0 at similar positions.
    
    l.completed = crossedFinish
    -- Use finish time if detected, otherwise last sample time
    local endTime = finishTime or lastSampleTime
    l.time = (endTime - (firstTime or 0)) * 1000  -- ms
    
    ac.log(string.format("lap.fromCSV: Loaded %d samples (%.3fs, finish detected: %s)", 
        #l.pos, l.time / 1000, crossedFinish and "yes" or "no"))
    ac.log(string.format("lap.fromCSV: pos range [%.4f - %.4f], times range [%.3f - %.3f]s",
        l.pos[1], l.pos[#l.pos], l.times[1], l.times[#l.times]))
    return l
end

return lap
