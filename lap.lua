-- lap.lua - Unified lap data structure
-- All lap data uses this structure: in-game recording, CSV import, storage

local lap = {}
lap.__index = lap

-- Extended brake module for better brake pressure data
local extended_brake = require('extended-brake')
local csv_parser = require('csv_parser')

-- Constants
lap.SAMPLE_RATE = 30  -- Hz (exported for other modules)
local STEERING_CAP = math.pi  -- 180 degrees in radians
local SPARSE_EPS = 1e-4
local SPARSE_POS_EPS = 1e-6

-- Sparse channels (position -> value) for low-frequency settings
lap.SPARSE_FIELDS = {
    brake_balance = true,
    tc_slip = true,
    tc_gain = true,
    fuel = true,
}

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
-- Wheel slip detection thresholds
-- slipRatio: positive = wheel spinning faster (wheelspin), negative = wheel spinning slower (lockup)
local WHEELSPIN_THRESHOLD = 0.3   -- 30% faster than road speed = significant wheelspin
local LOCKUP_THRESHOLD = -0.8     -- Wheel at 20% of road speed = locked up (slipRatio close to -1)
local LOCKUP_SPEED_MIN = 30       -- Minimum car speed (km/h) for lockup detection
local OVERLAP_THROTTLE_THRESHOLD = 0.1  -- Throttle must be > 10% for overlap
lap.BRAKE_THRESHOLD_BAR = 5             -- Minimum brake pressure to count as braking (bar)
local OVERLAP_BRAKE_THRESHOLD_BAR = 10  -- Brake must be > 10 bar for overlap
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
        brake = {},            -- bar (front brake pressure) - NOT normalized, stored in bar
        brake_r = {},          -- bar (rear brake pressure) - NOT normalized, stored in bar
        clutch = {},           -- 0.0 to 1.0 (inverted: 1.0 = pressed)
        steering = {},         -- 0.0 to 1.0 (normalized, 0.5 = straight)
        speed = {},            -- km/h
        gear = {},             -- gear number (0=neutral, 1-N=forward, -1=reverse)
        pos = {},              -- spline position 0.0 to 1.0
        times = {},            -- seconds (elapsed lap time at each sample)
        fuel = {},             -- liters remaining
        gforce = {},           -- vec3 (X = lateral, Z = longitudinal)

        -- In-sim only telemetry flags (bitmask per sample, see lap.FLAGS)
        -- NOTE: Not populated for CSV imports - these are sim-only events
        flags = {},            -- Bitmask: TC, limiter, wheel slip, lockups

        -- Sparse channels (position -> value) for low-frequency settings
        -- Format: { {pos, value}, ... } in ascending pos order
        sparse = {
            brake_balance = {},
            tc_slip = {},
            tc_gain = {},
            fuel = {},
        },

        -- CSV import metadata (nil for in-game recorded laps)
        csvSource = nil,       -- { throttle, brake, speed, steering, clutch, position, fuel }
    }, lap)
end

--------------------------------------------------------------------------------
-- Sparse Helpers
--------------------------------------------------------------------------------

local function ensureSparseTable(self)
    if self.sparse then return end
    self.sparse = {
        brake_balance = {},
        tc_slip = {},
        tc_gain = {},
        fuel = {},
    }
end

local function sparseAppend(list, pos, value)
    if value == nil then return end
    if not list then return end
    local n = #list
    if n == 0 then
        table.insert(list, { pos, value })
        return
    end
    local last = list[n]
    if last then
        local lastPos = last[1] or 0
        local lastVal = last[2] or 0
        -- If position is effectively the same, keep the latest value only
        if math.abs(lastPos - pos) <= SPARSE_POS_EPS then
            last[2] = value
            return
        end
        -- If value hasn't changed, previous sample covers this range
        if math.abs(lastVal - value) <= SPARSE_EPS then
            return
        end
    end
    table.insert(list, { pos, value })
end

--- Append a sparse sample for a low-frequency field
---@param field string Sparse field name
---@param pos number Spline position
---@param value number Value to record
function lap:addSparseSample(field, pos, value)
    if not lap.SPARSE_FIELDS[field] then return end
    ensureSparseTable(self)
    sparseAppend(self.sparse[field], pos, value)
end

