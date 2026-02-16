-- motec_ld_parser.lua - Parse MoTeC .ld binary telemetry files
-- Reads binary .ld session files and companion .ldx lap beacon files
-- Exports individual laps as CSV files compatible with lap_csv_parser.lua

local ffi = require("ffi")
local file_utils = require('lib.core.files')
local lap_mod = require('lib.lap')

local M = {}

--------------------------------------------------------------------------------
-- Binary Read Helpers (little-endian)
--------------------------------------------------------------------------------

--- Read unsigned 32-bit integer at 0-based byte offset
---@param data string Raw binary data
---@param offset number 0-based byte offset
---@return number
function M.read_u32(data, offset)
    local b1, b2, b3, b4 = data:byte(offset + 1, offset + 4)
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

--- Read unsigned 16-bit integer at 0-based byte offset
---@param data string Raw binary data
---@param offset number 0-based byte offset
---@return number
function M.read_u16(data, offset)
    local b1, b2 = data:byte(offset + 1, offset + 2)
    return b1 + b2 * 0x100
end

--- Read signed 16-bit integer at 0-based byte offset
---@param data string Raw binary data
---@param offset number 0-based byte offset
---@return number
function M.read_i16(data, offset)
    local v = M.read_u16(data, offset)
    if v >= 0x8000 then v = v - 0x10000 end
    return v
end

--- Read IEEE 754 float32 at 0-based byte offset (requires LuaJIT FFI)
---@param data string Raw binary data
---@param offset number 0-based byte offset
---@return number
function M.read_f32(data, offset)
    local buf = ffi.new("float[1]")
    ffi.copy(buf, data:sub(offset + 1, offset + 4), 4)
    return buf[0]
end

--- Read null-terminated string at 0-based byte offset
---@param data string Raw binary data
---@param offset number 0-based byte offset
---@param maxlen number Maximum bytes to read
---@return string
function M.read_str(data, offset, maxlen)
    local raw = data:sub(offset + 1, offset + maxlen)
    local null_pos = raw:find("\0")
    if null_pos then
        return raw:sub(1, null_pos - 1)
    end
    return raw
end

--------------------------------------------------------------------------------
-- Integer Data Conversion
--------------------------------------------------------------------------------

--- Convert raw integer value using MoTeC channel conversion formula
--- Formula: value = (raw / scale * 10^(-dec) + shift) * mul
---@param raw number Raw integer value
---@param scale number Scale divisor
---@param dec number Decimal places (power of 10)
---@param shift number Additive offset
---@param mul number Multiplier
---@return number Converted physical value
function M.convertIntValue(raw, scale, dec, shift, mul)
    if scale == 0 then scale = 1 end
    if mul == 0 then mul = 1 end
    local decFactor = math.pow(10, -dec)
    return (raw / scale * decFactor + shift) * mul
end

--------------------------------------------------------------------------------
-- Header Parser
--------------------------------------------------------------------------------

--- Parse .ld file header
---@param data string Raw binary file contents
---@return table|nil header Parsed header fields
---@return string|nil error Error message
function M.parseHeader(data)
    if #data < 200 then
        return nil, "File too small to be a valid .ld file"
    end

    local magic = M.read_u32(data, 0x00)
    if magic ~= 0x40 then
        return nil, string.format("Invalid magic: 0x%X (expected 0x40)", magic)
    end

    local header = {
        magic = magic,
        channel_meta_ptr = M.read_u32(data, 0x08),
        channel_data_ptr = M.read_u32(data, 0x0C),
        event_ptr = M.read_u32(data, 0x24),
        date = M.read_str(data, 0x5E, 16),
        time = M.read_str(data, 0x7E, 16),
        driver = M.read_str(data, 0x9E, 64),
        vehicle_id = M.read_str(data, 0xDE, 64),
        venue = M.read_str(data, 0x15E, 64),
    }

    -- Validate pointers are within file bounds
    if header.channel_meta_ptr >= #data then
        return nil, "channel_meta_ptr points beyond file end"
    end

    return header
end

--- Parse event block for additional metadata
---@param data string Raw binary file contents
---@param event_ptr number Offset to event block
---@return table event Parsed event fields
function M.parseEvent(data, event_ptr)
    if event_ptr == 0 or event_ptr + 128 > #data then
        return {}
    end
    return {
        event_name = M.read_str(data, event_ptr, 64),
        session = M.read_str(data, event_ptr + 64, 64),
    }
