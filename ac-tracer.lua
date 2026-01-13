-- AC Tracer - CSP high-performance telemetry app
-- Main script using centralized state architecture

local state = require('state')
local lap = require('lap')
local settings = require('app_settings')
local corner_analysis = require('corner_analysis')
local lap_telemetry = require('lap_telemetry')
local extended_brake = require('extended-brake')
local lap_picker = require('lap_picker')
local delta_bar = require('delta_bar')
local theme = require('theme')
local ui_utils = require('ui_utils')

-- History for trace display (rolling window)
-- Note: maxPoints is recalculated each frame to support live settings changes
local history = { 
    throttle = {}, brake = {}, clutch = {}, steering = {}, 
    speed = {}, gear = {}, pos = {}, flags = {} 
}
local updateTimer = 0

-- Overlap tracking state (for flag detection)
local overlapStartTime = nil

-- Current car reference (updated once per frame in script.update)
local currentCar = nil

--------------------------------------------------------------------------------
-- Brake Marker System (3D line on track at brakepoint)
--------------------------------------------------------------------------------

--- Find upcoming brake points from the reference lap
---@param refLap table Reference lap data
---@param currentPos number Current car position (0-1)
---@param corners table Corner definitions
---@param mode string "next" or "all"
---@return table Array of brake positions (up to 4)
local function findUpcomingBrakePoints(refLap, currentPos, corners, mode)
    if not refLap or not corners or #corners == 0 then return {} end
    
    local brakePoints = {}
    local trackLength = ac.getSim().trackLengthM or 5000
    local maxDistance = 500  -- meters ahead to look
    local maxDistanceSpline = maxDistance / trackLength
    
    for _, corner in ipairs(corners) do
        if corner.startPos and corner.endPos then
            -- Find brake point for this corner
            local brakePos = refLap:findBrakePoint(corner.startPos, corner.endPos, settings.brakeThreshold())
            
            if brakePos then
                -- Calculate distance ahead (handling wrap-around)
                local distance = brakePos - currentPos
                if distance < 0 then distance = distance + 1 end
                
                -- Only include if ahead and within render distance
                if distance > 0.002 and distance < maxDistanceSpline then
                    table.insert(brakePoints, { pos = brakePos, distance = distance })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(brakePoints, function(a, b) return a.distance < b.distance end)
    
    -- Return based on mode
    local result = {}
    if mode == "next" then
        if #brakePoints > 0 then
            result[1] = brakePoints[1].pos
        end
    else  -- "all"
        for i = 1, math.min(4, #brakePoints) do
            result[i] = brakePoints[i].pos
        end
    end
    
    return result
end

--- Draw a single brake marker line across the track using debug lines
---@param brakePos number Track position (0-1)
local function drawBrakeMarkerLine(brakePos)
    if not brakePos or brakePos < 0 then return end
    
    -- Get left and right points across the track
    -- X: -1 = left edge, 1 = right edge
    -- Y: height above track (0.1m to avoid z-fighting)
    -- Z: track progress
    local leftPoint = ac.trackCoordinateToWorld(vec3(-0.95, 0.1, brakePos))
    local rightPoint = ac.trackCoordinateToWorld(vec3(0.95, 0.1, brakePos))
    
    -- Draw thick bright red line
    -- HDR values > 1 create a glowing effect
    render.debugLine(leftPoint, rightPoint, rgbm(8, 0.2, 0.1, 1), rgbm(8, 0.2, 0.1, 1))
    
    -- Draw a second line slightly offset for thickness
    local leftPoint2 = ac.trackCoordinateToWorld(vec3(-0.95, 0.15, brakePos))
    local rightPoint2 = ac.trackCoordinateToWorld(vec3(0.95, 0.15, brakePos))
    render.debugLine(leftPoint2, rightPoint2, rgbm(6, 0.1, 0.05, 1), rgbm(6, 0.1, 0.05, 1))
end

--- Draw brake markers on the track
local function drawBrakeMarkers()
    local mode = settings.brakeMarkerMode()
    if mode == "off" then return end
    
    local refLap = state.bestLap
    if not refLap or refLap:length() < 10 then return end
    
    local car = currentCar
    if not car then return end
    
    local corners = state.trackCorners
    if not corners or #corners == 0 then return end
    
    -- Find brake points to display
    local brakePoints = findUpcomingBrakePoints(refLap, car.splinePosition, corners, mode)
    
    -- Draw each brake point as a line across the track
    for i = 1, #brakePoints do
        drawBrakeMarkerLine(brakePoints[i])
    end
end

local function updateHistory(car)
    local maxPoints = math.ceil(settings.timeWindow() * settings.sampleRate())
    
    table.insert(history.throttle, car.gas)
    -- Use extended brake pressure if available, otherwise fall back to pedal position
    table.insert(history.brake, extended_brake.getNormalizedBrake(car))
    table.insert(history.clutch, 1 - car.clutch)
    local s = lap.normalizeSteer(car.steer)
    table.insert(history.steering, s)
    table.insert(history.speed, car.speedKmh)
    table.insert(history.gear, car.gear)
    table.insert(history.pos, car.splinePosition)
    
    -- Build flags bitmask using shared detection function
    local overlapState = { startTime = overlapStartTime }
    local flagBits = lap.detectFlags(car, overlapState)
    overlapStartTime = overlapState.startTime  -- Sync state back
    
    table.insert(history.flags, flagBits)

    -- Prune all arrays to maxPoints
    while #history.throttle > maxPoints do
        table.remove(history.throttle, 1)
        table.remove(history.brake, 1)
        table.remove(history.clutch, 1)
        table.remove(history.steering, 1)
        table.remove(history.speed, 1)
        table.remove(history.gear, 1)
        table.remove(history.pos, 1)
        table.remove(history.flags, 1)
    end
end

-- Calculate max speed from current history and ghost for normalization
local function getMaxSpeed(ghostTraces)
    local maxS = 50
    for i = 1, #history.speed do
        if history.speed[i] > maxS then maxS = history.speed[i] end
    end
    if ghostTraces and ghostTraces.speed then
        for i = 1, #ghostTraces.speed do
            if ghostTraces.speed[i] > maxS then maxS = ghostTraces.speed[i] end
        end
    end
    return maxS
end

-- Calculate max gear from current history and ghost for normalization
local function getMaxGear(ghostTraces)
    local maxG = 6  -- Minimum sensible max gear
    for i = 1, #history.gear do
        if history.gear[i] > maxG then maxG = history.gear[i] end
    end
    if ghostTraces and ghostTraces.gear then
        for i = 1, #ghostTraces.gear do
            if ghostTraces.gear[i] > maxG then maxG = ghostTraces.gear[i] end
        end
    end
    return maxG
end

function script.update(dt)
    currentCar = ac.getCar(0)
    if not currentCar then return end

    local sim = ac.getSim()

    -- Skip all updates during pause or replay (TimeShift rewind)
    if sim.isPaused or sim.isReplayActive then return end

    -- Checkpoint keybind polling (check before state update)
    if settings.checkpointEnabled() then
        local saveButton = settings.getSaveCheckpointButton()
        local loadButton = settings.getLoadCheckpointButton()

        -- Save checkpoint on button press (pass trace history to be captured synchronously)
        if saveButton:pressed() then
            state.saveCheckpoint(history)
        end

        -- Load checkpoint on button press
        if loadButton:pressed() and state.hasCheckpoint() then
            if state.loadCheckpoint() then
                -- Restore trace history from checkpoint snapshot
                local traceSnapshot = state.getCheckpointTraceHistory()
                if traceSnapshot then
                    -- Deep copy snapshot back into history
                    for field, arr in pairs(traceSnapshot) do
                        history[field] = {}
                        for i = 1, #arr do
                            history[field][i] = arr[i]
                        end
                    end
                end

                -- Reset delta bar smoothing
                delta_bar.reset()

                -- Reset overlap tracking
                overlapStartTime = nil
            end
        end
    end

    -- Brake beep toggle hotkey
    local brakeBeepButton = settings.getBrakeBeepButton()
    if brakeBeepButton:pressed() then
        local newMode = settings.toggleBrakeBeepMode()
        ac.setMessage("Brake Beep", settings.brakeBeepModeDisplay())
    end

    -- Update centralized state (handles lap recording, completion, best lap)
    state.update(dt, currentCar)

    -- Update history for trace display
    updateTimer = updateTimer + dt
    local sampleInterval = 1 / settings.sampleRate()
    if updateTimer >= sampleInterval then
        updateTimer = updateTimer - sampleInterval
        updateHistory(currentCar)
    end

    -- Update corner analysis (live tracking)
    corner_analysis.update(currentCar, state.currentLap, state.bestLap, state.trackCorners)

    -- Draw brake markers on track (3D rendering)
    drawBrakeMarkers()

    -- Auto-hide telemetry window when above speed threshold (traces always visible)
    if settings.telemetryAutoHide() then
        ui_utils.updateAutoHide(dt, currentCar.speedKmh, settings.telemetryAutoHideSpeed(), {"telemetry"})
    end
end

-- Drawing helpers using shared ui_utils.drawTrace

-- Wrapper for rolling history traces (handles maxPts windowing)
local function drawTrace(origin, x, y, w, h, data, color, thickness, maxPts, filled)
    if #data < 2 then return end
    thickness = thickness or theme.style.traceThickness
    
    -- For windowed traces, we need to offset the starting X position
    local step = w / (maxPts - 1)
    local start = maxPts - #data
    local offsetX = start * step
    local actualW = (#data - 1) * step
    
    ui_utils.drawTrace(origin.x + x + offsetX, origin.y + y, actualW, h, data, color, {
        thickness = thickness,
        filled = filled,
    })
end

local function drawSpeedTrace(origin, x, y, w, h, data, color, maxSpeed, thickness, maxPts, filled)
    if #data < 2 then return end
    thickness = thickness or theme.style.traceThickness
    
    local step = w / (maxPts - 1)
    local start = maxPts - #data
    local offsetX = start * step
    local actualW = (#data - 1) * step
    
    ui_utils.drawTrace(origin.x + x + offsetX, origin.y + y, actualW, h, data, color, {
        thickness = thickness,
        filled = filled,
        maxVal = maxSpeed,
    })
end

local function drawGearTrace(origin, x, y, w, h, data, color, maxGear, thickness, maxPts, filled)
    if #data < 2 then return end
    thickness = thickness or theme.style.traceThickness
    
    local step = w / (maxPts - 1)
    local start = maxPts - #data
    local offsetX = start * step
    local actualW = (#data - 1) * step
    
    ui_utils.drawGearTrace(origin.x + x + offsetX, origin.y + y, actualW, h, data, color, {
        thickness = thickness,
        filled = filled,
        maxGear = maxGear or 8,
    })
end

-- Draw flag markers as background highlights
local function drawFlagMarkers(origin, x, y, w, h, flags, maxPts)
    if not flags or #flags < 2 then return end
    local step = w / (maxPts - 1)
    local start = maxPts - #flags
    
    -- Any lockup flag (FL, FR, RL, RR)
    local LOCKUP_ANY = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_FR, 
                               lap.FLAGS.LOCKUP_RL, lap.FLAGS.LOCKUP_RR)
    
    for i = 1, #flags do
        local f = flags[i]
        if f > 0 then
            local px = x + (start + i - 1) * step
            local color = nil
            
            -- Priority: lockup > TC > wheel slip > overlap
            if settings.showFlagMarker('Lockup') and bit.band(f, LOCKUP_ANY) > 0 then
                color = theme.flags.lockup
            elseif settings.showFlagMarker('TC') and bit.band(f, lap.FLAGS.TC_ACTIVE) > 0 then
                color = theme.flags.tc
            elseif settings.showFlagMarker('WheelSlip') and bit.band(f, lap.FLAGS.WHEEL_SLIP) > 0 then
                color = theme.flags.wheelSlip
            elseif settings.showFlagMarker('Overlap') and bit.band(f, lap.FLAGS.OVERLAP) > 0 then
                color = theme.flags.overlap
            end
            
            if color then
                ui.drawRectFilled(
                    origin + vec2(px, y),
                    origin + vec2(px + step, y + h),
                    color, 0
                )
            end
        end
    end
end

local function drawGrid(origin, x, y, w, h)
    -- Border
    ui.drawLine(origin + vec2(x, y), origin + vec2(x + w, y), theme.grid.line, 1)
    ui.drawLine(origin + vec2(x + w, y), origin + vec2(x + w, y + h), theme.grid.line, 1)
    ui.drawLine(origin + vec2(x + w, y + h), origin + vec2(x, y + h), theme.grid.line, 1)
    ui.drawLine(origin + vec2(x, y + h), origin + vec2(x, y), theme.grid.line, 1)

    -- Horizontal line at 50%
    local ly = y + h / 2
    ui.drawLine(origin + vec2(x, ly), origin + vec2(x + w, ly), theme.grid.line, 1)
end

local function drawBar(origin, x, y, w, h, val, color)
    -- Black outline around full bar area
    ui.drawRect(origin + vec2(x, y), origin + vec2(x + w, y + h), rgbm(0.05, 0.05, 0.05, 1.0), 0, 2)
    -- Filled bar
    local barH = h * val
    ui.drawRectFilled(origin + vec2(x, y + h - barH), origin + vec2(x + w, y + h), color)
end

local function drawWheel(origin, cx, cy, r, steerDeg, ghostSteerDeg)
    local innerR = r * 0.70
    local center = origin + vec2(cx, cy)
    local arcThickness = r - innerR
    local indicatorR = (innerR + r) / 2
    
    -- Outer ring for reference lap (5% larger radius, half thickness)
    local outerRingR = r * 1.05
    local outerRingThickness = arcThickness * 0.5
    local outerRingInnerR = outerRingR - outerRingThickness
    local outerIndicatorR = (outerRingInnerR + outerRingR) / 2

    -- Draw outer ring background first
    ui.drawCircleFilled(center, outerRingR, theme.wheel.bg, 48)
    ui.drawCircleFilled(center, outerRingInnerR, theme.bg.window, 48)
    
    -- Draw reference/ghost steering in outer ring
    if ghostSteerDeg then
        local ghostAngle = math.rad(ghostSteerDeg)
        ui.pathClear()
        ui.pathArcTo(center, outerIndicatorR, -math.pi/2 + ghostAngle - 0.25, -math.pi/2 + ghostAngle + 0.25, 16)
        ui.pathStroke(theme.wheel.ghost, false, outerRingThickness)

        -- Ghost center line in outer ring
        local ghostInnerX = center.x + math.sin(ghostAngle) * outerRingInnerR
        local ghostInnerY = center.y - math.cos(ghostAngle) * outerRingInnerR
        local ghostOuterX = center.x + math.sin(ghostAngle) * outerRingR
        local ghostOuterY = center.y - math.cos(ghostAngle) * outerRingR
        ui.drawLine(vec2(ghostInnerX, ghostInnerY), vec2(ghostOuterX, ghostOuterY), theme.withAlpha(theme.wheel.ghost, 0.5), 1)
    end

    -- Main wheel ring background (on top of outer ring)
    ui.drawCircleFilled(center, r, theme.wheel.bg, 48)
    ui.drawCircleFilled(center, innerR, theme.bg.window, 48)

    -- Center notch (always visible, subtle gray marker at top/center)
    local notchAngle = 0  -- Top = center/straight
    local notchLen = arcThickness * 0.6
    local notchInner = innerR + (arcThickness - notchLen) / 2
    local notchOuter = notchInner + notchLen
    local notchX1 = center.x + math.sin(notchAngle) * notchInner
    local notchY1 = center.y - math.cos(notchAngle) * notchInner
    local notchX2 = center.x + math.sin(notchAngle) * notchOuter
    local notchY2 = center.y - math.cos(notchAngle) * notchOuter
    ui.drawLine(vec2(notchX1, notchY1), vec2(notchX2, notchY2), theme.wheel.notch, 2)

    -- Current steering indicator (white, half width)
    local angle = math.rad(steerDeg)
    local halfArcThickness = arcThickness * 0.5
    ui.pathClear()
    ui.pathArcTo(center, indicatorR, -math.pi/2 + angle - 0.25, -math.pi/2 + angle + 0.25, 16)
    ui.pathStroke(theme.wheel.indicator, false, halfArcThickness)

    -- Red center line (current position)
    local lineInnerX = center.x + math.sin(angle) * innerR
    local lineInnerY = center.y - math.cos(angle) * innerR
    local lineOuterX = center.x + math.sin(angle) * r
    local lineOuterY = center.y - math.cos(angle) * r
    ui.drawLine(vec2(lineInnerX, lineInnerY), vec2(lineOuterX, lineOuterY), theme.wheel.centerLine, 2)
end

-- Bold font for gear display (defined once, reused)
local gearFont = ui.DWriteFont('Segoe UI'):weight(ui.DWriteFont.Weight.Black)

local function drawGear(origin, cx, cy, r, gear, refGear)
    local text = gear < 0 and "R" or (gear == 0 and "N" or tostring(gear))
    local innerR = r * 0.70
    local center = origin + vec2(cx, cy)
    
    -- Determine color based on comparison with reference gear
    local color = theme.text.primary  -- Default white
    if refGear and gear > 0 and refGear > 0 then
        if gear < refGear then
            color = theme.delta.negative  -- Red: lower gear than ref
        elseif gear > refGear then
            color = theme.delta.positive  -- Green: higher gear than ref
        end
    end
    
    -- Draw gear number with bold font, centered in wheel
    -- Font size scales with wheel radius for consistent look
    local fontSize = math.max(24, r * 0.5)
    ui.pushFont(gearFont)
    ui.dwriteDrawTextClipped(text, fontSize, 
        center - vec2(r * 0.4, r * 0.35),  -- Top-left of text box
        center + vec2(r * 0.4, r * 0.35),  -- Bottom-right of text box
        0.5, 0.5,  -- Center alignment (H, V)
        false, color)
    ui.popFont()
end

local function drawSpeed(origin, cx, y, w, car)
    ui.pushFont(ui.Font.Main)
    ui.setCursor(origin + vec2(cx - w/2, y))
    ui.textAligned(ui_utils.speedDisplay(car.speedKmh), vec2(0.5, 0.5), vec2(w, 20))
    ui.popFont()
end

-- Window toggle buttons
local buttonSize = vec2(26, 26)

local function getWindowName(windowId)
    -- CSP uses format: IMGUI_LUA_<AppName>_<windowId>
    -- AppName is the NAME from manifest.ini (not folder name)
    return "IMGUI_LUA_AC Tracer_" .. windowId
end

local function isWindowVisible(windowId)
    local acc = ac.accessAppWindow(getWindowName(windowId))
    return acc and acc:valid() and acc:visible()
end

local function toggleWindow(windowId)
    ui_utils.toggleWindow(windowId)
end

local function drawToggleButton(localPos, icon, tooltip, windowId)
    local isActive = isWindowVisible(windowId)

    -- Determine colors based on state
    local bg = isActive and theme.bg.buttonActive or theme.bg.button
    local bgHover = isActive and theme.bg.buttonActive or theme.bg.buttonHover
    local fg = isActive and theme.text.secondary or theme.text.muted

    -- Use styled button
    ui.setCursor(localPos)
    ui.pushStyleColor(ui.StyleColor.Button, bg)
    ui.pushStyleColor(ui.StyleColor.ButtonHovered, bgHover)
    ui.pushStyleColor(ui.StyleColor.ButtonActive, theme.bg.buttonActive)
    ui.pushStyleColor(ui.StyleColor.Text, fg)
    ui.pushStyleVar(ui.StyleVar.FrameRounding, 4)

    if ui.button(icon .. "##" .. windowId, buttonSize) then
        ac.log("AC Tracer: Button clicked for " .. windowId)
        toggleWindow(windowId)
    end

    ui.popStyleVar()
    ui.popStyleColor(4)

    if ui.itemHovered() then
        ui.setTooltip(tooltip)
    end
end

local function posToX(pos, positions, x, w)
    if not positions or #positions < 2 then return nil end
    for i = 1, #positions - 1 do
        local p1, p2 = positions[i], positions[i + 1]
        local targetPos = pos
        if p2 < p1 then p2 = p2 + 1 end
        if targetPos < p1 and p1 > 0.5 then targetPos = targetPos + 1 end
        if targetPos >= p1 and targetPos <= p2 then
            local t = (targetPos - p1) / (p2 - p1)
            local step = w / (#positions - 1)
            return x + (i - 1 + t) * step
        end
    end
    return nil
end

-- Layout calculation - separated from rendering for clarity
local function calculateLayout(windowSize)
    local layout = {}
    
    -- Padding and margins
    layout.pad = 15
    layout.btnAreaW = 32  -- Space for toggle buttons on left
    layout.gap = 5        -- Gap between elements
    
    -- Content area (excluding padding and button area)
    layout.contentX = layout.pad + layout.btnAreaW
    layout.contentY = layout.pad
    layout.contentW = windowSize.x - layout.pad * 2 - layout.btnAreaW
    layout.contentH = windowSize.y - layout.pad * 2
    
    -- Proportional sizing based on content height
    local h = layout.contentH
    local w = layout.contentW
    
    -- Right side: wheel and bars (sized proportionally to height)
    layout.wheelR = h * 0.48
    layout.barW = math.max(12, h * 0.08)
    layout.barGap = 5
    layout.elementGap = h * 0.1
    
    -- Calculate positions from right to left
    local cursor = w
    cursor = cursor - layout.wheelR - 2
    layout.wheelCX = cursor
    layout.wheelCY = h * 0.42
    cursor = cursor - layout.wheelR - layout.elementGap
    
    cursor = cursor - layout.barW
    layout.throttleX = cursor
    cursor = cursor - layout.barGap - layout.barW
    layout.brakeX = cursor
    cursor = cursor - layout.elementGap
    
    -- Left side: traces (remaining space)
    layout.traceW = math.max(0, cursor)
    layout.traceH = h
    layout.tracePad = 3
    
    -- Inner trace area (with padding)
    layout.innerX = layout.tracePad
    layout.innerY = layout.tracePad
    layout.innerW = layout.traceW - layout.tracePad * 2
    layout.innerH = h - layout.tracePad * 2
    
    return layout
end

function script.windowMain(dt)
    if not currentCar then
        ui.text("No car data")
        return
    end
    local car = currentCar

    local windowSize = ui.availableSpace()
    ui.drawRectFilled(vec2(0, 0), windowSize, theme.bg.window, 16)

    -- Calculate layout
    local L = calculateLayout(windowSize)
    
    -- Check minimum size
    if L.contentH < 20 or L.contentW < 100 then
        ui.setCursor(vec2(5, 5))
        ui.text(string.format("Window too small: %.0fx%.0f", windowSize.x, windowSize.y))
        return
    end

    local origin = vec2(L.contentX, L.contentY)
    local traceOrigin = origin
    
    if L.traceW > 10 then
        -- Dark background behind trace lines
        ui.drawRectFilled(traceOrigin, traceOrigin + vec2(L.traceW, L.traceH), theme.bg.graph, 4)
        
        -- Use layout for inner dimensions
        local innerX, innerY, innerW, innerH = L.innerX, L.innerY, L.innerW, L.innerH
        
        drawGrid(traceOrigin, innerX, innerY, innerW, innerH)

        -- Start/finish line (checkered flag pattern) - only at position 0
        -- Check if position 0 is within our sampled data range
        local hasZeroCrossing = false
        if history.pos and #history.pos > 1 then
            for i = 1, #history.pos - 1 do
                -- Detect wrap-around from high to low position (crossing 0)
                if history.pos[i] > 0.9 and history.pos[i + 1] < 0.1 then
                    hasZeroCrossing = true
                    break
                end
            end
        end
        
        if hasZeroCrossing then
            local sfX = posToX(0, history.pos, innerX, innerW)
            if sfX then
                local sfW = 5
                local squareSize = 4
                for row = 0, math.floor(innerH / squareSize) do
                    for col = 0, 1 do
                        local isWhite = (row + col) % 2 == 0
                        local color = isWhite and rgbm(1, 1, 1, 0.9) or rgbm(0.1, 0.1, 0.1, 0.9)
                        local px = sfX - sfW / 2 + col * (sfW / 2)
                        local py = innerY + row * squareSize
                        ui.drawRectFilled(
                            traceOrigin + vec2(px, py), 
                            traceOrigin + vec2(px + sfW / 2, math.min(py + squareSize, innerY + innerH)), 
                            color, 0)
                    end
                end
            end
        end

        local ghostTraces = state.getGhostTraces(history.pos)
        local maxSpeed = getMaxSpeed(ghostTraces)
        local maxGear = getMaxGear(ghostTraces)
        local ghostThickness = theme.style.ghostThickness
        local traceThickness = theme.style.traceThickness
        local maxPoints = math.ceil(settings.timeWindow() * settings.sampleRate())
        
        -- Draw flag markers as background highlights (before traces)
        drawFlagMarkers(traceOrigin, innerX, innerY, innerW, innerH, history.flags, maxPoints)
        
        -- Ghost traces (reference) - drawn first so current traces render on top
        -- Uses filled=true to draw area under line (30% more transparent)
        if ghostTraces and #ghostTraces.throttle == #history.throttle then
            if settings.displaySpeed() and ghostTraces.speed then drawSpeedTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.speed, theme.ghost.speed, maxSpeed, ghostThickness, maxPoints, true) end
            if settings.displayGear() and ghostTraces.gear then drawGearTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.gear, theme.ghost.gear, maxGear, ghostThickness, maxPoints, true) end
            if settings.displaySteering() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.steering, theme.ghost.steering, ghostThickness, maxPoints, true) end
            if settings.displayClutch() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.clutch, theme.ghost.clutch, ghostThickness, maxPoints, true) end
            -- Draw throttle before brake for both ref and current
            if settings.displayThrottle() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.throttle, theme.ghost.throttle, ghostThickness, maxPoints, true) end
            if settings.displayBrake() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.brake, theme.ghost.brake, ghostThickness, maxPoints, true) end
        end

        -- Current traces - drawn on top of ghost traces
        -- Draw throttle before brake so brake renders on top
        if settings.displaySpeed() then drawSpeedTrace(traceOrigin, innerX, innerY, innerW, innerH, history.speed, theme.trace.speed, maxSpeed, traceThickness, maxPoints) end
        if settings.displayGear() then drawGearTrace(traceOrigin, innerX, innerY, innerW, innerH, history.gear, theme.trace.gear, maxGear, traceThickness, maxPoints) end
        if settings.displaySteering() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.steering, theme.trace.steering, traceThickness, maxPoints) end
        if settings.displayClutch() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.clutch, theme.trace.clutch, traceThickness, maxPoints) end
        if settings.displayThrottle() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.throttle, theme.trace.throttle, traceThickness, maxPoints) end
        if settings.displayBrake() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.brake, theme.trace.brake, traceThickness, maxPoints) end
    end

    -- Use extended brake pressure for the brake bar
    drawBar(origin, L.brakeX, 0, L.barW, L.contentH, extended_brake.getNormalizedBrake(car), theme.trace.brake)
    drawBar(origin, L.throttleX, 0, L.barW, L.contentH, car.gas, theme.trace.throttle)

    drawWheel(origin, L.wheelCX, L.wheelCY, L.wheelR, car.steer, state.getGhostSteering())
    drawGear(origin, L.wheelCX, L.wheelCY, L.wheelR, car.gear, state.getGhostGear())
    drawSpeed(origin, L.wheelCX, L.wheelCY + L.wheelR + 2, L.wheelR * 2, car)

    -- Toggle window buttons (left side, vertically stacked next to trace area)
    local numButtons = 3
    local btnSpacing = 4
    local totalBtnHeight = numButtons * buttonSize.y + (numButtons - 1) * btnSpacing
    local btnLocalX = (L.pad + L.btnAreaW - buttonSize.x) / 2  -- Center in button area
    local btnLocalY = L.pad + (L.contentH - totalBtnHeight) / 2  -- Vertically center

    drawToggleButton(vec2(btnLocalX, btnLocalY), "📊", "Lap Telemetry", "telemetry")
    drawToggleButton(vec2(btnLocalX, btnLocalY + buttonSize.y + btnSpacing), "Δ", "Delta Bar", "delta")
    drawToggleButton(vec2(btnLocalX, btnLocalY + (buttonSize.y + btnSpacing) * 2), "◎", "Reference Lap", "referencelap")
end

function script.windowSettings(dt)
    settings.windowSettings()
end

function script.windowCorners(dt)
    -- corner_analysis.update() handles corner tracking internally
    corner_analysis.draw(dt, state.currentLap, state.bestLap, state.trackCorners)
end

function script.windowTelemetry(dt)
    lap_telemetry.draw(dt, state)
end

function script.windowReferenceLap(dt)
    -- Reference lap picker only shows R button (no C button)
    lap_picker.showCurrentButton = false
    lap_picker.draw(dt)
end

function script.windowDelta(dt)
    delta_bar.draw(dt, state.currentLap, state.bestLap, state.trackPosition, state.trackCorners)
end
