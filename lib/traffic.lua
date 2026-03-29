-- Traffic simulation module
-- Teleports AI cars into scenario-based positions at the next corner
-- Requires practice session to be started with AI opponents

local SCENARIOS = require('lib.traffic_scenarios')

local M = {}

local aiCars = {}       -- car indices (1, 2, ...)
local initialized = false
local currentScenario = 1

-- Timer to reset AI constraints after placement
local resetTimer = nil
local RESET_DELAY = 5  -- seconds after placement before resetting offsets/speed limits

-- Train mode state
local trainMode = false
local trainCornerQueue = {}       -- corners to deploy scenarios at this lap
local trainLastCornerIdx = nil    -- last corner we deployed at (avoid double-trigger)
local trainActiveScenario = nil   -- name of scenario active in train mode

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Get track direction (tangent) at a spline position using larger step for stability
local function getTrackDirection(splinePos)
    local eps = 0.002
    local behind = (splinePos - eps) % 1.0
    local ahead = (splinePos + eps) % 1.0
    local p1 = ac.trackProgressToWorldCoordinate(behind)
    local p2 = ac.trackProgressToWorldCoordinate(ahead)
    return (p2 - p1):normalize()
end

-- Find spline position that is `meters` from `startSpline`
-- Positive meters = ahead, negative = behind
local function findSplineAtDistance(startSpline, meters)
    local forward = meters >= 0
    local remaining = math.abs(meters)
    local step = 0.001
    local pos = startSpline
    local prevWorld = ac.trackProgressToWorldCoordinate(pos)
    local maxIter = 5000
    local iter = 0
    while remaining > 0 and iter < maxIter do
        if forward then
            pos = (pos + step) % 1.0
        else
            pos = (pos - step) % 1.0
        end
        local world = ac.trackProgressToWorldCoordinate(pos)
        remaining = remaining - prevWorld:distance(world)
        prevWorld = world
        iter = iter + 1
    end
    return pos
end

-- Find the next corner ahead of the current position
local function getNextCorner(pos, corners)
    if not corners or #corners == 0 then return nil, nil end
    local best = nil
    local bestDist = 2
    local bestIdx = nil
    for i, c in ipairs(corners) do
        if c.startPos then
            local dist = c.startPos - pos
            if dist < 0 then dist = dist + 1 end
            if dist > 0 and dist < bestDist then
                bestDist = dist
                best = c
                bestIdx = i
            end
        end
    end
    return best, bestIdx
end

-- Get midpoint of a corner (handles wrap-around)
local function getCornerMidpoint(corner)
    local s, e = corner.startPos, corner.endPos
    if e >= s then
        return (s + e) / 2
    else
        local mid = (s + (e + 1)) / 2
        return mid % 1.0
    end
end

-- Resolve a "where" keyword to a spline position relative to a corner
local function resolveWhere(where, corner)
    if where == "entry" then
        return corner.startPos
    elseif where == "exit" then
        return corner.endPos
    elseif where == "mid" then
        return getCornerMidpoint(corner)
    elseif where == "brake" then
        return findSplineAtDistance(corner.startPos, -30)
    end
    return corner.startPos
end

-- Teleport a car to a spline position at given speed, with optional lateral offset
local function placeCarAtSpline(carIndex, splinePos, speedKmh, laneOffset)
    -- Get position and direction on track
    local worldPos = ac.trackProgressToWorldCoordinate(splinePos)
    local dir = getTrackDirection(splinePos)

    -- Place car, give it initial velocity in the right direction
    physics.setCarPosition(carIndex, worldPos, dir)
    physics.setCarVelocity(carIndex, dir * (speedKmh / 3.6))

    -- Set lateral offset before enabling AI
    if laneOffset and laneOffset ~= 0 then
        physics.setAISplineOffset(carIndex, laneOffset)
    else
        physics.setAISplineOffset(carIndex, 0)
    end

    -- No speed cap — let AI drive at its natural pace
    physics.setAITopSpeed(carIndex, math.huge)

    -- Enable AI last so it starts driving from the placed position
    physics.setAILevel(carIndex, 1)
    physics.setAINoInput(carIndex, false, false)
end

-- Park a car (disable AI)
local function parkCar(carIndex)
    physics.setAINoInput(carIndex, true, false)
    physics.setAISplineOffset(carIndex, 0)
    physics.setAITopSpeed(carIndex, math.huge)
end

-- Reset all AI constraints (called after delay so AI drives normally post-corner)
local function resetAIConstraints()
    for _, carIndex in ipairs(aiCars) do
        physics.setAISplineOffset(carIndex, 0)
        physics.setAITopSpeed(carIndex, math.huge)
    end
end

-- Deploy a scenario at a specific corner
local function deployScenario(scenario, corner, playerSpeed)
    -- Park all cars first
    for _, carIndex in ipairs(aiCars) do
        parkCar(carIndex)
    end

    -- Place each car per the scenario definition
    for i, placement in ipairs(scenario.place) do
        if i <= #aiCars then
            local spline = resolveWhere(placement.where, corner)
            local speed = playerSpeed * placement.speed
            placeCarAtSpline(aiCars[i], spline, speed, placement.offset)
        end
    end

    resetTimer = RESET_DELAY
end

-- Get scenarios available for the current car count
local function getAvailableScenarios()
    local available = {}
    for i, s in ipairs(SCENARIOS) do
        if #aiCars >= s.minCars then
            table.insert(available, { index = i, scenario = s })
        end
    end
    return available
end

