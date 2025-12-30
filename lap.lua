-- lap.lua - Unified lap data structure
-- All lap data uses this structure: in-game recording, CSV import, storage

local lap = {}
lap.__index = lap

-- Extended brake module for better brake pressure data
local extended_brake = require('extended-brake')
local csv_parser = require('csv_parser')

-- Constants
lap.SAMPLE_RATE = 60  -- Hz (exported for other modules)
local STEERING_CAP = math.pi  -- 180 degrees in radians

--------------------------------------------------------------------------------
-- Flags Bitmask (in-sim only telemetry events)
-- NOTE: These flags are ONLY recorded for in-game laps, NOT loaded from CSV.
-- CSV imports don't have access to this low-level sim data (wheel slip, lockups, etc.)
-- The flags array stores a bitmask per sample for compact storage.
--------------------------------------------------------------------------------

lap.FLAGS = {
    TC_ACTIVE     = 0x01,  -- Traction control intervening
    LIMITER_HIT   = 0x02,  -- Rev limiter hit
    WHEEL_SLIP    = 0x04,  -- Significant wheel slip (any wheel spinning faster than road speed)
    LOCKUP_FL     = 0x08,  -- Front left wheel lockup (wheel stopped while car moving)
    LOCKUP_FR     = 0x10,  -- Front right wheel lockup
    LOCKUP_RL     = 0x20,  -- Rear left wheel lockup
    LOCKUP_RR     = 0x40,  -- Rear right wheel lockup
    OVERLAP       = 0x80,  -- Both pedals pressed (throttle & brake > 0.1 for > 100ms)
    OFFTRACK      = 0x100, -- Car went off track (2+ wheels outside track limits)
}

-- Thresholds for detecting events
local SLIP_THRESHOLD = 0.15      -- Wheel slip ratio threshold (15% difference from road speed)
local LOCKUP_SPEED_MIN = 20      -- Minimum car speed (km/h) for lockup detection
local OVERLAP_THRESHOLD = 0.1    -- Both pedals must be > 10% to count as overlap
local OVERLAP_MIN_DURATION = 0.1 -- 100ms minimum duration for overlap to be flagged

-- Overlap tracking state (per-lap)
local overlapStartTime = nil     -- When current overlap started (nil = not overlapping)

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

        -- Telemetry arrays (all synchronized, sampled at 60 Hz)
        throttle = {},         -- 0.0 to 1.0
        brake = {},            -- 0.0 to 1.0 (front brake pressure normalized)
        brake_r = {},          -- 0.0 to 1.0 (rear brake pressure normalized)
        clutch = {},           -- 0.0 to 1.0 (inverted: 1.0 = pressed)
        steering = {},         -- 0.0 to 1.0 (normalized, 0.5 = straight)
        speed = {},            -- km/h
        gear = {},             -- gear number (0=neutral, 1-N=forward, -1=reverse)
        pos = {},              -- spline position 0.0 to 1.0
        times = {},            -- seconds (elapsed lap time at each sample)
        fuel = {},             -- liters remaining

        -- In-sim only telemetry flags (bitmask per sample, see lap.FLAGS)
        -- NOTE: Not populated for CSV imports - these are sim-only events
        flags = {},            -- Bitmask: TC, limiter, wheel slip, lockups

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
    -- brake = front brake, brake_r = rear brake (or same as front if no DLL)
    local brakeFront, brakeRear = extended_brake.getNormalizedFrontRear(car)
    table.insert(self.brake, brakeFront)
    table.insert(self.brake_r, brakeRear)
    table.insert(self.clutch, 1 - car.clutch)  -- Invert: 1.0 = foot on pedal
    table.insert(self.steering, lap.normalizeSteer(car.steer))
    table.insert(self.speed, car.speedKmh)
    table.insert(self.gear, car.gear)
    table.insert(self.pos, car.splinePosition)
    table.insert(self.times, car.lapTimeMs / 1000)  -- seconds
    table.insert(self.fuel, car.fuel or 0)  -- Fuel remaining in liters

    -- Build flags bitmask for this sample (in-sim only data)
    local flagBits = 0

    -- TC active
    if car.tractionControlInAction then
        flagBits = bit.bor(flagBits, lap.FLAGS.TC_ACTIVE)
    end

    -- Rev limiter (engine hitting rev limit)
    if car.isEngineLimiterOn then
        flagBits = bit.bor(flagBits, lap.FLAGS.LIMITER_HIT)
    end

    -- Wheel slip detection (any wheel significantly faster than road speed)
    -- car.wheels[i].slip contains slip ratio
    if car.wheels then
        local hasSlip = false
        for i = 0, 3 do
            local wheel = car.wheels[i]
            if wheel and wheel.slip and wheel.slip > SLIP_THRESHOLD then
                hasSlip = true
                break
            end
        end
        if hasSlip then
            flagBits = bit.bor(flagBits, lap.FLAGS.WHEEL_SLIP)
        end

        -- Lockup detection (wheel locked while car is moving)
        -- Only detect lockups above minimum speed to avoid false positives at standstill
        if car.speedKmh > LOCKUP_SPEED_MIN then
            -- Lockup = wheel slip is very negative (wheel stopped/slowing, car moving)
            -- Use ndSlip (normalized directional slip) if available, fallback to slip
            -- Threshold: < -0.5 indicates significant lockup
            local LOCKUP_SLIP_THRESHOLD = -0.5
            local wheels = car.wheels

            local function isLocked(wheel)
                if not wheel then return false end
                local slip = wheel.ndSlip or wheel.slip
                return slip and slip < LOCKUP_SLIP_THRESHOLD
            end

            if isLocked(wheels[0]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_FL) end
            if isLocked(wheels[1]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_FR) end
            if isLocked(wheels[2]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_RL) end
            if isLocked(wheels[3]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_RR) end
        end
    end

    -- Overlap detection (both throttle and brake pressed > threshold)
    local currentTime = car.lapTimeMs / 1000
    local throttle = car.gas
    local brake = extended_brake.getNormalizedBrake(car)

    if throttle > OVERLAP_THRESHOLD and brake > OVERLAP_THRESHOLD then
        -- Both pedals pressed
        if not overlapStartTime then
            overlapStartTime = currentTime
        elseif currentTime - overlapStartTime >= OVERLAP_MIN_DURATION then
            -- Overlap has lasted long enough
            flagBits = bit.bor(flagBits, lap.FLAGS.OVERLAP)
        end
    else
        -- Pedals released, reset overlap tracking
        overlapStartTime = nil
    end

    -- Offtrack detection (2+ wheels outside track limits)
    if car.wheelsOutside and car.wheelsOutside >= 2 then
        flagBits = bit.bor(flagBits, lap.FLAGS.OFFTRACK)
    end

    table.insert(self.flags, flagBits)
