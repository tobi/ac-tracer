-- csv_parser.lua - CSV import parser for lap telemetry
-- Supports MoTeC CSV format (AC sim exports and real car exports)

local csv_parser = {}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local SAMPLE_RATE = 15  -- Hz - must match lap.SAMPLE_RATE

-- Column mapping configurations for different CSV sources
-- Priority order: first entry in list is preferred
local COLUMN_MAPPINGS = {
    -- Time column (required)
    time = { "time" },

    -- Position/distance columns (at least one required)
    pos = { "lap progression" },           -- 0-1 spline position (AC exports)
    distance = { "distance" },             -- meters from lap start (real car exports)

    -- Speed columns (in order of preference)
    speed = { "ground speed", "corr speed", "wheel speed avg" },

    -- Input columns - driver throttle pos preferred over throttle pos
    throttle = { "driver throttle pos", "throttle pos" },
    clutch = { "clutch pos" },
    steering = { "steering angle" },

    -- Brake: prefer pressure over pedal position for accuracy
    brakePressure = { "brake pressure f", "brake pressure fr", "p_f_brake" },
    brakePos = { "brake pos" },  -- fallback only

    -- Fuel
    fuel = { "fuel remaining", "fuel level", "fuel" },
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
    fuel = {
        ["l"] = 1.0,        -- liters (standard)
        ["kg"] = 1.0,       -- kg (approximate, depends on fuel density)
        ["gal"] = 3.78541,  -- US gallons to liters
        ["%"] = 1.0,        -- percentage (kept as-is)
    },
}

--------------------------------------------------------------------------------
-- Internal Parsing Functions
--------------------------------------------------------------------------------

--- Parse CSV header row and find column indices with priority-based selection
---@param line string Header row
---@return table indices Column indices by key
---@return table headers Raw header names by index
local function parseHeader(line)
    local headers = {}
    local allMatches = {}  -- key -> { {priority, index}, ... }

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

            -- Check all mappings for matches
            for key, targets in pairs(COLUMN_MAPPINGS) do
                for priority, target in ipairs(targets) do
                    if field == target then
                        if not allMatches[key] then allMatches[key] = {} end
                        table.insert(allMatches[key], { priority = priority, index = fieldIdx })
                    end
                end
            end

            fieldIdx = fieldIdx + 1
            fieldStart = i + 1
        end
    end

    -- For each key, pick the match with lowest priority number (highest priority)
    local indices = {}
    for key, matches in pairs(allMatches) do
        local bestMatch = nil
        for _, match in ipairs(matches) do
            if not bestMatch or match.priority < bestMatch.priority then
                bestMatch = match
            end
        end
        if bestMatch then
            indices[key] = bestMatch.index
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