--- Get sparse value at a specific track position (step-wise)
---@param field string Sparse field name
---@param targetPos number Spline position (0.0 to 1.0)
---@return number|nil Value at that position
function lap:getSparseAtPos(field, targetPos)
    if not lap.SPARSE_FIELDS[field] then return nil end
    if targetPos == nil then return nil end
    if not self.sparse or not self.sparse[field] then return nil end
    local list = self.sparse[field]
    if #list == 0 then return nil end

    -- Binary search for last entry <= targetPos
    local lo, hi = 1, #list
    if targetPos <= list[1][1] then
        return list[1][2]
    end
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if list[mid][1] <= targetPos then
            lo = mid
        else
            hi = mid - 1
        end
    end
    return list[lo][2]
end

--- Build sparse samples from a dense array (position-based)
---@param field string Dense field name to compress into sparse
function lap:populateSparseFromDense(field)
    if not lap.SPARSE_FIELDS[field] then return end
    if not self[field] or #self[field] == 0 then return end
    if not self.pos or #self.pos == 0 then return end
    ensureSparseTable(self)

    local out = {}
    local last = nil
    for i = 1, #self[field] do
        local v = self[field][i]
        if v ~= nil and (last == nil or math.abs(v - last) > SPARSE_EPS) then
            local p = self.pos[i]
            if p ~= nil then
                table.insert(out, { p, v })
                last = v
            end
        end
    end
    self.sparse[field] = out
end

--------------------------------------------------------------------------------
-- Position Range Checking (handles track wrap-around)
--------------------------------------------------------------------------------

--- Check if a position is within a range, handling track wrap-around
--- When startPos > endPos, the range wraps around the track (crosses 0.0 finish line)
---@param pos number Current position (0.0 to 1.0)
---@param startPos number Range start position (0.0 to 1.0)
---@param endPos number Range end position (0.0 to 1.0)
---@return boolean True if position is in range
function lap.isInRange(pos, startPos, endPos)
    if startPos <= endPos then
        -- Normal range (no wrap-around)
        return pos >= startPos and pos <= endPos
    else
        -- Wrap-around range (crosses finish line)
        return pos >= startPos or pos <= endPos
    end
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
-- Flag Detection (shared across in-sim recording)
--------------------------------------------------------------------------------

--- Detect and compute flag bitmask for current car state
--- This is a static function used both during live recording and for display
---@param car table Car state from ac.getCar()
---@param overlapState table Table with { startTime = number|nil } to track overlap state
---@return number flagBits Bitmask of lap.FLAGS
function lap.detectFlags(car, overlapState)
    local flagBits = 0
    
    -- TC active
    if car.tractionControlInAction then
        flagBits = bit.bor(flagBits, lap.FLAGS.TC_ACTIVE)
    end
    
    -- Rev limiter
    if car.isEngineLimiterOn then
        flagBits = bit.bor(flagBits, lap.FLAGS.LIMITER_HIT)
    end
    
    -- Wheel slip and lockup detection using slipRatio
    -- slipRatio: positive = wheel spinning faster than road (wheelspin/traction loss)
    --            negative = wheel spinning slower than road (braking lockup)
    --            -1 = completely locked, 0 = matching road speed
    if car.wheels then
        local hasWheelspin = false
        
        for i = 0, 3 do
            local wheel = car.wheels[i]
            if wheel then
                -- Use slipRatio for wheelspin detection (positive = spinning faster than road)
                local slipRatio = wheel.slipRatio or 0
                if slipRatio > WHEELSPIN_THRESHOLD then
                    hasWheelspin = true
                end
            end
        end
        
        if hasWheelspin then
            flagBits = bit.bor(flagBits, lap.FLAGS.WHEEL_SLIP)
        end
        
        -- Lockup detection (only at speed, using slipRatio)
        if car.speedKmh > LOCKUP_SPEED_MIN then
            local function isLocked(wheel)
                if not wheel then return false end
                -- slipRatio close to -1 means wheel is nearly stopped while car is moving
                local slipRatio = wheel.slipRatio or 0
                return slipRatio < LOCKUP_THRESHOLD
            end
            
            if isLocked(car.wheels[0]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_FL) end
            if isLocked(car.wheels[1]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_FR) end
            if isLocked(car.wheels[2]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_RL) end
            if isLocked(car.wheels[3]) then flagBits = bit.bor(flagBits, lap.FLAGS.LOCKUP_RR) end
        end
    end
    
    -- Overlap detection (throttle AND brake pressed simultaneously)
    if overlapState then
        local currentTime = car.lapTimeMs / 1000
        local throttle = car.gas
        local brakeBar = extended_brake.getBrakePressureBar(car)
        
        if throttle > OVERLAP_THROTTLE_THRESHOLD and brakeBar > OVERLAP_BRAKE_THRESHOLD_BAR then
            if not overlapState.startTime then
                overlapState.startTime = currentTime
            elseif currentTime - overlapState.startTime >= OVERLAP_MIN_DURATION then
                flagBits = bit.bor(flagBits, lap.FLAGS.OVERLAP)
            end
        else
            overlapState.startTime = nil
        end
    end
    
    -- Offtrack detection (2+ wheels off track)
    if car.wheelsOutside and car.wheelsOutside >= 2 then
        flagBits = bit.bor(flagBits, lap.FLAGS.OFFTRACK)
    end
    
    return flagBits