end

--- Reset overlap tracking state (call when starting a new lap)
function lap.resetOverlapTracking()
    overlapStartTime = nil
end

--- Get number of samples in this lap
---@return number Sample count
function lap:length()
    return self.pos and #self.pos or 0
end

--- Check if lap has no data
---@return boolean True if lap is empty
function lap:isEmpty()
    return not self.pos or #self.pos == 0
end

--- Prune lap data to a specific position (for TimeShift rewind support)
--- Removes all samples after the given position
---@param targetPos number Spline position to prune to (0.0 to 1.0)
---@return number Number of samples removed
function lap:pruneToPosition(targetPos)
    if self:isEmpty() then return 0 end

    -- Find the last sample at or before targetPos
    local pruneIdx = nil
    for i = #self.pos, 1, -1 do
        if self.pos[i] <= targetPos then
            pruneIdx = i
            break
        end
    end

    if not pruneIdx then
        -- All samples are past targetPos, clear everything
        pruneIdx = 0
    end

    local originalLength = self:length()
    local samplesToRemove = originalLength - pruneIdx

    if samplesToRemove <= 0 then return 0 end

    -- Prune all arrays to pruneIdx length
    local arrays = {'throttle', 'brake', 'brake_r', 'clutch', 'steering', 'speed', 'gear', 'pos', 'times', 'fuel', 'flags'}
    for _, field in ipairs(arrays) do
        if self[field] then
            for i = originalLength, pruneIdx + 1, -1 do
                self[field][i] = nil
            end
        end
    end

    return samplesToRemove
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
    if not self.pos then return nil end
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
    if not self.pos then return nil end
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
    if not self.pos then return 0 end
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

--- Find minimum gear used in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@return number|nil Minimum gear (nil if no gear data)
function lap:findMinGear(startPos, endPos)
    if not self.gear or #self.gear == 0 then return nil end

    local minGear = nil

    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end

        if inRange and self.gear[i] then
            local g = self.gear[i]
            -- Only consider forward gears (1+)
            if g >= 1 then
                if not minGear or g < minGear then
                    minGear = g
                end
            end
        end
    end
    return minGear
end

--- Find apex (minimum speed point) in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@return number|nil apexPos Position of minimum speed
---@return number|nil apexSpeed Speed at apex
function lap:findApex(startPos, endPos)
    if not self.pos then return nil, nil end
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
    if self:isEmpty() then return nil end
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

--- Find exit speed (max speed in last 1/3 of corner)
---@param startPos number Start of corner
---@param endPos number End of corner
---@return number|nil exitSpeed Max speed in exit phase
function lap:findExitSpeed(startPos, endPos)
    if self:isEmpty() then return nil end

    -- Calculate the last 1/3 of the corner
    local cornerLength = endPos - startPos
    if cornerLength < 0 then cornerLength = cornerLength + 1 end  -- Handle wrap-around

    local lastThirdStart = endPos - cornerLength / 3
    if lastThirdStart < 0 then lastThirdStart = lastThirdStart + 1 end

    -- Find max speed in the last 1/3 of the corner
    local maxSpeed = 0
    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if lastThirdStart <= endPos then
            inRange = pos >= lastThirdStart and pos <= endPos
        else
            -- Handle wrap-around
            inRange = pos >= lastThirdStart or pos <= endPos
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
-- Flags Helpers (in-sim only data - will be nil/empty for CSV imports)
--------------------------------------------------------------------------------

