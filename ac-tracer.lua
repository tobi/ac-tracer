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

-- Display settings
local display = settings.display or {
    throttle = true,
    brake = true,
    clutch = false,
    steering = false,
    speed = false,
}


-- History for trace display (rolling window)
local maxPoints = math.ceil(settings.timeWindow * settings.sampleRate)
local history = { throttle = {}, brake = {}, clutch = {}, steering = {}, speed = {}, pos = {} }
local updateTimer = 0

-- Current car reference (updated once per frame in script.update)
local currentCar = nil

local function updateHistory(car)
    table.insert(history.throttle, car.gas)
    -- Use extended brake pressure if available, otherwise fall back to pedal position
    table.insert(history.brake, extended_brake.getNormalizedBrake(car))
    table.insert(history.clutch, 1 - car.clutch)
    local s = lap.normalizeSteer(car.steer)
    table.insert(history.steering, s)
    table.insert(history.speed, car.speedKmh)
    table.insert(history.pos, car.splinePosition)

    if #history.throttle > maxPoints then
        table.remove(history.throttle, 1)
        table.remove(history.brake, 1)
        table.remove(history.clutch, 1)
        table.remove(history.steering, 1)
        table.remove(history.speed, 1)
        table.remove(history.pos, 1)
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
    if updateTimer >= 1 / settings.sampleRate then
        updateTimer = updateTimer - 1 / settings.sampleRate
        updateHistory(currentCar)
    end

    -- Update corner analysis (live tracking)
    corner_analysis.update(currentCar)

    -- Auto-hide telemetry window when above speed threshold (traces always visible)
    if settings.telemetryAutoHide then
        ui_utils.updateAutoHide(dt, currentCar.speedKmh, settings.telemetryAutoHideSpeed, {"telemetry"})
    end
end

-- Drawing helpers
local function drawTrace(origin, x, y, w, h, data, color)
    if #data < 2 then return end
    local step = w / (maxPoints - 1)
    local start = maxPoints - #data
    ui.pathClear()
    for i = 1, #data do
        ui.pathLineTo(origin + vec2(x + (start + i - 1) * step, y + h - data[i] * h))
    end
    ui.pathStroke(color, false, settings.thickness)
end

local function drawSpeedTrace(origin, x, y, w, h, data, color, maxSpeed)
    if #data < 2 then return end
    local step = w / (maxPoints - 1)
    local start = maxPoints - #data
    ui.pathClear()
    for i = 1, #data do
        local normalized = math.clamp(data[i] / maxSpeed, 0, 1)
        ui.pathLineTo(origin + vec2(x + (start + i - 1) * step, y + h - normalized * h))
    end
    ui.pathStroke(color, false, settings.thickness)
end