end

--------------------------------------------------------------------------------
-- Recording
--------------------------------------------------------------------------------

--- Add a sample from current car state
---@param self table Lap instance
---@param car table Car state from ac.getCar()
---@param timeOffsetMs number|nil Optional time offset in ms (for checkpoint restore correction)
function lap:addSample(car, timeOffsetMs)
    table.insert(self.throttle, car.gas)
    -- Get brake pressure in bar (from cphys DLL or fallback: pedal * 100)
    -- brake = front brake, brake_r = rear brake (or same as front if no DLL)
    local brakeFrontBar, brakeRearBar = extended_brake.getFrontRearBar(car)
    table.insert(self.brake, brakeFrontBar)
    table.insert(self.brake_r, brakeRearBar)
    table.insert(self.clutch, 1 - car.clutch)  -- Invert: 1.0 = foot on pedal
    table.insert(self.steering, lap.normalizeSteer(car.steer))
    table.insert(self.speed, car.speedKmh)
    table.insert(self.gear, car.gear)
    table.insert(self.pos, car.splinePosition)
    -- Apply time offset correction (for checkpoint restore)
    local correctedTimeMs = car.lapTimeMs - (timeOffsetMs or 0)
    table.insert(self.times, correctedTimeMs / 1000)  -- seconds
    -- Fuel is recorded as a sparse channel (low-frequency changes)
    self:addSparseSample('fuel', car.splinePosition, car.fuel or 0)

    -- G-forces (non-sparse, full resolution)
    -- Must copy the vec3 values since car.acceleration is reused each frame
    if car.acceleration then
        table.insert(self.gforce, vec3(car.acceleration.x, car.acceleration.y, car.acceleration.z))
    end

    -- Low-frequency settings (sparse)
    if car.brakeBias then
        self:addSparseSample('brake_balance', car.splinePosition, car.brakeBias)
    end
    if car.tractionControlMode then
        self:addSparseSample('tc_slip', car.splinePosition, car.tractionControlMode)
    end
    if car.tractionControl2 then
        self:addSparseSample('tc_gain', car.splinePosition, car.tractionControl2)
    end

    -- Build flags bitmask for this sample (in-sim only data)
    -- Use shared detection function with overlap state tracking
    local overlapState = { startTime = overlapStartTime }
    local flagBits = lap.detectFlags(car, overlapState)
    overlapStartTime = overlapState.startTime  -- Sync state back
    
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

--- Get maximum brake pressure in bar for this lap
--- Get maximum brake pressure in the lap (minimum 80 bar for chart scaling)
--- Caches result in _maxBrakeBar for completed laps
---@return number Maximum brake pressure in bar (minimum 80)
function lap:maxBrakeBars()
    -- Return cached value if available
    if self._maxBrakeBar then return self._maxBrakeBar end
    
    if self:isEmpty() or not self.brake then return 80 end
    
    local maxBar = 0
    for i = 1, #self.brake do
        if self.brake[i] > maxBar then
            maxBar = self.brake[i]
        end
    end
    
    -- Minimum of 80 bar for sensible chart scaling (race cars use 80-120+ bar)
    maxBar = math.max(maxBar, 80)
    
    -- Cache only for completed laps (still recording laps may get higher values)
    if self.completed then
        self._maxBrakeBar = maxBar
    end
    
    return maxBar
end

