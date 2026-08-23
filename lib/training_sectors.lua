-- Persistent training sectors inspired by CSP DynamicReturn.
-- One hotkey maps start/end points and, once mapped, reloads the selected
-- car-state while held. Sector timing starts only when the button is released.

local M = {}

local sectors = {}
local selectedIndex = 0
local initializedKey = nil
local mapping = false
local pendingStart = nil -- nil=no start, false=async capture pending, table=captured data
local holdingReturn = false
local suppressReturnUntilRelease = false
local active = false
local run = nil
local previousPos = nil
local fileCounter = 0

local function sanitize(value)
    return tostring(value or "unknown"):gsub("[^%w_.-]", "_")
end

local function storageDir()
    local root = ac.getFolder(ac.FolderID.ScriptConfig)
    local track = ac.getTrackFullID and ac.getTrackFullID('_') or ac.getTrackID()
    return string.format("%s/ac-tracer/training/%s_%s", root, sanitize(track), sanitize(ac.getCarID(0)))
end

local function currentPosition(car)
    if car and car.position and ac.worldCoordinateToTrackProgress then
        return ac.worldCoordinateToTrackProgress(car.position)
    end
    return car and car.splinePosition or 0
end

local function forwardDistance(fromPos, toPos)
    local d = (toPos or 0) - (fromPos or 0)
    if d < 0 then d = d + 1 end
    return d
end

local function crossed(prevPos, curPos, targetPos)
    if prevPos == nil or curPos == nil or targetPos == nil then return false end
    local travelled = forwardDistance(prevPos, curPos)
    local target = forwardDistance(prevPos, targetPos)
    return travelled > 0 and travelled < 0.25 and target > 0 and target <= travelled
end

local function traversedCorners(startPos, finishPos, corners)
    local result = {}
    local sectorLength = forwardDistance(startPos, finishPos)
    for _, corner in ipairs(corners or {}) do
        if corner.endPos ~= nil then
            local d = forwardDistance(startPos, corner.endPos)
            if d > 0 and d <= sectorLength + 1e-6 then
                result[#result + 1] = {
                    number = corner.number,
                    name = corner.name or (corner.number and ("Corner " .. corner.number) or "Corner"),
                    endPos = corner.endPos,
                    distance = d,
                }
            end
        end
    end
    table.sort(result, function(a, b) return a.distance < b.distance end)
    for _, corner in ipairs(result) do corner.distance = nil end
    return result
end

local function sectorName(startPos, finishPos, corners)
    local names = traversedCorners(startPos, finishPos, corners)
    if #names == 1 then return names[1].name, names end
    if #names > 1 then return names[1].name .. " to " .. names[#names].name, names end
    local length = ac.getSim().trackLengthM or 0
    return string.format("%.0f m to %.0f m", startPos * length, finishPos * length), names
end

local function exportSector(sector)
    return {
        state = sector.state,
        name = sector.name,
        startPos = sector.startPos,
        finishPos = sector.finishPos,
        corners = sector.corners or {},
        bestTimeMs = sector.bestTimeMs,
        lastTimeMs = sector.lastTimeMs,
        history = sector.history or {},
    }
end

local function saveSector(sector)
    if not sector or not sector.filename then return end
    io.createDir(storageDir())
    io.save(sector.filename, stringify.binary(exportSector(sector)))
end

