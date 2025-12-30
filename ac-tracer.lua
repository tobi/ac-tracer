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

-- Prune trace history to a specific position (for rewind support)
local function pruneHistoryToPosition(targetPos)
    if not history.pos or #history.pos == 0 then return 0 end
    
    -- Find the last sample at or before targetPos
    -- Handle wrap-around: if we're at 0.95 and history has 0.01, 0.02..., prune all
    local pruneIdx = nil
    local n = #history.pos
    
    -- Check if history wraps around
    local hasWrapAround = false
    local wrapIdx = nil
    for i = 1, n - 1 do
        if history.pos[i] > 0.9 and history.pos[i + 1] < 0.1 then
            hasWrapAround = true
            wrapIdx = i
            break
        end
    end
    
    if hasWrapAround and wrapIdx then
        if targetPos > 0.5 then
            -- Target before wrap
            for i = wrapIdx, 1, -1 do
                if history.pos[i] <= targetPos then
                    pruneIdx = i
                    break
                end
            end
        else
            -- Target after wrap
            for i = n, wrapIdx + 1, -1 do
                if history.pos[i] <= targetPos then
                    pruneIdx = i
                    break
                end
            end
            if not pruneIdx then
                pruneIdx = wrapIdx
            end
        end
    else
        -- Simple case: no wrap-around
        for i = n, 1, -1 do
            if history.pos[i] <= targetPos then
                pruneIdx = i
                break
            end
        end
    end
    
    if not pruneIdx then
        -- Clear everything
        pruneIdx = 0
    end
    
    local originalLength = n
    local samplesToRemove = originalLength - pruneIdx
    
    if samplesToRemove <= 0 then return 0 end
    
    -- Prune all arrays
    local arrays = {'throttle', 'brake', 'clutch', 'steering', 'speed', 'gear', 'pos', 'flags'}
    for _, field in ipairs(arrays) do
        if history[field] then
            for i = originalLength, pruneIdx + 1, -1 do
                history[field][i] = nil
            end
        end
    end
    
    return samplesToRemove
end

-- Register rewind callbacks with state module
state.onRewind(function(targetPos, pruned)
    -- Reset delta bar smoothing
    delta_bar.reset()
    
    -- Reset corner analysis live state
    corner_analysis.reset()
    
    -- Prune trace history
    local historyPruned = pruneHistoryToPosition(targetPos)
    
    -- Reset overlap tracking for trace display
    overlapStartTime = nil
    
    ac.log(string.format("AC Tracer: Rewind callback - pruned %d history samples to pos %.3f", 
        historyPruned, targetPos))
end)

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

    -- Auto-hide telemetry window when above speed threshold (traces always visible)
    if settings.telemetryAutoHide() then
        ui_utils.updateAutoHide(dt, currentCar.speedKmh, settings.telemetryAutoHideSpeed(), {"telemetry"})
    end
end

-- Drawing helpers
local function drawTrace(origin, x, y, w, h, data, color, thickness, maxPts)
    if #data < 2 then return end
    thickness = thickness or theme.style.traceThickness
    local step = w / (maxPts - 1)
    local start = maxPts - #data
    ui.pathClear()
    for i = 1, #data do
        ui.pathLineTo(origin + vec2(x + (start + i - 1) * step, y + h - data[i] * h))
    end
    ui.pathStroke(color, false, thickness)
end

local function drawSpeedTrace(origin, x, y, w, h, data, color, maxSpeed, thickness, maxPts)
    if #data < 2 then return end
    thickness = thickness or theme.style.traceThickness
    local step = w / (maxPts - 1)
    local start = maxPts - #data
    ui.pathClear()
    for i = 1, #data do
        local normalized = math.clamp(data[i] / maxSpeed, 0, 1)
        ui.pathLineTo(origin + vec2(x + (start + i - 1) * step, y + h - normalized * h))
    end
    ui.pathStroke(color, false, thickness)
end

