-- Corner Analysis - All corner-specific logic
-- Analyzes corners in laps, tracks live corner data, compares to reference

local state = require('state')
local lap = require('lap')
local scoring = require('scoring')
local settings = require('app_settings')

local corner_analysis = {}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local BRAKE_THRESHOLD = settings.brakeThreshold
local THROTTLE_ON_THRESHOLD = settings.throttleThreshold
local STEERING_CENTER_THRESHOLD = 0.042  -- ~15°

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

local colors = {
    background = rgbm(0.12, 0.12, 0.12, 1.0),
    graphBg = rgbm(0.05, 0.05, 0.05, 0.95),
    referenceLine = rgbm(1, 1, 1, 1.0),
    faster = rgbm(0.55, 0.20, 0.70, 0.85),
    onSpeed = rgbm(0.20, 0.70, 0.20, 0.85),
    slower = rgbm(0.70, 0.20, 0.20, 0.85),
    refApexLine = rgbm(0.5, 0.5, 0.5, 0.4),
    currentApexLine = rgbm(1.0, 1.0, 0.0, 1.0),
    refBrakeLine = rgbm(1.0, 0.3, 0.3, 0.4),
    currentBrakeLine = rgbm(1.0, 0.2, 0.2, 1.0),
    scoreYellow = rgbm(1.0, 0.85, 0.0, 1.0),
    gaugeBg = rgbm(0.25, 0.25, 0.25, 1.0),
    textDim = rgbm(0.6, 0.6, 0.6, 1.0),
    textBright = rgbm(1, 1, 1, 1.0),
}

--------------------------------------------------------------------------------
-- Live Corner Tracking State
--------------------------------------------------------------------------------

local liveCorner = {
    cornerNum = 0,
    entrySpeed = nil,
    entryPos = nil,
    entryTime = nil,
    apexSpeed = nil,
    apexPos = nil,
    exitSpeed = nil,
    exitPos = nil,
    exitTime = nil,
    ghostEntryTime = nil,
    ghostExitTime = nil,
    passedApex = false,
    leftCorner = false,
    wasBraking = false,
    brakePos = nil,
    liftOffPos = nil,
    wasOnThrottle = false,
    speeds = {},
    maxSteeringDeg = 0,
}

local lastLapCount = 0
local currentLapTime = 0

-- Display state (last completed corner)
local displayData = nil
local displayScore = 0

-- Frozen corner state (when viewing from telemetry)
local frozenCorner = {
    active = false,
    cornerNum = 0,
    lapNumber = 0,
}

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function isSteeringCentered(steering)
    return math.abs(steering - 0.5) < STEERING_CENTER_THRESHOLD
end

local function resetLiveCorner()
    liveCorner.cornerNum = 0
    liveCorner.entrySpeed = nil
    liveCorner.entryPos = nil
    liveCorner.entryTime = nil
    liveCorner.apexSpeed = nil
    liveCorner.apexPos = nil
    liveCorner.exitSpeed = nil
    liveCorner.exitPos = nil
    liveCorner.exitTime = nil
    liveCorner.ghostEntryTime = nil
    liveCorner.ghostExitTime = nil
    liveCorner.passedApex = false
    liveCorner.leftCorner = false
    liveCorner.wasBraking = false
    liveCorner.brakePos = nil
    liveCorner.liftOffPos = nil
    liveCorner.wasOnThrottle = false
    liveCorner.speeds = {}
    liveCorner.maxSteeringDeg = 0
end

--------------------------------------------------------------------------------
-- Corner Analysis: Analyze a single corner from a lap
--------------------------------------------------------------------------------

--- Analyze a single corner from a lap
---@param lapData table Lap instance
---@param cornerDef table Corner definition {number, startPos, endPos, apexPos}
---@return table Corner analysis data
function corner_analysis.analyzeCorner(lapData, cornerDef)
    if not lapData or not cornerDef then return nil end
    
    return {
        number = cornerDef.number,
        startPos = cornerDef.startPos,
        endPos = cornerDef.endPos,
        apexPos = cornerDef.apexPos,
        entrySpeed = lapData:getValueAtPos('speed', cornerDef.startPos),
        apexSpeed = lapData:getValueAtPos('speed', cornerDef.apexPos),
        exitSpeed = lapData:getValueAtPos('speed', cornerDef.endPos),
        brakePos = lapData:findBrakePoint(cornerDef.startPos, cornerDef.apexPos, settings.brakeThreshold),
        liftOffPos = lapData:findLiftPoint(cornerDef.startPos, cornerDef.apexPos, settings.throttleThreshold, settings.throttleThreshold * 0.8),
        maxSteeringDeg = lapData:findMaxSteering(cornerDef.startPos, cornerDef.endPos),
        entryTime = lapData:getTimeAtPos(cornerDef.startPos),
        exitTime = lapData:getTimeAtPos(cornerDef.endPos),
    }