local function loadSectors()
    sectors = {}
    local dir = storageDir()
    local files = io.scanDir(dir, '*.ats') or {}
    for _, name in ipairs(files) do
        local filename = name
        if not tostring(name):match('^%a:[/\\]') and not tostring(name):match('^/') then
            filename = dir .. '/' .. name
        end
        local raw = io.load(filename, '')
        local parsed = nil
        local ok, result = pcall(function() return stringify.binary.tryParse(raw) end)
        if ok then parsed = result end
        if not parsed and stringify.parse then parsed = stringify.parse(raw) end
        if parsed and parsed.state and parsed.startPos and parsed.finishPos then
            parsed.filename = filename
            parsed.history = parsed.history or {}
            parsed.corners = parsed.corners or {}
            sectors[#sectors + 1] = parsed
        end
    end
    table.sort(sectors, function(a, b) return a.startPos < b.startPos end)
    selectedIndex = #sectors > 0 and 1 or 0
    mapping = #sectors == 0
    active = #sectors > 0
end

local function ensureInitialized()
    local key = storageDir()
    if initializedKey ~= key then
        initializedKey = key
        loadSectors()
    end
end

local function selected()
    return sectors[selectedIndex]
end

local function finishMapping(car, corners)
    local finishPos = currentPosition(car)
    local name, cornerList = sectorName(pendingStart.pos, finishPos, corners)
    fileCounter = fileCounter + 1
    local filename = string.format("%s/%d-%03d.ats", storageDir(), os.time(), fileCounter)
    local sector = {
        state = pendingStart.state,
        startPos = pendingStart.pos,
        finishPos = finishPos,
        name = name,
        corners = cornerList,
        bestTimeMs = nil,
        lastTimeMs = nil,
        history = {},
        filename = filename,
    }
    sectors[#sectors + 1] = sector
    table.sort(sectors, function(a, b) return a.startPos < b.startPos end)
    for i, item in ipairs(sectors) do
        if item == sector then selectedIndex = i break end
    end
    saveSector(sector)
    pendingStart = nil
    mapping = false
    active = true
    suppressReturnUntilRelease = true
    ac.setMessage("Training sector", name .. " saved")
end

local function beginMapping(car)
    pendingStart = false
    local pos = currentPosition(car)
    ac.saveCarStateAsync(function(err, blob)
        if err or not blob then
            pendingStart = nil
            ac.setMessage("Training sector", "Could not save car state")
            return
        end
        pendingStart = { state = blob, pos = pos }
        ac.setMessage("Training sector", "Start saved — drive to the finish and press again")
    end)
end

local function registerResult(sector, timeMs)
    sector.lastTimeMs = timeMs
    sector.bestTimeMs = math.min(sector.bestTimeMs or math.huge, timeMs)
    sector.history = sector.history or {}
    sector.history[#sector.history + 1] = timeMs
    while #sector.history > 99 do table.remove(sector.history, 1) end
    saveSector(sector)
    ac.setMessage("Training sector", string.format("%.3f s", timeMs / 1000))
end

function M.update(dt, car, corners, button, enabled)
    ensureInitialized()
    if not enabled or not car or not button then
        holdingReturn = false
        return false
    end
    if not active and not mapping then
        holdingReturn = false
        run = nil
        return false
    end

    local pos = currentPosition(car)
    local teleported = false

    if button:pressed() and mapping then
        if ac.isCarResetAllowed and not ac.isCarResetAllowed() then
            ac.setMessage("Training sector", "Car-state saving is not allowed in this session")
            return false
        end
        if pendingStart == nil then
            beginMapping(car)
        elseif pendingStart == false then
            ac.setMessage("Training sector", "Still saving the start point…")
        else
            finishMapping(car, corners)
        end
    end

    local sector = selected()
    if sector and not mapping and not suppressReturnUntilRelease and button:down() then
        if ac.isCarResetAllowed and not ac.isCarResetAllowed() then
            holdingReturn = false
            return false
        end
        ac.loadCarState(sector.state, 30)
        holdingReturn = true
        run = nil
        previousPos = sector.startPos
        teleported = true
    end

    if button:released() then
        if suppressReturnUntilRelease then
            suppressReturnUntilRelease = false
        elseif holdingReturn and sector then
            -- Timing starts at release, after the car-state has settled.
            run = { elapsedMs = 0, finished = false }
            previousPos = sector.startPos
        end
        holdingReturn = false
    end

    if run and not run.finished and sector and not holdingReturn then
        run.elapsedMs = run.elapsedMs + math.max(0, dt or 0) * 1000
        if crossed(previousPos, pos, sector.finishPos) then
            local overshoot = forwardDistance(sector.finishPos, pos) * (ac.getSim().trackLengthM or 0)
            local correction = overshoot / math.max(0.1, car.speedMs or 0.1) * 1000
            run.elapsedMs = math.max(0, run.elapsedMs - correction)
            run.finished = true
            registerResult(sector, run.elapsedMs)
        end
        previousPos = pos
    else
        previousPos = pos
    end

    return teleported
end

function M.newSector()
    ensureInitialized()
    mapping = true
    pendingStart = nil
    run = nil
    active = true
end

function M.cancelMapping()
    pendingStart = nil
    mapping = false
end

function M.select(index)
    ensureInitialized()
    if sectors[index] then
        selectedIndex = index
        mapping = false
        pendingStart = nil
        run = nil
        active = true
    end
end

function M.sectors() ensureInitialized(); return sectors end
function M.selected() ensureInitialized(); return selected() end
function M.selectedIndex() return selectedIndex end
function M.isMapping() return mapping end
function M.pendingStart() return pendingStart end
function M.isHoldingReturn() return holdingReturn end
function M.run() return run end
function M.isActive() return active end
function M.setActive(value) active = value and true or false end
function M.reload() initializedKey = nil; ensureInitialized() end
function M.traversedCorners(startPos, finishPos, corners) return traversedCorners(startPos, finishPos, corners) end
function M.forwardDistance(startPos, finishPos) return forwardDistance(startPos, finishPos) end
function M.crossed(prevPos, curPos, targetPos) return crossed(prevPos, curPos, targetPos) end

return M