-- Draw gear trace as stepped line (gear is discrete, not continuous)
-- Normalizes gear to 0-1 where 0=neutral/reverse, maxGear=1.0
local function drawGearTrace(origin, x, y, w, h, data, color, maxGear, thickness, maxPts)
    if #data < 2 then return end
    thickness = thickness or theme.style.traceThickness
    maxGear = maxGear or 8
    local step = w / (maxPts - 1)
    local start = maxPts - #data
    
    -- Draw as horizontal segments (stepped) since gear is discrete
    local prevGear = nil
    local prevX = nil
    for i = 1, #data do
        local gear = data[i]
        -- Normalize: 0 and negative (neutral/reverse) = 0, positive gears scale to maxGear
        local normalized = gear > 0 and math.clamp(gear / maxGear, 0, 1) or 0
        local px = x + (start + i - 1) * step
        local py = y + h - normalized * h
        
        if prevGear ~= nil then
            local prevNorm = prevGear > 0 and math.clamp(prevGear / maxGear, 0, 1) or 0
            local prevY = y + h - prevNorm * h
            
            -- Horizontal line at previous gear level to current x
            ui.drawLine(origin + vec2(prevX, prevY), origin + vec2(px, prevY), color, thickness)
            -- Vertical line to new gear level (if changed)
            if gear ~= prevGear then
                ui.drawLine(origin + vec2(px, prevY), origin + vec2(px, py), color, thickness)
            end
        end
        
        prevGear = gear
        prevX = px
    end
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

    -- Background wheel ring
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

    -- Ghost steering (more visible)
    if ghostSteerDeg then
        local ghostAngle = math.rad(ghostSteerDeg)
        ui.pathClear()
        ui.pathArcTo(center, indicatorR, -math.pi/2 + ghostAngle - 0.25, -math.pi/2 + ghostAngle + 0.25, 16)
        ui.pathStroke(theme.wheel.ghost, false, arcThickness * 0.7)

        -- Ghost center line
        local ghostInnerX = center.x + math.sin(ghostAngle) * innerR
        local ghostInnerY = center.y - math.cos(ghostAngle) * innerR
        local ghostOuterX = center.x + math.sin(ghostAngle) * r
        local ghostOuterY = center.y - math.cos(ghostAngle) * r
        ui.drawLine(vec2(ghostInnerX, ghostInnerY), vec2(ghostOuterX, ghostOuterY), theme.withAlpha(theme.wheel.ghost, 0.5), 2)
    end

    -- Current steering indicator
    local angle = math.rad(steerDeg)
    ui.pathClear()
    ui.pathArcTo(center, indicatorR, -math.pi/2 + angle - 0.25, -math.pi/2 + angle + 0.25, 16)
    ui.pathStroke(theme.wheel.indicator, false, arcThickness)

    -- Red center line (current position)
    local lineInnerX = center.x + math.sin(angle) * innerR
    local lineInnerY = center.y - math.cos(angle) * innerR
    local lineOuterX = center.x + math.sin(angle) * r
    local lineOuterY = center.y - math.cos(angle) * r
    ui.drawLine(vec2(lineInnerX, lineInnerY), vec2(lineOuterX, lineOuterY), theme.wheel.centerLine, 2)
end

