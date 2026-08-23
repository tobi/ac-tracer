-- World-space reference racing line and training-sector gates.

local settings = require('lib.core.settings')
local state = require('lib.core.state')
local corner_analysis = require('lib.windows.corner_analysis')
local training = require('lib.training_sectors')

local M = {}

local cachedLap = nil
local cachedCorners = nil
local cachedCornerSignature = nil
local cachedPoints = nil
local cachedEvents = nil

local lineQuad = {
    p1 = vec3(), p2 = vec3(), p3 = vec3(), p4 = vec3(),
    directValuesExchange = true,
    cacheKey = 73101,
    values = { gColor = rgbm(0.1, 0.45, 1, 0.65) },
    shader = [[
        float4 main(PS_IN pin) {
            float edge = saturate(min(pin.Tex.y, 1 - pin.Tex.y) * 10);
            float4 color = gColor;
            color.a *= edge;
            if (color.a < 0.01) discard;
            return pin.ApplyFog(color);
        }
    ]],
}

local gateQuad = {
    p1 = vec3(), p2 = vec3(), p3 = vec3(), p4 = vec3(),
    directValuesExchange = true,
    cacheKey = 73102,
    values = { gColor = rgbm.colors.white, gWidthMul = 1 },
    shader = [[
        float4 main(PS_IN pin) {
            float border = max(
                saturate((abs(pin.Tex.x * 2 - 1) - 0.92) * 40 * gWidthMul),
                saturate((abs(pin.Tex.y * 2 - 1) - 0.90) * 40));
            if (border < 0.01) discard;
            float4 color = gColor;
            color.a *= border * 0.8;
            return pin.ApplyFog(color);
        }
    ]],
}

local function pointValues(point)
    return point.x or point[1] or 0, point.y or point[2] or 0, point.z or point[3] or 0
end

local function gpsValues(point)
    return point[1] or point.lat or 0, point[2] or point.lon or 0, point[3] or point.alt or 0
end

local function gpsLocal(gps, lat0, lon0)
    local lat, lon = gpsValues(gps)
    local metersPerDegree = 111320
    return (lon - lon0) * math.cos(math.rad(lat0)) * metersPerDegree,
        (lat - lat0) * metersPerDegree
end

