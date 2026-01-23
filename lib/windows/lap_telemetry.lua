-- Lap Telemetry - MoTeC-style professional telemetry analysis
-- Uses centralized state for all lap data

local lap = require('lib.lap')
local settings = require('lib.core.settings')
local corner_analysis = require('lib.windows.corner_analysis')
local theme = require('lib.ui.theme')
local file_utils = require('lib.core.files')
local csv_export = require('lib.lap.csv_export')
local lap_picker = require('lib.windows.lap_picker')
local ui_utils = require('lib.ui.utils')
local markdown = require('lib.ui.markdown')

local lap_telemetry = {}

-- View state
local selectedLap = nil    -- Direct lap reference (can be CSV or session lap)
local autoMode = true      -- Auto mode: automatically select best lap
local lastManualSelectLapCount = 0  -- Lap count when user last manually selected
local viewStartTime = 0  -- Start time of visible window (seconds)
local viewDuration = 0   -- Duration of visible window (seconds, 0 = full lap)
local cursorTime = nil   -- Cursor time position (nil = no cursor)
local draggingCursor = false
local panningView = false
local panStartMouseX = 0
local panStartTime = 0
local refPosOffset = 0   -- Position offset for reference lap alignment (-0.05 to +0.05)

-- Reference lap loading UI
local showRefPicker = false
local loadLapButtonPos = vec2(0, 0)  -- Track button position for dialog placement

-- Corner editing state
local editMode = false
local selectedCorner = nil  -- Corner number being edited
local draggingHandle = nil  -- "start", "end", or nil
local nameInputBuffer = ""
local lastEditedCorner = nil  -- Track which corner we're editing to reset buffer

-- Markers dropdown state
local showMarkersDropdown = false
local markersButtonPos = vec2(0, 0)

-- External context (passed in from main script)
local ctx = nil

--------------------------------------------------------------------------------
-- Lap Selection Helpers
--------------------------------------------------------------------------------

-- Check if we should switch to auto mode (new lap completed since manual selection)
local function checkAutoMode()
    local history = ctx and ctx.history or {}
    local currentLapCount = #history

    -- If a lap was completed since last manual selection, switch to auto mode
    if currentLapCount > lastManualSelectLapCount then
        autoMode = true
    end
end

-- Get selected lap (manual selection or auto-select best)
local function getSelectedLap()
    checkAutoMode()

    -- Manual mode: use the manually selected lap if valid
    if not autoMode and selectedLap and selectedLap:length() > 0 then
        return selectedLap
    end

    -- Auto mode: select best lap from current session (bestInSession)
    -- This is the fastest lap driven in this session (not loaded from file)
    local bestInSession = ctx and ctx.bestInSession or nil
    if bestInSession and bestInSession:length() > 0 then
        return bestInSession
    end

    -- Fallback to first history lap (which should be most recent)
    local history = ctx and ctx.history or {}
    return history[1]
end

-- Set the selected lap manually (disables auto mode)
local function setSelectedLap(lapData)
    selectedLap = lapData
    autoMode = false
    lastManualSelectLapCount = #(ctx and ctx.history or {})
end

-- Get reference lap (defaults to state.bestLap)
local function getReferenceLap()
    return ctx and ctx.bestLap or nil
end

