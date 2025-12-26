-- Traces (Lua) - CSP high-performance port
-- Main script using centralized state architecture

local state = require('state')
local lap = require('lap')
local settings = require('app_settings')
local corner = require('corner')
local corner_analysis = require('corner_analysis')
local lap_telemetry = require('lap_telemetry')

-- Local aliases
local colors = settings.colors
local display = settings.display

-- Hotkeys
local resetButton = ac.ControlButton('__APP_TRACES_RESET_BEST')
local recordCornerButton = ac.ControlButton('__APP_TRACES_RECORD_CORNER')

-- History for trace display (rolling window)
local maxPoints = math.ceil(settings.timeWindow * settings.sampleRate)
local history = { throttle = {}, brake = {}, clutch = {}, steering = {}, speed = {}, pos = {} }
local updateTimer = 0

local function updateHistory(car)
    table.insert(history.throttle, car.gas)
    table.insert(history.brake, car.brake)
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
    local car = ac.getCar(0)
    if not car then return end
    
    if not ac.getSim().isPaused then
        -- Update centralized state (handles lap recording, completion, best lap)
        state.update(dt, car)
        
        -- Update history for trace display
        updateTimer = updateTimer + dt
        if updateTimer >= 1 / settings.sampleRate then
            updateTimer = updateTimer - 1 / settings.sampleRate
            updateHistory(car)
        end
        
        -- Update corner analysis (live tracking)
        corner_analysis.update(car)
        
        -- Handle corner recording button
        corner.handleRecordButton(car, recordCornerButton)
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
    -- Border only (removed cluttered 50m vertical lines)
    ui.drawLine(origin + vec2(x, y), origin + vec2(x + w, y), colors.grid, 1)
    ui.drawLine(origin + vec2(x + w, y), origin + vec2(x + w, y + h), colors.grid, 1)
    ui.drawLine(origin + vec2(x + w, y + h), origin + vec2(x, y + h), colors.grid, 1)
    ui.drawLine(origin + vec2(x, y + h), origin + vec2(x, y), colors.grid, 1)

    -- Horizontal lines at 50% only (cleaner)
    local ly = y + h / 2
    ui.drawLine(origin + vec2(x, ly), origin + vec2(x + w, ly), colors.grid, 1)
end

local function drawBar(origin, x, y, w, h, val, color)
    local barH = h * val
    ui.drawRectFilled(origin + vec2(x, y + h - barH), origin + vec2(x + w, y + h), color)
end

local function drawWheel(origin, cx, cy, r, steerDeg, ghostSteerDeg)
    local innerR = r * 0.70
    local center = origin + vec2(cx, cy)
    local arcThickness = r - innerR
    local indicatorR = (innerR + r) / 2
    
    -- Background wheel ring
    ui.drawCircleFilled(center, r, colors.wheelBg, 48)
    ui.drawCircleFilled(center, innerR, colors.background, 48)
    
    -- Center notch (always visible, subtle gray marker at top/center)
    local notchAngle = 0  -- Top = center/straight
    local notchLen = arcThickness * 0.6
    local notchInner = innerR + (arcThickness - notchLen) / 2
    local notchOuter = notchInner + notchLen
    local notchX1 = center.x + math.sin(notchAngle) * notchInner
    local notchY1 = center.y - math.cos(notchAngle) * notchInner
    local notchX2 = center.x + math.sin(notchAngle) * notchOuter
    local notchY2 = center.y - math.cos(notchAngle) * notchOuter
    ui.drawLine(vec2(notchX1, notchY1), vec2(notchX2, notchY2), rgbm(0.5, 0.5, 0.5, 0.6), 2)

    -- Ghost steering (more visible)
    if ghostSteerDeg then
        local ghostAngle = math.rad(ghostSteerDeg)
        ui.pathClear()
        ui.pathArcTo(center, indicatorR, -math.pi/2 + ghostAngle - 0.25, -math.pi/2 + ghostAngle + 0.25, 16)
        ui.pathStroke(rgbm(0.6, 0.6, 0.6, 0.7), false, arcThickness * 0.7)
        
        -- Ghost center line
        local ghostInnerX = center.x + math.sin(ghostAngle) * innerR
        local ghostInnerY = center.y - math.cos(ghostAngle) * innerR
        local ghostOuterX = center.x + math.sin(ghostAngle) * r
        local ghostOuterY = center.y - math.cos(ghostAngle) * r
        ui.drawLine(vec2(ghostInnerX, ghostInnerY), vec2(ghostOuterX, ghostOuterY), rgbm(0.5, 0.5, 0.5, 0.5), 2)
    end

    -- Current steering indicator
    local angle = math.rad(steerDeg)
    ui.pathClear()
    ui.pathArcTo(center, indicatorR, -math.pi/2 + angle - 0.25, -math.pi/2 + angle + 0.25, 16)
    ui.pathStroke(colors.wheelIndicator, false, arcThickness)
    
    -- Red center line (current position)
    local lineInnerX = center.x + math.sin(angle) * innerR
    local lineInnerY = center.y - math.cos(angle) * innerR
    local lineOuterX = center.x + math.sin(angle) * r
    local lineOuterY = center.y - math.cos(angle) * r
    ui.drawLine(vec2(lineInnerX, lineInnerY), vec2(lineOuterX, lineOuterY), rgbm(1, 0.2, 0.2, 1), 2)