local function fitGPS(lapData)
    if not lapData.gps or #lapData.gps < 8 then return nil end
    local lat0, lon0 = gpsValues(lapData.gps[1])
    local samples = {}
    local meanGX, meanGZ, meanTX, meanTZ = 0, 0, 0, 0
    local stride = math.max(1, math.floor(#lapData.gps / 250))
    for i = 1, #lapData.gps, stride do
        local gx, gz = gpsLocal(lapData.gps[i], lat0, lon0)
        local track = ac.trackProgressToWorldCoordinate(lapData.pos[i] or 0)
        samples[#samples + 1] = { gx, gz, track.x, track.z }
        meanGX, meanGZ = meanGX + gx, meanGZ + gz
        meanTX, meanTZ = meanTX + track.x, meanTZ + track.z
    end
    if #samples < 3 then return nil end
    meanGX, meanGZ = meanGX / #samples, meanGZ / #samples
    meanTX, meanTZ = meanTX / #samples, meanTZ / #samples
    local a, b, denom = 0, 0, 0
    for _, sample in ipairs(samples) do
        local gx, gz = sample[1] - meanGX, sample[2] - meanGZ
        local tx, tz = sample[3] - meanTX, sample[4] - meanTZ
        a = a + gx * tx + gz * tz
        b = b + gx * tz - gz * tx
        denom = denom + gx * gx + gz * gz
    end
    local norm = math.sqrt(a * a + b * b)
    if denom < 1 or norm < 1 then return nil end
    return {
        lat0 = lat0, lon0 = lon0,
        meanGX = meanGX, meanGZ = meanGZ,
        meanTX = meanTX, meanTZ = meanTZ,
        cos = a / norm, sin = b / norm, scale = norm / denom,
    }
end

local function gpsToWorld(gps, center, fit)
    local gx, gz = gpsLocal(gps, fit.lat0, fit.lon0)
    gx, gz = gx - fit.meanGX, gz - fit.meanGZ
    return vec3(
        fit.meanTX + fit.scale * (fit.cos * gx - fit.sin * gz),
        center.y + 0.045,
        fit.meanTZ + fit.scale * (fit.sin * gx + fit.cos * gz))
end

local function buildPath(lapData)
    if not lapData or not lapData.pos or #lapData.pos < 8 then return nil end
    local hasWorld = lapData.worldPos and #lapData.worldPos == #lapData.pos
    local gpsFit = not hasWorld and fitGPS(lapData) or nil
    if not hasWorld and not gpsFit then return nil end

    local trackLength = ac.getSim().trackLengthM or 5000
    local spacing = 2.5 / math.max(1, trackLength)
    local points, lastPos = {}, nil
    for i = 1, #lapData.pos do
        local pos = lapData.pos[i]
        local distance = lastPos and ((pos - lastPos) % 1) or math.huge
        if i == #lapData.pos or distance >= spacing then
            local center = ac.trackProgressToWorldCoordinate(pos)
            local world
            if hasWorld then
                local x, _, z = pointValues(lapData.worldPos[i])
                world = vec3(x, center.y + 0.045, z)
            else
                world = gpsToWorld(lapData.gps[i], center, gpsFit)
            end
            points[#points + 1] = { pos = pos, world = world, speed = lapData.speed[i] or 0 }
            lastPos = pos
        end
    end
    return points
end

local function nearestPoint(points, pos)
    if not points or #points == 0 then return nil, nil end
    local best, bestIndex, bestDistance = nil, nil, math.huge
    for i, point in ipairs(points) do
        local d = math.abs(point.pos - pos)
        if d > 0.5 then d = 1 - d end
        if d < bestDistance then best, bestIndex, bestDistance = point, i, d end
    end
    return best, bestIndex
end

local function buildEvents(lapData, corners, points)
    local events = {}
    for _, corner in ipairs(corners or {}) do
        if corner.startPos and corner.endPos then
            local analysis = corner_analysis.analyzeCorner(lapData, corner)
            if analysis then
                local turnPos = analysis.turnInProfile and analysis.turnInProfile.positions
                    and analysis.turnInProfile.positions[2] or analysis.turnInPos
                for _, event in ipairs({
                    { pos = analysis.brakePos, color = rgbm(1, 0.2, 0.2, 0.9) },
                    { pos = turnPos, color = rgbm(0.2, 0.8, 1, 0.9) },
                    { pos = analysis.apexPos, color = rgbm(1, 1, 1, 0.9) },
                }) do
                    if event.pos then
                        local point = nearestPoint(points, event.pos)
                        if point then event.world = point.world; events[#events + 1] = event end
                    end
                end
            end
        end
    end
    return events
end

local function ensureCache()
    local lapData = state.bestLap
    local signatureParts = {}
    for i, corner in ipairs(state.trackCorners or {}) do
        signatureParts[i] = string.format("%.8f:%.8f", corner.startPos or -1, corner.endPos or -1)
    end
    local cornerSignature = table.concat(signatureParts, "|")
    if lapData ~= cachedLap or state.trackCorners ~= cachedCorners or cornerSignature ~= cachedCornerSignature then
        cachedLap = lapData
        cachedCorners = state.trackCorners
        cachedCornerSignature = cornerSignature
        cachedPoints = buildPath(lapData)
        cachedEvents = cachedPoints and buildEvents(lapData, state.trackCorners, cachedPoints) or nil
    end
    return cachedPoints
end

local function setQuad(quad, a, b, width, color)
    local dx, dz = b.x - a.x, b.z - a.z
    local length = math.sqrt(dx * dx + dz * dz)
    if length < 0.01 then return false end
    local px, pz = -dz / length * width * 0.5, dx / length * width * 0.5
    quad.p1:set(a.x + px, a.y, a.z + pz)
    quad.p2:set(b.x + px, b.y, b.z + pz)
    quad.p3:set(b.x - px, b.y, b.z - pz)
    quad.p4:set(a.x - px, a.y, a.z - pz)
    quad.values.gColor = color
    render.shaderedQuad(quad)
    return true
end

local function speedColor(point, currentLap, car)
    local currentSpeed = currentLap and currentLap.speedAt and currentLap:speedAt(point.pos) or nil
    if not currentSpeed then currentSpeed = car.speedKmh end
    local difference = currentSpeed - (point.speed or currentSpeed)
    local t = math.min(1, math.abs(difference) / 12)
    local neutral = rgbm(0.15, 0.45, 1, 0.68)
    local target = difference >= 0 and rgbm(0.1, 1, 0.25, 0.78) or rgbm(1, 0.12, 0.08, 0.78)
    return rgbm(
        neutral.r + (target.r - neutral.r) * t,
        neutral.g + (target.g - neutral.g) * t,
        neutral.b + (target.b - neutral.b) * t,
        neutral.mult + (target.mult - neutral.mult) * t)
end

local function closeToCar(pointPos, carPos)
    local ahead = (pointPos - carPos) % 1
    return ahead <= 0.035 or ahead >= 0.994
end

local function drawReferenceLine()
    local mode = settings.racingLineMode()
    if mode == 0 then return end
    local points = ensureCache()
    local car = ac.getCar(0)
    if not points or not car then return end
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        if closeToCar(a.pos, car.splinePosition) and closeToCar(b.pos, car.splinePosition) then
            local color = mode == 1 and rgbm(0.08, 0.42, 1, 0.68) or speedColor(a, state.currentLap, car)
            setQuad(lineQuad, a.world, b.world, 0.16, color)
        end
    end

    for _, event in ipairs(cachedEvents or {}) do
        if closeToCar(event.pos, car.splinePosition) then
            local point, index = nearestPoint(points, event.pos)
            if point and index then
                local before = points[math.max(1, index - 1)].world
                local after = points[math.min(#points, index + 1)].world
                local dx, dz = after.x - before.x, after.z - before.z
                local length = math.sqrt(dx * dx + dz * dz)
                if length > 0.01 then
                    local px, pz = -dz / length * 0.8, dx / length * 0.8
                    local a = vec3(point.world.x - px, point.world.y + 0.008, point.world.z - pz)
                    local b = vec3(point.world.x + px, point.world.y + 0.008, point.world.z + pz)
                    setQuad(lineQuad, a, b, 0.11, event.color)
                end
            end
        end
    end
end

local gateCenter, gateBack, gateSide = vec3(), vec3(), vec3()
local down, height = vec3(0, -1, 0), vec3(0, 3.2, 0)

local function drawGate(pos, color)
    ac.trackProgressToWorldCoordinateTo(pos, gateCenter)
    ac.trackProgressToWorldCoordinateTo((pos - 0.0001) % 1, gateBack)
    gateSide:setCrossNormalized(gateBack:sub(gateCenter), down)
    local sides = ac.getTrackAISplineSides(pos)
    gateCenter:addScaled(gateSide, (sides.x - sides.y) / 2)
    local width = (sides.x + sides.y) / 2 + 0.2
    gateSide:scale(width)
    gateQuad.p4:set(gateCenter):sub(gateSide)
    gateQuad.p3:set(gateCenter):add(gateSide)
    gateQuad.p2:set(gateQuad.p3):add(height)
    gateQuad.p1:set(gateQuad.p4):add(height)
    gateQuad.values.gColor = color
    gateQuad.values.gWidthMul = math.max(0.5, width / 4)
    render.shaderedQuad(gateQuad)
end

local function drawTrainingGates()
    if not settings.trainingEnabled() or not training.isActive() then return end
    local sector = training.selected()
    local pending = training.pendingStart()
    if training.isMapping() then
        if type(pending) == 'table' then
            drawGate(pending.pos, rgbm(0.2, 1, 0.25, 0.75))
        end
    elseif sector then
        drawGate(sector.startPos, rgbm(0.2, 1, 0.25, 0.75))
        drawGate(sector.finishPos, rgbm(1, 1, 1, 0.72))
    end
end

function M.lateralOffsetCm(lapData, car)
    if not lapData or lapData ~= state.bestLap or not car or not car.position or not car.side then return nil end
    local points = ensureCache()
    local point = nearestPoint(points, car.splinePosition)
    if not point then return nil end
    local dx, dz = point.world.x - car.position.x, point.world.z - car.position.z
    return (dx * car.side.x + dz * car.side.z) * 100
end

function M.hasPath(lapData)
    return lapData == state.bestLap and ensureCache() ~= nil
end

render.on('main.track.transparent', function()
    render.setBlendMode(render.BlendMode.AlphaBlend)
    render.setCullMode(render.CullMode.None)
    render.setDepthMode(render.DepthMode.ReadOnly)
    drawReferenceLine()
    drawTrainingGates()
end)

return M
