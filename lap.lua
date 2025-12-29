-- lap.lua - Unified lap data structure
-- All lap data uses this structure: in-game recording, CSV import, storage

local lap = {}
lap.__index = lap

-- Extended brake module for better brake pressure data
local extended_brake = require('extended-brake')
local csv_parser = require('csv_parser')

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
        fuel = {},             -- liters remaining

        -- CSV import metadata (nil for in-game recorded laps)
        csvSource = nil,       -- { throttle, brake, speed, steering, clutch, position, fuel }
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
    -- Use extended brake pressure if available, otherwise fall back to pedal position
    table.insert(self.brake, extended_brake.getNormalizedBrake(car))
    table.insert(self.clutch, 1 - car.clutch)  -- Invert: 1.0 = foot on pedal
    table.insert(self.steering, lap.normalizeSteer(car.steer))
    table.insert(self.speed, car.speedKmh)
    table.insert(self.pos, car.splinePosition)
    table.insert(self.times, car.lapTimeMs / 1000)  -- seconds
    table.insert(self.tcActive, car.tractionControlInAction or false)
    table.insert(self.fuel, car.fuel or 0)  -- Fuel remaining in liters
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
    threshold = threshold or 0.1  -- 10% brake pressure
    
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
--- Lift point = first position where throttle drops below threshold after being at full throttle
---@param startPos number Start of search range
---@param endPos number End of search range
---@param fullThrottleThreshold number Throttle threshold for "full throttle" (default 0.98)
---@return number|nil Spline position of lift point
function lap:findLiftPoint(startPos, endPos, fullThrottleThreshold)
    fullThrottleThreshold = fullThrottleThreshold or 0.98  -- 98% = full throttle

    local wasOnFullThrottle = false

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
            if throttle >= fullThrottleThreshold then
                wasOnFullThrottle = true
            elseif wasOnFullThrottle and throttle < fullThrottleThreshold then
                return pos  -- First drop below 98%
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

--- Find entry speed (max speed in first half of corner or before min speed point)
---@param startPos number Start of corner
---@param endPos number End of corner
---@return number|nil entrySpeed Max speed in entry phase
function lap:findEntrySpeed(startPos, endPos)
    -- First find the apex (min speed position)
    local apexPos, _ = self:findApex(startPos, endPos)
    if not apexPos then return self:getValueAtPos('speed', startPos) end

    -- Find max speed from start to apex
    local maxSpeed = 0
    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if startPos <= apexPos then
            inRange = pos >= startPos and pos <= apexPos
        else
            inRange = pos >= startPos or pos <= apexPos
        end

        if inRange then
            local speed = self.speed[i]
            if speed and speed > maxSpeed then
                maxSpeed = speed
            end
        end
    end

    return maxSpeed > 0 and maxSpeed or nil
end

--- Find exit speed (max speed in second half of corner or after min speed point)
---@param startPos number Start of corner
---@param endPos number End of corner
---@return number|nil exitSpeed Max speed in exit phase
function lap:findExitSpeed(startPos, endPos)
    -- First find the apex (min speed position)
    local apexPos, _ = self:findApex(startPos, endPos)
    if not apexPos then return self:getValueAtPos('speed', endPos) end

    -- Find max speed from apex to end
    local maxSpeed = 0
    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if apexPos <= endPos then
            inRange = pos >= apexPos and pos <= endPos
        else
            inRange = pos >= apexPos or pos <= endPos
        end

        if inRange then
            local speed = self.speed[i]
            if speed and speed > maxSpeed then
                maxSpeed = speed
            end
        end
    end

    return maxSpeed > 0 and maxSpeed or nil
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
        fuel = self.fuel,    -- Fuel remaining in liters
        csvSource = self.csvSource,  -- CSV column mappings
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
--- Supports both AC sim exports (with Lap Progression) and real car exports (with Distance)
--- For multi-lap files, automatically selects the fastest complete lap
---@param filePath string Path to CSV file
---@param track string Track ID
---@param car string Car ID
---@param trackLength number|nil Track length in meters (required for distance-based CSVs)
---@return table|nil Lap instance
---@return table|nil warnings Array of warning messages
function lap.fromCSV(filePath, track, car, trackLength)
    -- Delegate to csv_parser module
    local parsed, warnings = csv_parser.parseFile(filePath, trackLength)
    if not parsed then
        return nil, warnings
    end

    -- Create lap from parsed data
    local l = lap.new(track or '', car or '')
    l.pos = parsed.pos
    l.times = parsed.times
    l.throttle = parsed.throttle
    l.brake = parsed.brake
    l.clutch = parsed.clutch
    l.steering = parsed.steering
    l.speed = parsed.speed
    l.fuel = parsed.fuel or {}
    l.time = parsed.time
    l.completed = parsed.completed
    l.fuelLeftAtStart = parsed.fuelLeftAtStart or 0
    l.csvSource = parsed.csvSource

    return l, warnings
end

return lap
