-- History storage module for AC Tracer
-- Session-only in-memory lap history. Past laps are on disk via background_writer.

local M = {}

-- Track/car context
local currentTrack = nil
local currentCar = nil

--- Set the current track/car
---@param track string Track ID
---@param car string Car ID
function M.setTrackCar(track, car)
    currentTrack = track
    currentCar = car
end

-- In-memory history (current session only)
M.laps = {}

--- Add lap to history (most recent first)
---@param lapData table Lap to add
function M.add(lapData)
    if not lapData then return end
    table.insert(M.laps, 1, lapData)
end

--- Get fastest lap from a specific session
---@param sessionId string Session ID to filter by
---@return table|nil lap, number|nil index
function M.getFastestFromSession(sessionId)
    if not M.laps or #M.laps == 0 or not sessionId then return nil, nil end

    local fastest = nil
    local fastestIdx = nil
    for i, lapData in ipairs(M.laps) do
        if lapData.sessionId == sessionId and
           lapData.valid and lapData.time and lapData.time > 0 then
            if not fastest or lapData.time < fastest.time then
                fastest = lapData
                fastestIdx = i
            end
        end
    end
    return fastest, fastestIdx
end

--- Get laps from a specific session
---@param sessionId string Session ID to filter by
---@return table Array of {lap, index} pairs
function M.getLapsFromSession(sessionId)
    local result = {}
    if not M.laps or not sessionId then return result end

    for i, lapData in ipairs(M.laps) do
        if lapData.sessionId == sessionId then
            table.insert(result, {lap = lapData, index = i})
        end
    end
    return result
end

--- Get laps NOT from a specific session
---@param sessionId string Session ID to exclude
---@return table Array of {lap, index} pairs
function M.getLapsNotFromSession(sessionId)
    local result = {}
    if not M.laps then return result end

    for i, lapData in ipairs(M.laps) do
        if lapData.sessionId ~= sessionId then
            table.insert(result, {lap = lapData, index = i})
        end
    end
    return result
end

--- Clear all in-memory history
function M.clear()
    M.laps = {}
    ac.log("AC Tracer: Cleared lap history")
end

return M