-- Pick a random scenario that fits the car count
local function pickRandomScenario()
    local available = getAvailableScenarios()
    if #available == 0 then return nil end
    return available[math.random(#available)].scenario
end

--------------------------------------------------------------------------------
-- Train Mode
--------------------------------------------------------------------------------

-- Build a queue of random scenarios for random corners this lap
local function buildTrainQueue(corners)
    trainCornerQueue = {}
    if not corners or #corners == 0 then return end

    local indices = {}
    for i = 1, #corners do
        if corners[i].startPos then
            table.insert(indices, i)
        end
    end

    local count = math.min(math.max(2, math.floor(#indices * 0.4)), 4, #indices)

    -- Shuffle and take first `count`
    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    for i = 1, count do
        local scenario = pickRandomScenario()
        if scenario then
            trainCornerQueue[indices[i]] = scenario
        end
    end

    trainLastCornerIdx = nil
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Send all AI cars to pits with zero velocity
local function parkAllInPits()
    for _, carIndex in ipairs(aiCars) do
        physics.teleportCarTo(carIndex, ac.SpawnSet.Pits)
        physics.setAINoInput(carIndex, true, false)
        physics.setAITopSpeed(carIndex, math.huge)
        physics.setAISplineOffset(carIndex, 0)
    end
end

--- Initialize: detect AI car indices and schedule pit parking
--- Called on first button press (not on load)
function M.init()
    local totalCars = ac.getSim().carsCount
    aiCars = {}
    for i = 1, totalCars - 1 do
        table.insert(aiCars, i)
    end
    initialized = true
    -- Park cars in pits immediately (called from button press, sim is ready)
    parkAllInPits()
end

--- Teleport AI cars into the current scenario at the next corner
---@param corners table Array of corner definitions from state.trackCorners
---@return string|nil Scenario name for display, or nil on error
function M.teleportScenario(corners)
    if #aiCars == 0 then
        ac.setMessage("Traffic", "Add AI opponents to your session first")
        return nil
    end

    local player = ac.getCar(0)
    if not player then return nil end

    local corner = getNextCorner(player.splinePosition, corners)
    if not corner then
        ac.setMessage("Traffic", "No corners defined — record corners first")
        return nil
    end

    local scenario = SCENARIOS[currentScenario]

    if #aiCars < scenario.minCars then
        ac.setMessage("Traffic", scenario.name .. " needs " .. scenario.minCars
            .. " opponents (have " .. #aiCars .. ")")
        return nil
    end

    local playerSpeed = math.max(player.speedKmh, 100)
    deployScenario(scenario, corner, playerSpeed)
    return scenario.name
end

--- Advance to next scenario (wraps around), skipping scenarios that need more cars
---@return string New scenario name
function M.nextScenario()
    local start = currentScenario
    repeat
        currentScenario = currentScenario % #SCENARIOS + 1
    until #aiCars >= SCENARIOS[currentScenario].minCars or currentScenario == start
    return SCENARIOS[currentScenario].name
end

--- Get current scenario name
function M.currentScenarioName()
    return SCENARIOS[currentScenario].name
end

--- Get current scenario description
function M.currentScenarioDesc()
    return SCENARIOS[currentScenario].desc
end

--- Get all scenario names (for UI display)
function M.allScenarios()
    return SCENARIOS
end

--- Get current scenario index (1-based)
function M.currentScenarioIndex()
    return currentScenario
end

--- Toggle train mode on/off
function M.toggleTrainMode(corners)
    trainMode = not trainMode
    if trainMode then
        buildTrainQueue(corners)
        trainActiveScenario = nil
    else
        trainCornerQueue = {}
        trainActiveScenario = nil
        for _, carIndex in ipairs(aiCars) do
            parkCar(carIndex)
        end
    end
    return trainMode
end

--- Whether train mode is active
function M.isTrainMode()
    return trainMode
end

--- Get the active train scenario name (or nil)
function M.trainScenarioName()
    return trainActiveScenario
end

--- Update (call each frame)
function M.update(dt, corners, playerPos, lapNumber)
    -- Reset timer for AI constraints
    if resetTimer then
        resetTimer = resetTimer - dt
        if resetTimer <= 0 then
            resetAIConstraints()
            resetTimer = nil
        end
    end

    -- Train mode: auto-deploy at queued corners
    if trainMode and corners and playerPos and #aiCars > 0 then
        local _, nextIdx = getNextCorner(playerPos, corners)
        if nextIdx and trainCornerQueue[nextIdx] and nextIdx ~= trainLastCornerIdx then
            local corner = corners[nextIdx]
            local dist = corner.startPos - playerPos
            if dist < 0 then dist = dist + 1 end
            if dist < 0.025 and dist > 0 then
                local scenario = trainCornerQueue[nextIdx]
                local player = ac.getCar(0)
                local playerSpeed = math.max(player and player.speedKmh or 100, 100)
                deployScenario(scenario, corner, playerSpeed)
                trainActiveScenario = scenario.name
                trainLastCornerIdx = nextIdx
                trainCornerQueue[nextIdx] = nil
            end
        end
    end
end

--- Notify of new lap (rebuilds train queue)
function M.onNewLap(corners)
    if trainMode then
        buildTrainQueue(corners)
    end
end

--- Whether there are AI cars available in the session
function M.hasAICars()
    return #aiCars > 0
end

--- Whether traffic has been initialized
function M.isInitialized()
    return initialized
end

--- Number of AI cars detected
function M.aiCarCount()
    return #aiCars
end

return M