end

local function drawGear(origin, cx, cy, r, gear)
    local text = gear < 0 and "R" or (gear == 0 and "N" or tostring(gear))
    local innerR = r * 0.70
    local center = origin + vec2(cx, cy)
    -- Draw gear number larger, centered in wheel
    ui.pushFont(ui.Font.Huge)
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
    local car = ac.getCar(0)
    if not car then return end

    if resetButton:pressed() then
        state.resetBestLap()
    end

    local windowOrigin = ui.getCursor()
    local windowSize = ui.availableSpace()

    ui.drawRectFilled(windowOrigin, windowSize, colors.background, 16)

    local pad = 15
    local origin = windowOrigin + vec2(pad, pad)
    local w = windowSize.x - pad * 2
    local h = windowSize.y - pad * 2

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
    
    local traceOrigin = origin

    local trackLength = ac.getSim().trackLengthM
    if traceW > 10 then
        drawGrid(traceOrigin, 0, 0, traceW, h, history.pos, trackLength)

        -- Draw corner zones (very faint, with partial corner support)
        local corners = state.trackCorners
        local currentPos = car.splinePosition
        local currentCornerName = nil
        local currentCornerStartX = nil
        local currentCornerEndX = nil
        
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
                    local cStartX = posToX(c.startPos, history.pos, 0, traceW)
                    local cEndX = posToX(c.endPos, history.pos, 0, traceW)
                    
                    -- Handle partial corners (clamp to visible area)
                    local drawStartX = cStartX
                    local drawEndX = cEndX
                    
                    if minPos and maxPos then
                        -- If start is before visible range, clamp to left edge
                        if not cStartX and c.startPos < minPos then
                            drawStartX = 0
                        end
                        -- If end is after visible range, clamp to right edge
                        if not cEndX and c.endPos > maxPos then
                            drawEndX = traceW
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
                                traceOrigin + vec2(drawStartX, 0), 
                                traceOrigin + vec2(drawEndX, h), 
                                rgbm(0.3, 0.3, 0.4, 0.06), 0)
                            ui.drawRect(
                                traceOrigin + vec2(drawStartX, 0), 
                                traceOrigin + vec2(drawEndX, h), 
                                rgbm(1, 1, 1, 0.15), 1)
                            
                            currentCornerName = c.name
                            currentCornerStartX = drawStartX
                            currentCornerEndX = drawEndX
                        else
                            -- Inactive corner: very faint dark fill
                            ui.drawRectFilled(
                                traceOrigin + vec2(drawStartX, 0), 
                                traceOrigin + vec2(drawEndX, h), 
                                rgbm(0.15, 0.15, 0.2, 0.01), 0)
                        end
                        
                        -- Corner name in top left (for all visible corners)
                        if c.name then
                            ui.pushFont(ui.Font.Small)
                            ui.setCursor(traceOrigin + vec2(drawStartX + 3, 2))
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
            local sfX = posToX(0, history.pos, 0, traceW)
            if sfX then
                local sfW = 5
                local squareSize = 4
                for row = 0, math.floor(h / squareSize) do
                    for col = 0, 1 do
                        local isWhite = (row + col) % 2 == 0
                        local color = isWhite and rgbm(1, 1, 1, 0.9) or rgbm(0.1, 0.1, 0.1, 0.9)
                        local px = sfX - sfW / 2 + col * (sfW / 2)
                        local py = row * squareSize
                        ui.drawRectFilled(
                            traceOrigin + vec2(px, py), 
                            traceOrigin + vec2(px + sfW / 2, math.min(py + squareSize, h)), 
                            color, 0)
                    end
                end
            end
        end

        local ghostTraces = state.getGhostTraces(history.pos)
        local maxSpeed = getMaxSpeed(ghostTraces)
        
        -- Ghost traces (reference)
        if ghostTraces and #ghostTraces.throttle == #history.throttle then
            if display.speed and ghostTraces.speed then drawSpeedTrace(traceOrigin, 0, 0, traceW, h, ghostTraces.speed, colors.ghostSpeed, maxSpeed) end
            if display.steering then drawTrace(traceOrigin, 0, 0, traceW, h, ghostTraces.steering, colors.ghostSteering) end
            if display.clutch then drawTrace(traceOrigin, 0, 0, traceW, h, ghostTraces.clutch, colors.ghostClutch) end
            if display.throttle then drawTrace(traceOrigin, 0, 0, traceW, h, ghostTraces.throttle, colors.ghostThrottle) end
            if display.brake then drawTrace(traceOrigin, 0, 0, traceW, h, ghostTraces.brake, colors.ghostBrake) end
        end

        -- Current traces
        if display.speed then drawSpeedTrace(traceOrigin, 0, 0, traceW, h, history.speed, colors.speed, maxSpeed) end
        if display.steering then drawTrace(traceOrigin, 0, 0, traceW, h, history.steering, colors.steering) end
        if display.clutch then drawTrace(traceOrigin, 0, 0, traceW, h, history.clutch, colors.clutch) end
        if display.throttle then drawTrace(traceOrigin, 0, 0, traceW, h, history.throttle, colors.throttle) end
        if display.brake then drawTrace(traceOrigin, 0, 0, traceW, h, history.brake, colors.brake) end
        
        -- Corner name is now rendered in the corner zone loop above
    end

    drawBar(origin, brakeX, barY, barW, barH, car.brake, colors.brake)
    drawBar(origin, throttleX, barY, barW, barH, car.gas, colors.throttle)

    drawWheel(origin, wheelCX, wheelCY, wheelR, car.steer, state.getGhostSteering())
    drawGear(origin, wheelCX, wheelCY, wheelR, car.gear)
    drawSpeed(origin, wheelCX, wheelCY + wheelR + 2, wheelW, car)

    if corner.isRecording() then
        ui.pushFont(ui.Font.Title)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(1, 0.3, 0.3, 1))
        ui.setCursor(windowOrigin + vec2(10, 5))
        ui.text("REC")
        ui.popStyleColor()
        ui.popFont()
    end
end

function script.windowSettings(dt)
    settings.windowSettings(corner, resetButton, recordCornerButton)
end

function script.windowCorners(dt)
    -- corner_analysis.update() handles corner tracking internally
    corner_analysis.draw(dt, settings.useKMH)
end

function script.windowTelemetry(dt)
    lap_telemetry.draw(dt)
end
