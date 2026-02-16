-- file_utils.lua - Shared file system utilities
-- Provides CSV file scanning and formatting helpers

local paths = require('lib.core.paths')

local file_utils = {}

--------------------------------------------------------------------------------
-- File Info Cache
--------------------------------------------------------------------------------

local groupedCache = nil
local groupedCacheTime = 0
local groupedCacheKey = nil
local CACHE_TTL = 5  -- seconds

local function safeGetEnv(name)
    local getenv = os and os.getenv
    if not getenv or type(getenv) ~= "function" then return nil end
    return getenv(name)
end

--------------------------------------------------------------------------------
-- Formatting Helpers
--------------------------------------------------------------------------------

--- Format file size for display
---@param bytes number File size in bytes
---@return string Formatted size (e.g., "1.5MB", "256KB")
function file_utils.formatFileSize(bytes)
    if not bytes or bytes < 0 then return "?" end
    if bytes >= 1024 * 1024 then
        return string.format("%.1fMB", bytes / (1024 * 1024))
    elseif bytes >= 1024 then
        return string.format("%.0fKB", bytes / 1024)
    else
        return string.format("%dB", bytes)
    end
end

--- Format lap time in milliseconds to M:SS.mmm
---@param ms number Lap time in milliseconds
---@return string Formatted time
function file_utils.formatLapTime(ms)
    if not ms or ms <= 0 then return "--:--.---" end
    local mins = math.floor(ms / 60000)
    local secs = (ms % 60000) / 1000
    return string.format("%d:%06.3f", mins, secs)
end

--- Format lap time in milliseconds to M:SS.mm (shorter)
---@param ms number Lap time in milliseconds
---@return string Formatted time
function file_utils.formatLapTimeShort(ms)
    if not ms or ms <= 0 then return "--:--.--" end
    local mins = math.floor(ms / 60000)
    local secs = (ms % 60000) / 1000
    return string.format("%d:%05.2f", mins, secs)
end

--------------------------------------------------------------------------------
-- File Scanning
--------------------------------------------------------------------------------

--- Get default lap directory for manual export (references dir for current track/car)
---@param trackId string
---@param carId string
---@return string
function file_utils.getLapDirectory(trackId, carId)
    if trackId and carId then
        return paths.referencesDir(trackId, carId)
    end
    return paths.root() .. "data\\"
end

--- Parse lap time from autosave filename (e.g. "20250214_153012-1-23.456" -> 83456 ms)
---@param filename string
---@return number|nil Lap time in milliseconds, or nil if unparseable
local function parseLapTimeFromFilename(filename)
    -- Pattern: timestamp-M-SS.mmm  (the lap time part at the end)
    local m, s = filename:match("(%d+)-(%d+%.%d+)%.csv$")
    if m and s then
        return tonumber(m) * 60000 + tonumber(s) * 1000
    end
    return nil
end

--- Scan a single directory for CSV files
---@param dir string Directory path
---@param source string Source label
---@return table Array of {path, filename, source, size, lapTimeMs}
local function scanDir(dir, source)
    local results = {}
    if not io.dirExists(dir) then return results end

    local files = io.scanDir(dir, "*.csv")
    if not files then return results end

    for _, filename in ipairs(files) do
        local fullPath = dir .. filename
        table.insert(results, {
            path = fullPath,
            filename = filename,
            source = source,
            size = io.fileSize(fullPath),
            lapTimeMs = parseLapTimeFromFilename(filename),
        })
    end
    return results
end

--- Sort files by lap time (fastest first), files without parseable time go last
local function sortByLapTime(files)
    table.sort(files, function(a, b)
        if a.lapTimeMs and b.lapTimeMs then
            return a.lapTimeMs < b.lapTimeMs
        end
        if a.lapTimeMs then return true end
        if b.lapTimeMs then return false end
        return a.filename:lower() < b.filename:lower()
    end)
end

