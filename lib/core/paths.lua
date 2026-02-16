-- paths.lua - Central path module for AC Tracer
-- Single source of truth for all data directories.
-- Root: %USERPROFILE%\Documents\ac-tracer\

local paths = {}

-- Computed once and cached
local ROOT = nil

--- Get the root data directory (computed once)
---@return string Root path ending with separator
function paths.root()
    if ROOT then return ROOT end
    local profile = os.getenv("USERPROFILE") or os.getenv("HOME")
    if profile then
        ROOT = profile .. "\\Documents\\ac-tracer\\"
    else
        ROOT = __dirname .. "/data/"
    end
    return ROOT
end

--- Top-level data directory: root/data/
---@return string
function paths.dataDir()
    return paths.root() .. "data\\"
end

--- Sanitize a track/car ID for use in filesystem paths
---@param name string Track or car ID
---@return string Sanitized name safe for directory names
function paths.sanitize(name)
    if not name or name == "" then return "unknown" end
    return name:gsub('[\\/:*?"<>|]', "_"):gsub("%s+", "_"):gsub("_+", "_")
end

--- Track directory: data/{track}/
---@param trackId string
---@return string
function paths.trackDir(trackId)
    return paths.dataDir() .. paths.sanitize(trackId) .. "\\"
end

--- Corners file: data/{track}/corners.csv
---@param trackId string
---@return string
function paths.cornersFile(trackId)
    return paths.trackDir(trackId) .. "corners.csv"
end

--- Car directory: data/{track}/{car}/
---@param trackId string
---@param carId string
---@return string
function paths.carDir(trackId, carId)
    return paths.trackDir(trackId) .. paths.sanitize(carId) .. "\\"
end

--- Autosave directory: data/{track}/{car}/autosave/
---@param trackId string
---@param carId string
---@return string
function paths.autosaveDir(trackId, carId)
    return paths.carDir(trackId, carId) .. "autosave\\"
end

--- References directory: data/{track}/{car}/references/
---@param trackId string
---@param carId string
---@return string
function paths.referencesDir(trackId, carId)
    return paths.carDir(trackId, carId) .. "references\\"
end

--- Ensure all directories exist for a track/car combo
---@param trackId string
---@param carId string
function paths.ensureDirs(trackId, carId)
    io.createDir(paths.root())
    io.createDir(paths.dataDir())
    io.createDir(paths.trackDir(trackId))
    io.createDir(paths.carDir(trackId, carId))
    io.createDir(paths.autosaveDir(trackId, carId))
    io.createDir(paths.referencesDir(trackId, carId))
end

--- Ensure track directory exists (for corners, before car is known)
---@param trackId string
function paths.ensureTrackDir(trackId)
    io.createDir(paths.root())
    io.createDir(paths.dataDir())
    io.createDir(paths.trackDir(trackId))
end

return paths