end

--- Analyze all corners in a lap
---@param lapData table Lap instance
---@param corners table Array of corner definitions (defaults to state.trackCorners)
---@return table Corner analysis indexed by corner number
function corner_analysis.analyzeLap(lapData, corners)
    if not lapData then return {} end
    corners = corners or state.trackCorners
    if not corners then return {} end
    
    local analysis = {}
    for _, corner in ipairs(corners) do
        if corner.startPos and corner.endPos then
            analysis[corner.number] = corner_analysis.analyzeCorner(lapData, corner)
        end
    end
    return analysis
end

--- Compare two corner analyses (current vs reference)
---@param current table Current corner analysis
---@param reference table Reference corner analysis
---@return table Comparison with deltas
function corner_analysis.compareCorners(current, reference)
    if not current or not reference then return nil end
    
    local timeDelta = nil
    if current.entryTime and current.exitTime and reference.entryTime and reference.exitTime then
        local currentDuration = current.exitTime - current.entryTime
        local refDuration = reference.exitTime - reference.entryTime
        timeDelta = currentDuration - refDuration
    end
    
    return {
        number = current.number,
        -- Reference data
        refEntrySpeed = reference.entrySpeed or 0,
        refApexSpeed = reference.apexSpeed or 0,
        refExitSpeed = reference.exitSpeed or 0,
        refApexPos = reference.apexPos,
        refStartPos = reference.startPos,
        refEndPos = reference.endPos,
        refBrakePos = reference.brakePos,
        refLiftOffPos = reference.liftOffPos,
        refMaxSteeringDeg = reference.maxSteeringDeg or 0,
        -- Current data
        currentEntrySpeed = current.entrySpeed,
        currentApexSpeed = current.apexSpeed,
        currentExitSpeed = current.exitSpeed,
        currentApexPos = current.apexPos,
        currentBrakePos = current.brakePos,
        currentLiftOffPos = current.liftOffPos,
        currentMaxSteeringDeg = current.maxSteeringDeg or 0,
        -- Deltas
        timeDelta = timeDelta,
        entrySpeedDelta = current.entrySpeed and reference.entrySpeed and 
                          (current.entrySpeed - reference.entrySpeed) or nil,
        apexSpeedDelta = current.apexSpeed and reference.apexSpeed and 
                         (current.apexSpeed - reference.apexSpeed) or nil,
        exitSpeedDelta = current.exitSpeed and reference.exitSpeed and 
                         (current.exitSpeed - reference.exitSpeed) or nil,
        steeringDelta = (current.maxSteeringDeg or 0) - (reference.maxSteeringDeg or 0),
    }
end

--- Set a specific corner for display (called from lap_telemetry when clicking a corner)
---@param cornerNum number Corner number to display
---@param currentLap table Current lap data
---@param referenceLap table Reference lap data
function corner_analysis.setViewedCorner(cornerNum, currentLap, referenceLap)
    if not cornerNum or not currentLap or not referenceLap then return end
    
    -- Find the corner definition
    local cornerDef = state.getCornerInfo(cornerNum)
    if not cornerDef then return end
    
    -- Analyze both laps for this corner
    local currentAnalysis = corner_analysis.analyzeCorner(currentLap, cornerDef)
    local refAnalysis = corner_analysis.analyzeCorner(referenceLap, cornerDef)
    
    if not currentAnalysis or not refAnalysis then return end
    
    -- Build comparison data (matching the displayData structure from live tracking)
    displayData = corner_analysis.compareCorners(currentAnalysis, refAnalysis)
    
    if displayData then
        -- Generate currentSpeeds array by sampling the lap data through the corner
        local speeds = {}
        local startPos = cornerDef.startPos
        local endPos = cornerDef.endPos
        local numSamples = 50  -- Reasonable resolution for the speed trace
        
        for i = 0, numSamples do
            local pos = startPos + (endPos - startPos) * (i / numSamples)
            local speed = currentLap:getValueAtPos('speed', pos)
            if speed then
                table.insert(speeds, { pos = pos, speed = speed })
            end
        end
        displayData.currentSpeeds = speeds
        
        -- Calculate score
        displayScore = scoring.calculate(displayData)
        
        -- Set frozen state
        frozenCorner.active = true
        frozenCorner.cornerNum = cornerNum
        frozenCorner.lapNumber = currentLap.lapNumberInSession or 0
        
        ac.log(string.format("AC Tracer: Viewing corner %d analysis from telemetry (lap %d)",
            cornerNum, frozenCorner.lapNumber))
    end