end

--------------------------------------------------------------------------------
-- Channel Metadata Parser
--------------------------------------------------------------------------------

--- Parse one channel metadata block (192 bytes per entry in linked list)
---@param data string Raw binary file contents
---@param offset number 0-based offset of channel metadata
---@return table channel Parsed channel metadata
function M.parseChannelMeta(data, offset)
    return {
        prev_addr = M.read_u32(data, offset + 0),
        next_addr = M.read_u32(data, offset + 4),
        data_ptr = M.read_u32(data, offset + 8),
        n_data = M.read_u32(data, offset + 12),
        datatype_a = M.read_u16(data, offset + 18),
        datatype = M.read_u16(data, offset + 20),
        rec_freq = M.read_u16(data, offset + 22),
        shift = M.read_i16(data, offset + 24),
        mul = M.read_i16(data, offset + 26),
        scale = M.read_i16(data, offset + 28),
        dec_places = M.read_i16(data, offset + 30),
        name = M.read_str(data, offset + 32, 32),
        short_name = M.read_str(data, offset + 64, 8),
        unit = M.read_str(data, offset + 72, 12),
    }
end

--- Read all channel metadata by following the linked list
---@param data string Raw binary file contents
---@param meta_ptr number Starting address (from header)
---@return table channels Array of channel metadata tables
function M.readAllChannels(data, meta_ptr)
    local channels = {}
    local addr = meta_ptr
    local safety = 200 -- Max channels to prevent infinite loop

    while addr > 0 and addr < #data and safety > 0 do
        local ch = M.parseChannelMeta(data, addr)
        table.insert(channels, ch)
        addr = ch.next_addr
        safety = safety - 1
    end

    return channels
end

--------------------------------------------------------------------------------
-- Channel Data Reader
--------------------------------------------------------------------------------