--- Check if any sample in a position range has a specific flag set
---@param startPos number Start of search range
---@param endPos number End of search range
---@param flag number Flag bit to check (from lap.FLAGS)
---@return boolean True if flag was set at any point in range
function lap:hasFlagInRange(startPos, endPos, flag)
    if not self.flags or #self.flags == 0 then return false end

    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end

        if inRange and self.flags[i] then
            if bit.band(self.flags[i], flag) ~= 0 then
                return true
            end
        end
    end
    return false
end

--- Check if any lockup occurred in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@return boolean anyLockup True if any wheel locked up
---@return table|nil wheels Table of locked wheels {fl=bool, fr=bool, rl=bool, rr=bool}
function lap:hasLockupInRange(startPos, endPos)
    if not self.flags or #self.flags == 0 then return false, nil end

    local lockups = { fl = false, fr = false, rl = false, rr = false }
    local anyLockup = false

    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end

        if inRange and self.flags[i] then
            local f = self.flags[i]
            if bit.band(f, lap.FLAGS.LOCKUP_FL) ~= 0 then lockups.fl = true; anyLockup = true end
            if bit.band(f, lap.FLAGS.LOCKUP_FR) ~= 0 then lockups.fr = true; anyLockup = true end
            if bit.band(f, lap.FLAGS.LOCKUP_RL) ~= 0 then lockups.rl = true; anyLockup = true end
            if bit.band(f, lap.FLAGS.LOCKUP_RR) ~= 0 then lockups.rr = true; anyLockup = true end
        end
    end

    return anyLockup, anyLockup and lockups or nil
end

--- Count samples with a specific flag set in a position range
---@param startPos number Start of search range
---@param endPos number End of search range
---@param flag number Flag bit to check (from lap.FLAGS)
---@return number count Number of samples with flag set
function lap:countFlagInRange(startPos, endPos, flag)
    if not self.flags or #self.flags == 0 then return 0 end

    local count = 0
    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end

        if inRange and self.flags[i] then
            if bit.band(self.flags[i], flag) ~= 0 then
                count = count + 1
            end
        end
    end
    return count
end

--- Get total overlap time in a position range (in seconds)
---@param startPos number Start of search range
---@param endPos number End of search range
---@return number overlapTime Total time in seconds with overlap flag set
function lap:getOverlapTimeInRange(startPos, endPos)
    if not self.flags or #self.flags == 0 or not self.times or #self.times == 0 then
        return 0
    end

    local totalTime = 0
    local sampleDt = 1 / lap.SAMPLE_RATE  -- Time per sample

    for i = 1, #self.pos do
        local pos = self.pos[i]
        local inRange
        if startPos <= endPos then
            inRange = pos >= startPos and pos <= endPos
        else
            inRange = pos >= startPos or pos <= endPos
        end

        if inRange and self.flags[i] then
            if bit.band(self.flags[i], lap.FLAGS.OVERLAP) ~= 0 then
                totalTime = totalTime + sampleDt
            end
        end
    end

    return totalTime
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
        brake_r = self.brake_r,  -- Rear brake pressure
        clutch = self.clutch,
        steering = self.steering,
        speed = self.speed,
        gear = self.gear,        -- Gear number
        pos = self.pos,
        times = self.times,  -- Actual elapsed time at each sample
        fuel = self.fuel,    -- Fuel remaining in liters
        flags = self.flags,  -- In-sim only: TC, limiter, slip, lockups (bitmask per sample)
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
    if self:isEmpty() or #self.pos < 10 then return false end
    
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
    -- csv_parser returns { data = {...arrays...}, time, completed, fuelLeftAtStart, csvSource }
    local data = parsed.data
    if not data or not data.pos or #data.pos == 0 then
        return nil, {"CSV parsed but no position data found"}
    end

    local l = lap.new(track or '', car or '')
    l.pos = data.pos
    l.times = data.times
    l.throttle = data.throttle
    l.brake = data.brake
    l.brake_r = data.brake_r or data.brake  -- Rear brake (or same as front if not available)
    l.clutch = data.clutch
    l.steering = data.steering
    l.speed = data.speed
    l.fuel = data.fuel or {}
    l.time = parsed.time
    l.completed = parsed.completed
    l.fuelLeftAtStart = parsed.fuelLeftAtStart or 0
    l.csvSource = parsed.csvSource

    ac.log(string.format("lap.fromCSV: Loaded lap with %d samples, time: %.3fs",
        l:length(), l.time / 1000))

    return l, warnings
end

return lap
