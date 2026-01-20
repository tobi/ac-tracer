-- csv_export.lua - Export lap data to MoTeC-style CSV for reference loading

local lap = require('lap')
local file_utils = require('file_utils')

local csv_export = {}

local INVALID_FILENAME_CHARS = '[\\/:*?"<>|]'

local function sanitizeFilename(name)
    if not name or name == "" then return "lap" end
    local sanitized = name:gsub(INVALID_FILENAME_CHARS, "_")
    sanitized = sanitized:gsub("%s+", "_")
    sanitized = sanitized:gsub("[^%w%._%-]", "_")
    sanitized = sanitized:gsub("_+", "_")
    return sanitized
end

local function formatTimeLabel(ms)
    if not ms or ms <= 0 then return "0-00.000" end
    local mins = math.floor(ms / 60000)
    local secs = (ms % 60000) / 1000
    return string.format("%d-%06.3f", mins, secs)
end

local function buildFilename(lapObj)
    local track = sanitizeFilename(lapObj.track or "track")
    local timeLabel = formatTimeLabel(lapObj.time or 0)
    return string.format("%s_%s.csv", track, timeLabel)
end

--- Build autosave filename for a track/time
---@param track string Track ID
---@param timeMs number Lap time in milliseconds
---@return string Filename
function csv_export.buildAutosaveFilename(track, timeMs)
    local trackName = sanitizeFilename(track or "track")
    local timeLabel = formatTimeLabel(timeMs or 0)
    return string.format("%s-%s-autosave.csv", trackName, timeLabel)
end

local function formatNumber(value, fmt)
    if value == nil then return "" end
    return string.format(fmt or "%.3f", value)
end

local function writeLine(file, fields, forceQuote)
    local escaped = {}
    for i = 1, #fields do
        local value = tostring(fields[i] or "")
        if forceQuote then
            escaped[i] = '"' .. value:gsub('"', '""') .. '"'
        else
            escaped[i] = file_utils.escapeCSV(value)
        end
    end
    file:write(table.concat(escaped, ",") .. "\n")
end

--- Export a lap to MoTeC-style CSV (tracks/ by default)
---@param lapObj table Lap instance
---@param options table|nil { directory: string, filename: string }
---@return string|nil path Output file path
---@return string|nil err Error message
function csv_export.saveLap(lapObj, options)
    if not lapObj or lapObj:length() < 2 then
        return nil, "Lap has no data"
    end

    options = options or {}
    local baseDir = options.directory or file_utils.getLapDirectory()
    local filename = options.filename or buildFilename(lapObj)
    local path = baseDir .. filename

    io.createDir(baseDir)

    local f = io.open(path, "w")
    if not f then
        return nil, "Failed to open file for writing: " .. path
    end

    -- Minimal MoTeC-style metadata
    writeLine(f, { "Format", "MoTeC CSV File" }, true)
    writeLine(f, { "Sample Rate", string.format("%.3f", lap.SAMPLE_RATE), "Hz" }, true)
    f:write("\n")

    -- Header + units (must include Time and Lap Progression for parser)
    local headers = {
        "Time",
        "Track",
        "Lap Progression",
        "Ground Speed",
        "Driver Throttle Pos",
        "Brake Pressure F",
        "Brake Pressure R",
        "Clutch Pos",
        "Steering Angle",
        "Fuel Remaining",
        "Gear",
        "G Force Lat",
        "G Force Long",
    }
    local units = {
        "s",
        "",
        "",
        "km/h",
        "%",
        "bar",
        "bar",
        "%",
        "deg",
        "l",
        "",
        "g",
        "g",
    }

    writeLine(f, headers, true)
    writeLine(f, units, true)
    f:write("\n")

    -- Data rows
    local count = lapObj:length()
    for i = 1, count do
        local timeS = (lapObj.times and lapObj.times[i]) or ((i - 1) / lap.SAMPLE_RATE)
        local pos = lapObj.pos and lapObj.pos[i] or (i - 1) / (count - 1)
        local throttle = lapObj.throttle and lapObj.throttle[i] or 0
        local brake = lapObj.brake and lapObj.brake[i] or 0
        local brakeR = (lapObj.brake_r and lapObj.brake_r[i]) or brake
        local clutchInverted = lapObj.clutch and lapObj.clutch[i] or 0
        local steeringNorm = lapObj.steering and lapObj.steering[i] or 0.5
        local speed = lapObj.speed and lapObj.speed[i] or 0
        local gear = lapObj.gear and lapObj.gear[i] or 0
        local fuel = lapObj:fuelAt(pos) or 0
        local g = lapObj.gforce and lapObj.gforce[i] or nil
        local gLat = g and g.x or 0
        local gLong = g and g.z or 0

        -- Convert to CSV-friendly values
        local throttlePct = throttle * 100
        local clutchPct = (1 - clutchInverted) * 100  -- CSV expects non-inverted
        local steeringDeg = lap.steerToDegrees(steeringNorm)

        writeLine(f, {
            formatNumber(timeS, "%.3f"),
            lapObj.track or "",
            formatNumber(pos, "%.6f"),
            formatNumber(speed, "%.2f"),
            formatNumber(throttlePct, "%.2f"),
            formatNumber(brake, "%.2f"),
            formatNumber(brakeR, "%.2f"),
            formatNumber(clutchPct, "%.2f"),
            formatNumber(steeringDeg, "%.2f"),
            formatNumber(fuel, "%.3f"),
            tostring(gear or 0),
            formatNumber(gLat, "%.3f"),
            formatNumber(gLong, "%.3f"),
        })
    end

    f:close()
    return path, nil
end

return csv_export