--- Prune lap data to a specific position (for TimeShift rewind support)
--- Removes all samples after the given position
--- Handles wrap-around near start/finish line correctly
---@param targetPos number Spline position to prune to (0.0 to 1.0)
---@return number Number of samples removed
function lap:pruneToPosition(targetPos)
    if self:isEmpty() then return 0 end

    -- Find the last sample that should be kept
    -- We need to handle wrap-around: if lap crosses 0 (e.g., 0.98, 0.99, 0.01, 0.02)
    -- and we rewind to 0.95, we need to prune everything after position wrapped
    
    local pruneIdx = nil
    local n = #self.pos
    
    -- First, check if the lap data wraps around (crosses start/finish)
    local hasWrapAround = false
    local wrapIdx = nil
    for i = 1, n - 1 do
        if self.pos[i] > 0.9 and self.pos[i + 1] < 0.1 then
            hasWrapAround = true
            wrapIdx = i
            break
        end
    end
    
    if hasWrapAround and wrapIdx then
        -- Lap wraps around at wrapIdx
        if targetPos > 0.5 then
            -- Target is in the "before wrap" portion (e.g., 0.95)
            -- Only keep samples before the wrap that are <= targetPos
            for i = wrapIdx, 1, -1 do
                if self.pos[i] <= targetPos then
                    pruneIdx = i
                    break
                end
            end
        else
            -- Target is in the "after wrap" portion (e.g., 0.05)
            -- Keep all samples before wrap, plus samples after wrap that are <= targetPos
            for i = n, wrapIdx + 1, -1 do
                if self.pos[i] <= targetPos then
                    pruneIdx = i
                    break
                end
            end
            -- If not found after wrap, target might be before wrap point
            if not pruneIdx then
                pruneIdx = wrapIdx
            end
        end
    else
        -- No wrap-around: simple linear search from end
        for i = n, 1, -1 do
            if self.pos[i] <= targetPos then
                pruneIdx = i
                break
            end
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
    local arrays = {'throttle', 'brake', 'brake_r', 'clutch', 'steering', 'speed', 'gear', 'pos', 'times', 'fuel', 'gforce', 'flags'}
    for _, field in ipairs(arrays) do
        if self[field] then
            for i = originalLength, pruneIdx + 1, -1 do
                self[field][i] = nil
            end
        end
    end

    -- Prune sparse channels
    if self.sparse then
        for field, list in pairs(self.sparse) do
            if type(list) == 'table' and #list > 0 then
                for i = #list, 1, -1 do
                    if list[i][1] > targetPos then
                        table.remove(list, i)
                    else
                        break
                    end
                end
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

--- Internal: interpolate a dense array at position
---@param data table Array of values
---@param targetPos number Spline position (0.0 to 1.0)
---@return number|nil Interpolated value
local function interpolateAt(self, data, targetPos)
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
-- Accessors - :fieldAt(pos) for all telemetry fields
--------------------------------------------------------------------------------

--- Get throttle at position (0-1)
---@param pos number Spline position
---@return number|nil
function lap:throttleAt(pos) return interpolateAt(self, self.throttle, pos) end

--- Get brake pressure at position (in bar)
---@param pos number Spline position
---@return number|nil
function lap:brakeAt(pos) return interpolateAt(self, self.brake, pos) end

--- Get rear brake pressure at position (in bar)
---@param pos number Spline position
---@return number|nil
function lap:brakeRearAt(pos) return interpolateAt(self, self.brake_r, pos) end

--- Get brake as percentage of scale (0-1, for chart rendering)
---@param pos number Spline position
---@param maxBar number? Max brake for normalization (default 100 bar)
---@return number|nil Normalized 0-1 value
function lap:brakePercentAt(pos, maxBar)
    local bar = self:brakeAt(pos)
    if not bar then return nil end
    maxBar = maxBar or 100
    return math.min(bar / maxBar, 1.0)
end

--- Get clutch at position (0-1, inverted: 1 = pressed)
---@param pos number Spline position
---@return number|nil
function lap:clutchAt(pos) return interpolateAt(self, self.clutch, pos) end

--- Get steering at position (0-1 normalized, 0.5 = straight)
---@param pos number Spline position
---@return number|nil
function lap:steeringAt(pos) return interpolateAt(self, self.steering, pos) end

--- Get steering in degrees at position
---@param pos number Spline position
---@return number|nil Degrees (negative = left, positive = right)
function lap:steeringDegAt(pos)
    local norm = self:steeringAt(pos)
    if not norm then return nil end
    return lap.steerToDegrees(norm)
end

--- Get speed at position (km/h)
---@param pos number Spline position
---@return number|nil
function lap:speedAt(pos) return interpolateAt(self, self.speed, pos) end

--- Get gear at position
---@param pos number Spline position
---@return number|nil
function lap:gearAt(pos) return interpolateAt(self, self.gear, pos) end

--- Get fuel at position (liters) - sparse field
---@param pos number Spline position
---@return number|nil
function lap:fuelAt(pos) 
    -- Fuel is sparse, try dense first then fall back to sparse
    local dense = interpolateAt(self, self.fuel, pos)
    if dense then return dense end
    return self:getSparseAtPos('fuel', pos)
end

--- Get brake balance at position - sparse field
---@param pos number Spline position
---@return number|nil
function lap:brakeBalanceAt(pos) return self:getSparseAtPos('brake_balance', pos) end

