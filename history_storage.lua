-- History storage module for AC Tracer
-- Handles lap history persistence using ac.storage with stringify for complex data

local lap = require('lap')
local settings = require('app_settings')

local M = {}

local STORAGE_KEY = 'ac_tracer/history'

-- In-memory history
M.laps = {}

--- Save history to storage
function M.save()
    if not M.laps or #M.laps == 0 then
        ac.storage[STORAGE_KEY] = nil
        ac.log("AC Tracer: History empty, cleared storage")
        return
    end

    local serialized = {}
    local maxLaps = settings.maxHistoryLaps()
    for i, lapData in ipairs(M.laps) do
        if i <= maxLaps then
            local ser = lapData:serialize()
            if ser then
                table.insert(serialized, ser)
            end
        end
    end

    if #serialized > 0 then
        local data = stringify(serialized)
        ac.storage[STORAGE_KEY] = data
        ac.log(string.format("AC Tracer: Saved %d laps to history (%.1f KB)", #serialized, #data / 1024))
    end
end

--- Load history from storage
function M.load()
    local data = ac.storage[STORAGE_KEY]
    if not data then
        ac.log("AC Tracer: No history in storage")
        M.laps = {}
        return false
    end

    ac.log(string.format("AC Tracer: Loading history (%.1f KB)", #data / 1024))

    local ok, serialized = pcall(function() return stringify.parse(data) end)
    if not ok or not serialized then
        ac.log("AC Tracer: WARNING - Failed to parse history data")
        M.laps = {}
        return false
    end

    ac.log(string.format("AC Tracer: Parsed %d serialized laps", #serialized))

    M.laps = {}
    for i, lapStr in ipairs(serialized) do
        local loaded = lap.deserialize(lapStr)
        if loaded and loaded:length() > 10 then
            table.insert(M.laps, loaded)
        else
            ac.log(string.format("AC Tracer: Skipped lap %d (invalid or too short)", i))
        end
    end

    ac.log("AC Tracer: Loaded " .. #M.laps .. " valid laps from history")
    return #M.laps > 0
end

--- Add lap to history (most recent first)
---@param lapData table Lap to add
function M.add(lapData)
    if not lapData then return end
    table.insert(M.laps, 1, lapData)
    local maxLaps = settings.maxHistoryLaps()
    while #M.laps > maxLaps do
        table.remove(M.laps)
    end
    M.save()
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

--- Clear all history
function M.clear()
    M.laps = {}
    ac.storage[STORAGE_KEY] = nil
    ac.log("AC Tracer: Cleared lap history")
end

return M
