-- Corner Analysis - All corner-specific logic
-- Analyzes corners in laps, tracks live corner data, compares to reference

local state = require('state')
local lap = require('lap')
local scoring = require('scoring')
local settings = require('app_settings')
local extended_brake = require('extended-brake')
local theme = require('theme')
local ui_utils = require('ui_utils')

local corner_analysis = {}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local BRAKE_THRESHOLD = settings.brakeThreshold
local THROTTLE_ON_THRESHOLD = settings.throttleThreshold
local STEERING_CENTER_THRESHOLD = 0.042  -- ~15°

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
---@param cornerDef table Corner definition {number, startPos, endPos}
---@return table Corner analysis data
function corner_analysis.analyzeCorner(lapData, cornerDef)
    if not lapData or not cornerDef then return nil end

    -- Calculate apex dynamically for this specific lap (min speed point)
    local apexPos, apexSpeed = lapData:findApex(cornerDef.startPos, cornerDef.endPos)

    -- Entry speed: max speed before min speed point
    -- Exit speed: max speed after min speed point
    local entrySpeed = lapData:findEntrySpeed(cornerDef.startPos, cornerDef.endPos)
    local exitSpeed = lapData:findExitSpeed(cornerDef.startPos, cornerDef.endPos)

    return {
        number = cornerDef.number,
        startPos = cornerDef.startPos,
        endPos = cornerDef.endPos,
        apexPos = apexPos,
        entrySpeed = entrySpeed,
        apexSpeed = apexSpeed,
        exitSpeed = exitSpeed,
        brakePos = lapData:findBrakePoint(cornerDef.startPos, cornerDef.endPos, settings.brakeThreshold),
        liftOffPos = lapData:findLiftPoint(cornerDef.startPos, cornerDef.endPos, settings.throttleThreshold),
        maxSteeringDeg = lapData:findMaxSteering(cornerDef.startPos, cornerDef.endPos),
        minGear = lapData:findMinGear(cornerDef.startPos, cornerDef.endPos),
        entryTime = lapData:getTimeAtPos(cornerDef.startPos),
        exitTime = lapData:getTimeAtPos(cornerDef.endPos),
        overlapTime = lapData:getOverlapTimeInRange(cornerDef.startPos, cornerDef.endPos),
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
        currentMinGear = current.minGear,
        currentOverlapTime = current.overlapTime or 0,
        -- Reference gear
        refMinGear = reference.minGear,
        -- Deltas
        timeDelta = timeDelta,
        entrySpeedDelta = current.entrySpeed and reference.entrySpeed and
                          (current.entrySpeed - reference.entrySpeed) or nil,
        apexSpeedDelta = current.apexSpeed and reference.apexSpeed and
                         (current.apexSpeed - reference.apexSpeed) or nil,
        exitSpeedDelta = current.exitSpeed and reference.exitSpeed and
                         (current.exitSpeed - reference.exitSpeed) or nil,
        steeringDelta = (current.maxSteeringDeg or 0) - (reference.maxSteeringDeg or 0),
        gearDelta = (current.minGear and reference.minGear) and (current.minGear - reference.minGear) or nil,
        refOverlapTime = reference.overlapTime or 0,
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
    local isBraking = extended_brake.getNormalizedBrake(car) >= BRAKE_THRESHOLD
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
            
            -- Apex speed: minimum in corner (track continuously)
            if currentSpeed < liveCorner.apexSpeed then
                liveCorner.apexSpeed = currentSpeed
                liveCorner.apexPos = currentPos
                -- Reset passedApex since we found a new min speed point
                liveCorner.passedApex = false
            else
                -- Speed is increasing, we've passed the min speed point
                liveCorner.passedApex = true
            end

            -- Entry speed: max speed before min speed point
            if not liveCorner.passedApex then
                if currentSpeed > liveCorner.entrySpeed then
                    liveCorner.entrySpeed = currentSpeed
                    liveCorner.entryPos = currentPos
                end
            end

            -- Exit speed: max speed after min speed point
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
    local ghostApexPos, ghostApexSpeed = state.getGhostApexInRange(cornerInfo.startPos, cornerInfo.endPos)
    ghostApexSpeed = ghostApexSpeed or 0
    local ghostExitSpeed = state.getGhostValueAt('speed', cornerInfo.endPos) or 0

    return {
        number = liveCorner.cornerNum,
        ghostEntrySpeed = ghostEntrySpeed,
        ghostApexSpeed = ghostApexSpeed,
        ghostExitSpeed = ghostExitSpeed,
        ghostApexPos = ghostApexPos,
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
            color = theme.corner.onSpeed
        elseif speedDiff > 0 then
            color = theme.corner.faster
        else
            color = theme.corner.slower
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
    ui.pathStroke(theme.text.primary, false, 2)
end


--- Draw direction indicator between solid (current) and dashed (ref) marker lines
--- Shows which way the marker should move to match reference
--- Draws a small arrow at the very top (on the border) pointing toward reference
---@param x1 number X position of current (solid) line
---@param x2 number X position of reference (dashed) line
---@param y number Y position (top of graph area / border line)
---@param color rgbm Arrow color
local function drawDirectionArrows(x1, x2, y, color)
    if not x1 or not x2 then return end

    local gap = x2 - x1  -- Positive = ref is to the right
    local dist = math.abs(gap)
    if dist < 12 then return end  -- Too close to show indicator

    local direction = gap > 0 and 1 or -1  -- 1 = right, -1 = left
    local midX = (x1 + x2) / 2

    -- Small arrow at very top, on the border line
    local arrowLen = math.min(4, dist / 5)
    local arrowHalfH = 2
    local arrowTipX = midX + direction * arrowLen
    local arrowBaseX = midX - direction * arrowLen

    -- Draw small filled triangle arrow on the border
    ui.pathClear()
    ui.pathLineTo(vec2(arrowBaseX, y - arrowHalfH))
    ui.pathLineTo(vec2(arrowTipX, y))
    ui.pathLineTo(vec2(arrowBaseX, y + arrowHalfH))
    ui.pathFillConvex(theme.withAlpha(color, 0.8))
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

    local trackLen = ac.getSim().trackLengthM or 5000

    -- Reference lines (dashed, thicker for visibility)
    local refBrakeX = posToX(data.refBrakePos)
    if refBrakeX then
        ui_utils.drawDashedLine(vec2(refBrakeX, y), vec2(refBrakeX, y + h), theme.marker.brakeRef, 2, 4, 3)
    end

    local refApexX = posToX(data.refApexPos)
    if refApexX then
        ui_utils.drawDashedLine(vec2(refApexX, y), vec2(refApexX, y + h), theme.marker.apexRef, 2, 5, 3)
    end

    -- Reference lift line (dashed green) - only show if > 10m earlier than ref brake
    local refLiftX = nil
    if data.refLiftOffPos and data.refBrakePos then
        local refLiftM = data.refLiftOffPos * trackLen
        local refBrakeM = data.refBrakePos * trackLen
        local refLiftToBrakeDist = refBrakeM - refLiftM
        if refLiftToBrakeDist < 0 then refLiftToBrakeDist = refLiftToBrakeDist + trackLen end

        if refLiftToBrakeDist > 10 then
            refLiftX = posToX(data.refLiftOffPos)
            if refLiftX then
                ui_utils.drawDashedLine(vec2(refLiftX, y), vec2(refLiftX, y + h), theme.marker.liftRef, 2, 4, 3)
            end
        end
    end

    -- Current lines (solid)
    local curBrakeX = posToX(data.currentBrakePos)
    if curBrakeX then
        ui.drawLine(vec2(curBrakeX, y), vec2(curBrakeX, y + h), theme.marker.brake, 2)
    end

    local curApexX = posToX(data.currentApexPos)
    if curApexX then
        ui.drawLine(vec2(curApexX, y), vec2(curApexX, y + h), theme.marker.apex, 3)
    end

    -- Current lift point line (green) - only show if > 10m earlier than brake point
    local curLiftX = nil
    if data.currentLiftOffPos and data.currentBrakePos then
        local liftM = data.currentLiftOffPos * trackLen
        local brakeM = data.currentBrakePos * trackLen
        local liftToBreakeDist = brakeM - liftM
        if liftToBreakeDist < 0 then liftToBreakeDist = liftToBreakeDist + trackLen end

        if liftToBreakeDist > 10 then
            curLiftX = posToX(data.currentLiftOffPos)
            if curLiftX then
                ui.drawLine(vec2(curLiftX, y), vec2(curLiftX, y + h), theme.marker.lift, 2)
            end
        end
    end

    -- Draw direction arrows at top border (between solid and dashed lines)
    drawDirectionArrows(curBrakeX, refBrakeX, y, theme.marker.brake)
    drawDirectionArrows(curApexX, refApexX, y, theme.marker.apex)
    drawDirectionArrows(curLiftX, refLiftX, y, theme.marker.lift)
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
    ui.pathStroke(theme.score.bg, false, 8)

    local scoreAngle = startAngle + (score / 100) * totalArc
    ui.pathClear()
    for i = 0, segments do
        local angle = startAngle + (i / segments) * (scoreAngle - startAngle)
        if angle > scoreAngle then break end
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(theme.score.fill, false, 8)

    ui.pushFont(ui.Font.Title)
    local scoreText = tostring(math.floor(score))
    local textWidth = ui.measureText(scoreText).x
    ui.setCursor(vec2(cx - textWidth / 2, cy - 12))
    ui.pushStyleColor(ui.StyleColor.Text, theme.score.fill)
    ui.text(scoreText)
    ui.popStyleColor()
    ui.popFont()
end

--- Main window rendering
function corner_analysis.draw(dt, useKmh)
    local car = ac.getCar(0)

    local windowSize = ui.availableSpace()
    local padding = 8
    local panelX = windowSize.x * 0.68
    local graphWidth = panelX - padding * 2
    local graphY = 22
    local meterLabelHeight = 16  -- Space for meter annotations at bottom
    local graphHeight = windowSize.y - padding - graphY - meterLabelHeight
    
    -- Fixed layout constants
    local gaugeRadius = 25
    local gaugeCenterX = windowSize.x - gaugeRadius - 15
    local gaugeCenterY = 35
    local statsStartY = gaugeCenterY + gaugeRadius + 26
    local lineH = 18
    local labelW = 45
    local speedUnit = useKmh and "km/h" or "mph"
    
    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, theme.bg.window, 4)

    -- Graph area background
    ui.drawRectFilled(
        vec2(padding, graphY),
        vec2(padding + graphWidth, graphY + graphHeight),
        theme.bg.graph,
        4
    )
    
    -- Score gauge (always visible, same position)
    drawScoreGauge(gaugeCenterX, gaugeCenterY, gaugeRadius, displayScore)
    
    -- Header text
    ui.setCursor(vec2(padding, 4))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    if frozenCorner.active then
        local lapText = frozenCorner.lapNumber > 0 and string.format(" from lap %d", frozenCorner.lapNumber) or ""
        ui.text(string.format("Focusing on corner %d%s", frozenCorner.cornerNum, lapText))
    else
        ui.text("Corner Speed & Position vs. Reference Lap")
    end
    ui.popStyleColor()
    ui.popFont()
    
    local statsY = statsStartY
    
    if displayData then
        -- Graph outline (blue for frozen, green for live)
        local outlineColor = frozenCorner.active
            and theme.corner.focusedBorder
            or theme.withAlpha(theme.delta.positive, 0.6)
        ui.drawRect(
            vec2(padding, graphY),
            vec2(padding + graphWidth, graphY + graphHeight),
            outlineColor, 4, 2
        )

        -- Draw marker lines FIRST (behind other graphics)
        drawMarkerLines(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds, displayData
        )

        -- Graph content (filled comparison on top of markers)
        drawFilledComparison(
            padding + 4, graphY + 4,
            graphWidth - 8, graphHeight - 8,
            displayData.currentSpeeds,
            displayData.refStartPos, displayData.refEndPos, displayData.refApexPos
        )

        -- Meter annotations at bottom
        if displayData.refStartPos and displayData.refEndPos then
            local trackLen = ac.getSim().trackLengthM or 5000
            local startM = displayData.refStartPos * trackLen
            local endM = displayData.refEndPos * trackLen
            local cornerLenM = endM - startM
            if cornerLenM < 0 then cornerLenM = cornerLenM + trackLen end

            -- Choose nice round intervals based on corner length (fewer labels)
            local interval = 50
            if cornerLenM > 300 then interval = 100
            elseif cornerLenM < 100 then interval = 25
            end

            local labelY = graphY + graphHeight + 2
            ui.pushFont(ui.Font.Small)
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)

            -- Draw 0m at start
            ui.setCursor(vec2(padding, labelY))
            ui.text("0m")

            -- Draw intermediate labels at round intervals
            local numLabels = math.floor(cornerLenM / interval)
            for i = 1, numLabels do
                local meters = i * interval
                local frac = meters / cornerLenM
                if frac < 0.95 then  -- Don't draw too close to end
                    local labelX = padding + 4 + (graphWidth - 8) * frac
                    local labelText = tostring(meters) .. "m"
                    local textW = ui.measureText(labelText).x
                    ui.setCursor(vec2(labelX - textW / 2, labelY))
                    ui.text(labelText)
                end
            end

            -- Draw total length at end
            local endText = string.format("%dm", math.floor(cornerLenM + 0.5))
            local endTextW = ui.measureText(endText).x
            ui.setCursor(vec2(padding + graphWidth - endTextW, labelY))
            ui.text(endText)

            ui.popStyleColor()
            ui.popFont()
        end
        
        -- Time delta (left of gauge, vertically centered)
        if displayData.timeDelta then
            local sign = displayData.timeDelta >= 0 and "+" or ""
            local deltaColor = displayData.timeDelta >= 0 and theme.delta.negative or theme.delta.positive
            local deltaText = string.format("%s%.2fs", sign, displayData.timeDelta)
            ui.pushFont(ui.Font.Title)
            local textSize = ui.measureText(deltaText)
            ui.setCursor(vec2(gaugeCenterX - gaugeRadius - textSize.x - 15, gaugeCenterY - textSize.y / 2))
            ui.pushStyleColor(ui.StyleColor.Text, deltaColor)
            ui.text(deltaText)
            ui.popStyleColor()
            ui.popFont()
        end

        -- Stats panel
        ui.pushFont(ui.Font.Main)

        -- SPEED section
        statsY = statsY + ui_utils.sectionLabel("SPEED", panelX)
        statsY = ui_utils.deltaRow(panelX, statsY, "Entry", displayData.entrySpeedDelta, speedUnit, labelW, lineH)
        statsY = ui_utils.deltaRow(panelX, statsY, "Apex", displayData.apexSpeedDelta, speedUnit, labelW, lineH)
        statsY = ui_utils.deltaRow(panelX, statsY, "Exit", displayData.exitSpeedDelta, speedUnit, labelW, lineH)
        statsY = statsY + 4

        -- POSITION section
        statsY = statsY + ui_utils.sectionLabel("POSITION", panelX)
        local brakeMeters, liftOffMeters = scoring.getMeterDeltas(displayData)
        statsY = ui_utils.positionRow(panelX, statsY, "Brake", brakeMeters, labelW, lineH)
        statsY = ui_utils.positionRow(panelX, statsY, "Lift", liftOffMeters, labelW, lineH)
        if displayData.currentApexPos and displayData.refApexPos then
            statsY = ui_utils.positionRow(panelX, statsY, "Apex", (displayData.currentApexPos - displayData.refApexPos) * 1000, labelW, lineH)
        end

        -- Coast distance (lift to brake) - only show if > 10m
        -- Coasting is neutral - not inherently good or bad
        local currentCoast, refCoast, coastDelta = scoring.getCoastDistances(displayData)
        if currentCoast and currentCoast > 10 and coastDelta then
            local rounded = math.floor(math.abs(coastDelta) + 0.5)
            if rounded > 5 then
                statsY = statsY + 4
                local direction = coastDelta >= 0 and "more" or "less"
                ui.setCursor(vec2(panelX, statsY))
                ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
                ui.text("Coast:")
                ui.popStyleColor()
                ui.sameLine(panelX + labelW)
                ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
                ui.text(string.format("%dm %s", rounded, direction))
                ui.popStyleColor()
                statsY = statsY + lineH
            end
        end

        -- Steering delta (only show if > 10 degrees difference)
        -- Steering is neutral - more or less isn't inherently good or bad
        if displayData.steeringDelta and math.abs(displayData.steeringDelta) > 10 then
            statsY = statsY + 4
            statsY = ui_utils.neutralDeltaRow(panelX, statsY, "Steer", displayData.steeringDelta, "°", labelW, lineH)
        end

        ui.popFont()
    else
        -- Empty state: message in graph area
        ui.setCursor(vec2(padding + graphWidth / 2 - 60, graphY + graphHeight / 2 - 10))
        ui_utils.text(state.hasBestLap() and "Waiting for corner exit..." or "Load a reference lap first", theme.text.muted)
    end
end

function corner_analysis.reset()
    displayData = nil
    displayScore = 0
    resetLiveCorner()
    corner_analysis.clearFrozenCorner()
end

return corner_analysis