--------------------------------------------------------------------------------
-- Time-Based Data Access
--------------------------------------------------------------------------------

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
        -- Fallback: Convert time to index (assuming 60 Hz from time 0)
        local index = time * lap.SAMPLE_RATE + 1
        lo = math.floor(index)
        hi = math.ceil(index)
        t = index - lo
    end

    lo = math.clamp(lo, 1, lapObj:length())
    hi = math.clamp(hi, 1, lapObj:length())

    -- Handle sparse fields (position-based lookup)
    local fieldData = lapObj[field]
    if lap.SPARSE_FIELDS[field] and (not fieldData or #fieldData == 0) then
        if not lapObj.pos or #lapObj.pos == 0 then return nil end
        local p1, p2 = lapObj.pos[lo], lapObj.pos[hi]
        if not p1 or not p2 then return nil end
        local pos = (lo == hi) and p1 or (p1 + (p2 - p1) * (t or 0))
        return lapObj:getSparseAtPos(field, pos)
    end

    -- Check if field exists on this lap
    if not fieldData or #fieldData == 0 then return nil end

    if lo == hi then return fieldData[lo] end

    local v1 = fieldData[lo]
    local v2 = fieldData[hi]

    if not v1 or not v2 then return v1 or v2 end
    return v1 + (v2 - v1) * t
end

local function getAxisValue(v, axis)
    if not v then return nil end
    if axis == "x" then return v.x end
    if axis == "y" then return v.y end
    if axis == "z" then return v.z end
    return nil
end

-- Get G-force axis at time from lap (using times array if available, else sample rate)
local function getGForceAtTime(lapObj, time, axis)
    if not lapObj or not lapObj.gforce or #lapObj.gforce < 2 then return nil end

    local lo, hi, t
    if lapObj.times and #lapObj.times >= lapObj:length() then
        local times = lapObj.times
        lo, hi = 1, #times
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
        local index = time * lap.SAMPLE_RATE + 1
        lo = math.floor(index)
        hi = math.ceil(index)
        t = index - lo
    end

    lo = math.clamp(lo, 1, lapObj:length())
    hi = math.clamp(hi, 1, lapObj:length())

    local v1 = getAxisValue(lapObj.gforce[lo], axis)
    local v2 = getAxisValue(lapObj.gforce[hi], axis)
    if v1 == nil then return nil end
    if lo == hi or v2 == nil then return v1 end
    return v1 + (v2 - v1) * (t or 0)
end

-- Get G-force axis at position from lap (position-based)
local function getGForceAtPos(lapObj, targetPos, axis)
    if not lapObj or not lapObj.gforce or #lapObj.gforce < 2 then return nil end
    if not lapObj.pos or #lapObj.pos < 2 then return nil end

    local lo, hi = 1, #lapObj.pos
    while hi - lo > 1 do
        local mid = math.floor((lo + hi) / 2)
        if lapObj.pos[mid] <= targetPos then
            lo = mid
        else
            hi = mid
        end
    end

    local p1, p2 = lapObj.pos[lo], lapObj.pos[hi]
    local v1 = getAxisValue(lapObj.gforce[lo], axis)
    local v2 = getAxisValue(lapObj.gforce[hi], axis)
    if v1 == nil then return nil end
    if p1 == p2 or v2 == nil then return v1 end
    local t = math.clamp((targetPos - p1) / (p2 - p1), 0, 1)
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

--------------------------------------------------------------------------------
-- Trace Drawing
--------------------------------------------------------------------------------

-- Draw time-based trace with proper scaling
-- Note: Reference lap is compared by POSITION, not time (for proper alignment)
-- accessor: function(lapObj, pos) that returns value at position
local function drawTimeTrace(x, y, w, h, startTime, endTime, lapObj, refLapObj, accessor, color, refColor, minVal, maxVal, label, unit)
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
         local pos = getValueAtTime(lapObj, t, "pos")  -- Get position first
         
         -- Use accessor function for the actual value
         local actualVal = pos and accessor(lapObj, pos) or nil
         
         if actualVal ~= nil then
             table.insert(values, actualVal)
             table.insert(positions, pos)
             if not minVal or not maxVal then
                 actualMin = math.min(actualMin, actualVal)
                 actualMax = math.max(actualMax, actualVal)
             end
         else
             table.insert(values, 0)
             table.insert(positions, nil)
         end

         -- Get reference value at SAME POSITION (not same time) for proper alignment
         -- Apply position offset for lap alignment adjustment
          if refLapObj and pos then
              local offsetPos = (pos + refPosOffset) % 1.0  -- Wrap around 0-1
              local refVal = accessor(refLapObj, offsetPos)
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
        ui.drawLine(vec2(x, py), vec2(x + w, py), i == gridLines / 2 and theme.grid.major or theme.grid.line, 1)

        ui.setCursor(vec2(x - 50, py - 7))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
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

         local cursorPos = getValueAtTime(lapObj, cursorTime, "pos")
         local cursorVal = cursorPos and accessor(lapObj, cursorPos) or nil
         if cursorVal ~= nil then
             local cursorY = y + h - ((cursorVal - minVal) / range) * h
             ui.drawCircleFilled(vec2(cursorX, cursorY), 6, color, 16)
             ui.drawCircle(vec2(cursorX, cursorY), 6, theme.marker.cursor, 16, 2)
         end

         -- Get reference value at SAME POSITION (not same time)
         if refLapObj and cursorPos then
             local refVal = accessor(refLapObj, cursorPos)
             if refVal ~= nil then
                 local refY = y + h - ((refVal - minVal) / range) * h
                 ui.drawCircleFilled(vec2(cursorX, refY), 5, refColor, 12)
             end
         end
     end

    -- Trace label
    ui.setCursor(vec2(x + 5, y + 2))
    ui_utils.textFont(label, ui.Font.Small, theme.text.primary)
end

-- Draw lateral G trace (x-axis of car acceleration)
local function drawLatGTrace(x, y, w, h, startTime, endTime, lapObj, refLapObj)
    if not lapObj or lapObj:length() < 2 then return end
    if endTime <= startTime then return end

    local numSamples = math.max(10, math.floor(w / 2))
    local timeStep = (endTime - startTime) / numSamples

    local values = {}
    local refValues = {}
    local positions = {}
    local actualMin = math.huge
    local actualMax = -math.huge

    for i = 0, numSamples do
        local t = startTime + i * timeStep
        local val = getGForceAtTime(lapObj, t, "x")
        local pos = getValueAtTime(lapObj, t, "pos")

        if val ~= nil then
            table.insert(values, val)
            table.insert(positions, pos)
            actualMin = math.min(actualMin, val)
            actualMax = math.max(actualMax, val)
        else
            table.insert(values, 0)
            table.insert(positions, nil)
        end

        if refLapObj and pos then
            local refVal = getGForceAtPos(refLapObj, pos, "x")
            if refVal ~= nil then
                table.insert(refValues, refVal)
                actualMin = math.min(actualMin, refVal)
                actualMax = math.max(actualMax, refVal)
            else
                table.insert(refValues, 0)
            end
        elseif refLapObj then
            table.insert(refValues, 0)
        end
    end

    if #values < 2 then return end

    local maxAbs = math.max(math.abs(actualMin), math.abs(actualMax), 0.5)
    local minVal = -maxAbs
    local maxVal = maxAbs
    local range = maxVal - minVal
    if range <= 0 then return end

    -- Draw grid lines
    local gridLines = 5
    for i = 0, gridLines do
        local val = minVal + (maxVal - minVal) * (i / gridLines)
        local py = y + h - (i / gridLines) * h
        ui.drawLine(vec2(x, py), vec2(x + w, py), i == gridLines / 2 and theme.grid.major or theme.grid.line, 1)

        ui.setCursor(vec2(x - 50, py - 7))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        ui.text(string.format("%.1fg", val))
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
        ui.pathStroke(theme.ghost.speed, false, 1.5)
    end

    -- Draw current trace
    ui.pathClear()
    for i = 1, #values do
        local px = x + (i - 1) / (#values - 1) * w
        local py = y + h - ((values[i] - minVal) / range) * h
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathStroke(theme.trace.speed, false, 2)

    -- Cursor markers
    if cursorTime and cursorTime >= startTime and cursorTime <= endTime then
        local cursorX = x + ((cursorTime - startTime) / (endTime - startTime)) * w
        local cursorVal = getGForceAtTime(lapObj, cursorTime, "x")
        local cursorPos = getValueAtTime(lapObj, cursorTime, "pos")
        if cursorVal ~= nil then
            local cursorY = y + h - ((cursorVal - minVal) / range) * h
            ui.drawCircleFilled(vec2(cursorX, cursorY), 6, theme.trace.speed, 16)
            ui.drawCircle(vec2(cursorX, cursorY), 6, theme.marker.cursor, 16, 2)
        end

        if refLapObj and cursorPos then
            local refVal = getGForceAtPos(refLapObj, cursorPos, "x")
            if refVal ~= nil then
                local refY = y + h - ((refVal - minVal) / range) * h
                ui.drawCircleFilled(vec2(cursorX, refY), 5, theme.ghost.speed, 12)
            end
        end
    end

    -- Trace label
    ui.setCursor(vec2(x + 5, y + 2))
    ui_utils.textFont("Lat G", ui.Font.Small, theme.text.primary)
end

--------------------------------------------------------------------------------
-- Corner Zone Drawing
--------------------------------------------------------------------------------

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
            -- Apply position offset for lap alignment adjustment
            local selectedTime = selectedLap:getTimeAtPos(pos)
            local offsetPos = (pos + refPosOffset) % 1.0  -- Wrap around 0-1
            local refTime = refLapObj:getTimeAtPos(offsetPos)

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
    local corners = ctx and ctx.trackCorners or nil
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
                    local isFocused = corner_analysis.getFrozenCornerNum() == corner.number

                    -- Draw corner zone background
                    local cornerColor
                    if isSelected then
                        cornerColor = theme.corner.selected
                    elseif isFocused then
                        cornerColor = theme.corner.focused
                    elseif editMode then
                        cornerColor = (i % 2 == 0) and theme.corner.evenEdit or theme.corner.oddEdit
                    else
                        cornerColor = (i % 2 == 0) and theme.corner.even or theme.corner.odd
                    end
                    ui.drawRectFilled(vec2(drawStartX, y), vec2(drawEndX, y + h), cornerColor, 0)

                    -- Draw blue outline around focused corner
                    if isFocused then
                        ui.drawRect(vec2(drawStartX, y), vec2(drawEndX, y + h), theme.corner.focusedBorder, 0, 2)
                    end

                    -- Click detection for corner analysis (when not in edit mode)
                    if not editMode and ui.mouseClicked(ui.MouseButton.Left) then
                        if localMouseX >= drawStartX and localMouseX <= drawEndX and localMouseY >= y and localMouseY <= y + h then
                            -- Show this corner in corner_analysis
                            corner_analysis.setViewedCorner(corner, selectedLap, refLapObj)
                        end
                    end

                    -- Corner name in top left of zone
                    local labelText = corner.name or tostring(corner.number or i)
                    ui.pushFont(ui.Font.Small)
                    ui.setCursor(vec2(drawStartX + 3, y + 2))
                    ui.pushStyleColor(ui.StyleColor.Text, isSelected and theme.text.primary or theme.withAlpha(theme.text.primary, 0.35))
                    ui.text(labelText)
                    ui.popStyleColor()

                    -- Calculate corner delta (delta at exit - delta at entry)
                    -- Apply position offset for lap alignment adjustment
                    local entryDelta = selectedLap:getTimeAtPos(corner.startPos)
                    local exitDelta = selectedLap:getTimeAtPos(corner.endPos)
                    local refStartPos = (corner.startPos + refPosOffset) % 1.0
                    local refEndPos = (corner.endPos + refPosOffset) % 1.0
                    local refEntryTime = refLapObj:getTimeAtPos(refStartPos)
                    local refExitTime = refLapObj:getTimeAtPos(refEndPos)

                    if entryDelta and exitDelta and refEntryTime and refExitTime then
                        local currentCornerTime = exitDelta - entryDelta
                        local refCornerTime = refExitTime - refEntryTime
                        local cornerTimeDelta = currentCornerTime - refCornerTime

                        -- Draw corner delta at bottom left
                        local deltaText = ui_utils.formatDelta(cornerTimeDelta, 2)
                        local deltaColor = ui_utils.getDeltaColor(cornerTimeDelta)

                        ui.setCursor(vec2(drawStartX + 3, y + h - 14))
                        ui.pushStyleColor(ui.StyleColor.Text, theme.withAlpha(deltaColor, 0.9))
                        ui.text(deltaText)
                        ui.popStyleColor()

                        -- Draw cumulative delta at bottom right (total delta up to this corner exit)
                        local cumulativeDelta = exitDelta - refExitTime
                        local cumText = string.format("%s >>", ui_utils.formatDelta(cumulativeDelta, 2))
                        local cumColor = ui_utils.getDeltaColor(cumulativeDelta)

                        local cumTextWidth = ui.measureText(cumText).x
                        ui.setCursor(vec2(drawEndX - cumTextWidth - 3, y + h - 14))
                        ui.pushStyleColor(ui.StyleColor.Text, theme.withAlpha(cumColor, 0.7))
                        ui.text(cumText)
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
                                and theme.corner.handleHover or theme.corner.handle

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
                                and theme.corner.handleHover or theme.corner.handle

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
                    if ctx and ctx.updateCorner then
                        ctx.updateCorner(selectedCorner, { startPos = newPos })
                    end
                elseif draggingHandle == "end" then
                    if ctx and ctx.updateCorner then
                        ctx.updateCorner(selectedCorner, { endPos = newPos })
                    end
                end
            end
        end

        -- Stop dragging on mouse up
        if not ui.mouseDown(ui.MouseButton.Left) then
            draggingHandle = nil
        end
    end

    -- Zero line (use inner dimensions)
    ui.drawLine(vec2(x, innerY + innerH / 2), vec2(x + w, innerY + innerH / 2), theme.grid.major, 2)

    -- Grid (use inner dimensions)
    for i = 0, 4 do
        local py = innerY + (i / 4) * innerH
        ui.drawLine(vec2(x, py), vec2(x + w, py), theme.grid.line, 1)
    end

    -- Delta trace (use inner dimensions)
    if #deltas >= 2 then
        ui.pathClear()
        for i = 1, #deltas do
            local px = x + (i - 1) / (#deltas - 1) * w
            local py = innerY + innerH / 2 - (deltas[i] / maxDelta) * (innerH / 2)
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(theme.trace.delta, false, 2)
    end

    -- Y-axis labels (use inner dimensions)
    ui.setCursor(vec2(x - 50, innerY + innerH / 2 - 7))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text("0.00s")
    ui.popStyleColor()
    ui.popFont()

    ui.setCursor(vec2(x - 55, innerY + 2))
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text(string.format("-%.2fs", maxDelta))
    ui.popStyleColor()

    ui.setCursor(vec2(x - 55, innerY + innerH - 10))
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text(string.format("+%.2fs", maxDelta))
    ui.popStyleColor()

    -- Label
    ui.setCursor(vec2(x + 5, y + 2))
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
    ui.text("Delta-T")
    ui.popStyleColor()
end

--------------------------------------------------------------------------------
-- Time Axis
--------------------------------------------------------------------------------

-- Draw time axis
local function drawTimeAxis(x, y, w, startTime, endTime)
    if endTime <= startTime then return end

    local duration = endTime - startTime
    local majorInterval = duration > 60 and 10 or (duration > 20 and 5 or 1)

    ui.drawLine(vec2(x, y), vec2(x + w, y), theme.grid.major, 2)

    local firstMarker = math.ceil(startTime / majorInterval) * majorInterval
    for t = firstMarker, endTime, majorInterval do
        local px = x + ((t - startTime) / duration) * w
        ui.drawLine(vec2(px, y), vec2(px, y + 5), theme.grid.major, 1)

        ui.setCursor(vec2(px - 20, y + 7))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
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

--------------------------------------------------------------------------------
-- Value Panel
--------------------------------------------------------------------------------

local function drawValuePanel(panelX, panelY, panelW, panelH, selectedLap, referenceLap)
    if not cursorTime then return end

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
    cursorValues.brake = getValueAtTime(selectedLap, cursorTime, "brake")  -- Front brake
    cursorValues.brake_r = getValueAtTime(selectedLap, cursorTime, "brake_r")  -- Rear brake
    cursorValues.speed = getValueAtTime(selectedLap, cursorTime, "speed")
    cursorValues.steering = getValueAtTime(selectedLap, cursorTime, "steering")
    cursorValues.fuel = getValueAtTime(selectedLap, cursorTime, "fuel")
    cursorValues.latG = getGForceAtTime(selectedLap, cursorTime, "x")
    cursorValues.brake_balance = getValueAtTime(selectedLap, cursorTime, "brake_balance")
    cursorValues.tc_slip = getValueAtTime(selectedLap, cursorTime, "tc_slip")
    cursorValues.tc_gain = getValueAtTime(selectedLap, cursorTime, "tc_gain")

     if referenceLap and cursorValues.pos then
         -- Apply position offset for lap alignment adjustment
         local offsetPos = (cursorValues.pos + refPosOffset) % 1.0
         cursorValues.refThrottle = referenceLap:throttleAt(offsetPos)
         cursorValues.refBrake = referenceLap:brakeAt(offsetPos)
         cursorValues.refBrake_r = referenceLap:brakeRearAt(offsetPos)
         cursorValues.refSpeed = referenceLap:speedAt(offsetPos)
         cursorValues.refSteering = referenceLap:steeringAt(offsetPos)
         cursorValues.refFuel = referenceLap:fuelAt(offsetPos)
         cursorValues.refLatG = getGForceAtPos(referenceLap, offsetPos, "x")
         cursorValues.refBrakeBalance = referenceLap:brakeBalanceAt(offsetPos)
         cursorValues.refTcSlip = referenceLap:tcSlipAt(offsetPos)
         cursorValues.refTcGain = referenceLap:tcGainAt(offsetPos)
     end

    if not cursorValues.throttle then return end

    ui.drawRectFilled(vec2(panelX, panelY), vec2(panelX + panelW, panelY + panelH), theme.bg.panel, 4)
    ui.drawRect(vec2(panelX, panelY), vec2(panelX + panelW, panelY + panelH), theme.grid.major, 1)

    local py = panelY + 10
    local lineH = 20

    -- Header
    ui.setCursor(vec2(panelX + 10, py))
    ui_utils.textFont("At Cursor", ui.Font.Main, theme.text.primary)
    py = py + lineH

    ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), theme.grid.line, 1)
    py = py + 8

    -- Time (formatted as m:ss.sss)
    ui.setCursor(vec2(panelX + 10, py))
    ui.pushFont(ui.Font.Main)
    local mins = math.floor(cursorTime / 60)
    local secs = cursorTime - mins * 60
    if mins > 0 then
        ui_utils.text(string.format("%d:%06.3f", mins, secs), theme.text.primary)
    else
        ui_utils.text(string.format("%.3fs", secs), theme.text.primary)
    end
    ui.popFont()
    py = py + lineH + 5

    ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), theme.grid.line, 1)
    py = py + 8

    -- Helper to draw a value row
    local function drawRow(label, value, color, refValue, unit)
        ui.setCursor(vec2(panelX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui_utils.labelValue(label, value, panelX + 70, theme.text.muted, color)
        if refValue then
            ui.sameLine(panelX + 110)
            ui_utils.text(refValue, theme.text.muted)
        end
        ui.popFont()
        py = py + lineH
    end

    -- Delta-T
    if cursorValues.deltaTime then
        local deltaColor = ui_utils.getDeltaColor(cursorValues.deltaTime)
        drawRow("Delta-T:", ui_utils.formatDelta(cursorValues.deltaTime, 3) .. "s", deltaColor, nil)
    end

    -- Throttle
    drawRow("Throttle", ui_utils.formatPercent(cursorValues.throttle or 0, 1), theme.trace.throttle,
        cursorValues.refThrottle and string.format("(%.1f%%)", cursorValues.refThrottle * 100))

     -- Brake Front (brake = front, in bar)
     drawRow("Brake F", string.format("%.0f bar", cursorValues.brake or 0), theme.trace.brake,
         cursorValues.refBrake and string.format("(%.0f)", cursorValues.refBrake))

     -- Brake Rear (show if data exists, in bar)
     local hasBrakeR = selectedLap.brake_r and #selectedLap.brake_r > 0
     if hasBrakeR then
         drawRow("Brake R", string.format("%.0f bar", cursorValues.brake_r or 0), theme.trace.brake,
             cursorValues.refBrake_r and string.format("(%.0f)", cursorValues.refBrake_r))
     end

    -- Speed
    drawRow("Speed", string.format("%.1f", cursorValues.speed or 0), theme.trace.speed,
        cursorValues.refSpeed and string.format("(%.1f)", cursorValues.refSpeed))

    -- Lateral G (only if enabled)
    if settings.telemetryShowLateralG() and cursorValues.latG ~= nil then
        drawRow("Lat G", string.format("%.2fg", cursorValues.latG), theme.trace.speed,
            cursorValues.refLatG and string.format("(%.2fg)", cursorValues.refLatG))
    end

    -- Steering
    local steerDeg = lap.steerToDegrees(cursorValues.steering or 0.5)
    local refSteerDeg = cursorValues.refSteering and lap.steerToDegrees(cursorValues.refSteering)
    drawRow("Steering", string.format("%.1f", steerDeg), theme.trace.steering,
        refSteerDeg and string.format("(%.1f)", refSteerDeg))

    -- Brake bias (sparse)
    if cursorValues.brake_balance ~= nil then
        drawRow("Brake Bias", string.format("%.1f%%", (cursorValues.brake_balance or 0) * 100), theme.text.primary,
            cursorValues.refBrakeBalance and string.format("(%.1f%%)", cursorValues.refBrakeBalance * 100))
    end

    -- TC settings (sparse)
    if cursorValues.tc_slip ~= nil then
        drawRow("TC Slip", tostring(math.floor(cursorValues.tc_slip or 0)), theme.text.primary,
            cursorValues.refTcSlip and string.format("(%d)", math.floor(cursorValues.refTcSlip)))
    end
    if cursorValues.tc_gain ~= nil then
        drawRow("TC Gain", tostring(math.floor(cursorValues.tc_gain or 0)), theme.text.primary,
            cursorValues.refTcGain and string.format("(%d)", math.floor(cursorValues.refTcGain)))
    end

    -- Fuel (show if lap has any fuel data)
    local hasFuelData = cursorValues.fuel ~= nil
    if hasFuelData then
        drawRow("Fuel", string.format("%.1fL", cursorValues.fuel or 0), theme.trace.fuel,
            cursorValues.refFuel and string.format("(%.1fL)", cursorValues.refFuel))
    end

    -- Position
    if cursorValues.pos then
        py = py + 5
        ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), theme.grid.line, 1)
        py = py + 8

        drawRow("Position:", ui_utils.formatPercent(cursorValues.pos, 1), theme.text.primary, nil)
        drawRow("Meters:", ui_utils.formatPositionMeters(cursorValues.pos), theme.text.primary, nil)
    end

    -- CSV Source columns (for imported laps)
    if selectedLap and selectedLap.csvSource then
        py = py + 5
        ui.drawLine(vec2(panelX + 5, py), vec2(panelX + panelW - 5, py), theme.grid.line, 1)
        py = py + 8

        ui.setCursor(vec2(panelX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.accent)
        ui.text("CSV Columns")
        ui.popStyleColor()
        ui.popFont()
        py = py + lineH - 4

        local csvLineH = 14
        local src = selectedLap.csvSource

        local function drawCsvRow(rowLabel, rowValue)
            if rowValue then
                ui.setCursor(vec2(panelX + 10, py))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
                ui.text(rowLabel .. ":")
                ui.popStyleColor()
                ui.sameLine(panelX + 60)
                ui.pushStyleColor(ui.StyleColor.Text, theme.text.secondary)
                ui.text(rowValue)
                ui.popStyleColor()
                ui.popFont()
                py = py + csvLineH
            end
        end

        drawCsvRow("Track", src.track)
        drawCsvRow("Throt", src.throttle)
        drawCsvRow("Brake", src.brake)
        drawCsvRow("Speed", src.speed)
        drawCsvRow("Steer", src.steering)
        drawCsvRow("Fuel", src.fuel)
        drawCsvRow("Lat G", src.g_lat)
        drawCsvRow("Long G", src.g_long)
        drawCsvRow("Pos", src.position)
    end

    -- Help text
    py = panelY + panelH - 40
    ui.setCursor(vec2(panelX + 10, py))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text(" : Scrub")
    ui.popStyleColor()
    py = py + 15
    ui.setCursor(vec2(panelX + 10, py))
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text("R-Click: Pan")
    ui.popStyleColor()
    ui.popFont()
end

--------------------------------------------------------------------------------
-- Corner Edit Panel
--------------------------------------------------------------------------------

local function drawCornerEditPanel(panelX, contentY, contentH, panelW)
    local editPanelH = 160
    local editPanelY = contentY + contentH - editPanelH - 10

    ui.drawRectFilled(vec2(panelX, editPanelY), vec2(panelX + panelW, editPanelY + editPanelH), theme.bg.panel, 4)
    ui.drawRect(vec2(panelX, editPanelY), vec2(panelX + panelW, editPanelY + editPanelH), theme.corner.handleHover, 2)

    local epy = editPanelY + 10
    local eLineH = 22

    if selectedCorner then
        local corner = ctx and ctx.getCornerInfo and ctx.getCornerInfo(selectedCorner) or nil
        if corner then
            -- Header
            ui.setCursor(vec2(panelX + 10, epy))
            ui.pushFont(ui.Font.Main)
            ui.pushStyleColor(ui.StyleColor.Text, theme.corner.handleHover)
            ui.text(string.format("Corner %d", selectedCorner))
            ui.popStyleColor()
            ui.popFont()
            epy = epy + eLineH

            ui.drawLine(vec2(panelX + 5, epy), vec2(panelX + panelW - 5, epy), theme.grid.line, 1)
            epy = epy + 8

            -- Corner name input
            ui.setCursor(vec2(panelX + 10, epy))
            ui.pushFont(ui.Font.Small)
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
            ui.text("Name:")
            ui.popStyleColor()
            ui.popFont()

            ui.setCursor(vec2(panelX + 50, epy - 2))
            ui.pushStyleVar(ui.StyleVar.FramePadding, vec2(4, 2))
            ui.pushStyleColor(ui.StyleColor.FrameBg, theme.bg.input)
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
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
                if ctx and ctx.updateCorner then
                    ctx.updateCorner(selectedCorner, { name = newName ~= "" and newName or nil })
                end
            end

            ui.popStyleColor(2)
            ui.popStyleVar()
            epy = epy + eLineH + 4

            -- Position info
            local trackLength = ui_utils.getTrackLength()

            ui.setCursor(vec2(panelX + 10, epy))
            ui.pushFont(ui.Font.Small)
            ui_utils.labelValue("Start:", string.format("%.1f%% (%dm)", (corner.startPos or 0) * 100, math.floor((corner.startPos or 0) * trackLength)), panelX + 50)
            ui.popFont()
            epy = epy + eLineH - 4

            ui.setCursor(vec2(panelX + 10, epy))
            ui.pushFont(ui.Font.Small)
            ui_utils.labelValue("End:", string.format("%.1f%% (%dm)", (corner.endPos or 0) * 100, math.floor((corner.endPos or 0) * trackLength)), panelX + 50)
            ui.popFont()
            epy = epy + eLineH

            -- Delete corner button
            ui.setCursor(vec2(panelX + 10, epy))
            ui.pushStyleColor(ui.StyleColor.Button, theme.button.danger)
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.dangerHover)
            if ui.button("Delete Corner", vec2(panelW - 20, 0)) then
                if ctx and ctx.deleteCorner then
                    ctx.deleteCorner(selectedCorner)
                end
                selectedCorner = nil
            end
            ui.popStyleColor(2)
        end
    else
        -- No corner selected - show insert option
        ui.setCursor(vec2(panelX + 10, epy))
        ui.pushFont(ui.Font.Main)
        ui.pushStyleColor(ui.StyleColor.Text, theme.corner.handleHover)
        ui.text("Edit Corners")
        ui.popStyleColor()
        ui.popFont()
        epy = epy + eLineH

        ui.drawLine(vec2(panelX + 5, epy), vec2(panelX + panelW - 5, epy), theme.grid.line, 1)
        epy = epy + 10

        ui.setCursor(vec2(panelX + 10, epy))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        ui.text("Click a corner to edit it")
        ui.popStyleColor()
        ui.popFont()
        epy = epy + eLineH

        ui.setCursor(vec2(panelX + 10, epy))
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        local cornerCount = ctx and ctx.getCornerCount and ctx.getCornerCount() or 0
        ui.text(string.format("Corners: %d", cornerCount))
        ui.popStyleColor()
        epy = epy + eLineH + 5

        -- Insert corner button
        ui.setCursor(vec2(panelX + 10, epy))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.success)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.successHover)
        if ui.button("+ Insert Corner", vec2(panelW - 20, 0)) then
            -- Insert at cursor position
            local insertPos = cursorTime and getValueAtTime(getSelectedLap(), cursorTime, "pos") or 0.5
            if ctx and ctx.insertCorner then
                ctx.insertCorner(insertPos - 0.02, insertPos + 0.02)
            end
        end
        ui.popStyleColor(2)
    end
