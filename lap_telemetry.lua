-- Lap Telemetry - MoTeC-style professional telemetry analysis
-- Uses centralized state for all lap data

local state = require('state')
local lap = require('lap')
local settings = require('app_settings')

local lap_telemetry = {}

-- View state
local selectedLapIndex = nil  -- nil = auto-select fastest, or index into state.history
local autoSelectFastest = true  -- Auto-select fastest lap from session

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

-- Corner editing state
local editMode = false
local selectedCorner = nil  -- Corner number being edited
local draggingHandle = nil  -- "start", "end", or nil
local nameInputBuffer = ""
local lastEditedCorner = nil  -- Track which corner we're editing to reset buffer

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
    -- Edit mode
    cornerSelected = rgbm(0.4, 0.6, 1, 0.5),
    cornerHandle = rgbm(1, 1, 1, 0.9),
    cornerHandleHover = rgbm(1, 0.8, 0.2, 1),
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

-- Get selected lap from state.history (auto-select fastest if enabled)
local function getSelectedLap()
    if #state.history == 0 then return nil end
    
    if autoSelectFastest then
        local fastest, idx = state.getFastestSessionLap()
        if fastest then
            selectedLapIndex = idx
            return fastest
        end
    end
    
    if not selectedLapIndex then selectedLapIndex = 1 end
    local idx = math.clamp(selectedLapIndex, 1, #state.history)
    return state.history[idx]
end

-- Get reference lap (defaults to state.bestLap)
local function getReferenceLap()
    return state.bestLap
end

-- Get value at time from lap (using times array if available, else sample rate)
local function getValueAtTime(lapObj, time, field)
    if not lapObj or lapObj:length() < 2 then return nil end
    
    local lo, hi, t
    
    -- If lap has times array, use binary search to find indices
    if lapObj.times and #lapObj.times >= lapObj:length() then
        local times = lapObj.times
        lo, hi = 1, #times
        
        -- Binary search for surrounding time indices
        while hi - lo > 1 do
            local mid = math.floor((lo + hi) / 2)
            if times[mid] <= time then
                lo = mid
            else
                hi = mid
            end
        end
        
        local t1, t2 = times[lo], times[hi]
        if t1 == t2 then
            t = 0
        else
            t = math.clamp((time - t1) / (t2 - t1), 0, 1)
        end
    else
        -- Fallback: Convert time to index (assuming 15 Hz from time 0)
        local index = time * lap.SAMPLE_RATE + 1
        lo = math.floor(index)
        hi = math.ceil(index)
        t = index - lo
    end
    
    lo = math.clamp(lo, 1, lapObj:length())
    hi = math.clamp(hi, 1, lapObj:length())
    
    if lo == hi then return lapObj[field][lo] end
    
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
-- Note: Reference lap is compared by POSITION, not time (for proper alignment)
local function drawTimeTrace(x, y, w, h, startTime, endTime, lapObj, refLapObj, field, color, refColor, minVal, maxVal, label, unit)
    if not lapObj or lapObj:length() < 2 then return end
    if endTime <= startTime then return end
    
    local numSamples = math.max(10, math.floor(w / 2))
    local timeStep = (endTime - startTime) / numSamples
    
    local values = {}
    local refValues = {}
    local positions = {}  -- Track positions for position-based ref lookup
    local actualMin = minVal or math.huge
    local actualMax = maxVal or -math.huge
    
    for i = 0, numSamples do
        local t = startTime + i * timeStep
        local val = getValueAtTime(lapObj, t, field)
        local pos = getValueAtTime(lapObj, t, "pos")
        
        if val ~= nil then
            table.insert(values, val)
            table.insert(positions, pos)
            if not minVal or not maxVal then
                actualMin = math.min(actualMin, val)
                actualMax = math.max(actualMax, val)
            end
        else
            table.insert(values, 0)
            table.insert(positions, nil)
        end
        
        -- Get reference value at SAME POSITION (not same time) for proper alignment
        if refLapObj and pos then
            local refVal = refLapObj:getValueAtPos(field, pos)
            if refVal ~= nil then
                table.insert(refValues, refVal)
                if not minVal or not maxVal then
                    actualMin = math.min(actualMin, refVal)
                    actualMax = math.max(actualMax, refVal)
                end
            else
                table.insert(refValues, 0)
            end
        elseif refLapObj then
            table.insert(refValues, 0)
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
        local labelText
        if unit and unit:find("km") then
            labelText = string.format("%d", val)  -- Integer for speed
        else
            labelText = string.format("%.1f", val)
        end
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
        local cursorPos = getValueAtTime(lapObj, cursorTime, "pos")
        if cursorVal ~= nil then
            local cursorY = y + h - ((cursorVal - minVal) / range) * h
            ui.drawCircleFilled(vec2(cursorX, cursorY), 6, color, 16)
            ui.drawCircle(vec2(cursorX, cursorY), 6, colors.cursorLine, 16, 2)
        end
        
        -- Get reference value at SAME POSITION (not same time)
        if refLapObj and cursorPos then
            local refVal = refLapObj:getValueAtPos(field, cursorPos)
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

-- Helper: convert position to X coordinate in the graph
local function posToGraphX(pos, selectedLap, startTime, endTime, graphX, graphW)
    if not pos or not selectedLap then return nil end
    
    -- Find the time at this position in the selected lap
    local timeAtPos = selectedLap:getTimeAtPos(pos)
    if not timeAtPos then return nil end
    
    -- Check if within visible time range
    if timeAtPos < startTime or timeAtPos > endTime then return nil end
    
    -- Convert to X coordinate
    local normalizedTime = (timeAtPos - startTime) / (endTime - startTime)
    return graphX + normalizedTime * graphW
end

-- Draw delta time trace with corner highlighting
local function drawDeltaTimeTrace(x, y, w, h, startTime, endTime, selectedLap, refLapObj)
    if not selectedLap or not refLapObj then return end
    if endTime <= startTime then return end
    
    -- Apply 20px top/bottom margin for visual separation
    local marginY = 20
    local innerY = y + marginY
    local innerH = h - marginY * 2
    
    local numSamples = math.max(10, math.floor(w / 2))
    local timeStep = (endTime - startTime) / numSamples
    
    -- Build position-to-delta map for corner delta calculations
    local posDeltas = {}
    local deltas = {}
    local maxDelta = 0.1
    
    for i = 0, numSamples do
        local t = startTime + i * timeStep
        local pos = getValueAtTime(selectedLap, t, "pos")
        if pos then
            -- Get time at this position for both laps
            local selectedTime = selectedLap:getTimeAtPos(pos)
            local refTime = refLapObj:getTimeAtPos(pos)
            
            if selectedTime and refTime then
                local delta = selectedTime - refTime
                table.insert(deltas, delta)
                posDeltas[pos] = delta
                maxDelta = math.max(math.abs(maxDelta), math.abs(delta))
            else
                table.insert(deltas, 0)
            end
        else
            table.insert(deltas, 0)
        end
    end
    
    if maxDelta == 0 then maxDelta = 0.1 end
    
    -- Draw corner zones (before other elements) - with partial corner support
    local corners = state.trackCorners
    local mousePos = ui.mousePos()
    local winPos = ui.windowPos()
    local localMouseX = mousePos.x - winPos.x
    local localMouseY = mousePos.y - winPos.y
    local hoveredCorner = nil
    local hoveredHandle = nil  -- "start" or "end" or nil
    
    if corners then
        -- Draw corners
        for i, corner in ipairs(corners) do
            if corner.startPos and corner.endPos then
                local startX = posToGraphX(corner.startPos, selectedLap, startTime, endTime, x, w)
                local endX = posToGraphX(corner.endPos, selectedLap, startTime, endTime, x, w)
                
                -- Handle partial corners (clamp to visible graph area)
                local drawStartX = startX or x  -- Default to graph start if corner start is before visible range
                local drawEndX = endX or (x + w)  -- Default to graph end if corner end is after visible range
                
                -- Skip if both are outside visible range on the same side
                local cornerVisible = startX or endX or 
                    (corner.startPos < startTime / (selectedLap.time / 1000) and 
                     corner.endPos > endTime / (selectedLap.time / 1000))
                
                if cornerVisible or editMode then
                    local isSelected = editMode and selectedCorner == corner.number
                    
                    -- Draw corner zone background (very faint)
                    local cornerColor
                    if isSelected then
                        cornerColor = colors.cornerSelected
                    elseif editMode then
                        -- Slightly more visible in edit mode
                        cornerColor = (i % 2 == 0) and rgbm(0.2, 0.2, 0.35, 0.15) or rgbm(0.2, 0.35, 0.2, 0.15)
                    else
                        -- Very faint for normal view
                        cornerColor = rgbm(0.15, 0.15, 0.2, 0.01)
                    end
                    ui.drawRectFilled(vec2(drawStartX, y), vec2(drawEndX, y + h), cornerColor, 0)
                    
                    -- Corner name in top left of zone
                    local labelText = corner.name or tostring(corner.number or i)
                    ui.pushFont(ui.Font.Small)
                    ui.setCursor(vec2(drawStartX + 3, y + 2))
                    ui.pushStyleColor(ui.StyleColor.Text, isSelected and rgbm(1, 1, 1, 1) or rgbm(1, 1, 1, 0.35))
                    ui.text(labelText)
                    ui.popStyleColor()
                    
                    -- Calculate corner delta (delta at exit - delta at entry)
                    local entryDelta = selectedLap:getTimeAtPos(corner.startPos)
                    local exitDelta = selectedLap:getTimeAtPos(corner.endPos)
                    local refEntryTime = refLapObj:getTimeAtPos(corner.startPos)
                    local refExitTime = refLapObj:getTimeAtPos(corner.endPos)
                    
                    if entryDelta and exitDelta and refEntryTime and refExitTime then
                        local currentCornerTime = exitDelta - entryDelta
                        local refCornerTime = refExitTime - refEntryTime
                        local cornerTimeDelta = currentCornerTime - refCornerTime
                        
                        -- Draw corner delta at bottom
                        local sign = cornerTimeDelta >= 0 and "+" or ""
                        local deltaText = string.format("%s%.2f", sign, cornerTimeDelta)
                        local deltaColor = cornerTimeDelta >= 0 and rgbm(1, 0.4, 0.4, 0.9) or rgbm(0.4, 1, 0.4, 0.9)
                        
                        ui.setCursor(vec2(drawStartX + 3, y + h - 14))
                        ui.pushStyleColor(ui.StyleColor.Text, deltaColor)
                        ui.text(deltaText)
                        ui.popStyleColor()
                    end
                    
                    ui.popFont()
                    
                    -- Edit mode: check for hover and draw handles (only if edges are visible)
                    if editMode then
                        local handleSize = 8
                        local handleHitSize = 12  -- Larger hit area
                        
                        -- Check if hovering this corner zone (for selection)
                        if localMouseX >= drawStartX and localMouseX <= drawEndX and localMouseY >= y and localMouseY <= y + h then
                            hoveredCorner = corner.number
                        end
                        
                        -- Start handle (only if visible)
                        if startX then
                            local startHandleHover = math.abs(localMouseX - startX) < handleHitSize and localMouseY >= y and localMouseY <= y + h
                            if startHandleHover then
                                hoveredCorner = corner.number
                                hoveredHandle = "start"
                            end
                            local startHandleColor = (startHandleHover or (isSelected and draggingHandle == "start")) 
                                and colors.cornerHandleHover or colors.cornerHandle
                            
                            ui.drawRectFilled(vec2(startX - 2, y), vec2(startX + 2, y + h), startHandleColor, 0)
                            ui.drawCircleFilled(vec2(startX, y + h / 2), handleSize, startHandleColor, 16)
                        end
                        
                        -- End handle (only if visible)
                        if endX then
                            local endHandleHover = math.abs(localMouseX - endX) < handleHitSize and localMouseY >= y and localMouseY <= y + h
                            if endHandleHover then
                                hoveredCorner = corner.number
                                hoveredHandle = "end"
                            end
                            local endHandleColor = (endHandleHover or (isSelected and draggingHandle == "end")) 
                                and colors.cornerHandleHover or colors.cornerHandle
                            
                            ui.drawRectFilled(vec2(endX - 2, y), vec2(endX + 2, y + h), endHandleColor, 0)
                            ui.drawCircleFilled(vec2(endX, y + h / 2), handleSize, endHandleColor, 16)
                        end
                    end
                end
            end
        end
    end
    
    -- Handle mouse interactions for edit mode
    if editMode then
        -- Convert mouse X to position
        local function xToPos(mouseX)
            local normalizedTime = (mouseX - x) / w
            local t = startTime + normalizedTime * (endTime - startTime)
            local pos = getValueAtTime(selectedLap, t, "pos")
            return pos
        end
        
        -- Start dragging on mouse down
        if ui.mouseClicked(ui.MouseButton.Left) then
            if hoveredHandle then
                selectedCorner = hoveredCorner
                draggingHandle = hoveredHandle
            elseif hoveredCorner then
                selectedCorner = hoveredCorner
                draggingHandle = nil
            elseif localMouseX >= x and localMouseX <= x + w and localMouseY >= y and localMouseY <= y + h then
                -- Clicked in delta area but not on a corner - deselect
                selectedCorner = nil
                draggingHandle = nil
            end
        end
        
        -- Handle dragging
        if draggingHandle and selectedCorner and ui.mouseDown(ui.MouseButton.Left) then
            local newPos = xToPos(localMouseX)
            if newPos then
                if draggingHandle == "start" then
                    state.updateCorner(selectedCorner, { startPos = newPos })
                elseif draggingHandle == "end" then
                    state.updateCorner(selectedCorner, { endPos = newPos })
                end
            end
        end
        
        -- Stop dragging on mouse up
        if not ui.mouseDown(ui.MouseButton.Left) then
            draggingHandle = nil
        end
    end
    
    -- Zero line (use inner dimensions)
    ui.drawLine(vec2(x, innerY + innerH / 2), vec2(x + w, innerY + innerH / 2), colors.gridMajor, 2)
    
    -- Grid (use inner dimensions)
    for i = 0, 4 do
        local py = innerY + (i / 4) * innerH
        ui.drawLine(vec2(x, py), vec2(x + w, py), colors.grid, 1)
    end
    
    -- Delta trace (use inner dimensions)
    if #deltas >= 2 then
        ui.pathClear()
        for i = 1, #deltas do
            local px = x + (i - 1) / (#deltas - 1) * w
            local py = innerY + innerH / 2 - (deltas[i] / maxDelta) * (innerH / 2)
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(colors.deltaTime, false, 2)
    end
    
    -- Y-axis labels (use inner dimensions)
    ui.setCursor(vec2(x - 50, innerY + innerH / 2 - 7))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("0.00s")
    ui.popStyleColor()
    ui.popFont()
    
    ui.setCursor(vec2(x - 55, innerY + 2))
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text(string.format("-%.2fs", maxDelta))
    ui.popStyleColor()
    
    ui.setCursor(vec2(x - 55, innerY + innerH - 10))
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text(string.format("+%.2fs", maxDelta))
    ui.popStyleColor()
    
    -- Label
    ui.setCursor(vec2(x + 5, y + 2))
    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
    ui.text("Delta-T")
    ui.popStyleColor()
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
    local car = ac.getCar(0)
    
    -- Auto-hide when traveling above speed threshold
    if settings.telemetryAutoHide and car and car.speedKmh > settings.telemetryAutoHideSpeed then
        -- Draw minimal collapsed indicator
        ui.drawRectFilled(vec2(0, 0), vec2(100, 22), rgbm(0.08, 0.08, 0.1, 0.9), 4)
        ui.setCursor(vec2(8, 3))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.4, 0.5, 0.7, 1))
        ui.text("Telemetry")
        ui.popStyleColor()
        ui.popFont()
        return
    end
    
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
    
    -- Controls bar
    local controlsY = headerH + 5
    local controlsH = 25
    ui.setCursor(vec2(padding, controlsY))
    ui.pushFont(ui.Font.Small)
    
    local selectedLap = getSelectedLap()
    local referenceLap = getReferenceLap()
    
    if selectedLap then
        ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
        local lapTimeS = selectedLap.time / 1000
        local mins = math.floor(lapTimeS / 60)
        local secs = lapTimeS - mins * 60
        local autoLabel = autoSelectFastest and " (fastest)" or ""
        ui.text(string.format("Lap: %d:%05.2f%s", mins, secs, autoLabel))
        ui.popStyleColor()
        
        ui.sameLine(130)
        if #state.history > 1 then
            if ui.button("<", vec2(30, 0)) then
                autoSelectFastest = false
                selectedLapIndex = math.max(1, (selectedLapIndex or 1) - 1)
                viewStartTime = 0
                viewDuration = 0
            end
            ui.sameLine()
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            
            ui.text(string.format("lap %d", selectedLap or 1))
            ui.popStyleColor()
            ui.sameLine()
            if ui.button(">", vec2(30, 0)) then
                autoSelectFastest = false
                selectedLapIndex = math.min(#state.history, (selectedLapIndex or 1) + 1)
                viewStartTime = 0
                viewDuration = 0
            end
        end
        
        ui.sameLine(300)
        if referenceLap then
            local refTimeS = referenceLap.time / 1000
            local refMins = math.floor(refTimeS / 60)
            local refSecs = refTimeS - refMins * 60
            ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.6, 0.6, 1, 1))
            ui.text(string.format("vs Best: %d:%05.2f", refMins, refSecs))
            ui.popStyleColor()
        else
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            ui.text("No reference lap")
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
        
        -- Edit Corners button
        ui.sameLine()
        if editMode then
            ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.3, 0.6, 0.3, 1))
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.4, 0.7, 0.4, 1))
            if ui.button("Save Corners", vec2(100, 0)) then
                state.saveCornersToFile()
                editMode = false
                selectedCorner = nil
                draggingHandle = nil
                editingName = false
            end
            ui.popStyleColor(2)
        else
            if ui.button("Edit Corners", vec2(100, 0)) then
                editMode = true
                selectedCorner = nil
            end
        end
        
        -- Load Lap button
        ui.sameLine()
        if ui.button("Load Lap...", vec2(90, 0)) then
            showRefPicker = not showRefPicker
            if showRefPicker then ghostFiles = nil end
        end
    else
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("No laps recorded")
        ui.popStyleColor()
        
        -- Load Lap button (always available)
        ui.sameLine(windowSize.x - 110)
        if ui.button("Load Lap...", vec2(90, 0)) then
            showRefPicker = not showRefPicker
            if showRefPicker then ghostFiles = nil end
        end
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
        
        -- Mouse interaction (convert screen coords to window-local)
        local windowPos = ui.windowPos()
        local mousePos = ui.mousePos()
        local localMouseX = mousePos.x - windowPos.x
        local localMouseY = mousePos.y - windowPos.y
        
        if localMouseX >= graphX and localMouseX <= graphX + graphW and
           localMouseY >= contentY and localMouseY <= contentY + contentH then
            
            local mouseX = localMouseX - graphX
            cursorTime = startTime + (mouseX / graphW) * (endTime - startTime)
            cursorTime = math.clamp(cursorTime, startTime, endTime)
            
            if ui.mouseClicked(ui.MouseButton.Right) then
                -- Enable panning - if not zoomed, start with a zoom first
                if viewDuration == 0 then
                    viewDuration = lapTime * 0.5
                    viewStartTime = math.max(0, cursorTime - viewDuration / 2)
                end
                panningView = true
                panStartMouseX = mousePos.x
                panStartTime = viewStartTime
            elseif ui.mouseClicked(ui.MouseButton.Left) and not editMode then
                draggingCursor = true
            end
        end
        
        -- Panning (right-click drag to pan the view)
        if panningView then
            if ui.mouseDown(ui.MouseButton.Right) then
                local deltaX = mousePos.x - panStartMouseX
                local currentDuration = viewDuration > 0 and viewDuration or lapTime
                local timeDelta = (deltaX / graphW) * currentDuration
                viewStartTime = math.max(0, math.min(panStartTime - timeDelta, lapTime - viewDuration))
            else
                panningView = false
            end
        end
        
        -- Cursor dragging
        if draggingCursor then
            if ui.mouseDown(ui.MouseButton.Left) then
                local mouseX = math.clamp(localMouseX - graphX, 0, graphW)
                cursorTime = startTime + (mouseX / graphW) * (endTime - startTime)
                cursorTime = math.clamp(cursorTime, startTime, endTime)
            else
                draggingCursor = false
            end
        end
        
        -- Mouse wheel zoom (centered on cursor position)
        local wheel = ui.mouseWheel()
        if wheel ~= 0 and localMouseX >= graphX and localMouseX <= graphX + graphW and
           localMouseY >= contentY and localMouseY <= contentY + contentH then
            
            -- Get time at mouse position (zoom center)
            local mouseX = localMouseX - graphX
            local mouseTime = startTime + (mouseX / graphW) * (endTime - startTime)
            
            local currentDuration = endTime - startTime
            local zoomFactor = wheel > 0 and 0.8 or 1.25  -- Scroll up = zoom in
            local newDuration = currentDuration * zoomFactor
            
            if newDuration >= lapTime then
                -- Fully zoomed out
                viewStartTime = 0
                viewDuration = 0
            else
                -- Keep mouse position at same relative spot after zoom
                local mouseRatio = (mouseTime - startTime) / currentDuration
                local newStartTime = mouseTime - mouseRatio * newDuration
                
                -- Clamp to valid range
                viewStartTime = math.max(0, math.min(newStartTime, lapTime - newDuration))
                viewDuration = math.min(newDuration, lapTime - viewStartTime)
                
                -- Minimum zoom level
                if viewDuration < 1 then viewDuration = 1 end
            end
        end
        
        local y = contentY
        
        -- Delta-T
        drawDeltaTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap)
        y = y + traceH
        
        -- Throttle
        local throttleY = y
        local throttleH = traceH - 5
        drawTimeTrace(graphX, y, graphW, throttleH, startTime, endTime, selectedLap, referenceLap, "throttle", colors.throttle, colors.refThrottle, 0, 1, "Throttle", "")
        
        -- Draw TC markers on throttle trace (current session laps only)
        if selectedLap.tcActive and #selectedLap.tcActive > 0 then
            local tcColor = rgbm(1, 0.5, 0, 1)  -- Orange for TC
            
            for i = 1, selectedLap:length() do
                if selectedLap.tcActive[i] then
                    local sampleTime
                    if selectedLap.times and selectedLap.times[i] then
                        sampleTime = selectedLap.times[i]
                    else
                        sampleTime = (i - 1) / lap.SAMPLE_RATE
                    end
                    
                    -- Check if sample is in visible range
                    if sampleTime >= startTime and sampleTime <= endTime then
                        local px = graphX + ((sampleTime - startTime) / (endTime - startTime)) * graphW
                        local throttleVal = selectedLap.throttle[i] or 0
                        local py = throttleY + throttleH - throttleVal * throttleH
                        
                        -- TC marker (small orange triangle pointing down)
                        ui.drawTriangleFilled(
                            vec2(px - 3, py - 8),
                            vec2(px + 3, py - 8),
                            vec2(px, py - 2),
                            tcColor
                        )
                    end
                end
            end
            
            -- Legend
            ui.setCursor(vec2(graphX + 70, throttleY + 2))
            ui.pushFont(ui.Font.Small)
            ui.drawTriangleFilled(vec2(graphX + 70, throttleY + 4), vec2(graphX + 76, throttleY + 4), vec2(graphX + 73, throttleY + 10), tcColor)
            ui.setCursor(vec2(graphX + 80, throttleY + 2))
            ui.pushStyleColor(ui.StyleColor.Text, tcColor)
            ui.text("TC")
            ui.popStyleColor()
            ui.popFont()
        end
        
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
        drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, "speed", colors.speed, colors.refSpeed, 0, maxSpeed, "Speed", " kmh")
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
                
                -- Time (formatted as m:ss.sss)
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Main)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                local mins = math.floor(cursorTime / 60)
                local secs = cursorTime - mins * 60
                if mins > 0 then
                    ui.text(string.format("%d:%06.3f", mins, secs))
                else
                    ui.text(string.format("%.3fs", secs))
                end
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
                    ui.text(string.format("%.1f%%", cursorValues.pos * 100))
                    ui.popStyleColor()
                    py = py + lineH
                    -- position in meters (using actual track length)
                    local trackLength = ac.getSim().trackLengthM or 5000
                    ui.setCursor(vec2(panelX + 10, py))
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                    ui.text("Meters:")
                    ui.popStyleColor()
                    ui.sameLine(panelX + 70)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                    ui.text(string.format("%d m", math.floor(cursorValues.pos * trackLength)))
                    ui.popStyleColor()
                end
                
                -- Help text
                py = panelY + panelH - 40
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("← → : Scrub")
                ui.popStyleColor()
                py = py + 15
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("R-Click: Pan")
                ui.popStyleColor()
                ui.popFont()
            end
        end
        
        -- Corner editing panel (when in edit mode)
        if editMode then
            local editPanelH = 160
            local editPanelY = contentY + contentH - editPanelH - 10
            
            ui.drawRectFilled(vec2(panelX, editPanelY), vec2(panelX + panelW, editPanelY + editPanelH), colors.valuePanelBg, 4)
            ui.drawRect(vec2(panelX, editPanelY), vec2(panelX + panelW, editPanelY + editPanelH), colors.cornerHandleHover, 2)
            
            local epy = editPanelY + 10
            local eLineH = 22
            
            if selectedCorner then
                local corner = state.getCornerInfo(selectedCorner)
                if corner then
                -- Header
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushFont(ui.Font.Main)
                ui.pushStyleColor(ui.StyleColor.Text, colors.cornerHandleHover)
                ui.text(string.format("Corner %d", selectedCorner))
                ui.popStyleColor()
                ui.popFont()
                epy = epy + eLineH
                
                ui.drawLine(vec2(panelX + 5, epy), vec2(panelX + panelW - 5, epy), colors.grid, 1)
                epy = epy + 8
                
                -- Corner name input
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Name:")
                ui.popStyleColor()
                ui.popFont()
                
                ui.setCursor(vec2(panelX + 50, epy - 2))
                ui.pushStyleVar(ui.StyleVar.FramePadding, vec2(4, 2))
                ui.pushStyleColor(ui.StyleColor.FrameBg, rgbm(0.15, 0.15, 0.15, 1))
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                ui.setNextItemWidth(panelW - 60)
                
                -- Initialize name buffer when corner changes
                if selectedCorner ~= lastEditedCorner then
                    nameInputBuffer = corner.name or ""
                    lastEditedCorner = selectedCorner
                end
                
                -- ui.inputText returns the new string value directly
                local newName = ui.inputText("##cornerName", nameInputBuffer, ui.InputTextFlags.None)
                if newName ~= nameInputBuffer then
                    nameInputBuffer = newName
                    state.updateCorner(selectedCorner, { name = newName ~= "" and newName or nil })
                end
                
                ui.popStyleColor(2)
                ui.popStyleVar()
                epy = epy + eLineH + 4
                
                -- Position info
                local trackLength = ac.getSim().trackLengthM or 5000
                
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Start:")
                ui.popStyleColor()
                ui.sameLine(panelX + 50)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                ui.text(string.format("%.1f%% (%dm)", (corner.startPos or 0) * 100, math.floor((corner.startPos or 0) * trackLength)))
                ui.popStyleColor()
                ui.popFont()
                epy = epy + eLineH - 4
                
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("End:")
                ui.popStyleColor()
                ui.sameLine(panelX + 50)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                ui.text(string.format("%.1f%% (%dm)", (corner.endPos or 0) * 100, math.floor((corner.endPos or 0) * trackLength)))
                ui.popStyleColor()
                ui.popFont()
                epy = epy + eLineH
                
                -- Delete corner button
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.5, 0.2, 0.2, 1))
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.6, 0.3, 0.3, 1))
                if ui.button("Delete Corner", vec2(panelW - 20, 0)) then
                    state.deleteCorner(selectedCorner)
                    selectedCorner = nil
                end
                ui.popStyleColor(2)
                end
            else
                -- No corner selected - show insert option
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushFont(ui.Font.Main)
                ui.pushStyleColor(ui.StyleColor.Text, colors.cornerHandleHover)
                ui.text("Edit Corners")
                ui.popStyleColor()
                ui.popFont()
                epy = epy + eLineH
                
                ui.drawLine(vec2(panelX + 5, epy), vec2(panelX + panelW - 5, epy), colors.grid, 1)
                epy = epy + 10
                
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text("Click a corner to edit it")
                ui.popStyleColor()
                ui.popFont()
                epy = epy + eLineH
                
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
                ui.text(string.format("Corners: %d", state.getCornerCount()))
                ui.popStyleColor()
                epy = epy + eLineH + 5
                
                -- Insert corner button
                ui.setCursor(vec2(panelX + 10, epy))
                ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.4, 0.2, 1))
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.5, 0.3, 1))
                if ui.button("+ Insert Corner", vec2(panelW - 20, 0)) then
                    -- Insert at cursor position
                    local insertPos = cursorTime and getValueAtTime(getSelectedLap(), cursorTime, "pos") or 0.5
                    state.insertCorner(insertPos - 0.02, insertPos + 0.02)
                end
                ui.popStyleColor(2)
            end
        end
    else
        ui.setCursor(vec2(windowSize.x / 2 - 100, contentY + contentH / 2))
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("Complete a lap to see telemetry")
        ui.popStyleColor()
    end
    
    -- Lap picker dialog (drawn last to be on top)
    if showRefPicker then
        local dialogW = 340
        local dialogH = 420  -- Taller to fit more sections
        local dialogX = windowSize.x - dialogW - 10
        local dialogY = headerH + 5
        
        -- Dialog background
        ui.drawRectFilled(vec2(dialogX, dialogY), vec2(dialogX + dialogW, dialogY + dialogH), rgbm(0.1, 0.1, 0.12, 0.98), 4)
        ui.drawRect(vec2(dialogX, dialogY), vec2(dialogX + dialogW, dialogY + dialogH), colors.gridMajor, 2)
        
        local py = dialogY + 10
        local labelW = dialogW - 110  -- Width for lap label
        local btnW = 40  -- Width for each button
        
        -- Header
        ui.setCursor(vec2(dialogX + 10, py))
        ui.pushFont(ui.Font.Main)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
        ui.text("Load Lap")
        ui.popStyleColor()
        ui.popFont()
        
        -- Column headers
        ui.sameLine(dialogX + labelW + 15)
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("Cur")
        ui.sameLine(dialogX + labelW + 55)
        ui.text("Ref")
        ui.popStyleColor()
        ui.popFont()
        py = py + 25
        
        ui.drawLine(vec2(dialogX + 5, py), vec2(dialogX + dialogW - 5, py), colors.grid, 1)
        py = py + 10
        
        -- Helper to draw a lap entry with C/R buttons
        local function drawLapEntry(lapData, idx, labelPrefix)
            local lapTimeS = lapData.time / 1000
            local mins = math.floor(lapTimeS / 60)
            local secs = lapTimeS - mins * 60
            local lapLabel = string.format("%s%d:%05.2f", labelPrefix, mins, secs)
            local isBest = lapData == state.bestLap
            local isCurrent = (selectedLapIndex == idx) or (autoSelectFastest and lapData == state.getFastestSessionLap())
            
            -- Lap label
            ui.setCursor(vec2(dialogX + 10, py + 2))
            ui.pushFont(ui.Font.Small)
            if isBest then
                ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.5, 0.7, 1, 1))
            elseif isCurrent then
                ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.5, 1, 0.5, 1))
            else
                ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
            end
            ui.text(lapLabel)
            if isBest then ui.sameLine() ui.text("(ref)") end
            if isCurrent then ui.sameLine() ui.text("(cur)") end
            ui.popStyleColor()
            ui.popFont()
            
            -- "Cur" button
            ui.setCursor(vec2(dialogX + labelW + 5, py))
            ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.4, 0.2, 1))
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.5, 0.3, 1))
            if ui.button("C##cur" .. idx, vec2(btnW, 0)) then
                autoSelectFastest = false
                selectedLapIndex = idx
                viewStartTime = 0
                viewDuration = 0
                showRefPicker = false
                ac.setMessage("Current Set", string.format("Viewing lap %d:%05.2f", mins, secs))
            end
            ui.popStyleColor(2)
            
            -- "Ref" button
            ui.sameLine()
            ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.2, 0.4, 1))
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.3, 0.5, 1))
            if ui.button("R##ref" .. idx, vec2(btnW, 0)) then
                state.setBestLap(lapData)
                showRefPicker = false
                ac.setMessage("Reference Set", string.format("Reference: %d:%05.2f", mins, secs))
            end
            ui.popStyleColor(2)
            
            py = py + 22
        end
        
        -- Current Session Laps
        ui.setCursor(vec2(dialogX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.5, 1, 0.5, 1))
        ui.text("This Session:")
        ui.popStyleColor()
        ui.popFont()
        py = py + 18
        
        local currentSessionLaps = state.getCurrentSessionLaps()
        if #currentSessionLaps > 0 then
            local shown = 0
            for _, entry in ipairs(currentSessionLaps) do
                if shown < 5 then
                    drawLapEntry(entry.lap, entry.index, "")
                    shown = shown + 1
                end
            end
        else
            ui.setCursor(vec2(dialogX + 15, py))
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            ui.text("No laps yet")
            ui.popStyleColor()
            py = py + 20
        end
        
        py = py + 5
        ui.drawLine(vec2(dialogX + 5, py), vec2(dialogX + dialogW - 5, py), colors.grid, 1)
        py = py + 10
        
        -- Previous Session Laps
        ui.setCursor(vec2(dialogX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.7, 0.7, 0.9, 1))
        ui.text("Previous Sessions:")
        ui.popStyleColor()
        ui.popFont()
        py = py + 18
        
        local prevSessionLaps = state.getPreviousSessionLaps()
        if #prevSessionLaps > 0 then
            local shown = 0
            for _, entry in ipairs(prevSessionLaps) do
                if shown < 4 then
                    drawLapEntry(entry.lap, entry.index, "")
                    shown = shown + 1
                end
            end
        else
            ui.setCursor(vec2(dialogX + 15, py))
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            ui.text("No previous laps saved")
            ui.popStyleColor()
            py = py + 20
        end
        
        py = py + 5
        ui.drawLine(vec2(dialogX + 5, py), vec2(dialogX + dialogW - 5, py), colors.grid, 1)
        py = py + 10
        
        -- CSV Files section
        ui.setCursor(vec2(dialogX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("CSV Files:")
        ui.popStyleColor()
        ui.popFont()
        py = py + 18
        
        local files = scanGhostFiles()
        if #files > 0 then
            for j, filename in ipairs(files) do
                if j <= 5 then  -- Limit CSV files shown
                    -- Truncate long filenames
                    local displayName = filename
                    if #displayName > 20 then
                        displayName = string.sub(displayName, 1, 17) .. "..."
                    end
                    
                    -- File label
                    ui.setCursor(vec2(dialogX + 10, py + 2))
                    ui.pushFont(ui.Font.Small)
                    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
                    ui.text(displayName)
                    ui.popStyleColor()
                    ui.popFont()
                    
                    -- "Cur" button
                    ui.setCursor(vec2(dialogX + labelW + 5, py))
                    ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.4, 0.2, 1))
                    ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.5, 0.3, 1))
                    if ui.button("C##csvcur" .. j, vec2(btnW, 0)) and not isLoadingRef then
                        isLoadingRef = true
                        local filePath = __dirname .. "/tracks/" .. filename
                        local loaded = lap.fromCSV(filePath, state.track, state.car)
                        if loaded then
                            -- Add to history and select it
                            table.insert(state.history, 1, loaded)
                            table.insert(state.historyReferences, loaded)
                            autoSelectFastest = false
                            selectedLapIndex = 1
                            viewStartTime = 0
                            viewDuration = 0
                            showRefPicker = false
                            ac.setMessage("Loaded as Current", string.format("CSV: %d:%05.2f", 
                                math.floor(loaded.time / 60000), (loaded.time / 1000) % 60))
                        else
                            ac.setMessage("Load Error", "Failed to load " .. filename)
                        end
                        isLoadingRef = false
                    end
                    ui.popStyleColor(2)
                    
                    -- "Ref" button
                    ui.sameLine()
                    ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.2, 0.4, 1))
                    ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.3, 0.5, 1))
                    if ui.button("R##csvref" .. j, vec2(btnW, 0)) and not isLoadingRef then
                        isLoadingRef = true
                        local filePath = __dirname .. "/tracks/" .. filename
                        local loaded = lap.fromCSV(filePath, state.track, state.car)
                        if loaded then
                            state.setBestLap(loaded)
                            table.insert(state.historyReferences, loaded)
                            showRefPicker = false
                            ac.setMessage("Reference Loaded", string.format("CSV: %d:%05.2f", 
                                math.floor(loaded.time / 60000), (loaded.time / 1000) % 60))
                        else
                            ac.setMessage("Load Error", "Failed to load " .. filename)
                        end
                        isLoadingRef = false
                    end
                    ui.popStyleColor(2)
                    
                    py = py + 22
                end
            end
        else
            ui.setCursor(vec2(dialogX + 15, py))
            ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
            ui.text("No CSV files in tracks/")
            ui.popStyleColor()
            py = py + 20
        end
        
        -- Cancel button at bottom
        py = dialogY + dialogH - 30
        ui.setCursor(vec2(dialogX + 10, py))
        if ui.button("Close##refdlg", vec2(dialogW - 20, 0)) then
            showRefPicker = false
        end
    end
end

return lap_telemetry