--- Get TC slip setting at position - sparse field
---@param pos number Spline position
---@return number|nil
function lap:tcSlipAt(pos) return self:getSparseAtPos('tc_slip', pos) end

--- Get TC gain setting at position - sparse field
---@param pos number Spline position
---@return number|nil
function lap:tcGainAt(pos) return self:getSparseAtPos('tc_gain', pos) end

--- Get time at position (seconds)
---@param pos number Spline position
---@return number|nil
function lap:timeAt(pos) return self:getTimeAtPos(pos) end

--------------------------------------------------------------------------------
-- Trace Extraction
--------------------------------------------------------------------------------

--- Get traces for display, matched to specified positions
---@param positions table Array of spline positions to match
---@param maxBar number? Max brake pressure for normalization (default 100)
---@return table|nil traces { throttle={}, brake={}, clutch={}, steering={}, speed={}, gear={} }
function lap:getTracesAt(positions, maxBar)
    if not positions or #positions < 1 then return nil end

    maxBar = maxBar or 100  -- Default to 100 bar for normalization

    local traces = {
        throttle = {},
        brake = {},
        clutch = {},
        steering = {},
        speed = {},
        gear = {}
    }

    for i = 1, #positions do
        local pos = positions[i]
        table.insert(traces.throttle, self:throttleAt(pos) or 0)
        table.insert(traces.brake, self:brakePercentAt(pos, maxBar) or 0)
        table.insert(traces.clutch, self:clutchAt(pos) or 0)
        table.insert(traces.steering, self:steeringAt(pos) or 0.5)
        table.insert(traces.speed, self:speedAt(pos) or 0)
        table.insert(traces.gear, self:gearAt(pos) or 0)
    end

    return traces
end

--------------------------------------------------------------------------------
-- Corner Analysis Helpers
--------------------------------------------------------------------------------

--- Find brake point in a position range (first significant brake application)
---@param startPos number Start of search range
---@param endPos number End of search range
---@param threshold number? Brake threshold (default lap.BRAKE_THRESHOLD_BAR)
---@return number|nil Spline position of brake point
function lap:findBrakePoint(startPos, endPos, threshold)
    if not self.pos then return nil end
    threshold = threshold or lap.BRAKE_THRESHOLD_BAR

    for i = 1, #self.pos do
         local pos = self.pos[i]
         if lap.isInRange(pos, startPos, endPos) and self.brake[i] > threshold then
             return pos
         end
     end
     return nil
 end