end

--- Clear frozen corner state (return to live tracking)
function corner_analysis.clearFrozenCorner()
    frozenCorner.active = false
    frozenCorner.cornerNum = 0
    frozenCorner.lapNumber = 0
end

--- Check if viewing a frozen corner
function corner_analysis.isFrozen()
    return frozenCorner.active
end

--- Get the frozen corner number (0 if not frozen)
function corner_analysis.getFrozenCornerNum()
    return frozenCorner.active and frozenCorner.cornerNum or 0
end

--------------------------------------------------------------------------------
-- Live Corner Tracking: Called on corner exit
--------------------------------------------------------------------------------

local function onCornerExit()
    if liveCorner.cornerNum == 0 then return end
    
    local cornerInfo = state.getCornerInfo(liveCorner.cornerNum)
    if not cornerInfo then return end
    
    -- Calculate corner time delta
    local timeDelta = nil
    if liveCorner.entryTime and liveCorner.exitTime then
        local currentDuration = liveCorner.exitTime - liveCorner.entryTime
        if liveCorner.ghostEntryTime and liveCorner.ghostExitTime then
            local ghostDuration = liveCorner.ghostExitTime - liveCorner.ghostEntryTime
            timeDelta = currentDuration - ghostDuration
        end
    end
    
    -- Get ghost data from best lap
    local ghostEntrySpeed = state.getGhostValueAt('speed', cornerInfo.startPos) or 0
    local ghostExitSpeed = state.getGhostValueAt('speed', cornerInfo.endPos) or 0
    local ghostMaxSteeringDeg = state.getGhostMaxSteeringInRange(cornerInfo.startPos, cornerInfo.endPos)
    local refBrakePos = state.getGhostBrakePointInRange(cornerInfo.startPos, cornerInfo.endPos)
    local refLiftOffPos = state.getGhostLiftPointInRange(cornerInfo.startPos, cornerInfo.endPos)
    
    -- Get ghost's actual apex (minimum speed point) in the corner range
    local ghostApexPos, ghostApexSpeed = state.getGhostApexInRange(cornerInfo.startPos, cornerInfo.endPos)
    ghostApexPos = ghostApexPos or cornerInfo.apexPos
    ghostApexSpeed = ghostApexSpeed or 0
    
    -- Build comparison data
    displayData = {
        number = liveCorner.cornerNum,
        -- Reference data
        refEntrySpeed = ghostEntrySpeed,
        refApexSpeed = ghostApexSpeed,
        refExitSpeed = ghostExitSpeed,
        refApexPos = ghostApexPos,
        refStartPos = cornerInfo.startPos,
        refEndPos = cornerInfo.endPos,
        refBrakePos = refBrakePos,
        refLiftOffPos = refLiftOffPos,
        refMaxSteeringDeg = ghostMaxSteeringDeg,
        -- Current lap data
        currentSpeeds = liveCorner.speeds,
        currentEntrySpeed = liveCorner.entrySpeed,
        currentApexSpeed = liveCorner.apexSpeed,
        currentApexPos = liveCorner.apexPos,
        currentExitSpeed = liveCorner.exitSpeed or liveCorner.apexSpeed,
        currentBrakePos = liveCorner.brakePos,
        currentLiftOffPos = liveCorner.liftOffPos,
        currentMaxSteeringDeg = liveCorner.maxSteeringDeg,
        -- Deltas (apex speed uses each lap's own apex, not same position)
        timeDelta = timeDelta,
        entrySpeedDelta = liveCorner.entrySpeed and ghostEntrySpeed > 0 and 
                          (liveCorner.entrySpeed - ghostEntrySpeed) or nil,
        apexSpeedDelta = liveCorner.apexSpeed and ghostApexSpeed > 0 and 
                         (liveCorner.apexSpeed - ghostApexSpeed) or nil,
        exitSpeedDelta = (liveCorner.exitSpeed or liveCorner.apexSpeed or 0) - ghostExitSpeed,
        steeringDelta = liveCorner.maxSteeringDeg - ghostMaxSteeringDeg,
    }
    
    displayScore = scoring.calculate(displayData)
end

--------------------------------------------------------------------------------
-- Live Corner Tracking: Update (call every frame)
--------------------------------------------------------------------------------

--- Update live corner tracking
---@param car table Car state from ac.getCar()
function corner_analysis.update(car)
    if not car then return end
    
    -- Clear frozen corner state when car starts moving (above 30 km/h)
    if frozenCorner.active and car.speedKmh >= 30 then
        corner_analysis.clearFrozenCorner()
    end
    
    -- Reset on new lap
    if car.lapCount ~= lastLapCount then
        lastLapCount = car.lapCount
        resetLiveCorner()
    end
    
    currentLapTime = car.lapTimeMs / 1000
    
    local currentPos = car.splinePosition
    local currentSpeed = car.speedKmh
    local isBraking = car.brake >= BRAKE_THRESHOLD
    local isFullThrottle = car.gas >= THROTTLE_ON_THRESHOLD
    
    local normalizedSteering = lap.normalizeSteer(car.steer)
    local isCentered = isSteeringCentered(normalizedSteering)
    
    local wasInCorner = liveCorner.cornerNum > 0 and not liveCorner.leftCorner
    
    -- Check what corner we're in
    local cornerNum = state.isInCorner(currentPos)
    local cornerInfo = cornerNum > 0 and state.getCornerInfo(cornerNum) or nil
    
    if cornerNum > 0 and cornerInfo then
        if liveCorner.cornerNum ~= cornerNum then
            -- Entering new corner
            liveCorner.cornerNum = cornerNum
            liveCorner.entrySpeed = currentSpeed
            liveCorner.entryPos = currentPos
            liveCorner.entryTime = currentLapTime
            liveCorner.ghostEntryTime = state.getGhostTimeAtPos(currentPos)
            liveCorner.ghostExitTime = nil
            liveCorner.apexSpeed = currentSpeed
            liveCorner.apexPos = currentPos
            liveCorner.exitSpeed = nil
            liveCorner.exitPos = nil
            liveCorner.exitTime = nil
            liveCorner.passedApex = false
            liveCorner.leftCorner = false
            liveCorner.wasBraking = false
            liveCorner.brakePos = nil
            liveCorner.liftOffPos = nil
            liveCorner.wasOnThrottle = false
            liveCorner.speeds = {}
            liveCorner.maxSteeringDeg = 0
        else
            -- In corner - track data
            table.insert(liveCorner.speeds, { pos = currentPos, speed = currentSpeed })
            
            -- Track max steering (absolute degrees)
            local steerDeg = math.abs(car.steer)
            if steerDeg > liveCorner.maxSteeringDeg then
                liveCorner.maxSteeringDeg = steerDeg
            end
            
            -- Track lift-off
            if isFullThrottle then
                liveCorner.wasOnThrottle = true
            elseif liveCorner.wasOnThrottle and not liveCorner.liftOffPos then
                liveCorner.liftOffPos = currentPos
            end
            
            -- Track brake point
            if isBraking and not liveCorner.brakePos then
                liveCorner.brakePos = currentPos
            end
            
            -- Entry speed: highest before braking
            if not liveCorner.wasBraking then
                if isBraking then
                    liveCorner.wasBraking = true
                elseif currentSpeed > liveCorner.entrySpeed then
                    liveCorner.entrySpeed = currentSpeed
                    liveCorner.entryPos = currentPos
                end
            end
            
            -- Apex speed: minimum in corner
            if currentSpeed < liveCorner.apexSpeed then
                liveCorner.apexSpeed = currentSpeed
                liveCorner.apexPos = currentPos
            end
            
            -- Check if passed apex
            if cornerInfo.apexPos then
                if currentPos >= cornerInfo.apexPos or (cornerInfo.apexPos > 0.9 and currentPos < 0.1) then
                    liveCorner.passedApex = true
                end
            end
            
            -- Exit speed: highest after apex
            if liveCorner.passedApex then
                if liveCorner.exitSpeed == nil or currentSpeed > liveCorner.exitSpeed then
                    liveCorner.exitSpeed = currentSpeed
                    liveCorner.exitPos = currentPos
                end
            end
        end
    else
        -- Not in corner
        if liveCorner.cornerNum > 0 and not liveCorner.leftCorner then
            liveCorner.leftCorner = true
            liveCorner.exitTime = currentLapTime
            liveCorner.ghostExitTime = state.getGhostTimeAtPos(currentPos)
        end
    end
    
    -- Detect corner exit
    if wasInCorner and liveCorner.leftCorner then
        onCornerExit()
    end
end

--------------------------------------------------------------------------------
-- Accessors
--------------------------------------------------------------------------------

--- Get current corner data (while in corner)
function corner_analysis.getCurrentCornerData()
    if liveCorner.cornerNum == 0 then return nil end
    
    local cornerInfo = state.getCornerInfo(liveCorner.cornerNum)
    if not cornerInfo then return nil end
    
    local cornerTimeDelta = nil
    if liveCorner.leftCorner and liveCorner.entryTime and liveCorner.exitTime then
        local currentDuration = liveCorner.exitTime - liveCorner.entryTime
        if liveCorner.ghostEntryTime and liveCorner.ghostExitTime then
            local ghostDuration = liveCorner.ghostExitTime - liveCorner.ghostEntryTime
            cornerTimeDelta = currentDuration - ghostDuration
        end
    end
    
    local ghostEntrySpeed = state.getGhostValueAt('speed', cornerInfo.startPos) or 0
    local ghostApexSpeed = state.getGhostValueAt('speed', cornerInfo.apexPos) or 0
    local ghostExitSpeed = state.getGhostValueAt('speed', cornerInfo.endPos) or 0
    
    return {
        number = liveCorner.cornerNum,
        ghostEntrySpeed = ghostEntrySpeed,
        ghostApexSpeed = ghostApexSpeed,
        ghostExitSpeed = ghostExitSpeed,
        ghostApexPos = cornerInfo.apexPos,
        currentEntrySpeed = liveCorner.entrySpeed,
        currentApexSpeed = liveCorner.apexSpeed,
        currentExitSpeed = liveCorner.exitSpeed,
        entryPos = liveCorner.entryPos,
        apexPos = liveCorner.apexPos,
        exitPos = liveCorner.exitPos,
        entryDelta = liveCorner.entrySpeed and ghostEntrySpeed > 0 and 
                     (liveCorner.entrySpeed - ghostEntrySpeed) or nil,
        apexDelta = liveCorner.apexSpeed and ghostApexSpeed > 0 and 
                    (liveCorner.apexSpeed - ghostApexSpeed) or nil,
        exitDelta = liveCorner.exitSpeed and ghostExitSpeed > 0 and 
                    (liveCorner.exitSpeed - ghostExitSpeed) or nil,
        cornerTimeDelta = cornerTimeDelta,
        passedApex = liveCorner.passedApex,
        leftCorner = liveCorner.leftCorner,
        startPos = cornerInfo.startPos,
        endPos = cornerInfo.endPos
    }
end

function corner_analysis.getCurrentCornerNum()
    return liveCorner.cornerNum
end

function corner_analysis.getLastCompletedCorner()
    return displayData
end

function corner_analysis.justExitedCorner()
    return liveCorner.leftCorner
end

--------------------------------------------------------------------------------
-- UI Drawing
--------------------------------------------------------------------------------

local function drawFilledComparison(x, y, w, h, currentSpeeds, refStartPos, refEndPos, refApexPos)
    if not currentSpeeds or #currentSpeeds < 2 then return end
    if not state.hasBestLap() then return end

    local SPEED_TOLERANCE = 1

    local minSpeed, maxSpeed = math.huge, 0
    for _, s in ipairs(currentSpeeds) do
        minSpeed = math.min(minSpeed, s.speed)
        maxSpeed = math.max(maxSpeed, s.speed)
        local refSpd = state.getGhostValueAt('speed', s.pos)
        if refSpd then
            minSpeed = math.min(minSpeed, refSpd)
            maxSpeed = math.max(maxSpeed, refSpd)
        end
    end

    local speedRange = maxSpeed - minSpeed
    minSpeed = minSpeed - speedRange * 0.15
    maxSpeed = maxSpeed + speedRange * 0.1
    speedRange = maxSpeed - minSpeed

    if speedRange <= 0 then return end

    local numPoints = #currentSpeeds
    local bottomY = y + h

    for i = 1, numPoints - 1 do
        local s1 = currentSpeeds[i]
        local s2 = currentSpeeds[i + 1]
        local ref1 = state.getGhostValueAt('speed', s1.pos) or s1.speed
        local ref2 = state.getGhostValueAt('speed', s2.pos) or s2.speed
        local x1 = x + (i - 1) / (numPoints - 1) * w
        local x2 = x + i / (numPoints - 1) * w
        local curY1 = y + h - ((s1.speed - minSpeed) / speedRange) * h
        local curY2 = y + h - ((s2.speed - minSpeed) / speedRange) * h
        local avgCurSpeed = (s1.speed + s2.speed) / 2
        local avgRefSpeed = (ref1 + ref2) / 2
        local speedDiff = avgCurSpeed - avgRefSpeed
        local color
        if math.abs(speedDiff) <= SPEED_TOLERANCE then
            color = colors.onSpeed
        elseif speedDiff > 0 then
            color = colors.faster
        else
            color = colors.slower
        end
        ui.pathClear()
        ui.pathLineTo(vec2(x1, curY1))
        ui.pathLineTo(vec2(x2, curY2))
        ui.pathLineTo(vec2(x2, bottomY))
        ui.pathLineTo(vec2(x1, bottomY))
        ui.pathFillConvex(color)
    end

    ui.pathClear()
    for i, s in ipairs(currentSpeeds) do
        local refSpd = state.getGhostValueAt('speed', s.pos) or s.speed
        local px = x + (i - 1) / (numPoints - 1) * w
        local py = y + h - ((refSpd - minSpeed) / speedRange) * h
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(colors.referenceLine, false, 2)
end

local function drawDashedLine(x1, y1, x2, y2, color, dashLen, gapLen, thickness)
    dashLen = dashLen or 4
    gapLen = gapLen or 4
    thickness = thickness or 2
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length == 0 then return end
    local unitX = dx / length
    local unitY = dy / length
    local pos = 0
    while pos < length do
        local endPos = math.min(pos + dashLen, length)
        ui.drawLine(
            vec2(x1 + unitX * pos, y1 + unitY * pos),
            vec2(x1 + unitX * endPos, y1 + unitY * endPos),
            color, thickness
        )
        pos = endPos + gapLen
    end
end

local function drawMarkerLines(x, y, w, h, currentSpeeds, data)
    if not currentSpeeds or #currentSpeeds < 2 then return end
    local startPos = currentSpeeds[1].pos
    local endPos = currentSpeeds[#currentSpeeds].pos
    local posRange = endPos - startPos
    if posRange <= 0 then posRange = 1 end

    local function posToX(pos)
        if not pos then return nil end
        local px = x + ((pos - startPos) / posRange) * w
        if px >= x and px <= x + w then return px end
        return nil
    end

    local refBrakeX = posToX(data.refBrakePos)
    if refBrakeX then
        drawDashedLine(refBrakeX, y, refBrakeX, y + h, colors.refBrakeLine, 3, 3, 1)
    end

    local refApexX = posToX(data.refApexPos)
    if refApexX then
        drawDashedLine(refApexX, y, refApexX, y + h, colors.refApexLine, 4, 3, 1)
    end

    local curBrakeX = posToX(data.currentBrakePos)
    if curBrakeX then
        ui.drawLine(vec2(curBrakeX, y), vec2(curBrakeX, y + h), colors.currentBrakeLine, 2)
    end

    local curApexX = posToX(data.currentApexPos)
    if curApexX then
        ui.drawLine(vec2(curApexX, y), vec2(curApexX, y + h), colors.currentApexLine, 3)
    end
end

local function drawScoreGauge(cx, cy, radius, score)
    local startAngle = math.rad(-225)
    local endAngle = math.rad(45)
    local totalArc = endAngle - startAngle
    local segments = 32
    ui.pathClear()
    for i = 0, segments do
        local angle = startAngle + (i / segments) * totalArc
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(colors.gaugeBg, false, 8)

    local scoreAngle = startAngle + (score / 100) * totalArc
    ui.pathClear()
    for i = 0, segments do
        local angle = startAngle + (i / segments) * (scoreAngle - startAngle)
        if angle > scoreAngle then break end
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(colors.scoreYellow, false, 8)

    ui.pushFont(ui.Font.Title)
    local scoreText = tostring(math.floor(score))
    local textWidth = ui.measureText(scoreText).x
    ui.setCursor(vec2(cx - textWidth / 2, cy - 12))
    ui.pushStyleColor(ui.StyleColor.Text, colors.scoreYellow)
    ui.text(scoreText)
    ui.popStyleColor()
    ui.popFont()
end

--- Main window rendering
function corner_analysis.draw(dt, useKmh)
    local car = ac.getCar(0)
    
    -- Auto-hide when traveling above speed threshold
    if settings.telemetryAutoHide and car and car.speedKmh > settings.telemetryAutoHideSpeed then
        ui.drawRectFilled(vec2(0, 0), vec2(115, 22), rgbm(0.08, 0.1, 0.08, 0.9), 4)
        ui.setCursor(vec2(8, 3))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.5, 0.7, 0.4, 1))
        ui.text("Corner Analysis")
        ui.popStyleColor()
        ui.popFont()
        return
    end
    
    local windowSize = ui.availableSpace()
    local padding = 8
    local panelX = windowSize.x * 0.68
    local graphWidth = panelX - padding * 2
    local graphY = 22
    local graphHeight = windowSize.y - padding - graphY
    
    -- Fixed layout constants
    local gaugeRadius = 25
    local gaugeCenterX = windowSize.x - gaugeRadius - 15
    local gaugeCenterY = 35
    local statsStartY = gaugeCenterY + gaugeRadius + 26
    local lineH = 18
    local labelW = 45
    local speedUnit = useKmh and "km/h" or "mph"
    
    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, colors.background, 4)
    
    -- Graph area background
    ui.drawRectFilled(
        vec2(padding, graphY),
        vec2(padding + graphWidth, graphY + graphHeight),
        colors.graphBg,
        4
    )
    
    -- Score gauge (always visible, same position)
    drawScoreGauge(gaugeCenterX, gaugeCenterY, gaugeRadius, displayScore)
    
    -- Header text
    ui.setCursor(vec2(padding, 4))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    if frozenCorner.active then
        local lapText = frozenCorner.lapNumber > 0 and string.format(" from lap %d", frozenCorner.lapNumber) or ""
        ui.text(string.format("Focusing on corner %d%s", frozenCorner.cornerNum, lapText))
    else
        ui.text("Corner Speed & Position vs. Reference Lap")
    end
    ui.popStyleColor()
    ui.popFont()
    
    -- Helper functions for stats (defined once, used below)
    local statsY = statsStartY
    
    local function drawStatRow(label, delta, unit)
        if delta == nil then return end
        local sign = delta >= 0 and "+" or ""
        local rounded = math.floor(math.abs(delta) + 0.5)
        local valueColor = colors.textBright
        if rounded ~= 0 then
            valueColor = delta > 0 and rgbm(0.3, 1, 0.3, 1) or rgbm(1, 0.4, 0.4, 1)
        end
        ui.setCursor(vec2(panelX, statsY))
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text(label)
        ui.popStyleColor()
        ui.sameLine(panelX + labelW)
        ui.pushStyleColor(ui.StyleColor.Text, valueColor)
        ui.text(string.format("%s%d %s", sign, rounded, unit))
        ui.popStyleColor()
        statsY = statsY + lineH
    end
    
    local function drawPosRow(label, meters)
        if meters == nil then return end
        local rounded = math.abs(math.floor(meters + 0.5))
        local direction = meters >= 0 and "later" or "earlier"
        local valueColor = colors.textBright
        if rounded ~= 0 then
            valueColor = meters > 0 and rgbm(0.3, 1, 0.3, 1) or rgbm(1, 0.4, 0.4, 1)
        end
        ui.setCursor(vec2(panelX, statsY))
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text(label)
        ui.popStyleColor()
        ui.sameLine(panelX + labelW)
        ui.pushStyleColor(ui.StyleColor.Text, valueColor)
        ui.text(string.format("%dm %s", rounded, direction))
        ui.popStyleColor()
        statsY = statsY + lineH
    end
    
    if displayData then
        -- Graph outline (blue for frozen, green for live)
        local outlineColor = frozenCorner.active 
            and rgbm(0.4, 0.7, 1, 0.8)
            or rgbm(0.6, 0.8, 0.4, 0.6)
        ui.drawRect(
            vec2(padding, graphY),
            vec2(padding + graphWidth, graphY + graphHeight),
            outlineColor, 4, 2
        )
        
        -- Graph content
        drawFilledComparison(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds,
            displayData.refStartPos, displayData.refEndPos, displayData.refApexPos
        )
        drawMarkerLines(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds, displayData
        )
        
        -- Time delta (left of gauge, vertically centered)
        if displayData.timeDelta then
            local sign = displayData.timeDelta >= 0 and "+" or ""
            local deltaColor = displayData.timeDelta >= 0 and rgbm(1, 0.3, 0.3, 1) or rgbm(0.3, 1, 0.3, 1)
            local deltaText = string.format("%s%.2fs", sign, displayData.timeDelta)
            ui.pushFont(ui.Font.Title)
            local textSize = ui.measureText(deltaText)
            ui.setCursor(vec2(gaugeCenterX - gaugeRadius - textSize.x - 15, gaugeCenterY - textSize.y / 2))
            ui.pushStyleColor(ui.StyleColor.Text, deltaColor)
            ui.text(deltaText)
            ui.popStyleColor()
            ui.popFont()
        end
        
        -- Corner label
        ui.setCursor(vec2(panelX, gaugeCenterY + gaugeRadius + 8))
        ui.pushFont(ui.Font.Small)
        local labelColor = frozenCorner.active and rgbm(0.4, 0.7, 1, 1) or colors.textDim
        ui.pushStyleColor(ui.StyleColor.Text, labelColor)
        ui.text("Corner " .. displayData.number .. (frozenCorner.active and " (frozen)" or ""))
        ui.popStyleColor()
        ui.popFont()
        
        -- Stats panel
        ui.pushFont(ui.Font.Main)
        
        -- SPEED section
        ui.setCursor(vec2(panelX, statsY))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.5, 0.5, 0.5, 1))
        ui.text("SPEED")
        ui.popStyleColor()
        ui.popFont()
        statsY = statsY + 14
        
        drawStatRow("Entry", displayData.entrySpeedDelta, speedUnit)
        drawStatRow("Apex", displayData.apexSpeedDelta, speedUnit)
        drawStatRow("Exit", displayData.exitSpeedDelta, speedUnit)
        statsY = statsY + 4
        
        -- POSITION section
        ui.setCursor(vec2(panelX, statsY))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.5, 0.5, 0.5, 1))
        ui.text("POSITION")
        ui.popStyleColor()
        ui.popFont()
        statsY = statsY + 14
        
        local brakeMeters, liftOffMeters = scoring.getMeterDeltas(displayData)
        drawPosRow("Brake", brakeMeters)
        drawPosRow("Lift", liftOffMeters)
        if displayData.currentApexPos and displayData.refApexPos then
            drawPosRow("Apex", (displayData.currentApexPos - displayData.refApexPos) * 1000)
        end
        
        ui.popFont()
    else
        -- Empty state: message in graph area
        ui.setCursor(vec2(padding + graphWidth / 2 - 60, graphY + graphHeight / 2 - 10))
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text(state.hasBestLap() and "Waiting for corner exit..." or "Load a reference lap first")
        ui.popStyleColor()
    end
end

function corner_analysis.reset()
    displayData = nil
    displayScore = 0
    resetLiveCorner()
    corner_analysis.clearFrozenCorner()
end

return corner_analysis