--- Parse a single lap from CSV data starting at a given position
---@param lines table All lines from CSV file
---@param startIdx number Starting line index
---@param indices table Column indices
---@param config table Parsing configuration
---@return table lapData Raw lap data tables
---@return number endIdx Ending line index
---@return boolean completed Whether lap crossed finish line
local function parseSingleLap(lines, startIdx, indices, config)
    local SAMPLE_INTERVAL = 1 / SAMPLE_RATE
    local steeringCap = math.pi

    -- Raw data arrays
    local data = {
        throttle = {},
        brake = {},
        clutch = {},
        steering = {},
        speed = {},
        pos = {},
        times = {},
        fuel = {},
    }
    local fuelLeftAtStart = 0

    local lastSampleTime = -SAMPLE_INTERVAL
    local firstTime = nil
    local firstDistance = nil
    local finishTime = nil
    local lastPos = nil
    local crossedFinish = false
    local endIdx = startIdx

    for i = startIdx, #lines do
        local line = lines[i]
        endIdx = i

        if line ~= "" and not line:match("^%s*$") then
            local fields = extractFields(line, indices)
            local time = tonumber(fields.time)

            if time then
                time = time * config.timeFactor
                if not firstTime then firstTime = time end

                if time >= lastSampleTime + SAMPLE_INTERVAL then
                    local pos

                    if config.useDistance then
                        local distance = tonumber(fields.distance) or 0
                        distance = distance * config.distanceFactor
                        if not firstDistance then firstDistance = distance end
                        local lapDistance = distance - firstDistance
                        pos = lapDistance / config.trackLength
                        if pos > 1 then pos = pos - math.floor(pos) end
                    else
                        pos = tonumber(fields.pos)
                        if pos and pos > 1 then pos = pos / 100 end
                    end

                    if pos then
                        -- Detect finish line crossing
                        if lastPos and lastPos > 0.9 and pos < 0.1 then
                            finishTime = time
                            crossedFinish = true
                            break
                        end

                        lastSampleTime = time
                        lastPos = pos

                        local speed = tonumber(fields.speed) or 0
                        local throttle = tonumber(fields.throttle) or 0
                        local clutch = tonumber(fields.clutch) or 0
                        local steering = tonumber(fields.steering) or 0

                        local brake = 0
                        if config.useBrakePressure then
                            local pressure = tonumber(fields.brakePressure) or 0
                            brake = pressure / config.brakePressureMax
                        elseif indices.brakePos then
                            brake = tonumber(fields.brakePos) or 0
                            if brake > 1 then brake = brake / 100 end
                        end

                        -- Normalize 0-100 to 0-1
                        if throttle > 1 and throttle <= 2 then
                            throttle = 1
                        elseif throttle > 2 then
                            throttle = throttle / 100
                        end
                        if clutch > 1 then clutch = clutch / 100 end

                        speed = speed * config.speedFactor

                        local steerNorm = math.clamp(0.5 - math.rad(steering) / (2 * steeringCap), 0, 1)

                        -- Fuel (if available)
                        local fuel = nil
                        if indices.fuel then
                            fuel = tonumber(fields.fuel)
                            if fuel then
                                fuel = fuel * (config.fuelFactor or 1.0)
                                if #data.fuel == 0 then
                                    fuelLeftAtStart = fuel
                                end
                            end
                        end

                        local sampleTime = time - firstTime
                        table.insert(data.times, sampleTime)
                        table.insert(data.pos, pos)
                        table.insert(data.throttle, throttle)
                        table.insert(data.brake, brake)
                        table.insert(data.clutch, 1 - clutch)
                        table.insert(data.steering, steerNorm)
                        table.insert(data.speed, speed)
                        table.insert(data.fuel, fuel or 0)
                    end
                end
            end
        end
    end

    local endTime = finishTime or lastSampleTime
    local lapTime = (endTime - (firstTime or 0)) * 1000  -- ms

    return {
        data = data,
        time = lapTime,
        fuelLeftAtStart = fuelLeftAtStart,
        completed = crossedFinish,
    }, endIdx, crossedFinish
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Parse configuration for CSV import
---@class CSVParseResult
---@field data table Raw telemetry arrays
---@field time number Lap time in milliseconds
---@field fuelLeftAtStart number Fuel at lap start
---@field completed boolean Whether lap crossed finish
---@field csvSource table Column name mappings for UI