--- Find throttle lift point in a position range
--- Lift point = first position where throttle drops below threshold after being at full throttle
--- Ignores brief throttle lifts during gear shifts (within GEAR_SHIFT_WINDOW samples)
---@param startPos number Start of search range
---@param endPos number End of search range
---@param fullThrottleThreshold number Throttle threshold for "full throttle" (default 0.98)
---@return number|nil Spline position of lift point
function lap:findLiftPoint(startPos, endPos, fullThrottleThreshold)
    if not self.pos then return nil end
    fullThrottleThreshold = fullThrottleThreshold or 0.98  -- 98% = full throttle

    local GEAR_SHIFT_WINDOW = 30  -- Samples to ignore around gear shifts (~0.5s at 60Hz)

    -- Helper to check if a gear shift occurred near index i
    local function isNearGearShift(i)
        if not self.gear or #self.gear < 2 then return false end
        local currentGear = self.gear[i]
        if not currentGear then return false end

        -- Check samples before and after for gear changes
        for j = math.max(1, i - GEAR_SHIFT_WINDOW), math.min(#self.gear, i + GEAR_SHIFT_WINDOW) do
            if self.gear[j] and self.gear[j] ~= currentGear then
                return true
            end
        end
        return false
    end

    local wasOnFullThrottle = false

    for i = 1, #self.pos do
        local pos = self.pos[i]
        if lap.isInRange(pos, startPos, endPos) then
            local throttle = self.throttle[i]
            if throttle >= fullThrottleThreshold then
                wasOnFullThrottle = true
            elseif wasOnFullThrottle and throttle < fullThrottleThreshold then
                -- Check if this is a gear shift - if so, skip it
                if not isNearGearShift(i) then
                    return pos  -- Real lift point (not a gear shift)
                end
                -- Otherwise continue looking - this was just a gear shift throttle cut
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
         if lap.isInRange(pos, startPos, endPos) then
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
         if lap.isInRange(pos, startPos, endPos) and self.gear[i] then
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
         if lap.isInRange(pos, startPos, endPos) and self.speed[i] < minSpeed then
             minSpeed = self.speed[i]
             apexPos = pos
         end
     end

    if apexPos then
        return apexPos, minSpeed
    end
    return nil, nil
end

--- Find the delay in milliseconds between brake initiation and first/last downshift
--- Useful for analyzing braking technique (trail braking with heel-toe)
---@param startPos number Start of search range
---@param endPos number End of search range
---@param brakeThreshold number? Brake threshold in bar (default lap.BRAKE_THRESHOLD_BAR)
---@return number|nil firstDelayMs Milliseconds between brake and first downshift (reaction time)
---@return number|nil lastDelayMs Milliseconds between brake and last downshift (total shift time)
---@return number|nil brakeTime Time of brake initiation
---@return number|nil firstDownshiftTime Time of first downshift
---@return number|nil lastDownshiftTime Time of last downshift
function lap:findDownshiftDelay(startPos, endPos, brakeThreshold)
    if not self.pos or #self.pos < 2 then return nil end
    if not self.gear or #self.gear < 2 then return nil end
    if not self.times or #self.times < 2 then return nil end
    if not self.brake or #self.brake < 2 then return nil end

    brakeThreshold = brakeThreshold or lap.BRAKE_THRESHOLD_BAR

    -- Find brake initiation point (first sample where brake > threshold)
    local brakeIdx = nil
    local brakeTime = nil
    local brakeGear = nil

    for i = 1, #self.pos do
        local pos = self.pos[i]
        if lap.isInRange(pos, startPos, endPos) then
            if self.brake[i] and self.brake[i] > brakeThreshold then
                brakeIdx = i
                brakeTime = self.times[i]
                brakeGear = self.gear[i]
                break
            end
        end
    end

    if not brakeIdx or not brakeTime or not brakeGear then
        return nil -- No braking found in range
    end

    -- Find first and last downshifts after brake initiation
    local firstDownshiftTime = nil
    local lastDownshiftTime = nil
    local lastGear = brakeGear

    for i = brakeIdx + 1, #self.pos do
        local pos = self.pos[i]
        if lap.isInRange(pos, startPos, endPos) then
            local currentGear = self.gear[i]
            if currentGear and lastGear and currentGear < lastGear and currentGear >= 1 then
                -- Found a downshift (gear decreased, still in forward gear)
                if not firstDownshiftTime then
                    firstDownshiftTime = self.times[i]
                end
                lastDownshiftTime = self.times[i]
            end
            if currentGear then
                lastGear = currentGear
            end
        elseif brakeIdx and i > brakeIdx then
            -- We've left the corner range without finding more downshifts
            break
        end
    end

    if not firstDownshiftTime then
        return nil -- No downshift found after brake initiation
    end

    -- Calculate delays in milliseconds
    local firstDelayMs = (firstDownshiftTime - brakeTime) * 1000
    local lastDelayMs = (lastDownshiftTime - brakeTime) * 1000

    return firstDelayMs, lastDelayMs, brakeTime, firstDownshiftTime, lastDownshiftTime
end

--- Find entry speed (max speed in first half of corner or before min speed point)
---@param startPos number Start of corner
---@param endPos number End of corner
---@return number|nil entrySpeed Max speed in entry phase
function lap:findEntrySpeed(startPos, endPos)
    if self:isEmpty() then return nil end
    -- First find the apex (min speed position)
    local apexPos, _ = self:findApex(startPos, endPos)
    if not apexPos then return self:speedAt(startPos) end

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
         if lap.isInRange(pos, startPos, endPos) and self.flags[i] then
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
        if lap.isInRange(pos, startPos, endPos) and self.flags[i] then
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
        if lap.isInRange(pos, startPos, endPos) and self.flags[i] then
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
        if lap.isInRange(pos, startPos, endPos) and self.flags[i] then
            if bit.band(self.flags[i], lap.FLAGS.OVERLAP) ~= 0 then
                totalTime = totalTime + sampleDt
            end
        end
    end

    return totalTime
end

--- Get a summary of all flags in a position range
--- Returns counts and boolean flags for each event type
---@param startPos number Start of search range
---@param endPos number End of search range
---@return table summary { tc={count,active}, limiter={count,active}, slip={count,active}, lockup={count,active,wheels}, overlap={count,time}, offtrack={count,active} }
function lap:getFlagSummary(startPos, endPos)
    local summary = {
        tc = { count = 0, active = false },
        limiter = { count = 0, active = false },
        slip = { count = 0, active = false },
        lockup = { count = 0, active = false, wheels = { fl = false, fr = false, rl = false, rr = false } },
        overlap = { count = 0, active = false, time = 0 },
        offtrack = { count = 0, active = false },
    }

    if not self.flags or #self.flags == 0 then return summary end

    local sampleDt = 1 / lap.SAMPLE_RATE

    for i = 1, #self.pos do
        local pos = self.pos[i]
        if lap.isInRange(pos, startPos, endPos) and self.flags[i] then
            local f = self.flags[i]

            if bit.band(f, lap.FLAGS.TC_ACTIVE) ~= 0 then
                summary.tc.count = summary.tc.count + 1
                summary.tc.active = true
            end
            if bit.band(f, lap.FLAGS.LIMITER_HIT) ~= 0 then
                summary.limiter.count = summary.limiter.count + 1
                summary.limiter.active = true
            end
            if bit.band(f, lap.FLAGS.WHEEL_SLIP) ~= 0 then
                summary.slip.count = summary.slip.count + 1
                summary.slip.active = true
            end
            if bit.band(f, lap.FLAGS.OFFTRACK) ~= 0 then
                summary.offtrack.count = summary.offtrack.count + 1
                summary.offtrack.active = true
            end
            if bit.band(f, lap.FLAGS.OVERLAP) ~= 0 then
                summary.overlap.count = summary.overlap.count + 1
                summary.overlap.active = true
                summary.overlap.time = summary.overlap.time + sampleDt
            end

            -- Lockups (track individual wheels)
            local hasLockup = false
            if bit.band(f, lap.FLAGS.LOCKUP_FL) ~= 0 then
                summary.lockup.wheels.fl = true
                hasLockup = true
            end
            if bit.band(f, lap.FLAGS.LOCKUP_FR) ~= 0 then
                summary.lockup.wheels.fr = true
                hasLockup = true
            end
            if bit.band(f, lap.FLAGS.LOCKUP_RL) ~= 0 then
                summary.lockup.wheels.rl = true
                hasLockup = true
            end
            if bit.band(f, lap.FLAGS.LOCKUP_RR) ~= 0 then
                summary.lockup.wheels.rr = true
                hasLockup = true
            end
            if hasLockup then
                summary.lockup.count = summary.lockup.count + 1
                summary.lockup.active = true
            end
        end
    end

    return summary
end

--- Check if lap has any flags data (in-sim recorded, not CSV import)
---@return boolean True if flags array has data
function lap:hasFlags()
    return self.flags and #self.flags > 0
end

--- Get flag at a specific sample index
---@param index number Sample index (1-based)
---@return number flags Bitmask of flags at that sample (0 if no data)
function lap:getFlagAt(index)
    if not self.flags or index < 1 or index > #self.flags then
        return 0
    end
    return self.flags[index] or 0
end

--- Check if a specific flag is set at a sample index
---@param index number Sample index (1-based)
---@param flag number Flag bit to check (from lap.FLAGS)
---@return boolean True if flag is set
function lap:hasFlagAt(index, flag)
    local f = self:getFlagAt(index)
    return bit.band(f, flag) ~= 0
end

--- Get human-readable flag names for a bitmask
---@param flagBits number Bitmask of flags
---@return table names Array of flag name strings
function lap.flagsToNames(flagBits)
    local names = {}
    if not flagBits or flagBits == 0 then return names end

    if bit.band(flagBits, lap.FLAGS.TC_ACTIVE) ~= 0 then table.insert(names, "TC") end
    if bit.band(flagBits, lap.FLAGS.LIMITER_HIT) ~= 0 then table.insert(names, "Limiter") end
    if bit.band(flagBits, lap.FLAGS.WHEEL_SLIP) ~= 0 then table.insert(names, "Slip") end
    if bit.band(flagBits, lap.FLAGS.LOCKUP_FL) ~= 0 then table.insert(names, "Lockup FL") end
    if bit.band(flagBits, lap.FLAGS.LOCKUP_FR) ~= 0 then table.insert(names, "Lockup FR") end
    if bit.band(flagBits, lap.FLAGS.LOCKUP_RL) ~= 0 then table.insert(names, "Lockup RL") end
    if bit.band(flagBits, lap.FLAGS.LOCKUP_RR) ~= 0 then table.insert(names, "Lockup RR") end
    if bit.band(flagBits, lap.FLAGS.OVERLAP) ~= 0 then table.insert(names, "Overlap") end
    if bit.band(flagBits, lap.FLAGS.OFFTRACK) ~= 0 then table.insert(names, "Offtrack") end

    return names
end

--- Combine multiple flags into a bitmask
---@vararg number Flag values from lap.FLAGS
---@return number Combined bitmask
function lap.combineFlags(...)
    local result = 0
    for i = 1, select('#', ...) do
        local flag = select(i, ...)
        if flag then
            result = bit.bor(result, flag)
        end
    end
    return result
end

--- Check if any lockup flag is set in a bitmask
---@param flagBits number Bitmask of flags
---@return boolean True if any lockup flag is set
function lap.hasAnyLockup(flagBits)
    if not flagBits then return false end
    local lockupMask = bit.bor(
        lap.FLAGS.LOCKUP_FL,
        lap.FLAGS.LOCKUP_FR,
        lap.FLAGS.LOCKUP_RL,
        lap.FLAGS.LOCKUP_RR
    )
    return bit.band(flagBits, lockupMask) ~= 0
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
        gear = self.gear,
        pos = self.pos,
        times = self.times,  -- Actual elapsed time at each sample
        fuel = self.fuel,    -- Fuel remaining in liters (may be empty if sparse)
        gforce = self.gforce,
        flags = self.flags,  -- In-sim only: TC, limiter, slip, lockups (bitmask per sample)
        sparse = self.sparse,
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
    
    if not ok or not parsed or type(parsed) ~= 'table' then return nil end
    local l = setmetatable(parsed, lap)
    if not l.gforce then l.gforce = {} end
    ensureSparseTable(l)
    return l
end

--------------------------------------------------------------------------------
-- Cloning (for checkpoint snapshots)
--------------------------------------------------------------------------------

--- Helper to deep copy an array
local function copyArray(arr)
    if not arr then return {} end
    local copy = {}
    for i = 1, #arr do
        copy[i] = arr[i]
    end
    return copy
end

--- Helper to deep copy sparse data
local function copySparse(sparse)
    if not sparse then return nil end
    local copy = {}
    for field, list in pairs(sparse) do
        copy[field] = {}
        for i = 1, #list do
            copy[field][i] = { list[i][1], list[i][2] }
        end
    end
    return copy
end

--- Create a deep copy of this lap (for checkpoint snapshots)
--- This is more efficient than serialize/deserialize for in-memory cloning
---@return table New lap instance with copied data
function lap:clone()
    local l = lap.new(self.track, self.car, self.sessionId)
    
    -- Copy metadata
    l.completed = self.completed
    l.valid = self.valid
    l.time = self.time
    l.fuelLeftAtStart = self.fuelLeftAtStart
    l.lapNumberInSession = self.lapNumberInSession
    l.csvSource = self.csvSource
    
    -- Deep copy telemetry arrays
    l.throttle = copyArray(self.throttle)
    l.brake = copyArray(self.brake)
    l.brake_r = copyArray(self.brake_r)
    l.clutch = copyArray(self.clutch)
    l.steering = copyArray(self.steering)
    l.speed = copyArray(self.speed)
    l.gear = copyArray(self.gear)
    l.pos = copyArray(self.pos)
    l.times = copyArray(self.times)
    l.fuel = copyArray(self.fuel)
    l.flags = copyArray(self.flags)
    
    -- Deep copy gforce vectors
    l.gforce = {}
    if self.gforce then
        for i = 1, #self.gforce do
            local g = self.gforce[i]
            if g then
                l.gforce[i] = vec3(g.x, g.y, g.z)
            end
        end
    end
    
    -- Deep copy sparse channels
    l.sparse = copySparse(self.sparse)
    
    return l
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
    -- Delegate to csv_parser module, passing our target sample rate and expected track
    local parsed, warnings = csv_parser.parseFile(filePath, trackLength, lap.SAMPLE_RATE, track)
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
    l.gear = data.gear or {}
    l.gforce = {}
    l.time = parsed.time
    l.completed = parsed.completed
    l.fuelLeftAtStart = parsed.fuelLeftAtStart or 0
    l.csvSource = parsed.csvSource

    -- Build sparse fuel channel for lighter lookups
    l:populateSparseFromDense('fuel')
    if l.sparse and l.sparse.fuel and #l.sparse.fuel > 0 then
        l.fuel = {}
    end

    -- Build g-force vectors from CSV (if available)
    if (data.g_lat and #data.g_lat > 0) or (data.g_long and #data.g_long > 0) then
        local count = #l.pos
        for i = 1, count do
            local gx = data.g_lat and data.g_lat[i] or 0
            local gz = data.g_long and data.g_long[i] or 0
            l.gforce[i] = vec3(gx or 0, 0, gz or 0)
        end
    end

    ac.log(string.format("lap.fromCSV: Loaded lap with %d samples, time: %.3fs",
        l:length(), l.time / 1000))

    return l, warnings
end

return lap
