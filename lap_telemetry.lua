-- Lap Telemetry - MoTeC-style professional telemetry analysis
-- Uses centralized state for all lap data

local state = require('state')
local lap = require('lap')
local settings = require('app_settings')

local lap_telemetry = {}

-- View state
local selectedLapIndex = 1  -- Index into state.history (1 = most recent)
local referenceLapIndex = 0  -- 0 = from CSV, 1+ = from state.historyReferences
local referenceLap = nil  -- Current reference lap

local viewStartTime = 0  -- Start time of visible window (seconds)
local viewDuration = 0   -- Duration of visible window (seconds, 0 = full lap)
local cursorTime = nil   -- Cursor time position (nil = no cursor)
local draggingCursor = false
local panningView = false
local panStartMouseX = 0
local panStartTime = 0

-- Reference lap loading UI
local showRefPicker = false
local ghostFiles = nil
local ghostFilesLastScan = 0
local isLoadingRef = false

-- Colors (MoTeC-style dark theme)
local colors = {
    background = rgbm(0.05, 0.05, 0.05, 0.98),
    grid = rgbm(0.3, 0.3, 0.3, 0.4),
    gridMajor = rgbm(0.5, 0.5, 0.5, 0.6),
    -- Traces (bright)
    throttle = rgbm(0, 1, 0, 1),
    brake = rgbm(1, 0, 0, 1),
    speed = rgbm(0.7, 0.7, 1, 1),
    steering = rgbm(1, 1, 0.5, 1),
    deltaTime = rgbm(1, 1, 0, 1),
    -- Reference traces (fainter)
    refThrottle = rgbm(0, 0.6, 0, 0.5),
    refBrake = rgbm(0.6, 0, 0, 0.5),
    refSpeed = rgbm(0.5, 0.5, 0.7, 0.4),
    refSteering = rgbm(0.7, 0.7, 0.3, 0.4),
    -- UI
    textDim = rgbm(0.7, 0.7, 0.7, 1),
    textBright = rgbm(1, 1, 1, 1),
    cursorLine = rgbm(1, 1, 1, 0.9),
    labelBg = rgbm(0.1, 0.1, 0.1, 0.9),
    valuePanelBg = rgbm(0.08, 0.08, 0.08, 0.95),
    deltaPos = rgbm(0.3, 1, 0.3, 1),
    deltaNeg = rgbm(1, 0.3, 0.3, 1),
}

-- Check if file exists
local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

-- Scan for CSV files
local function scanGhostFiles()
    local now = os.clock()
    if ghostFiles and (now - ghostFilesLastScan) < 5 then
        return ghostFiles
    end
    
    ghostFiles = {}
    local tracksPath = __dirname .. "/tracks/"
    
    local trackId = ac.getTrackID()
    if trackId then
        local safeName = trackId:gsub("[/\\:]", "_") .. ".csv"
        if fileExists(tracksPath .. safeName) then
            table.insert(ghostFiles, safeName)
        end
    end
    
    local knownFiles = {"ier_daytona.csv"}
    for _, filename in ipairs(knownFiles) do
        if fileExists(tracksPath .. filename) then
            local found = false
            for _, existing in ipairs(ghostFiles) do
                if existing == filename then found = true; break end
            end
            if not found then
                table.insert(ghostFiles, filename)
            end
        end
    end
    
    ghostFilesLastScan = now
    return ghostFiles
end