local function drawGrid(origin, x, y, w, h, positions, trackLength)
    -- Border
    ui.drawLine(origin + vec2(x, y), origin + vec2(x + w, y), theme.grid.line, 1)
    ui.drawLine(origin + vec2(x + w, y), origin + vec2(x + w, y + h), theme.grid.line, 1)
    ui.drawLine(origin + vec2(x + w, y + h), origin + vec2(x, y + h), theme.grid.line, 1)
    ui.drawLine(origin + vec2(x, y + h), origin + vec2(x, y), theme.grid.line, 1)

    -- Horizontal line at 50%
    local ly = y + h / 2
    ui.drawLine(origin + vec2(x, ly), origin + vec2(x + w, ly), theme.grid.line, 1)
    
    -- 50m vertical markers
    if positions and #positions >= 2 and trackLength and trackLength > 0 then
        local startPos = positions[1]
        local endPos = positions[#positions]
        local startM = startPos * trackLength
        local endM = endPos * trackLength
        
        -- Handle wrap-around (crossing start/finish)
        if endM < startM then endM = endM + trackLength end
        
        -- Find first 50m mark after start
        local firstMark = math.ceil(startM / 50) * 50
        local markerColor = rgbm(0.3, 0.3, 0.3, 0.4)
        
        for m = firstMark, endM, 50 do
            local actualM = m % trackLength
            local markerPos = actualM / trackLength
            
            -- Find X position for this marker
            for i = 1, #positions - 1 do
                local p1, p2 = positions[i], positions[i + 1]
                local checkPos = markerPos
                
                -- Handle wrap-around
                if p2 < p1 then p2 = p2 + 1 end
                if checkPos < p1 and p1 > 0.5 then checkPos = checkPos + 1 end
                
                if checkPos >= p1 and checkPos <= p2 then
                    local t = (checkPos - p1) / (p2 - p1)
                    local step = w / (#positions - 1)
                    local lx = x + (i - 1 + t) * step
                    ui.drawLine(origin + vec2(lx, y), origin + vec2(lx, y + h), markerColor, 1)
                    break
                end
            end
        end
    end
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
    local speed = settings.useKMH and car.speedKmh or car.speedMph
    local unit = settings.useKMH and " km/h" or " mph"
    ui.pushFont(ui.Font.Main)
    ui.setCursor(origin + vec2(cx - w/2, y))
    ui.textAligned(string.format("%.0f%s", speed, unit), vec2(0.5, 0.5), vec2(w, 20))
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

function script.windowMain(dt)
    if not currentCar then
        ui.text("No car data")
        return
    end
    local car = currentCar

    local windowSize = ui.availableSpace()
    
    -- Use local coordinates (0,0 = top-left of window content)
    local windowOrigin = vec2(0, 0)
    
    ui.drawRectFilled(windowOrigin, windowOrigin + windowSize, theme.bg.window, 16)

    local pad = 15
    local btnAreaW = 32  -- Space for toggle buttons on left
    local origin = vec2(pad + btnAreaW, pad)
    local w = windowSize.x - pad * 2 - btnAreaW
    local h = windowSize.y - pad * 2
    
    -- Debug: show dimensions if too small
    if h < 20 or w < 100 then
        ui.setCursor(vec2(5, 5))
        ui.text(string.format("Window too small: %.0fx%.0f", windowSize.x, windowSize.y))
        return
    end

    local wheelR = h * 0.48
    local wheelW = wheelR * 2
    local barW = h * 0.08
    local barGap = 5
    local gap = h * 0.1

    local cursor = w
    cursor = cursor - wheelR - 2
    local wheelCX = cursor
    local wheelCY = h * 0.42
    cursor = cursor - wheelR - gap

    local barH = h 
    local barY = 0
    cursor = cursor - barW
    local throttleX = cursor
    cursor = cursor - barGap - barW
    local brakeX = cursor
    cursor = cursor - gap

    local traceW = math.max(0, cursor)
    local tracePad = 3  -- Padding inside trace background
    
    local traceOrigin = origin

    local trackLength = ac.getSim().trackLengthM
    if traceW > 10 then
        -- Dark background behind trace lines
        ui.drawRectFilled(traceOrigin, traceOrigin + vec2(traceW, h), rgbm(0.05, 0.05, 0.05, 0.95), 4)
        
        -- Inner dimensions for traces (with padding)
        local innerX = tracePad
        local innerY = tracePad
        local innerW = traceW - tracePad * 2
        local innerH = h - tracePad * 2
        
        drawGrid(traceOrigin, innerX, innerY, innerW, innerH, history.pos, trackLength)

        -- Draw corner zones (very faint, with partial corner support)
        local corners = state.trackCorners
        local currentPos = car.splinePosition
        
        if corners and #corners > 0 then
            -- Get position range from history
            local minPos, maxPos = nil, nil
            if history.pos and #history.pos > 1 then
                minPos = history.pos[1]
                maxPos = history.pos[#history.pos]
            end
            
            for _, c in ipairs(corners) do
                if c.startPos and c.endPos then
                    -- Try to get X positions (may be nil if outside visible range)
                    local cStartX = posToX(c.startPos, history.pos, innerX, innerW)
                    local cEndX = posToX(c.endPos, history.pos, innerX, innerW)
                    
                    -- Handle partial corners (clamp to visible area)
                    local drawStartX = cStartX
                    local drawEndX = cEndX
                    
                    if minPos and maxPos then
                        -- If start is before visible range, clamp to left edge
                        if not cStartX and c.startPos < minPos then
                            drawStartX = innerX
                        end
                        -- If end is after visible range, clamp to right edge
                        if not cEndX and c.endPos > maxPos then
                            drawEndX = innerX + innerW
                        end
                    end
                    
                    -- Check if we're in this corner
                    local inCorner = false
                    if c.endPos >= c.startPos then
                        inCorner = currentPos >= c.startPos and currentPos <= c.endPos
                    else
                        inCorner = currentPos >= c.startPos or currentPos <= c.endPos
                    end
                    
                    -- Draw if we have at least one valid edge
                    if drawStartX and drawEndX then
                        if inCorner then
                            -- Active corner: slightly brighter with border
                            ui.drawRectFilled(
                                traceOrigin + vec2(drawStartX, innerY), 
                                traceOrigin + vec2(drawEndX, innerY + innerH), 
                                rgbm(0.3, 0.3, 0.4, 0.06), 0)
                            ui.drawRect(
                                traceOrigin + vec2(drawStartX, innerY), 
                                traceOrigin + vec2(drawEndX, innerY + innerH), 
                                rgbm(1, 1, 1, 0.15), 1)
                        else
                            -- Inactive corner: very faint dark fill
                            ui.drawRectFilled(
                                traceOrigin + vec2(drawStartX, innerY), 
                                traceOrigin + vec2(drawEndX, innerY + innerH), 
                                rgbm(0.15, 0.15, 0.2, 0.01), 0)
                        end
                        
                        -- Corner name in top left (for all visible corners)
                        if c.name then
                            ui.pushFont(ui.Font.Small)
                            ui.setCursor(traceOrigin + vec2(drawStartX + 3, innerY + 2))
                            ui.pushStyleColor(ui.StyleColor.Text, inCorner and rgbm(1, 1, 1, 0.7) or rgbm(1, 1, 1, 0.25))
                            ui.text(c.name)
                            ui.popStyleColor()
                            ui.popFont()
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
        
        -- Ghost traces (reference) - use inner dimensions with padding
        if ghostTraces and #ghostTraces.throttle == #history.throttle then
            if display.speed and ghostTraces.speed then drawSpeedTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.speed, theme.ghost.speed, maxSpeed) end
            if display.steering then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.steering, theme.ghost.steering) end
            if display.clutch then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.clutch, theme.ghost.clutch) end
            if display.throttle then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.throttle, theme.ghost.throttle) end
            if display.brake then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, ghostTraces.brake, theme.ghost.brake) end
        end

        -- Current traces - use inner dimensions with padding
        if display.speed then drawSpeedTrace(traceOrigin, innerX, innerY, innerW, innerH, history.speed, theme.trace.speed, maxSpeed) end
        if display.steering then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.steering, theme.trace.steering) end
        if display.clutch then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.clutch, theme.trace.clutch) end
        if display.throttle then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.throttle, theme.trace.throttle) end
        if display.brake then drawTrace(traceOrigin, innerX, innerY, innerW, innerH, history.brake, theme.trace.brake) end
    end

    -- Use extended brake pressure for the brake bar
    drawBar(origin, brakeX, barY, barW, barH, extended_brake.getNormalizedBrake(car), theme.trace.brake)
    drawBar(origin, throttleX, barY, barW, barH, car.gas, theme.trace.throttle)

    drawWheel(origin, wheelCX, wheelCY, wheelR, car.steer, state.getGhostSteering())
    drawGear(origin, wheelCX, wheelCY, wheelR, car.gear)
    drawSpeed(origin, wheelCX, wheelCY + wheelR + 2, wheelW, car)

    -- Toggle window buttons (left side, vertically stacked next to trace area)
    -- Position buttons to fit within the trace area height
    local numButtons = 4
    local btnSpacing = 4
    local totalBtnHeight = numButtons * buttonSize.y + (numButtons - 1) * btnSpacing
    local btnLocalX = (pad + btnAreaW - buttonSize.x) / 2  -- Center in button area
    local btnLocalY = pad + (h - totalBtnHeight) / 2  -- Vertically center relative to trace area

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
    corner_analysis.draw(dt, settings.useKMH)
end

function script.windowTelemetry(dt)
    lap_telemetry.draw(dt)
end

function script.windowReferenceLap(dt)
    -- Reference lap picker only shows R button (no C button)
    lap_picker.showCurrentButton = false
    lap_picker.draw(dt)
end

function script.windowDelta(dt)
    delta_bar.draw(dt)
end