local function drawGear(origin, cx, cy, r, gear)
    local text = gear < 0 and "R" or (gear == 0 and "N" or tostring(gear))
    local innerR = r * 0.70
    local center = origin + vec2(cx, cy)
    -- Draw gear number larger, centered in wheel
    ui.pushFont(ui.Font.Title)
    local textSize = ui.measureText(text)
    ui.setCursor(center - textSize / 2)
    ui.text(text)
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

        -- Draw corner zones (faint gray with white borders, labels scroll with zone)
        local corners = state.trackCorners
        local currentPos = car.splinePosition
        
        if corners and #corners > 0 and history.pos and #history.pos > 1 then
            local minPos = history.pos[1]
            local maxPos = history.pos[#history.pos]
            
            -- Handle wrap-around: if maxPos < minPos, we've crossed start/finish
            local wrapsAround = maxPos < minPos
            
            for _, c in ipairs(corners) do
                if c.startPos and c.endPos then
                    -- Determine if corner is visible (even partially)
                    local cornerVisible = false
                    local drawStartX, drawEndX = nil, nil
                    
                    -- Get actual X positions
                    local cStartX = posToX(c.startPos, history.pos, innerX, innerW)
                    local cEndX = posToX(c.endPos, history.pos, innerX, innerW)
                    
                    -- Check visibility and compute draw bounds
                    if cStartX and cEndX then
                        -- Both edges visible
                        drawStartX, drawEndX = cStartX, cEndX
                        cornerVisible = true
                    elseif cStartX and not cEndX then
                        -- Start visible, end off-screen (corner extends past right edge)
                        drawStartX = cStartX
                        drawEndX = innerX + innerW
                        cornerVisible = true
                    elseif not cStartX and cEndX then
                        -- End visible, start off-screen (corner started before left edge)
                        drawStartX = innerX
                        drawEndX = cEndX
                        cornerVisible = true
                    else
                        -- Neither edge visible - check if corner spans entire view
                        local cornerSpansView = false
                        if not wrapsAround then
                            -- Normal case: corner wraps around or spans view
                            if c.endPos < c.startPos then
                                -- Corner wraps around start/finish
                                cornerSpansView = (minPos <= c.endPos) or (maxPos >= c.startPos)
                            else
                                -- Normal corner: check if it contains our view range
                                cornerSpansView = (c.startPos <= minPos and c.endPos >= maxPos)
                            end
                        end
                        if cornerSpansView then
                            drawStartX = innerX
                            drawEndX = innerX + innerW
                            cornerVisible = true
                        end
                    end
                    
                    if cornerVisible and drawStartX and drawEndX and drawEndX > drawStartX then
                        -- Check if we're in this corner
                        local inCorner = false
                        if c.endPos >= c.startPos then
                            inCorner = currentPos >= c.startPos and currentPos <= c.endPos
                        else
                            inCorner = currentPos >= c.startPos or currentPos <= c.endPos
                        end
                        
                        local zoneTop = traceOrigin + vec2(drawStartX, innerY)
                        local zoneBottom = traceOrigin + vec2(drawEndX, innerY + innerH)
                        
                        -- Draw zone fill - faint gray (0.05 alpha)
                        ui.drawRectFilled(zoneTop, zoneBottom, rgbm(0.5, 0.5, 0.5, 0.05), 0)
                        
                        -- Draw zone border - white (slightly more visible when active)
                        local borderAlpha = inCorner and 0.2 or 0.08
                        ui.drawRect(zoneTop, zoneBottom, rgbm(1, 1, 1, borderAlpha), 0, 1)
                        
                        -- Corner name - clips to zone, scrolls with it
                        if c.name then
                            local labelPadX = 4
                            local labelPadY = 2
                            local zoneWidth = drawEndX - drawStartX
                            
                            -- Only draw label if zone is wide enough (at least 20px)
                            if zoneWidth > 20 then
                                -- Calculate label position relative to corner start
                                -- If corner start is off-screen left, offset the label
                                local labelOffsetX = 0
                                if not cStartX then
                                    -- Corner starts before view - calculate how much is clipped
                                    -- Label should appear at left edge initially, then scroll left
                                    labelOffsetX = 0  -- Start at left edge of visible zone
                                end
                                
                                local labelX = drawStartX + labelPadX + labelOffsetX
                                local labelY = innerY + labelPadY
                                
                                -- Use clipping to keep label inside zone
                                ui.pushClipRect(zoneTop, zoneBottom, true)
                                ui.pushFont(ui.Font.Small)
                                ui.setCursor(traceOrigin + vec2(labelX, labelY))
                                local textAlpha = inCorner and 0.6 or 0.25
                                ui.pushStyleColor(ui.StyleColor.Text, rgbm(1, 1, 1, textAlpha))
                                ui.text(c.name)
                                ui.popStyleColor()
                                ui.popFont()
                                ui.popClipRect()
                            end
                        end
                    end
                end
            end
        end

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
        if ghostTraces and #ghostTraces.throttle == #history.throttle then
            if settings.displaySpeed() and ghostTraces.speed then drawSpeedTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.speed, theme.ghost.speed, maxSpeed, ghostThickness, maxPoints) end
            if settings.displayGear() and ghostTraces.gear then drawGearTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.gear, theme.ghost.gear, maxGear, ghostThickness, maxPoints) end
            if settings.displaySteering() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.steering, theme.ghost.steering, ghostThickness, maxPoints) end
            if settings.displayClutch() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.clutch, theme.ghost.clutch, ghostThickness, maxPoints) end
            if settings.displayThrottle() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.throttle, theme.ghost.throttle, ghostThickness, maxPoints) end
            if settings.displayBrake() then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.brake, theme.ghost.brake, ghostThickness, maxPoints) end
        end

        -- Current traces - drawn on top of ghost traces
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
    drawGear(origin, L.wheelCX, L.wheelCY, L.wheelR, car.gear)
    drawSpeed(origin, L.wheelCX, L.wheelCY + L.wheelR + 2, L.wheelR * 2, car)

    -- Toggle window buttons (left side, vertically stacked next to trace area)
    local numButtons = 4
    local btnSpacing = 4
    local totalBtnHeight = numButtons * buttonSize.y + (numButtons - 1) * btnSpacing
    local btnLocalX = (L.pad + L.btnAreaW - buttonSize.x) / 2  -- Center in button area
    local btnLocalY = L.pad + (L.contentH - totalBtnHeight) / 2  -- Vertically center

    drawToggleButton(vec2(btnLocalX, btnLocalY), "⚡", "Corner Analysis", "corners")
    drawToggleButton(vec2(btnLocalX, btnLocalY + buttonSize.y + btnSpacing), "📊", "Lap Telemetry", "telemetry")
    drawToggleButton(vec2(btnLocalX, btnLocalY + (buttonSize.y + btnSpacing) * 2), "Δ", "Delta Bar", "delta")
    drawToggleButton(vec2(btnLocalX, btnLocalY + (buttonSize.y + btnSpacing) * 3), "◎", "Reference Lap", "referencelap")
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
    delta_bar.draw(dt, state.currentLap, state.bestLap, state.trackPosition)
end