-- Get selected lap from state.history
local function getSelectedLap()
    if #state.history == 0 then return nil end
    local idx = math.clamp(selectedLapIndex, 1, #state.history)
    return state.history[idx]
end

-- Get value at time from lap (using sample rate conversion)
local function getValueAtTime(lapObj, time, field)
    if not lapObj or lapObj:length() < 2 then return nil end
    
    -- Convert time to index (assuming 15 Hz)
    local index = time * lap.SAMPLE_RATE + 1
    local lo = math.floor(index)
    local hi = math.ceil(index)
    
    lo = math.clamp(lo, 1, lapObj:length())
    hi = math.clamp(hi, 1, lapObj:length())
    
    if lo == hi then return lapObj[field][lo] end
    
    local t = index - lo
    local v1 = lapObj[field][lo]
    local v2 = lapObj[field][hi]
    
    if not v1 or not v2 then return v1 or v2 end
    return v1 + (v2 - v1) * t
end

-- Get time range for view
local function getTimeRange(selectedLap)
    if not selectedLap then return 0, 0, 0 end
    
    local lapTime = selectedLap.time / 1000  -- Convert ms to seconds
    local startTime = viewStartTime
    local endTime = viewDuration > 0 and (viewStartTime + viewDuration) or lapTime
    
    return startTime, endTime, lapTime
end

-- Draw time-based trace with proper scaling
local function drawTimeTrace(x, y, w, h, startTime, endTime, lapObj, refLapObj, field, color, refColor, minVal, maxVal, label, unit)
    if not lapObj or lapObj:length() < 2 then return end
    if endTime <= startTime then return end
    
    local numSamples = math.max(10, math.floor(w / 2))
    local timeStep = (endTime - startTime) / numSamples
    
    local values = {}
    local refValues = {}
    local actualMin = minVal or math.huge
    local actualMax = maxVal or -math.huge
    
    for i = 0, numSamples do
        local t = startTime + i * timeStep
        local val = getValueAtTime(lapObj, t, field)
        if val ~= nil then
            table.insert(values, val)
            if not minVal or not maxVal then
                actualMin = math.min(actualMin, val)
                actualMax = math.max(actualMax, val)
            end
        else
            table.insert(values, 0)
        end
        
        if refLapObj then
            local refVal = getValueAtTime(refLapObj, t, field)
            if refVal ~= nil then
                table.insert(refValues, refVal)
                if not minVal or not maxVal then
                    actualMin = math.min(actualMin, refVal)
                    actualMax = math.max(actualMax, refVal)
                end
            else
                table.insert(refValues, 0)
            end
        end
    end
    
    if #values < 2 then return end
    
    if not minVal then minVal = actualMin end
    if not maxVal then maxVal = actualMax end
    if maxVal == minVal then maxVal = minVal + 1 end
    
    local range = maxVal - minVal
    if range <= 0 then return end
    
    -- Draw grid lines
    local gridLines = 5
    for i = 0, gridLines do
        local val = minVal + (maxVal - minVal) * (i / gridLines)
        local py = y + h - (i / gridLines) * h
        ui.drawLine(vec2(x, py), vec2(x + w, py), i == gridLines / 2 and colors.gridMajor or colors.grid, 1)
        
        ui.setCursor(vec2(x - 50, py - 7))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        local labelText = string.format("%.1f", val)
        if unit then labelText = labelText .. unit end
        ui.text(labelText)
        ui.popStyleColor()
        ui.popFont()
    end
    
    -- Draw reference trace
    if refLapObj and #refValues == #values then
        ui.pathClear()
        for i = 1, #refValues do
            local px = x + (i - 1) / (#refValues - 1) * w
            local py = y + h - ((refValues[i] - minVal) / range) * h
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(refColor, false, 1.5)
    end
    
    -- Draw current trace
    ui.pathClear()
    for i = 1, #values do
        local px = x + (i - 1) / (#values - 1) * w
        local py = y + h - ((values[i] - minVal) / range) * h
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(color, false, 2)
    
    -- Cursor markers
    if cursorTime and cursorTime >= startTime and cursorTime <= endTime then
        local cursorX = x + ((cursorTime - startTime) / (endTime - startTime)) * w
        
        local cursorVal = getValueAtTime(lapObj, cursorTime, field)
        if cursorVal ~= nil then
            local cursorY = y + h - ((cursorVal - minVal) / range) * h
            ui.drawCircleFilled(vec2(cursorX, cursorY), 6, color, 16)
            ui.drawCircle(vec2(cursorX, cursorY), 6, colors.cursorLine, 16, 2)
        end
        
        if refLapObj then
            local refVal = getValueAtTime(refLapObj, cursorTime, field)
            if refVal ~= nil then
                local refY = y + h - ((refVal - minVal) / range) * h
                ui.drawCircleFilled(vec2(cursorX, refY), 5, refColor, 12)
            end
        end
    end
    
    -- Trace label
    ui.setCursor(vec2(x + 5, y + 2))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
    ui.text(label)
    ui.popStyleColor()
    ui.popFont()
end

-- Draw delta time trace
local function drawDeltaTimeTrace(x, y, w, h, startTime, endTime, selectedLap, refLapObj)
    if not selectedLap or not refLapObj then return end
    if endTime <= startTime then return end
    
    local numSamples = math.max(10, math.floor(w / 2))
    local timeStep = (endTime - startTime) / numSamples
    
    local deltas = {}
    local maxDelta = 0.1
    
    for i = 0, numSamples do
        local t = startTime + i * timeStep
        local pos = getValueAtTime(selectedLap, t, "pos")
        if pos then
            local selectedTime = t
            local refTime = refLapObj:getTimeAtPos(pos)
            
            if selectedTime and refTime then
                local delta = selectedTime - refTime
                table.insert(deltas, delta)
                maxDelta = math.max(math.abs(maxDelta), math.abs(delta))
            else
                table.insert(deltas, 0)
            end
        else
            table.insert(deltas, 0)
        end
    end
    
    if maxDelta == 0 then maxDelta = 0.1 end
    
    -- Zero line
    ui.drawLine(vec2(x, y + h / 2), vec2(x + w, y + h / 2), colors.gridMajor, 2)
    
    -- Grid
    for i = 0, 4 do
        local py = y + (i / 4) * h
        ui.drawLine(vec2(x, py), vec2(x + w, py), colors.grid, 1)
    end
    
    -- Delta trace
    if #deltas >= 2 then
        ui.pathClear()
        for i = 1, #deltas do
            local px = x + (i - 1) / (#deltas - 1) * w
            local py = y + h / 2 - (deltas[i] / maxDelta) * (h / 2)
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(colors.deltaTime, false, 2)
    end
    
    -- Y-axis labels
    ui.setCursor(vec2(x - 50, y + h / 2 - 7))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("0.00s")
    ui.popStyleColor()
    ui.popFont()
    
    ui.setCursor(vec2(x - 55, y + 2))
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text(string.format("-%.2fs", maxDelta))
    ui.popStyleColor()
    
    ui.setCursor(vec2(x - 55, y + h - 16))
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text(string.format("+%.2fs", maxDelta))
    ui.popStyleColor()
    
    -- Label
    ui.setCursor(vec2(x + 5, y + 2))
    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
    ui.text("Delta-T")
    ui.popStyleColor()
    ui.popFont()
end

-- Draw time axis
local function drawTimeAxis(x, y, w, startTime, endTime)
    if endTime <= startTime then return end
    
    local duration = endTime - startTime
    local majorInterval = duration > 60 and 10 or (duration > 20 and 5 or 1)
    
    ui.drawLine(vec2(x, y), vec2(x + w, y), colors.gridMajor, 2)
    
    local firstMarker = math.ceil(startTime / majorInterval) * majorInterval
    for t = firstMarker, endTime, majorInterval do
        local px = x + ((t - startTime) / duration) * w
        ui.drawLine(vec2(px, y), vec2(px, y + 5), colors.gridMajor, 1)
        
        ui.setCursor(vec2(px - 20, y + 7))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        local mins = math.floor(t / 60)
        local secs = t - mins * 60
        if mins > 0 then
            ui.text(string.format("%d:%05.2f", mins, secs))
        else
            ui.text(string.format("%.2f", secs))
        end
        ui.popStyleColor()
        ui.popFont()
    end
end

-- Main window
function lap_telemetry.draw(dt)
    local windowSize = ui.availableSpace()
    if windowSize.x <= 0 or windowSize.y <= 0 then return end
    
    local padding = 10
    local labelW = 60
    
    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, colors.background, 4)
    
    -- Header bar
    local headerH = 30
    ui.drawRectFilled(vec2(0, 0), vec2(windowSize.x, headerH), colors.labelBg, 0)
    
    ui.setCursor(vec2(padding, 5))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
    ui.text("Lap Telemetry")
    ui.popStyleColor()
    ui.popFont()
    
    -- Reference lap button
    ui.sameLine(windowSize.x - 150)
    if ui.button("Load Reference...", vec2(140, 0)) then
        showRefPicker = not showRefPicker
        if showRefPicker then ghostFiles = nil end
    end
    
    -- Reference lap picker
    if showRefPicker then
        ui.setCursor(vec2(windowSize.x - 150, headerH + 5))
        
        local files = scanGhostFiles()
        if #files == 0 then
            ui.textColored("No CSV files", colors.textDim)
        else
            for _, filename in ipairs(files) do
                if ui.button(filename, vec2(140, 0)) and not isLoadingRef then
                    isLoadingRef = true
                    showRefPicker = false
                    
                    local filePath = __dirname .. "/tracks/" .. filename
                    local loaded = lap.fromCSV(filePath, state.track, state.car)
                    
                    if loaded then
                        referenceLap = loaded
                        table.insert(state.historyReferences, loaded)
                        ac.setMessage("Reference Loaded", "Loaded " .. loaded:length() .. " samples")
                    else
                        ac.setMessage("Load Error", "Failed to load " .. filename)
                    end
                    
                    isLoadingRef = false
                end
            end
        end
        
        if ui.button("Cancel##ref", vec2(140, 0)) then
            showRefPicker = false
        end
    end
    
    -- Controls bar
    local controlsY = headerH + 5
    local controlsH = 25
    ui.setCursor(vec2(padding, controlsY))
    ui.pushFont(ui.Font.Small)
    
    local selectedLap = getSelectedLap()
    if selectedLap then
        ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
        local lapTimeS = selectedLap.time / 1000
        local mins = math.floor(lapTimeS / 60)
        local secs = lapTimeS - mins * 60
        ui.text(string.format("Lap: %d:%05.2f", mins, secs))
        ui.popStyleColor()
        
        ui.sameLine(150)
        if #state.history > 1 then
            if ui.button("<", vec2(30, 0)) then
                selectedLapIndex = math.max(1, selectedLapIndex - 1)
                viewStartTime = 0
                viewDuration = 0
            end
            ui.sameLine()
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            ui.text(string.format("%d/%d", selectedLapIndex, #state.history))
            ui.popStyleColor()
            ui.sameLine()
            if ui.button(">", vec2(30, 0)) then
                selectedLapIndex = math.min(#state.history, selectedLapIndex + 1)
                viewStartTime = 0
                viewDuration = 0
            end
        end
        
        ui.sameLine(300)
        if referenceLap then
            ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.3, 1, 0.3, 1))
            ui.text("Reference: Loaded")
            ui.popStyleColor()
        else
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            ui.text("Reference: None")
            ui.popStyleColor()
        end
        
        -- Zoom controls
        ui.sameLine(450)
        if ui.button("Zoom In", vec2(70, 0)) then
            local start, endT, lapT = getTimeRange(selectedLap)
            local center = (start + endT) / 2
            local newDuration = (endT - start) * 0.7
            viewStartTime = math.max(0, center - newDuration / 2)
            viewDuration = math.min(newDuration, lapT - viewStartTime)
        end
        
        ui.sameLine()
        if ui.button("Zoom Out", vec2(70, 0)) then
            local start, endT, lapT = getTimeRange(selectedLap)
            local center = (start + endT) / 2
            local newDuration = (endT - start) * 1.4
            if newDuration >= lapT then
                viewStartTime = 0
                viewDuration = 0
            else
                viewStartTime = math.max(0, center - newDuration / 2)
                viewDuration = math.min(newDuration, lapT - viewStartTime)
            end
        end
        
        ui.sameLine()
        if ui.button("Full Lap", vec2(70, 0)) then
            viewStartTime = 0
            viewDuration = 0
        end
    else
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("No laps recorded")
        ui.popStyleColor()
    end
    
    ui.popFont()
    
    -- Content area
    local contentY = headerH + controlsH + 5
    local contentH = windowSize.y - contentY - 30
    if contentH < 100 then return end
    
    local traceH = contentH / 5
    local graphX = padding + labelW
    local panelW = 180
    local graphW = windowSize.x - padding * 2 - labelW - panelW - 10
    
    if selectedLap then
        local startTime, endTime, lapTime = getTimeRange(selectedLap)
        if viewDuration == 0 then endTime = lapTime end
        
        -- Mouse interaction
        local mousePos = ui.getMousePos()
        local graphArea = vec2(graphX, contentY)
        local graphSize = vec2(graphW, contentH)
        
        if mousePos.x >= graphArea.x and mousePos.x <= graphArea.x + graphSize.x and
           mousePos.y >= graphArea.y and mousePos.y <= graphArea.y + graphSize.y then
            
            local mouseX = mousePos.x - graphArea.x
            cursorTime = startTime + (mouseX / graphW) * (endTime - startTime)
            cursorTime = math.clamp(cursorTime, startTime, endTime)
            
            if ui.isMouseClicked(1) and viewDuration > 0 then
                panningView = true
                panStartMouseX = mousePos.x
                panStartTime = viewStartTime
            elseif ui.isMouseClicked(0) then
                draggingCursor = true
            end
        end
        
        -- Panning
        if panningView then
            if ui.isMouseDown(1) and viewDuration > 0 then
                local deltaX = mousePos.x - panStartMouseX
                local timeDelta = (deltaX / graphW) * (endTime - startTime)
                viewStartTime = math.max(0, math.min(panStartTime - timeDelta, lapTime - viewDuration))
            else
                panningView = false
            end
        end
        
        -- Cursor dragging
        if draggingCursor then
            if ui.isMouseDown(0) then
                local mouseX = math.clamp(mousePos.x - graphArea.x, 0, graphW)
                cursorTime = startTime + (mouseX / graphW) * (endTime - startTime)
                cursorTime = math.clamp(cursorTime, startTime, endTime)
            else
                draggingCursor = false
            end
        end
        
        -- Keyboard scrubbing
        if cursorTime then
            if ui.isKeyPressed(ui.Key.LeftArrow) then
                cursorTime = math.max(startTime, cursorTime - 0.1)
            elseif ui.isKeyPressed(ui.Key.RightArrow) then
                cursorTime = math.min(endTime, cursorTime + 0.1)
            end
        end
        
        local y = contentY
        
        -- Delta-T
        drawDeltaTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap)
        y = y + traceH
        
        -- Throttle
        drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, "throttle", colors.throttle, colors.refThrottle, 0, 1, "Throttle", "")
        y = y + traceH
        
        -- Brake
        drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, "brake", colors.brake, colors.refBrake, 0, 1, "Brake", "")
        y = y + traceH
        
        -- Speed
        local maxSpeed = 0
        for i = 1, selectedLap:length() do
            maxSpeed = math.max(maxSpeed, selectedLap.speed[i] or 0)
        end
        if referenceLap then
            for i = 1, referenceLap:length() do
                maxSpeed = math.max(maxSpeed, referenceLap.speed[i] or 0)
            end
        end
        maxSpeed = math.max(100, math.ceil(maxSpeed / 50) * 50)
        drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, "speed", colors.speed, colors.refSpeed, 0, maxSpeed, "Speed", " km/h")
        y = y + traceH
        
        -- Steering
        drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, "steering", colors.steering, colors.refSteering, 0, 1, "Steering", "")
        
        -- Global cursor line
        if cursorTime and cursorTime >= startTime and cursorTime <= endTime then
            local cursorX = graphX + ((cursorTime - startTime) / (endTime - startTime)) * graphW
            ui.drawLine(vec2(cursorX, contentY), vec2(cursorX, contentY + contentH), colors.cursorLine, 2)
            ui.drawRectFilled(vec2(cursorX - 3, contentY - 2), vec2(cursorX + 3, contentY + 2), colors.cursorLine, 0)
        end
        
        -- Time axis
        drawTimeAxis(graphX, windowSize.y - 20, graphW, startTime, endTime)
        
        -- Value display panel
        local panelX = windowSize.x - panelW - padding
        local panelY = contentY
        local panelH = contentH
        
        if cursorTime then
            local cursorValues = {}
            cursorValues.pos = getValueAtTime(selectedLap, cursorTime, "pos")
            
            if referenceLap and cursorValues.pos then
                local curTime = cursorTime
                local refTime = referenceLap:getTimeAtPos(cursorValues.pos)
                if curTime and refTime then
                    cursorValues.deltaTime = curTime - refTime
                end
            end
            
            cursorValues.throttle = getValueAtTime(selectedLap, cursorTime, "throttle")
            cursorValues.brake = getValueAtTime(selectedLap, cursorTime, "brake")
            cursorValues.speed = getValueAtTime(selectedLap, cursorTime, "speed")
            cursorValues.steering = getValueAtTime(selectedLap, cursorTime, "steering")
            
            if referenceLap and cursorValues.pos then
                cursorValues.refThrottle = referenceLap:getValueAtPos("throttle", cursorValues.pos)
                cursorValues.refBrake = referenceLap:getValueAtPos("brake", cursorValues.pos)
                cursorValues.refSpeed = referenceLap:getValueAtPos("speed", cursorValues.pos)
                cursorValues.refSteering = referenceLap:getValueAtPos("steering", cursorValues.pos)
            end
            
            if cursorValues.throttle then
                ui.drawRectFilled(vec2(panelX, panelY), vec2(panelX + panelW, panelY + panelH), colors.valuePanelBg, 4)
                ui.drawRect(vec2(panelX, panelY), vec2(panelX + panelW, panelY + panelH), colors.gridMajor, 1)
                
                local py = panelY + 10
                local lineH = 20
                
                -- Header
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Main)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                ui.text("At Cursor")
                ui.popStyleColor()
                ui.popFont()
                py = py + lineH
                
                ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), colors.grid, 1)
                py = py + 8
                
                -- Time
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Main)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                ui.text(string.format("%.3fs", cursorTime))
                ui.popStyleColor()
                ui.popFont()
                py = py + lineH + 5
                
                ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), colors.grid, 1)
                py = py + 8
                
                -- Delta-T
                if cursorValues.deltaTime then
                    ui.setCursor(vec2(panelX + 10, py))
                    ui.pushFont(ui.Font.Small)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    ui.text("Delta-T:")
                    ui.popStyleColor()
                    ui.sameLine(panelX + 70)
                    local deltaColor = cursorValues.deltaTime < 0 and colors.deltaPos or colors.deltaNeg
                    ui.pushStyleColor(ui.StyleColor.Text, deltaColor)
                    local sign = cursorValues.deltaTime >= 0 and "+" or ""
                    ui.text(string.format("%s%.3fs", sign, cursorValues.deltaTime))
                    ui.popStyleColor()
                    ui.popFont()
                    py = py + lineH
                end
                
                -- Throttle
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Throttle")
                ui.popStyleColor()
                ui.sameLine(panelX + 70)
                ui.pushStyleColor(ui.StyleColor.Text, colors.throttle)
                ui.text(string.format("%.1f%%", (cursorValues.throttle or 0) * 100))
                ui.popStyleColor()
                if cursorValues.refThrottle then
                    ui.sameLine(panelX + 110)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    ui.text(string.format("(%.1f%%)", cursorValues.refThrottle * 100))
                    ui.popStyleColor()
                end
                ui.popFont()
                py = py + lineH
                
                -- Brake
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Brake")
                ui.popStyleColor()
                ui.sameLine(panelX + 70)
                ui.pushStyleColor(ui.StyleColor.Text, colors.brake)
                ui.text(string.format("%.1f%%", (cursorValues.brake or 0) * 100))
                ui.popStyleColor()
                if cursorValues.refBrake then
                    ui.sameLine(panelX + 110)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    ui.text(string.format("(%.1f%%)", cursorValues.refBrake * 100))
                    ui.popStyleColor()
                end
                ui.popFont()
                py = py + lineH
                
                -- Speed
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Speed")
                ui.popStyleColor()
                ui.sameLine(panelX + 70)
                ui.pushStyleColor(ui.StyleColor.Text, colors.speed)
                ui.text(string.format("%.1f", cursorValues.speed or 0))
                ui.popStyleColor()
                if cursorValues.refSpeed then
                    ui.sameLine(panelX + 110)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    ui.text(string.format("(%.1f)", cursorValues.refSpeed))
                    ui.popStyleColor()
                end
                ui.popFont()
                py = py + lineH
                
                -- Steering
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Steering")
                ui.popStyleColor()
                ui.sameLine(panelX + 70)
                ui.pushStyleColor(ui.StyleColor.Text, colors.steering)
                local steerDeg = lap.steerToDegrees(cursorValues.steering or 0.5)
                ui.text(string.format("%.1f°", steerDeg))
                ui.popStyleColor()
                if cursorValues.refSteering then
                    ui.sameLine(panelX + 110)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    local refSteerDeg = lap.steerToDegrees(cursorValues.refSteering)
                    ui.text(string.format("(%.1f°)", refSteerDeg))
                    ui.popStyleColor()
                end
                ui.popFont()
                py = py + lineH
                
                -- Position
                if cursorValues.pos then
                    py = py + 5
                    ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), colors.grid, 1)
                    py = py + 8
                    ui.setCursor(vec2(panelX + 10, py))
                    ui.pushFont(ui.Font.Small)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    ui.text("Position:")
                    ui.popStyleColor()
                    ui.sameLine(panelX + 70)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                    ui.text(string.format("%.3f", cursorValues.pos))
                    ui.popStyleColor()
                    ui.popFont()
                end
                
                -- Help text
                py = panelY + panelH - 40
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("← → : Scrub")
                ui.popStyleColor()
                ui.popFont()
                py = py + 15
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("R-Click: Pan")
                ui.popStyleColor()
                ui.popFont()
            end
        end
    else
        ui.setCursor(vec2(windowSize.x / 2 - 100, contentY + contentH / 2))
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("Complete a lap to see telemetry")
        ui.popStyleColor()
    end
end

return lap_telemetry