--- Scan CSV files grouped by source for the lap picker
--- Returns cached results if called within CACHE_TTL seconds
---@param trackId string|nil Current track ID
---@param carId string|nil Current car ID
---@return table { autosave: {...}, references: {...}, otherCars: { {car, files}, ... }, legacy: {...}, motec: {...} }
function file_utils.scanCSVFilesGrouped(trackId, carId)
    local now = os.clock()
    local cacheKey = (trackId or "") .. "|" .. (carId or "")
    if groupedCache and (now - groupedCacheTime) < CACHE_TTL and groupedCacheKey == cacheKey then
        return groupedCache
    end

    local result = {
        autosave = {},
        references = {},
        otherCars = {},  -- Array of { car = string, files = {...} }
        legacy = {},
        motec = {},
    }

    -- 1. Current car's autosave and references
    if trackId and carId then
        result.autosave = scanDir(paths.autosaveDir(trackId, carId), "autosave")
        sortByLapTime(result.autosave)

        result.references = scanDir(paths.referencesDir(trackId, carId), "references")
        sortByLapTime(result.references)
    end

    -- 2. Other cars on this track
    if trackId then
        local trackDir = paths.trackDir(trackId)
        if io.dirExists(trackDir) then
            local entries = io.scanDir(trackDir)
            if entries then
                for _, entry in ipairs(entries) do
                    -- Skip corners.csv and current car directory
                    if entry ~= "corners.csv" and entry ~= (carId and paths.sanitize(carId) or "") then
                        local subDir = trackDir .. entry .. "\\"
                        -- Check if it's a directory by looking for autosave/ or references/ inside
                        local autoDir = subDir .. "autosave\\"
                        local refsDir = subDir .. "references\\"
                        local carFiles = {}
                        if io.dirExists(autoDir) then
                            for _, fileInfo in ipairs(scanDir(autoDir, "autosave")) do
                                table.insert(carFiles, fileInfo)
                            end
                        end
                        if io.dirExists(refsDir) then
                            for _, fileInfo in ipairs(scanDir(refsDir, "references")) do
                                table.insert(carFiles, fileInfo)
                            end
                        end
                        if #carFiles > 0 then
                            sortByLapTime(carFiles)
                            table.insert(result.otherCars, { car = entry, files = carFiles })
                        end
                    end
                end
            end
        end
    end

    -- 3. Legacy tracks/ directory (bundled with app)
    result.legacy = scanDir(__dirname .. "/tracks/", "legacy")

    -- 4. MoTeC export directory
    result.motec = scanDir("C:\\MoTeC\\Logged Data\\", "motec")

    groupedCache = result
    groupedCacheTime = now
    groupedCacheKey = cacheKey
    return result
end

--- Flat scan for backward compatibility (returns all files combined)
---@param trackId string|nil Current track ID
---@param carId string|nil Current car ID
---@return table Array of {path, filename, source, size}
function file_utils.scanCSVFiles(trackId, carId)
    local grouped = file_utils.scanCSVFilesGrouped(trackId, carId)
    local all = {}
    for _, f in ipairs(grouped.autosave) do table.insert(all, f) end
    for _, f in ipairs(grouped.references) do table.insert(all, f) end
    for _, carGroup in ipairs(grouped.otherCars) do
        for _, f in ipairs(carGroup.files) do table.insert(all, f) end
    end
    for _, f in ipairs(grouped.legacy) do table.insert(all, f) end
    for _, f in ipairs(grouped.motec) do table.insert(all, f) end
    return all
end

--- Invalidate the file cache (call when files may have changed)
function file_utils.invalidateCache()
    groupedCache = nil
    groupedCacheKey = nil
end

--- Check if a file exists
---@param path string File path
---@return boolean
function file_utils.fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

--- Parse lap time from filename (exposed for lap_picker)
file_utils.parseLapTimeFromFilename = parseLapTimeFromFilename

--------------------------------------------------------------------------------
-- CSV Field Parsing
--------------------------------------------------------------------------------

--- Escape a field for CSV output
---@param str string Value to escape
---@return string Escaped value
function file_utils.escapeCSV(str)
    if not str then return "" end
    if str:find('[,"\n]') then
        return '"' .. str:gsub('"', '""') .. '"'
    end
    return str
end

--- Parse a CSV line into fields (handles quotes)
---@param line string CSV line
---@return table Array of field values
function file_utils.parseCSVLine(line)
    local fields = {}
    local field = ""
    local inQuotes = false

    for i = 1, #line do
        local c = line:sub(i, i)
        if inQuotes then
            if c == '"' then
                if line:sub(i + 1, i + 1) == '"' then
                    field = field .. '"'
                    -- Note: next quote handled by loop
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

return file_utils