--- Read sample data for a channel and convert to physical values
---@param data string Raw binary file contents
---@param channel table Channel metadata (from parseChannelMeta)
---@return table values Array of float values in physical units
function M.readChannelData(data, channel)
    local values = {}
    local ptr = channel.data_ptr
    local n = channel.n_data
    local byteSize = channel.datatype
    local isFloat = (channel.datatype_a == 0x07)

    -- Bounds check
    local endOffset = ptr + n * byteSize
    if endOffset > #data then
        ac.log(string.format("motec: Channel '%s' data extends beyond file (need %d, have %d)",
            channel.name, endOffset, #data))
        -- Read as many samples as we can
        n = math.floor((#data - ptr) / byteSize)
        if n <= 0 then return {} end
    end

    if isFloat and byteSize == 4 then
        -- Bulk float32 read via FFI
        local byteCount = n * 4
        local buf = ffi.new("float[?]", n)
        ffi.copy(buf, data:sub(ptr + 1, ptr + byteCount), byteCount)
        for i = 0, n - 1 do
            values[i + 1] = buf[i]
        end
    elseif isFloat and byteSize == 2 then
        -- Float16 (rare) - fallback to 0
        for i = 1, n do
            values[i] = 0
        end
    elseif byteSize == 2 then
        -- Int16 with conversion
        local scale = channel.scale
        local dec = channel.dec_places
        local shift = channel.shift
        local mul = channel.mul
        for i = 0, n - 1 do
            local raw = M.read_i16(data, ptr + i * 2)
            values[i + 1] = M.convertIntValue(raw, scale, dec, shift, mul)
        end
    elseif byteSize == 4 then
        -- Int32 with conversion
        local scale = channel.scale
        local dec = channel.dec_places
        local shift = channel.shift
        local mul = channel.mul
        for i = 0, n - 1 do
            -- Read as unsigned then treat as signed
            local raw = M.read_u32(data, ptr + i * 4)
            if raw >= 0x80000000 then raw = raw - 0x100000000 end
            values[i + 1] = M.convertIntValue(raw, scale, dec, shift, mul)
        end
    end

    return values
end

--------------------------------------------------------------------------------
-- Channel Name Mapping
--------------------------------------------------------------------------------

-- Priority-ordered channel name mappings (same priorities as lap_csv_parser.lua)
local CHANNEL_MAPPINGS = {
    speed = { "corr speed", "ground speed", "wheel speed avg", "aero speed", "uspeed", "vehrefspeed", "speed" },
    throttle = { "driver throttle pos", "accel pedal pos", "acc pedal pos", "pps", "aps", "driver demand", "tps driver", "throttle pos" },
    brake = { "brake pressure f", "brake pressure fr", "p_f_brake" },
    brake_r = { "brake pressure r", "brake pressure rl", "p_r_brake" },
    brakePos = { "brake pos" },
    steering = { "steering angle" },
    clutch = { "clutch pos" },
    gear = { "gear_pos", "gear", "gearposdisplay" },
    fuel = { "fuel remaining", "fuel level", "fuel" },
    g_lat = { "g force lat", "lat g", "g lat", "lateral g" },
    g_long = { "g force long", "long g", "g long", "longitudinal g" },
    distance = { "distance", "lap distance" },
    pos = { "lap progression" },
}

--- Map MoTeC channel names to ac-tracer telemetry fields
---@param channels table Array of channel metadata
---@return table mapping { fieldName = channelIndex, ... }
function M.mapChannels(channels)
    local mapping = {}

    for fieldName, priorities in pairs(CHANNEL_MAPPINGS) do
        local bestIdx = nil
        local bestPriority = math.huge

        for chIdx, ch in ipairs(channels) do
            local chName = ch.name:lower()
            for priority, target in ipairs(priorities) do
                if chName == target and priority < bestPriority then
                    bestIdx = chIdx
                    bestPriority = priority
                end
            end
        end

        if bestIdx then
            mapping[fieldName] = bestIdx
        end
    end

    return mapping
end

--------------------------------------------------------------------------------
-- Unit Conversion
--------------------------------------------------------------------------------

local UNIT_CONVERSIONS = {
    speed = {
        ["m/s"] = 3.6,
        ["km/h"] = 1.0,
        ["mph"] = 1.60934,
    },
    brake = {
        ["bar"] = 1.0,
        ["psi"] = 0.0689476,
        ["kpa"] = 0.01,
    },
}

--- Get unit string for a channel (checks unit field, falls back to short_name)
---@param channel table Channel metadata
---@return string unit Lowercase unit string
function M.getChannelUnit(channel)
    local unit = channel.unit or ""
    unit = unit:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if unit == "" then
        -- Some MoTeC hardware stores units in short_name instead of unit field
        unit = (channel.short_name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    end
    return unit
end

--- Get unit conversion factor for a channel based on its field role
---@param channel table Channel metadata
---@param fieldName string The mapped field name (e.g., "speed", "brake")
---@return number factor Conversion factor to apply
function M.getUnitFactor(channel, fieldName)
    local unit = M.getChannelUnit(channel)

    if fieldName == "speed" then
        return UNIT_CONVERSIONS.speed[unit] or 3.6 -- default m/s -> km/h
    elseif fieldName == "brake" or fieldName == "brake_r" then
        return UNIT_CONVERSIONS.brake[unit] or 1.0
    end

    return 1.0
end

--------------------------------------------------------------------------------
-- .ldx Beacon Parser
--------------------------------------------------------------------------------

--- Parse .ldx XML file for lap beacons and metadata
---@param ldxPath string Path to .ldx file
---@return table|nil beacons Array of beacon times in seconds (sorted)
---@return table|nil metadata Session metadata from .ldx
function M.parseLdx(ldxPath)
    local f = io.open(ldxPath, "r")
    if not f then
        return nil, nil
    end

    local content = f:read("*a")
    f:close()

    if not content or #content == 0 then
        return nil, nil
    end

    -- Extract beacon times from Marker elements
    local beacons = {}
    for time_str in content:gmatch('<Marker[^>]* Time="([^"]+)"') do
        local time_us = tonumber(time_str)
        if time_us then
            table.insert(beacons, time_us / 1e6) -- microseconds to seconds
        end
    end

    table.sort(beacons)

    -- Extract metadata from Details section
    local metadata = {}
    metadata.totalLaps = tonumber(content:match('<String Id="Total Laps" Value="(%d+)"') or "")
    metadata.fastestTime = content:match('<String Id="Fastest Time" Value="([^"]+)"')
    metadata.fastestLap = tonumber(content:match('<String Id="Fastest Lap" Value="(%d+)"') or "")
    metadata.event = content:match('<String Id="Event" Value="([^"]+)"')
    metadata.venue = content:match('<String Id="Venue" Value="([^"]+)"')
    metadata.driver = content:match('<String Id="Driver" Value="([^"]+)"')

    return #beacons > 0 and beacons or nil, metadata
end

--------------------------------------------------------------------------------
-- Lap Computation
--------------------------------------------------------------------------------

--- Compute lap information from beacon timestamps
---@param beacons table Array of beacon times in seconds (sorted)
---@return table laps Array of { index, startTime, endTime, timeMs, timeFormatted }
function M.computeLaps(beacons)
    local laps = {}

    for i = 1, #beacons - 1 do
        local startTime = beacons[i]
        local endTime = beacons[i + 1]
        local timeMs = (endTime - startTime) * 1000

        local mins = math.floor(timeMs / 60000)
        local secs = (timeMs % 60000) / 1000

        table.insert(laps, {
            index = i,
            startTime = startTime,
            endTime = endTime,
            timeMs = timeMs,
            timeFormatted = string.format("%d:%06.3f", mins, secs),
        })
    end

    return laps
end

--- Find the index of the fastest lap
---@param laps table Array from computeLaps
---@return number|nil fastestIndex 1-based index into laps array
function M.findFastestLap(laps)
    if #laps == 0 then return nil end

    local bestIdx = 1
    local bestTime = laps[1].timeMs

    for i = 2, #laps do
        if laps[i].timeMs < bestTime then
            bestTime = laps[i].timeMs
            bestIdx = i
        end
    end

    return bestIdx
end

--------------------------------------------------------------------------------
-- Lap Extraction
--------------------------------------------------------------------------------

--- Extract sample data for a single lap from full session channel data
---@param channelValues table { [channelIdx] = values_array }
---@param channels table Channel metadata array
---@param startTime number Lap start time in seconds
---@param endTime number Lap end time in seconds
---@return table lapValues { [channelIdx] = { values for this lap } }
function M.extractLapData(channelValues, channels, startTime, endTime)
    local lapValues = {}

    for chIdx, values in pairs(channelValues) do
        local ch = channels[chIdx]
        local freq = ch.rec_freq
        local startSample = math.floor(startTime * freq)
        local endSample = math.floor(endTime * freq)

        -- Clamp to available data
        startSample = math.max(0, startSample)
        endSample = math.min(#values - 1, endSample)

        local lapData = {}
        for i = startSample, endSample do
            table.insert(lapData, values[i + 1]) -- 1-based Lua indexing
        end

        lapValues[chIdx] = lapData
    end

    return lapValues
end

--------------------------------------------------------------------------------
-- Multi-Rate Channel Unification
--------------------------------------------------------------------------------

--- Linear interpolation helper
local function lerp(a, b, t)
    return a + (b - a) * t
end

--- Resample a channel's values to a target sample rate
---@param values table Source values array
---@param srcFreq number Source sample rate in Hz
---@param targetFreq number Target sample rate in Hz
---@param durationS number Duration in seconds
---@return table resampled Values at target rate
function M.resampleChannel(values, srcFreq, targetFreq, durationS)
    if srcFreq == targetFreq then return values end
    if #values == 0 then return {} end

    local numOut = math.floor(durationS * targetFreq) + 1
    local result = {}

    for i = 0, numOut - 1 do
        local t = i / targetFreq -- time in seconds
        local srcIdx = t * srcFreq -- fractional source index
        local lo = math.floor(srcIdx)
        local hi = lo + 1
        local frac = srcIdx - lo

        -- Clamp to bounds
        lo = math.max(0, math.min(lo, #values - 1))
        hi = math.max(0, math.min(hi, #values - 1))

        result[i + 1] = lerp(values[lo + 1], values[hi + 1], frac)
    end

    return result
end

--- Unify all mapped channels to a common time base at lap.SAMPLE_RATE
---@param lapValues table { [channelIdx] = values_array }
---@param channels table Channel metadata array
---@param mapping table { fieldName = channelIdx }
---@param durationS number Lap duration in seconds
---@return table unified { time={}, speed={}, throttle={}, ... } at target rate
---@return number outputFreq The output sample rate (lap.SAMPLE_RATE)
function M.unifyChannels(lapValues, channels, mapping, durationS)
    -- Resample directly to lap.SAMPLE_RATE (25Hz) instead of the max native rate.
    -- All native rates (50, 100, 200Hz) are exact multiples of 25Hz,
    -- so this gives clean downsampling with no intermediate step needed.
    local targetFreq = lap_mod.SAMPLE_RATE

    local numSamples = math.floor(durationS * targetFreq) + 1
    local unified = {
        time = {},
    }

    -- Build time array
    for i = 0, numSamples - 1 do
        unified.time[i + 1] = i / targetFreq
    end

    -- Resample each mapped channel to targetFreq
    local fieldToChannel = {}
    for fieldName, chIdx in pairs(mapping) do
        local ch = channels[chIdx]
        local values = lapValues[chIdx] or {}
        local resampled = M.resampleChannel(values, ch.rec_freq, targetFreq, durationS)
        fieldToChannel[fieldName] = { values = resampled, channel = ch }
    end

    -- Build unified arrays with unit conversions
    unified.speed = {}
    unified.throttle = {}
    unified.brake = {}
    unified.brake_r = {}
    unified.brakePos = {}
    unified.steering = {}
    unified.clutch = {}
    unified.gear = {}
    unified.fuel = {}
    unified.g_lat = {}
    unified.g_long = {}

    for i = 1, numSamples do
        -- Speed (convert to km/h)
        if fieldToChannel.speed then
            local fc = fieldToChannel.speed
            local raw = fc.values[i] or 0
            unified.speed[i] = raw * M.getUnitFactor(fc.channel, "speed")
        else
            unified.speed[i] = 0
        end

        -- Throttle (keep as ratio 0-1 or convert from %)
        if fieldToChannel.throttle then
            local v = fieldToChannel.throttle.values[i] or 0
            -- MoTeC files may store as ratio (0-1) or percent (0-100)
            -- Real MoTeC hardware often outputs ratios slightly above 1.0 (e.g. 1.01)
            -- Only treat as percentage if clearly > 1.5 (not just sensor overshoot)
            if v > 1.5 then v = v / 100 end
            unified.throttle[i] = math.max(0, math.min(1, v))
        else
            unified.throttle[i] = 0
        end

        -- Brake pressure front (bar)
        if fieldToChannel.brake then
            local fc = fieldToChannel.brake
            local raw = fc.values[i] or 0
            unified.brake[i] = math.max(0, raw * M.getUnitFactor(fc.channel, "brake"))
        elseif fieldToChannel.brakePos then
            -- Fallback: pedal position * 100 bar
            local v = fieldToChannel.brakePos.values[i] or 0
            if v > 1.5 then v = v / 100 end
            unified.brake[i] = math.max(0, v * 100)
        else
            unified.brake[i] = 0
        end

        -- Brake pressure rear (bar)
        if fieldToChannel.brake_r then
            local fc = fieldToChannel.brake_r
            local raw = fc.values[i] or 0
            unified.brake_r[i] = math.max(0, raw * M.getUnitFactor(fc.channel, "brake_r"))
        else
            unified.brake_r[i] = unified.brake[i] -- Same as front if no rear data
        end

        -- Brake pedal position (for CSV export if no pressure available)
        if fieldToChannel.brakePos then
            local v = fieldToChannel.brakePos.values[i] or 0
            if v > 1.5 then v = v / 100 end
            unified.brakePos[i] = math.max(0, math.min(1, v))
        end

        -- Steering (degrees)
        if fieldToChannel.steering then
            unified.steering[i] = fieldToChannel.steering.values[i] or 0
        else
            unified.steering[i] = 0
        end

        -- Clutch (keep as ratio 0-1 or convert from %)
        if fieldToChannel.clutch then
            local v = fieldToChannel.clutch.values[i] or 0
            if v > 1.5 then v = v / 100 end
            unified.clutch[i] = math.max(0, math.min(1, v))
        else
            unified.clutch[i] = 0
        end

        -- Gear
        if fieldToChannel.gear then
            unified.gear[i] = math.floor(fieldToChannel.gear.values[i] or 0)
        else
            unified.gear[i] = 0
        end

        -- Fuel
        if fieldToChannel.fuel then
            unified.fuel[i] = fieldToChannel.fuel.values[i] or 0
        else
            unified.fuel[i] = 0
        end

        -- G-forces
        unified.g_lat[i] = fieldToChannel.g_lat and fieldToChannel.g_lat.values[i] or 0
        unified.g_long[i] = fieldToChannel.g_long and fieldToChannel.g_long.values[i] or 0
    end

    return unified, targetFreq
end

--------------------------------------------------------------------------------
-- Distance Computation
--------------------------------------------------------------------------------

--- Compute cumulative distance by integrating speed over time
---@param speedKmh table Array of speed values in km/h
---@param freq number Sample rate in Hz
---@return table distance Array of cumulative distance in meters
function M.computeDistance(speedKmh, freq)
    local distance = {}
    local dt = 1 / freq
    local cumDist = 0

    for i = 1, #speedKmh do
        distance[i] = cumDist
        local speedMs = speedKmh[i] / 3.6 -- km/h to m/s
        cumDist = cumDist + speedMs * dt
    end

    return distance
end

--------------------------------------------------------------------------------
-- CSV Export
--------------------------------------------------------------------------------

local INVALID_FILENAME_CHARS = '[\\/:*?"<>|]'

local function sanitizeFilename(name)
    if not name or name == "" then return "motec" end
    local sanitized = name:gsub(INVALID_FILENAME_CHARS, "_")
    sanitized = sanitized:gsub("%s+", "_")
    sanitized = sanitized:gsub("[^%w%._%-]", "_")
    sanitized = sanitized:gsub("_+", "_")
    return sanitized
end

--- Build export filename for a MoTeC lap
---@param session table Parsed session
---@param lapIndex number 1-based lap index
---@return string filename
function M.buildExportFilename(session, lapIndex)
    local venue = sanitizeFilename(session.header.venue or "motec")
    local lap = session.laps[lapIndex]
    local timeMs = lap and lap.timeMs or 0
    local mins = math.floor(timeMs / 60000)
    local secs = (timeMs % 60000) / 1000
    return string.format("motec_%s_lap%d_%d-%06.3f.csv", venue, lapIndex, mins, secs)
end

--- Export a specific lap from a parsed MoTeC session to CSV
---@param session table Parsed session from parseFile
---@param lapIndex number 1-based lap index (into session.laps)
---@param outputPath string Full output path for CSV
---@param trackName string|nil Track name to embed in CSV
---@return string|nil path Written path on success
---@return string|nil err Error message on failure
function M.exportLapAsCSV(session, lapIndex, outputPath, trackName)
    local laps = session.laps
    if not laps or lapIndex < 1 or lapIndex > #laps then
        return nil, "Invalid lap index"
    end

    local lap = laps[lapIndex]
    local startTime = lap.startTime
    local endTime = lap.endTime
    local durationS = (endTime - startTime)

    -- Extract lap data from full session
    local lapValues = M.extractLapData(
        session.channelData, session.channels,
        startTime, endTime)

    -- Unify to common rate
    local unified, freq = M.unifyChannels(
        lapValues, session.channels,
        session.mapping, durationS)

    -- Compute distance from speed
    local distance = M.computeDistance(unified.speed, freq)

    -- Ensure output directory exists
    local dir = outputPath:match("^(.+)[/\\]")
    if dir then
        io.createDir(dir)
    end

    local f = io.open(outputPath, "w")
    if not f then
        return nil, "Failed to open file for writing: " .. outputPath
    end

    -- MoTeC CSV metadata
    f:write('"Format","MoTeC CSV File"\n')
    f:write(string.format('"Sample Rate","%.3f","Hz"\n', freq))
    f:write('\n')

    -- Determine which brake column to use
    local hasBrakePressure = (session.mapping.brake ~= nil)

    -- Header row
    local headers = { "Time", "Track", "Distance", "Ground Speed", "Driver Throttle Pos" }
    local units = { "s", "", "m", "km/h", "%" }

    if hasBrakePressure then
        table.insert(headers, "Brake Pressure F")
        table.insert(units, "bar")
    else
        table.insert(headers, "Brake Pos")
        table.insert(units, "%")
    end

    table.insert(headers, "Steering Angle")
    table.insert(units, "deg")
    table.insert(headers, "Gear")
    table.insert(units, "")

    -- Write headers with quotes
    local quotedHeaders = {}
    for _, h in ipairs(headers) do
        table.insert(quotedHeaders, '"' .. h .. '"')
    end
    f:write(table.concat(quotedHeaders, ",") .. "\n")

    -- Write units with quotes
    local quotedUnits = {}
    for _, u in ipairs(units) do
        table.insert(quotedUnits, '"' .. u .. '"')
    end
    f:write(table.concat(quotedUnits, ",") .. "\n")

    f:write('\n')

    -- Data rows
    local trackStr = trackName or session.header.venue or ""
    local numSamples = #unified.time

    for i = 1, numSamples do
        local timeS = unified.time[i]
        local dist = distance[i] or 0
        local speed = unified.speed[i] or 0
        local throttlePct = (unified.throttle[i] or 0) * 100
        local steerDeg = unified.steering[i] or 0
        local gear = unified.gear[i] or 0

        local brakeVal
        if hasBrakePressure then
            brakeVal = string.format("%.2f", unified.brake[i] or 0)
        else
            brakeVal = string.format("%.2f", (unified.brakePos[i] or 0) * 100)
        end

        f:write(string.format('%.3f,"%s",%.3f,%.2f,%.2f,%s,%.2f,%d\n',
            timeS, trackStr, dist, speed, throttlePct, brakeVal, steerDeg, gear))
    end

    f:close()
    return outputPath
end

--------------------------------------------------------------------------------
-- High-Level Parse API
--------------------------------------------------------------------------------

--- Parse a MoTeC .ld file and return session information
---@param ldPath string Path to .ld file
---@return table|nil session { header, channels, mapping, channelData, beacons, laps, ldxMetadata }
---@return string|nil error Error message
function M.parseFile(ldPath)
    -- Read binary file
    local f = io.open(ldPath, "rb")
    if not f then
        return nil, "Failed to open file: " .. ldPath
    end
    local data = f:read("*a")
    f:close()

    if not data or #data == 0 then
        return nil, "Empty file: " .. ldPath
    end

    -- Parse header
    local header, err = M.parseHeader(data)
    if not header then
        return nil, err
    end

    -- Parse event for additional metadata
    if header.event_ptr and header.event_ptr > 0 then
        local event = M.parseEvent(data, header.event_ptr)
        header.event_name = event.event_name
    end

    -- Read channel metadata
    local channels = M.readAllChannels(data, header.channel_meta_ptr)
    if #channels == 0 then
        return nil, "No channels found in file"
    end

    -- Map channels to telemetry fields
    local mapping = M.mapChannels(channels)
    if not mapping.speed then
        return nil, "No speed channel found (need 'Corr Speed', 'Ground Speed', or similar)"
    end

    -- Read data for all mapped channels
    local channelData = {}
    for fieldName, chIdx in pairs(mapping) do
        channelData[chIdx] = M.readChannelData(data, channels[chIdx])
    end

    -- Try to read companion .ldx file for lap beacons
    local ldxPath = ldPath:gsub("%.ld$", ".ldx"):gsub("%.LD$", ".LDX")
    local beacons, ldxMetadata = M.parseLdx(ldxPath)

    -- Compute laps from beacons
    local laps = {}
    if beacons and #beacons >= 2 then
        laps = M.computeLaps(beacons)
    else
        -- No beacons - treat entire session as one lap
        -- Find session duration from longest channel
        local maxDuration = 0
        for _, chIdx in pairs(mapping) do
            local ch = channels[chIdx]
            local dur = ch.n_data / ch.rec_freq
            if dur > maxDuration then maxDuration = dur end
        end

        if maxDuration > 0 then
            laps = {
                {
                    index = 1,
                    startTime = 0,
                    endTime = maxDuration,
                    timeMs = maxDuration * 1000,
                    timeFormatted = string.format("%d:%06.3f",
                        math.floor(maxDuration / 60),
                        maxDuration % 60),
                },
            }
        end
    end

    return {
        header = header,
        channels = channels,
        mapping = mapping,
        channelData = channelData,
        beacons = beacons,
        laps = laps,
        ldxMetadata = ldxMetadata or {},
    }
end

return M
