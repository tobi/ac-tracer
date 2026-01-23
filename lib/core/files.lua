-- file_utils.lua - Shared file system utilities
-- Provides CSV file scanning and formatting helpers

local file_utils = {}

--------------------------------------------------------------------------------
-- File Info Cache
--------------------------------------------------------------------------------

local csvFilesCache = nil
local csvFilesCacheTime = 0
local csvFilesCacheTrack = nil
local CACHE_TTL = 5  -- seconds

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

--- Search paths for CSV files
local function getUserDocumentsLapDir()
    local profile = os.getenv("USERPROFILE") or os.getenv("HOME")
    if not profile or profile == "" then return nil end
    return profile .. "\\Documents\\AC-Laps\\"
end

--- Get track folder path for a track ID
---@param trackId string Track ID
---@return string Track folder path under tracks/
local function getTrackFolder(trackId)
    if not trackId then return nil end
    return __dirname .. "/tracks/" .. trackId:gsub("[/\\:]", "_") .. "/"
end

--- Build search paths for CSV files, prioritizing track-specific folders
---@param trackId string|nil Track ID to look for track-specific folder
---@return table Array of {path, source}
local function buildSearchPaths(trackId)
    local paths = {}

    -- If track ID is provided, add track-specific folder first
    if trackId then
        local trackFolder = getTrackFolder(trackId)
        table.insert(paths, { path = trackFolder, source = "tracks" })
    end

    -- Add generic tracks folder (legacy location)
    table.insert(paths, { path = __dirname .. "/tracks/", source = "tracks" })

    -- Add MoTeC standard location
    table.insert(paths, { path = "C:\\MoTeC\\Logged Data\\", source = "motec" })

    -- Add user documents folder at front if exists
    local userDir = getUserDocumentsLapDir()
    if userDir then
        table.insert(paths, 1, { path = userDir, source = "documents" })
    end

    return paths
end

--- Get default lap directory path
---@param trackId string|nil Track ID for track-specific folder
---@return string Default lap directory path
function file_utils.getLapDirectory(trackId)
    local userDir = getUserDocumentsLapDir()
    if userDir then return userDir end

    -- Return track-specific folder if track ID provided
    if trackId then
        return getTrackFolder(trackId)
    end

    return __dirname .. "/tracks/"
end

--- Get track folder path (exported for other modules)
---@param trackId string Track ID
---@return string|nil Track folder path or nil if no track ID
function file_utils.getTrackFolder(trackId)
    return getTrackFolder(trackId)
end

local function normalizeTrackName(name)
    if not name then return nil end
    local norm = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
    norm = norm:gsub("[^%w]+", "_")
    norm = norm:gsub("_+", "_")
    return norm
end

local function getCSVTrack(path)
    local f = io.open(path, "r")
    if not f then return nil end

    local lineNum = 0
    local headers = nil
    local trackIdx = nil
    local headerLineNum = 0

    for line in f:lines() do
        lineNum = lineNum + 1
        if line:find('"Time"') and (line:find('"Lap Progression"') or line:find('"Distance"')) then
            headers = file_utils.parseCSVLine(line)
            headerLineNum = lineNum
            for i = 1, #headers do
                local h = headers[i]:gsub('^"', ''):gsub('"$', '')
                if h:lower() == "track" then
                    trackIdx = i
                    break
                end
            end
            break
        end
    end

    if not trackIdx then
        f:close()
        return nil
    end

    local targetLine = headerLineNum + 3
    lineNum = 0
    local trackValue = nil
    for line in f:lines() do
        lineNum = lineNum + 1
        if lineNum >= targetLine and line ~= "" and not line:match("^%s*$") then
            local fields = file_utils.parseCSVLine(line)
            trackValue = fields[trackIdx]
            break
        end
    end

    f:close()
    return trackValue and trackValue:gsub('^"', ''):gsub('"$', '') or nil
end

--- Scan for CSV files in known directories
--- Returns cached results if called within CACHE_TTL seconds
---@param trackId string|nil Current track ID for filtering
---@return table Array of {path, filename, source, size}
function file_utils.scanCSVFiles(trackId)
    local now = os.clock()
    if csvFilesCache and (now - csvFilesCacheTime) < CACHE_TTL and csvFilesCacheTrack == trackId then
        return csvFilesCache
    end

    local trackNorm = normalizeTrackName(trackId)
    csvFilesCache = {}
    local seenFiles = {}  -- Track by lowercase to avoid duplicates

    for _, dir in ipairs(buildSearchPaths(trackId)) do
        if io.dirExists(dir.path) then
            local files = io.scanDir(dir.path, "*.csv")
            if files then
                for _, filename in ipairs(files) do
                    local lowerName = filename:lower()
                    -- Skip corners.csv files (not reference laps)
                    if not seenFiles[lowerName] and lowerName ~= "corners.csv" then
                        seenFiles[lowerName] = true
                        local fullPath = dir.path .. filename
                        local includeFile = true
                        if trackNorm then
                            local csvTrack = getCSVTrack(fullPath)
                            if csvTrack then
                                includeFile = normalizeTrackName(csvTrack) == trackNorm
                            end
                        end
                        if not includeFile then
                            goto continue
                        end
                        table.insert(csvFilesCache, {
                            path = fullPath,
                            filename = filename,
                            source = dir.source,
                            size = io.fileSize(fullPath)
                        })
                        ::continue::
                    end
                end
            end
        end
    end

    -- Sort by filename
    table.sort(csvFilesCache, function(a, b)
        return a.filename:lower() < b.filename:lower()
    end)

    csvFilesCacheTime = now
    csvFilesCacheTrack = trackId
    return csvFilesCache
end

--- Invalidate the file cache (call when files may have changed)
function file_utils.invalidateCache()
    csvFilesCache = nil
    csvFilesCacheTrack = nil
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