end

--------------------------------------------------------------------------------
-- Main Window
--------------------------------------------------------------------------------

function lap_telemetry.draw(dt, context)
    ctx = context or ctx or {}

    local windowSize = ui.availableSpace()
    if windowSize.x <= 0 or windowSize.y <= 0 then return end

    local padding = 10
    local labelW = 60

    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, theme.bg.window, 4)

    -- Header bar
    local headerH = 30
    ui.drawRectFilled(vec2(0, 0), vec2(windowSize.x, headerH), theme.bg.header, 0)

    ui.setCursor(vec2(padding, 5))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
    ui.text("Lap Telemetry")
    ui.popStyleColor()
    ui.popFont()

    -- Title bar buttons (right side)
    local viewingLap = getSelectedLap()
    local referenceLap = getReferenceLap()

    ui.pushFont(ui.Font.Small)

    -- Load Lap button (far right)
    ui.setCursor(vec2(windowSize.x - 100, 4))
    loadLapButtonPos = ui.getCursor()
    if ui.button("Load Lap...", vec2(90, 22)) then
        showRefPicker = not showRefPicker
    end

    -- Save as Reference button
    ui.setCursor(vec2(windowSize.x - 210, 4))
    if ui.button("Save as Reference", vec2(100, 22)) then
        if viewingLap then
            local path, err = csv_export.saveLap(viewingLap)
            if path then
                file_utils.invalidateCache()
                local filename = path:match("([^/\\]+)$") or path
                ac.setMessage("Reference saved", filename)
            else
                ac.setMessage("Error", err or "Failed to save reference")
            end
        else
            ac.setMessage("Error", "No lap to save")
        end
    end

    -- Copy as Markdown button
    ui.setCursor(vec2(windowSize.x - 340, 4))
    if ui.button("Copy as Markdown", vec2(120, 22)) then
        local success, msg = markdown.copyToClipboard(viewingLap, referenceLap)
        if success then
            ac.setMessage("Copied", msg)
        else
            ac.setMessage("Error", msg)
        end
    end
    if ui.itemHovered() then
        ui.setTooltip("Copy lap telemetry as Markdown for AI coaching")
    end

    -- Markers dropdown button
    ui.setCursor(vec2(windowSize.x - 420, 4))
    markersButtonPos = ui.getCursor()
    if ui.button("Markers", vec2(70, 22)) then
        showMarkersDropdown = not showMarkersDropdown
    end

    ui.popFont()

    -- Controls bar
    local controlsY = headerH + 5
    local controlsH = 25
    ui.setCursor(vec2(padding, controlsY))
    ui.pushFont(ui.Font.Small)

    if viewingLap then
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
        local lapTimeS = viewingLap.time / 1000
        local mins = math.floor(lapTimeS / 60)
        local secs = lapTimeS - mins * 60
        -- Show label based on mode: (Session Best), (CSV), or nothing for manual
        local label = ""
        if viewingLap.csvSource then
            label = " (CSV)"
        elseif autoMode then
            label = " (Session Best)"
        end
        ui.text(string.format("Lap: %d:%05.2f%s", mins, secs, label))
        ui.popStyleColor()

        -- Navigation through history
        ui.sameLine(130)
        local history = ctx and ctx.history or {}
        if #history > 0 then
            -- Find current index in history
            local currentIdx = 1
            for i, l in ipairs(history) do
                if l == viewingLap then currentIdx = i break end
            end

            if ui.button("<", vec2(30, 0)) and currentIdx > 1 then
                setSelectedLap(history[currentIdx - 1])
                viewStartTime = 0
                viewDuration = 0
            end
            ui.sameLine()
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
            ui.text(string.format("%d/%d", currentIdx, #history))
            ui.popStyleColor()
            ui.sameLine()
            if ui.button(">", vec2(30, 0)) and currentIdx < #history then
                setSelectedLap(history[currentIdx + 1])
                viewStartTime = 0
                viewDuration = 0
            end
        end

        ui.sameLine(300)
        if referenceLap then
            local refTimeS = referenceLap.time / 1000
            local refMins = math.floor(refTimeS / 60)
            local refSecs = refTimeS - refMins * 60
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.reference)
            ui.text(string.format("vs Best: %d:%05.2f", refMins, refSecs))
            ui.popStyleColor()
        else
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
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
            ui.pushStyleColor(ui.StyleColor.Button, theme.button.success)
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.successHover)
            if ui.button("Save Corners", vec2(100, 0)) then
                if ctx and ctx.saveCornersToFile then
                    ctx.saveCornersToFile()
                end
                editMode = false
                selectedCorner = nil
                draggingHandle = nil
            end
            ui.popStyleColor(2)
        else
            if ui.button("Edit Corners", vec2(100, 0)) then
                editMode = true
                selectedCorner = nil
            end
        end
    else
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        ui.text("No laps recorded")
        ui.popStyleColor()
    end

    ui.popFont()

    -- Bottom bar height for ref offset slider
    local bottomBarH = referenceLap and 28 or 0

    -- Content area (reserve space at bottom for ref offset slider)
    local contentY = headerH + controlsH + 8
    local contentH = windowSize.y - contentY - 30 - bottomBarH
    if contentH < 100 then return end

    -- Add 10px padding between traces (5 gaps for 6 traces)
    local tracePadding = 10
    local totalPadding = tracePadding * 5
    local traceH = (contentH - totalPadding) / 6
    local graphX = padding + labelW
    local panelW = 180
    local graphW = windowSize.x - padding * 2 - labelW - panelW - 10

    if viewingLap then
        -- Use viewingLap for all drawing (handles both manual and auto mode)
        local selectedLap = viewingLap
        local startTime, endTime, lapTime = getTimeRange(selectedLap)
        if viewDuration == 0 then endTime = lapTime end

        -- Mouse interaction (convert screen coords to window-local)
        local windowPos = ui.windowPos()
        local mousePos = ui.mousePos()
        local localMouseX = mousePos.x - windowPos.x
        local localMouseY = mousePos.y - windowPos.y

        -- Add invisible button to capture mouse in graph area (prevents window dragging)
        ui.setCursor(vec2(graphX, contentY))
        ui.invisibleButton("##graphArea", vec2(graphW, contentH))
        local graphHovered = ui.itemHovered()

        if graphHovered then

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
        y = y + traceH + tracePadding

        -- Throttle
        local throttleY = y
         local throttleH = traceH - 5
         drawTimeTrace(graphX, y, graphW, throttleH, startTime, endTime, selectedLap, referenceLap, function(l, p) return l:throttleAt(p) end, theme.trace.throttle, theme.ghost.throttle, 0, 1, "Throttle", "")

        -- Draw flag markers on throttle trace (TC, lockups, etc.)
        local hasFlags = selectedLap.flags and #selectedLap.flags > 0
        local showTC = settings.showFlagMarker('TC')
        local showLockup = settings.showFlagMarker('Lockup')
        local showSlip = settings.showFlagMarker('WheelSlip')
        local showOverlap = settings.showFlagMarker('Overlap')
        
        if hasFlags and (showTC or showLockup or showSlip or showOverlap) then
            local LOCKUP_ANY = bit.bor(lap.FLAGS.LOCKUP_FL, lap.FLAGS.LOCKUP_FR, 
                                       lap.FLAGS.LOCKUP_RL, lap.FLAGS.LOCKUP_RR)
            local drawnTC = false
            local drawnLockup = false
            
            for i = 1, selectedLap:length() do
                local f = selectedLap.flags[i] or 0
                if f > 0 then
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
                        if showTC and bit.band(f, lap.FLAGS.TC_ACTIVE) ~= 0 then
                            ui.drawTriangleFilled(
                                vec2(px - 3, py - 8),
                                vec2(px + 3, py - 8),
                                vec2(px, py - 2),
                                theme.marker.tc
                            )
                            drawnTC = true
                        end
                        
                        -- Lockup marker (small red square)
                        if showLockup and bit.band(f, LOCKUP_ANY) ~= 0 then
                            ui.drawRectFilled(vec2(px - 2, py - 6), vec2(px + 2, py - 2), theme.flags.lockup)
                            drawnLockup = true
                        end
                    end
                end
            end

            -- Legend for TC
            if drawnTC then
                ui.setCursor(vec2(graphX + 70, throttleY + 2))
                ui.pushFont(ui.Font.Small)
                ui.drawTriangleFilled(vec2(graphX + 70, throttleY + 4), vec2(graphX + 76, throttleY + 4), vec2(graphX + 73, throttleY + 10), theme.marker.tc)
                ui.setCursor(vec2(graphX + 80, throttleY + 2))
                ui.pushStyleColor(ui.StyleColor.Text, theme.marker.tc)
                ui.text("TC")
                ui.popStyleColor()
                ui.popFont()
            end
            
            -- Legend for Lockup
            if drawnLockup then
                local lockupLegendX = drawnTC and (graphX + 110) or (graphX + 70)
                ui.setCursor(vec2(lockupLegendX, throttleY + 2))
                ui.pushFont(ui.Font.Small)
                ui.drawRectFilled(vec2(lockupLegendX, throttleY + 5), vec2(lockupLegendX + 6, throttleY + 11), theme.flags.lockup)
                ui.setCursor(vec2(lockupLegendX + 10, throttleY + 2))
                ui.pushStyleColor(ui.StyleColor.Text, theme.flags.lockup)
                ui.text("Lockup")
                ui.popStyleColor()
                ui.popFont()
            end
        end

        y = y + traceH + tracePadding

         -- Brake (scale to brakeScaleBar from state)
         local brakeScale = ctx and ctx.brakeScaleBar or 100
         drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, function(l, p) return l:brakeAt(p) end, theme.trace.brake, theme.ghost.brake, 0, brakeScale, "Brake", " bar")
        y = y + traceH + tracePadding

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
         drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, function(l, p) return l:speedAt(p) end, theme.trace.speed, theme.ghost.speed, 0, maxSpeed, "Speed", " kmh")
        y = y + traceH + tracePadding

        -- Lateral G (optional)
        if settings.telemetryShowLateralG() then
            drawLatGTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap)
            y = y + traceH + tracePadding
        end

         -- Steering
         drawTimeTrace(graphX, y, graphW, traceH - 5, startTime, endTime, selectedLap, referenceLap, function(l, p) return l:steeringAt(p) end, theme.trace.steering, theme.ghost.steering, 0, 1, "Steering", "")

        -- Global cursor line
        if cursorTime and cursorTime >= startTime and cursorTime <= endTime then
            local cursorX = graphX + ((cursorTime - startTime) / (endTime - startTime)) * graphW
            ui.drawLine(vec2(cursorX, contentY), vec2(cursorX, contentY + contentH), theme.marker.cursor, 2)
            ui.drawRectFilled(vec2(cursorX - 3, contentY - 2), vec2(cursorX + 3, contentY + 2), theme.marker.cursor, 0)
        end

        -- Time axis (above bottom bar if present)
        drawTimeAxis(graphX, windowSize.y - 20 - bottomBarH, graphW, startTime, endTime)

        -- Value display panel
        local panelX = windowSize.x - panelW - padding
        local panelY = contentY
        local panelH = contentH

        drawValuePanel(panelX, panelY, panelW, panelH, selectedLap, referenceLap)

        -- Corner editing panel (when in edit mode)
        if editMode then
            drawCornerEditPanel(panelX, contentY, contentH, panelW)
        end
    else
        ui.setCursor(vec2(windowSize.x / 2 - 100, contentY + contentH / 2))
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        ui.text("Complete a lap to see telemetry")
        ui.popStyleColor()
    end

    -- Bottom bar: Reference offset slider (drawn at bottom of window)
    if referenceLap then
        local bottomY = windowSize.y - bottomBarH
        ui.drawRectFilled(vec2(0, bottomY), vec2(windowSize.x, windowSize.y), theme.bg.header, 0)

        ui.setCursor(vec2(padding, bottomY + 5))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        ui.text("Ref Offset:")
        ui.popStyleColor()

        ui.sameLine(80)
        ui.pushItemWidth(200)
        local newOffset = ui.slider("##refOffset", refPosOffset * 1000, -50, 50, "%.1f m")
        if newOffset then
            refPosOffset = newOffset / 1000  -- Convert back to position (0-1 scale)
        end
        ui.popItemWidth()

        ui.sameLine()
        if ui.button("Reset", vec2(50, 0)) then
            refPosOffset = 0
        end

        -- Show current offset in meters
        ui.sameLine()
        ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        local trackLength = ui_utils.getTrackLength()
        local offsetMeters = refPosOffset * trackLength
        ui.text(string.format("(%.1f m / %.3f pos)", offsetMeters, refPosOffset))
        ui.popStyleColor()

        ui.popFont()
    end

    -- Lap picker popover (drawn last to be on top)
    if showRefPicker then
        local dialogW = 340
        local dialogH = math.min(windowSize.y - 50, 600)  -- Scale with window, max 600
        -- Position dialog below the Load Lap button, right-aligned to button
        local buttonW = 90
        local dialogX = math.max(10, loadLapButtonPos.x + buttonW - dialogW)
        local dialogY = loadLapButtonPos.y + 22  -- Just below button

        -- Callbacks for lap picker
        local function onSelectCurrent(lapData, idx)
            setSelectedLap(lapData)
            viewStartTime = 0
            viewDuration = 0
            showRefPicker = false
        end

        local function onSelectReference(lapData)
            if ctx and ctx.setBestLap then
                ctx.setBestLap(lapData)
            end
            showRefPicker = false
        end

        local function onClose()
            showRefPicker = false
        end

        lap_picker.drawPopover(dialogX, dialogY, dialogW, dialogH, {
            showCurrent = true,
            showReference = true,
            onSelectCurrent = onSelectCurrent,
            onSelectReference = onSelectReference,
            onClose = onClose,
        })
    end

    -- Markers dropdown (drawn last to be on top)
    if showMarkersDropdown then
        local dropW = 160
        local dropH = 120
        local dropX = markersButtonPos.x
        local dropY = markersButtonPos.y + 22

        -- Background
        ui.drawRectFilled(vec2(dropX, dropY), vec2(dropX + dropW, dropY + dropH), theme.bg.panel, 4)
        ui.drawRect(vec2(dropX, dropY), vec2(dropX + dropW, dropY + dropH), theme.grid.major, 4, 1)

        ui.setCursor(vec2(dropX + 10, dropY + 8))
        ui.pushFont(ui.Font.Small)

        -- TC checkbox
        if ui.checkbox("Traction Control", settings.showFlagMarker('TC')) then
            settings.toggleFlagMarker('TC')
        end

        ui.setCursor(vec2(dropX + 10, dropY + 28))
        if ui.checkbox("Lockups", settings.showFlagMarker('Lockup')) then
            settings.toggleFlagMarker('Lockup')
        end

        ui.setCursor(vec2(dropX + 10, dropY + 48))
        if ui.checkbox("Wheel Slip", settings.showFlagMarker('WheelSlip')) then
            settings.toggleFlagMarker('WheelSlip')
        end

        ui.setCursor(vec2(dropX + 10, dropY + 68))
        if ui.checkbox("Pedal Overlap", settings.showFlagMarker('Overlap')) then
            settings.toggleFlagMarker('Overlap')
        end

        ui.popFont()

        -- Close button
        ui.setCursor(vec2(dropX + dropW - 25, dropY + 5))
        if ui.button("X", vec2(20, 16)) then
            showMarkersDropdown = false
        end

        -- Close if clicked outside
        local mousePos = ui.mousePos()
        local windowPos = ui.windowPos()
        local localX = mousePos.x - windowPos.x
        local localY = mousePos.y - windowPos.y
        if ui.mouseClicked(ui.MouseButton.Left) then
            if localX < dropX or localX > dropX + dropW or localY < dropY or localY > dropY + dropH then
                -- Check if not clicking on the markers button itself
                if localX < markersButtonPos.x or localX > markersButtonPos.x + 70 or
                   localY < markersButtonPos.y or localY > markersButtonPos.y + 20 then
                    showMarkersDropdown = false
                end
            end
        end
    end
end

return lap_telemetry