--- Load and parse lap data from MoTeC CSV file
--- Supports AC sim exports (Lap Progression) and real car exports (Distance)
--- For multi-lap files, automatically selects the fastest complete lap
---@param filePath string Path to CSV file
---@param trackLength number|nil Track length in meters (required for distance-based CSVs)
---@return CSVParseResult|nil result Parsed lap data
---@return table|nil warnings Array of warning messages
function csv_parser.parseFile(filePath, trackLength)
    local warnings = {}

    local f = io.open(filePath, "r")
    if not f then
        ac.log("csv_parser: Failed to open " .. filePath)
        return nil, {"Failed to open file: " .. filePath}
    end

    -- Read entire file into memory
    local allLines = {}
    for line in f:lines() do
        table.insert(allLines, line)
    end
    f:close()

    -- Parse metadata and find header row
    local indices = nil
    local headers = nil
    local units = nil
    local sampleRate = nil
    local headerLineNum = 0

    for lineNum, line in ipairs(allLines) do
        -- Extract sample rate from metadata
        if line:find('"Sample Rate"') then
            local rate = line:match('"Sample Rate","([%d%.]+)"')
            if rate then
                sampleRate = tonumber(rate)
            end
        end

        -- Find header row
        if line:find('"Time"') and (line:find('"Lap Progression"') or line:find('"Distance"')) then
            indices, headers = parseHeader(line)
            headerLineNum = lineNum
            break
        end
    end

    if not indices or not indices.time then
        ac.log("csv_parser: Could not find required Time column")
        return nil, {"Could not find required Time column"}
    end

    -- Log column selections
    if indices.throttle then
        ac.log("csv_parser: Using throttle: " .. headers[indices.throttle])
    end
    if indices.speed then
        ac.log("csv_parser: Using speed: " .. headers[indices.speed])
    end
    if indices.fuel then
        ac.log("csv_parser: Using fuel: " .. headers[indices.fuel])
    end

    -- Check for position/distance data
    local useDistance = false
    if not indices.pos then
        if indices.distance then
            useDistance = true
            if not trackLength then
                return nil, {"CSV uses Distance - track length required"}
            end
        else
            return nil, {"Could not find Lap Progression or Distance column"}
        end
    end

    -- Parse unit row
    if headerLineNum + 1 <= #allLines then
        units = parseUnits(allLines[headerLineNum + 1], headers)
    end
    local dataStartLine = headerLineNum + 3

    -- Get unit strings
    local timeUnit = units and units["time"] or "s"
    local distanceUnit = units and (units["distance"] or units["lap progression"]) or "m"

    if not units or not units["time"] then
        table.insert(warnings, "WARNING: CSV missing time units - assuming seconds")
    end

    -- Warn about high sample rate
    if sampleRate and sampleRate > 15 then
        table.insert(warnings, string.format(
            "WARNING: CSV sample rate (%.1f Hz) > 15 Hz - downsampling", sampleRate))
    end

    -- Determine brake source
    local useBrakePressure = indices.brakePressure ~= nil
    local brakePressureMax = 100  -- default bar
    local brakePressureUnit = nil

    if useBrakePressure and units then
        local brakeHeader = headers[indices.brakePressure]
        brakePressureUnit = units[brakeHeader]
        if brakePressureUnit == "psi" then
            brakePressureMax = 1450
        elseif brakePressureUnit == "kpa" then
            brakePressureMax = 10000
        end
    end

    if useBrakePressure then
        ac.log("csv_parser: Using brake pressure (unit: " .. (brakePressureUnit or "bar") .. ")")
    elseif indices.brakePos then
        ac.log("csv_parser: Using brake pedal position")
    else
        table.insert(warnings, "WARNING: No brake data column found")
    end

    -- Get unit conversion factors
    local speedUnit = nil
    if indices.speed and units then
        speedUnit = units[headers[indices.speed]]
    end
    local speedFactor = speedUnit and UNIT_CONVERSIONS.speed[speedUnit] or 3.6
    local timeFactor = UNIT_CONVERSIONS.time[timeUnit] or 1.0
    local distanceFactor = UNIT_CONVERSIONS.distance[distanceUnit] or 1.0

    -- Fuel conversion
    local fuelUnit = nil
    if indices.fuel and units then
        fuelUnit = units[headers[indices.fuel]]
    end
    local fuelFactor = fuelUnit and UNIT_CONVERSIONS.fuel[fuelUnit] or 1.0

    -- Build config
    local config = {
        useDistance = useDistance,
        trackLength = trackLength,
        timeFactor = timeFactor,
        distanceFactor = distanceFactor,
        speedFactor = speedFactor,
        useBrakePressure = useBrakePressure,
        brakePressureMax = brakePressureMax,
        fuelFactor = fuelFactor,
    }

    -- Parse all laps
    local allLaps = {}
    local currentIdx = dataStartLine

    while currentIdx <= #allLines do
        local lapResult, endIdx, completed = parseSingleLap(allLines, currentIdx, indices, config)

        if #lapResult.data.pos >= 10 then
            table.insert(allLaps, lapResult)
            ac.log(string.format("csv_parser: Found lap %d: %.3fs (complete: %s)",
                #allLaps, lapResult.time / 1000, completed and "yes" or "no"))
        end

        if completed then
            currentIdx = endIdx + 1
        else
            break
        end
    end

    if #allLaps == 0 then
        return nil, {"No valid laps found in file"}
    end

    -- Select fastest complete lap
    local bestLap = nil
    local bestTime = math.huge

    for _, entry in ipairs(allLaps) do
        if entry.completed and entry.time < bestTime then
            bestTime = entry.time
            bestLap = entry
        end
    end

    -- Fallback to first lap if no complete
    if not bestLap then
        bestLap = allLaps[1]
        table.insert(warnings, "WARNING: No complete laps - using partial data")
    end

    if #allLaps > 1 then
        table.insert(warnings, string.format("INFO: Found %d laps - selected fastest (%.3fs)",
            #allLaps, bestLap.time / 1000))
    end

    -- Add CSV source metadata
    bestLap.csvSource = {
        throttle = indices.throttle and headers[indices.throttle] or nil,
        brake = useBrakePressure and headers[indices.brakePressure]
            or (indices.brakePos and headers[indices.brakePos] or nil),
        speed = indices.speed and headers[indices.speed] or nil,
        steering = indices.steering and headers[indices.steering] or nil,
        clutch = indices.clutch and headers[indices.clutch] or nil,
        position = useDistance and (indices.distance and headers[indices.distance])
            or (indices.pos and headers[indices.pos] or nil),
        time = indices.time and headers[indices.time] or nil,
        fuel = indices.fuel and headers[indices.fuel] or nil,
    }

    -- Log warnings
    for _, warn in ipairs(warnings) do
        ac.log("csv_parser: " .. warn)
    end

    ac.log(string.format("csv_parser: Loaded %d samples (%.3fs)",
        #bestLap.data.pos, bestLap.time / 1000))

    return bestLap, #warnings > 0 and warnings or nil
end

return csv_parser
