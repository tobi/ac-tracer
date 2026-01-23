-- ui_utils.lua - Shared UI drawing utilities
-- Common drawing helpers used across multiple windows

local theme = require('lib.ui.theme')
local settings = require('lib.core.settings')

local ui_utils = {}

--------------------------------------------------------------------------------
-- Speed Display (handles km/h vs mph conversion based on settings)
--------------------------------------------------------------------------------

local KMH_TO_MPH = 0.621371

--- Convert speed from km/h to display units (km/h or mph based on settings)
---@param kmh number Speed in km/h
---@return number Speed in display units
function ui_utils.speed(kmh)
    if not kmh then return 0 end
    if settings.useKMH() then
        return kmh
    else
        return kmh * KMH_TO_MPH
    end
end

--- Get the current speed unit string
---@return string "km/h" or "mph"
function ui_utils.speedUnit()
    return settings.useKMH() and "km/h" or "mph"
end

--- Format speed for display (converts and adds unit)
---@param kmh number Speed in km/h
---@param includeUnit boolean|nil Include unit suffix (default true)
---@return string Formatted speed (e.g., "150 km/h" or "93 mph")
function ui_utils.speedDisplay(kmh, includeUnit)
    if not kmh then return "--" end
    if includeUnit == nil then includeUnit = true end
    local displaySpeed = ui_utils.speed(kmh)
    if includeUnit then
        return string.format("%.0f %s", displaySpeed, ui_utils.speedUnit())
    else
        return string.format("%.0f", displaySpeed)
    end
end

--- Format speed delta for display (converts to display units)
---@param deltaKmh number Speed delta in km/h
---@param includeUnit boolean|nil Include unit suffix (default false)
---@return string Formatted delta (e.g., "+5" or "+5 km/h")
function ui_utils.speedDeltaDisplay(deltaKmh, includeUnit)
    if not deltaKmh then return "--" end
    local displayDelta = ui_utils.speed(deltaKmh)
    local sign = displayDelta >= 0 and "+" or ""
    if includeUnit then
        return string.format("%s%.0f %s", sign, displayDelta, ui_utils.speedUnit())
    else
        return string.format("%s%.0f", sign, displayDelta)
    end
end

--------------------------------------------------------------------------------
-- Line Drawing
--------------------------------------------------------------------------------

--- Draw a dashed line
---@param p1 vec2 Start point
---@param p2 vec2 End point
---@param color rgbm Line color
---@param thickness number Line thickness
---@param dashLen number Length of each dash (default 5)
---@param gapLen number Length of gap between dashes (default 3)
function ui_utils.drawDashedLine(p1, p2, color, thickness, dashLen, gapLen)
    dashLen = dashLen or 5
    gapLen = gapLen or 3
    thickness = thickness or 1

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end

    local nx, ny = dx / len, dy / len
    local segmentLen = dashLen + gapLen
    local segments = math.floor(len / segmentLen)

    for i = 0, segments do
        local startDist = i * segmentLen
        local endDist = math.min(startDist + dashLen, len)
        local dashStart = vec2(p1.x + nx * startDist, p1.y + ny * startDist)
        local dashEnd = vec2(p1.x + nx * endDist, p1.y + ny * endDist)
        ui.drawLine(dashStart, dashEnd, color, thickness)
    end
end

--- Draw a dotted line (very short dashes)
---@param p1 vec2 Start point
---@param p2 vec2 End point
---@param color rgbm Line color
---@param thickness number Line thickness
function ui_utils.drawDottedLine(p1, p2, color, thickness)
    ui_utils.drawDashedLine(p1, p2, color, thickness or 1, 2, 4)
end

--------------------------------------------------------------------------------
-- Delta Formatting
--------------------------------------------------------------------------------

--- Format delta time with sign
---@param delta number Delta in seconds
---@param decimals number Number of decimal places (default 2)
---@return string Formatted delta (e.g., "+0.25", "-1.03")
function ui_utils.formatDelta(delta, decimals)
    if not delta then return "--" end
    decimals = decimals or 2
    local sign = delta >= 0 and "+" or ""
    local fmt = "%s%." .. decimals .. "f"
    return string.format(fmt, sign, delta)
end

--- Format delta with seconds suffix
---@param delta number Delta in seconds
---@return string Formatted delta (e.g., "+0.25s")
function ui_utils.formatDeltaS(delta)
    if not delta then return "--" end
    return ui_utils.formatDelta(delta, 2) .. "s"
end

--- Get color for delta (positive = behind/red, negative = ahead/green)
---@param delta number Delta value
---@param invert boolean If true, positive = good (for speed deltas)
---@return rgbm Color
function ui_utils.getDeltaColor(delta, invert)
    if not delta or delta == 0 then return theme.delta.neutral end
    if invert then
        return delta > 0 and theme.delta.positive or theme.delta.negative
    else
        return delta < 0 and theme.delta.positive or theme.delta.negative
    end
end

--------------------------------------------------------------------------------
-- Percentage Formatting
--------------------------------------------------------------------------------

--- Format a 0-1 value as percentage
---@param value number Value between 0 and 1
---@param decimals number Decimal places (default 0)
---@return string Formatted percentage
function ui_utils.formatPercent(value, decimals)
    if not value then return "--%%" end
    decimals = decimals or 0
    local fmt = "%." .. decimals .. "f%%"
    return string.format(fmt, value * 100)
end

--------------------------------------------------------------------------------
-- Trace Drawing
--------------------------------------------------------------------------------

--- Draw a telemetry trace line with optional filled area underneath
--- Works with any array of normalized 0-1 values
---@param x number Left edge X position
---@param y number Top edge Y position
---@param w number Width of trace area
---@param h number Height of trace area
---@param data table Array of values (0-1 normalized, or raw values if maxVal provided)
---@param color rgbm Trace line color
---@param opts table|nil Options: { filled, thickness, maxVal }
---  - filled: boolean - Draw filled area under line (30% more transparent than line)
---  - thickness: number - Line thickness (default 2)
---  - maxVal: number - Max value for normalization (default 1, data is 0-1)
function ui_utils.drawTrace(x, y, w, h, data, color, opts)
    if not data or #data < 2 then return end
    
    opts = opts or {}
    local thickness = opts.thickness or 2
    local filled = opts.filled or false
    local maxVal = opts.maxVal or 1
    
    local numPoints = #data
    local step = w / (numPoints - 1)
    
    -- Draw filled area first if requested (use quads for non-convex shapes)
    if filled then
        local fillColor = rgbm(color.r, color.g, color.b, color.mult * 0.7 * 0.5)  -- 30% more transparent
        local baseY = y + h
        for i = 1, numPoints - 1 do
            local val1 = math.clamp(data[i] / maxVal, 0, 1)
            local val2 = math.clamp(data[i + 1] / maxVal, 0, 1)
            local x1 = x + (i - 1) * step
            local x2 = x + i * step
            local y1 = y + h - val1 * h
            local y2 = y + h - val2 * h
            ui.drawQuadFilled(vec2(x1, y1), vec2(x2, y2), vec2(x2, baseY), vec2(x1, baseY), fillColor)
        end
    end
    
    -- Draw the line on top
    ui.pathClear()
    for i = 1, numPoints do
        local val = math.clamp(data[i] / maxVal, 0, 1)
        ui.pathLineTo(vec2(x + (i - 1) * step, y + h - val * h))
    end
    ui.pathStroke(color, false, thickness)
end

--- Draw a stepped gear trace (discrete values)
---@param x number Left edge X position
---@param y number Top edge Y position
---@param w number Width of trace area
---@param h number Height of trace area
---@param data table Array of gear values
---@param color rgbm Trace line color
---@param opts table|nil Options: { filled, thickness, maxGear }
function ui_utils.drawGearTrace(x, y, w, h, data, color, opts)
    if not data or #data < 2 then return end
    
    opts = opts or {}
    local thickness = opts.thickness or 2
    local filled = opts.filled or false
    local maxGear = opts.maxGear or 8
    
    local numPoints = #data
    local step = w / (numPoints - 1)
    
    -- Draw filled area first if requested
    if filled then
        local fillColor = rgbm(color.r, color.g, color.b, color.mult * 0.7 * 0.5)
        local prevGear = nil
        local prevX = nil
        for i = 1, numPoints do
            local gear = data[i]
            local normalized = gear > 0 and math.clamp(gear / maxGear, 0, 1) or 0
            local px = x + (i - 1) * step
            
            if prevGear ~= nil then
                local prevNorm = prevGear > 0 and math.clamp(prevGear / maxGear, 0, 1) or 0
                local prevY = y + h - prevNorm * h
                ui.drawRectFilled(vec2(prevX, prevY), vec2(px, y + h), fillColor)
            end
            
            prevGear = gear
            prevX = px
        end
    end
    
    -- Draw stepped line (horizontal segments with vertical transitions)
    local prevGear = nil
    local prevX = nil
    for i = 1, numPoints do
        local gear = data[i]
        local normalized = gear > 0 and math.clamp(gear / maxGear, 0, 1) or 0
        local px = x + (i - 1) * step
        local py = y + h - normalized * h
        
        if prevGear ~= nil then
            local prevNorm = prevGear > 0 and math.clamp(prevGear / maxGear, 0, 1) or 0
            local prevY = y + h - prevNorm * h
            
            ui.drawLine(vec2(prevX, prevY), vec2(px, prevY), color, thickness)
            if gear ~= prevGear then
                ui.drawLine(vec2(px, prevY), vec2(px, py), color, thickness)
            end
        end
        
        prevGear = gear
        prevX = px
    end
end

--------------------------------------------------------------------------------
-- Graph Helpers
--------------------------------------------------------------------------------

--- Convert track position to X coordinate in a graph
---@param pos number Track position (0-1)
---@param graphX number Graph left edge
---@param graphW number Graph width
---@return number X coordinate
function ui_utils.posToX(pos, graphX, graphW)
    return graphX + pos * graphW
end

--- Convert time to X coordinate in a time-based graph
---@param time number Time value
---@param startTime number Visible start time
---@param endTime number Visible end time
---@param graphX number Graph left edge
---@param graphW number Graph width
---@return number X coordinate
function ui_utils.timeToX(time, startTime, endTime, graphX, graphW)
    if endTime <= startTime then return graphX end
    return graphX + ((time - startTime) / (endTime - startTime)) * graphW
end

--- Convert X coordinate to time in a time-based graph
---@param x number X coordinate
---@param startTime number Visible start time
---@param endTime number Visible end time
---@param graphX number Graph left edge
---@param graphW number Graph width
---@return number Time value
function ui_utils.xToTime(x, startTime, endTime, graphX, graphW)
    if graphW <= 0 then return startTime end
    return startTime + ((x - graphX) / graphW) * (endTime - startTime)
end

--- Convert value to Y coordinate (bottom = min, top = max)
---@param value number Value to convert
---@param minVal number Minimum value
---@param maxVal number Maximum value
---@param graphY number Graph top edge
---@param graphH number Graph height
---@return number Y coordinate
function ui_utils.valueToY(value, minVal, maxVal, graphY, graphH)
    if maxVal <= minVal then return graphY + graphH / 2 end
    return graphY + graphH - ((value - minVal) / (maxVal - minVal)) * graphH
end

--------------------------------------------------------------------------------
-- Simple Widgets
--------------------------------------------------------------------------------

--- Draw colored text at current cursor position
---@param str string Text to draw
---@param color rgbm|nil Color (default primary)
function ui_utils.text(str, color)
    if color then
        ui.pushStyleColor(ui.StyleColor.Text, color)
    end
    ui.text(str)
    if color then
        ui.popStyleColor()
    end
end

--- Draw text with specific font and color
---@param str string Text to draw
---@param font any Font (e.g., ui.Font.Main, ui.Font.Small, ui.Font.Title)
---@param color rgbm|nil Color (default nil = inherit)
function ui_utils.textFont(str, font, color)
    ui.pushFont(font)
    if color then
        ui.pushStyleColor(ui.StyleColor.Text, color)
    end
    ui.text(str)
    if color then
        ui.popStyleColor()
    end
    ui.popFont()
end

--- Draw label: value pair inline (same line)
---@param label string Label text
---@param value string Value text
---@param valueX number|nil X position for value (absolute, default sameLine +5)
---@param labelColor rgbm|nil Label color (default muted)
---@param valueColor rgbm|nil Value color (default primary)
function ui_utils.labelValue(label, value, valueX, labelColor, valueColor)
    labelColor = labelColor or theme.text.muted
    valueColor = valueColor or theme.text.primary

    ui.pushStyleColor(ui.StyleColor.Text, labelColor)
    ui.text(label)
    ui.popStyleColor()
    if valueX then
        ui.sameLine(valueX)
    else
        ui.sameLine()
    end
    ui.pushStyleColor(ui.StyleColor.Text, valueColor)
    ui.text(value)
    ui.popStyleColor()
end

--- Draw a labeled value row at specific position
---@param x number X position
---@param y number Y position
---@param label string Label text
---@param value string Value text
---@param labelColor rgbm|nil Label color (default muted)
---@param valueColor rgbm|nil Value color (default primary)
---@param labelWidth number|nil Width for label column (default 60)
function ui_utils.drawLabeledValue(x, y, label, value, labelColor, valueColor, labelWidth)
    labelWidth = labelWidth or 60
    labelColor = labelColor or theme.text.muted
    valueColor = valueColor or theme.text.primary

    ui.setCursor(vec2(x, y))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, labelColor)
    ui.text(label)
    ui.popStyleColor()
    ui.sameLine(x + labelWidth)
    ui.pushStyleColor(ui.StyleColor.Text, valueColor)
    ui.text(value)
    ui.popStyleColor()
    ui.popFont()
end

--- Draw a delta stat row (label + delta value with color coding)
--- Returns the Y position for next row
---@param x number X position
---@param y number Y position
---@param label string Label text
---@param delta number|nil Delta value
---@param unit string Unit suffix (e.g., "km/h", "m")
---@param labelWidth number|nil Width for label column (default 45)
---@param lineHeight number|nil Line height (default 18)
---@return number nextY Y position for next row
function ui_utils.deltaRow(x, y, label, delta, unit, labelWidth, lineHeight)
    if delta == nil then return y end

    labelWidth = labelWidth or 45
    lineHeight = lineHeight or 18

    local sign = delta >= 0 and "+" or ""
    local rounded = math.floor(math.abs(delta) + 0.5)
    local valueColor = theme.text.primary
    if rounded ~= 0 then
        valueColor = delta > 0 and theme.delta.positive or theme.delta.negativeFaint
    end

    ui.setCursor(vec2(x, y))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text(label)
    ui.popStyleColor()
    ui.sameLine(x + labelWidth)
    ui.pushStyleColor(ui.StyleColor.Text, valueColor)
    ui.text(string.format("%s%d %s", sign, rounded, unit))
    ui.popStyleColor()
    ui.popFont()

    return y + lineHeight
end

--- Draw a neutral delta row (no color coding - for values where more/less isn't inherently good/bad)
--- Returns the Y position for next row
---@param x number X position
---@param y number Y position
---@param label string Label text
---@param delta number|nil Delta value
---@param unit string Unit suffix (e.g., "°", "m")
---@param labelWidth number|nil Width for label column (default 45)
---@param lineHeight number|nil Line height (default 18)
---@return number nextY Y position for next row
function ui_utils.neutralDeltaRow(x, y, label, delta, unit, labelWidth, lineHeight)
    if delta == nil then return y end

    labelWidth = labelWidth or 45
    lineHeight = lineHeight or 18

    local rounded = math.floor(math.abs(delta) + 0.5)
    if rounded == 0 then return y end

    local direction = delta > 0 and "more" or "less"

    ui.setCursor(vec2(x, y))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text(label)
    ui.popStyleColor()
    ui.sameLine(x + labelWidth)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
    ui.text(string.format("%d%s %s", rounded, unit, direction))
    ui.popStyleColor()
    ui.popFont()

    return y + lineHeight
end

--- Draw a position delta row (label + meters earlier/later)
--- Returns the Y position for next row
---@param x number X position
---@param y number Y position
---@param label string Label text
---@param meters number|nil Delta in meters
---@param labelWidth number|nil Width for label column (default 45)
---@param lineHeight number|nil Line height (default 18)
---@return number nextY Y position for next row
function ui_utils.positionRow(x, y, label, meters, labelWidth, lineHeight)
    if meters == nil then return y end

    labelWidth = labelWidth or 45
    lineHeight = lineHeight or 18

    local rounded = math.abs(math.floor(meters + 0.5))
    local direction = meters >= 0 and "later" or "earlier"
    local valueColor = theme.text.primary
    if rounded ~= 0 then
        valueColor = meters > 0 and theme.delta.positive or theme.delta.negativeFaint
    end

    ui.setCursor(vec2(x, y))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
    ui.text(label)
    ui.popStyleColor()
    ui.sameLine(x + labelWidth)
    ui.pushStyleColor(ui.StyleColor.Text, valueColor)
    ui.text(string.format("%dm %s", rounded, direction))
    ui.popStyleColor()
    ui.popFont()

    return y + lineHeight
end

--- Draw a separator line at current cursor Y
---@param width number Line width
---@param spacing number|nil Vertical spacing before and after (default 8)
function ui_utils.separator(width, spacing)
    spacing = spacing or 8
    ui.offsetCursorY(spacing)
    local cursor = ui.getCursor()
    ui.drawLine(cursor, cursor + vec2(width, 0), theme.grid.separator, 1)
    ui.offsetCursorY(spacing)
end

--- Draw section header with small caps style
---@param text string Header text
---@param x number|nil X position (default current cursor)
---@param color rgbm|nil Text color (default muted)
---@return number lineHeight Height used
function ui_utils.sectionLabel(text, x, color)
    color = color or theme.text.muted
    if x then ui.setCursor(vec2(x, ui.getCursor().y)) end
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, color)
    ui.text(text)
    ui.popStyleColor()
    ui.popFont()
    return 14  -- Typical small font height
end

--- Draw a simple section header with separator line
---@param x number X position
---@param y number Y position
---@param width number Available width
---@param text string Header text
---@param color rgbm|nil Text color (default primary)
---@return number New Y position after header
function ui_utils.drawSectionHeader(x, y, width, text, color)
    color = color or theme.text.primary

    ui.setCursor(vec2(x, y))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, color)
    ui.text(text)
    ui.popStyleColor()
    ui.popFont()

    y = y + 20
    ui.drawLine(vec2(x, y), vec2(x + width, y), theme.grid.separator, 1)
    return y + 8
end

--- Format and draw a time value (m:ss.sss or ss.sss)
---@param timeS number Time in seconds
---@param color rgbm|nil Text color
function ui_utils.drawTime(timeS, color)
    local mins = math.floor(timeS / 60)
    local secs = timeS - mins * 60
    local text
    if mins > 0 then
        text = string.format("%d:%06.3f", mins, secs)
    else
        text = string.format("%.3fs", secs)
    end
    ui_utils.text(text, color or theme.text.primary)
end

--- Format lap time in milliseconds to m:ss.sss string
---@param timeMs number Time in milliseconds
---@return string Formatted time
function ui_utils.formatLapTime(timeMs)
    local timeS = timeMs / 1000
    local mins = math.floor(timeS / 60)
    local secs = timeS - mins * 60
    if mins > 0 then
        return string.format("%d:%05.2f", mins, secs)
    else
        return string.format("%.2fs", secs)
    end
end

--------------------------------------------------------------------------------
-- Track Position Helpers
--------------------------------------------------------------------------------

--- Get track length in meters
---@return number Track length
function ui_utils.getTrackLength()
    local sim = ac.getSim()
    return sim and sim.trackLengthM or 5000
end

--- Convert position delta to meters
---@param currentPos number Current position (0-1)
---@param refPos number Reference position (0-1)
---@return number|nil Delta in meters (positive = later/further)
function ui_utils.positionDeltaToMeters(currentPos, refPos)
    if not currentPos or not refPos then return nil end

    local trackLength = ui_utils.getTrackLength()
    local delta = currentPos - refPos

    -- Handle wrap-around at start/finish
    if delta > 0.5 then delta = delta - 1 end
    if delta < -0.5 then delta = delta + 1 end

    return delta * trackLength
end

--- Format position as percentage
---@param pos number Position (0-1)
---@return string Formatted position (e.g., "45.2%")
function ui_utils.formatPosition(pos)
    if not pos then return "--%" end
    return string.format("%.1f%%", pos * 100)
end

--- Format position as meters
---@param pos number Position (0-1)
---@return string Formatted distance (e.g., "1234m")
function ui_utils.formatPositionMeters(pos)
    if not pos then return "--m" end
    return string.format("%dm", math.floor(pos * ui_utils.getTrackLength()))
end

--------------------------------------------------------------------------------
-- Window Management
--------------------------------------------------------------------------------

-- Auto-hide state tracking
local autoHideState = {
    hiddenWindows = {},      -- { windowId = true } for windows we auto-hid
    timeBelowThreshold = 0,  -- Seconds spent below speed threshold
    wasAboveThreshold = false, -- Were we above threshold last frame?
}
local AUTO_HIDE_RESHOW_DELAY = 4.0  -- Seconds below threshold before re-showing

--- Update auto-hide for speed-based window management
--- Call this from script.update() with dt and current speed
---@param dt number Delta time
---@param speed number Current speed (km/h)
---@param speedThreshold number Speed threshold for hiding
---@param windowIds table Array of window IDs to manage (e.g., {"main", "telemetry"})
function ui_utils.updateAutoHide(dt, speed, speedThreshold, windowIds)
    local isAboveThreshold = speed > speedThreshold

    if isAboveThreshold then
        -- Above threshold - hide windows that are visible
        autoHideState.timeBelowThreshold = 0
        autoHideState.wasAboveThreshold = true

        for _, windowId in ipairs(windowIds) do
            if ui_utils.isWindowVisible(windowId) and not autoHideState.hiddenWindows[windowId] then
                -- Window is visible and we haven't already hidden it - hide it now
                ui_utils.setWindowVisible(windowId, false)
                autoHideState.hiddenWindows[windowId] = true
            end
        end
    else
        -- Below threshold
        if autoHideState.wasAboveThreshold then
            -- Just dropped below threshold - start timer
            autoHideState.timeBelowThreshold = 0
        end

        autoHideState.timeBelowThreshold = autoHideState.timeBelowThreshold + dt

        -- Re-show after delay
        if autoHideState.timeBelowThreshold >= AUTO_HIDE_RESHOW_DELAY then
            for windowId, wasAutoHidden in pairs(autoHideState.hiddenWindows) do
                if wasAutoHidden then
                    ui_utils.setWindowVisible(windowId, true)
                end
            end
            autoHideState.hiddenWindows = {}
        end

        autoHideState.wasAboveThreshold = false
    end
end

--- Check if a window is currently auto-hidden
---@param windowId string Window ID
---@return boolean
function ui_utils.isAutoHidden(windowId)
    return autoHideState.hiddenWindows[windowId] == true
end

--- Reset auto-hide state (e.g., on session change)
function ui_utils.resetAutoHide()
    autoHideState.hiddenWindows = {}
    autoHideState.timeBelowThreshold = 0
    autoHideState.wasAboveThreshold = false
end

--- Set window visibility directly
---@param windowId string Window ID
---@param visible boolean
---@param appName string|nil App name (default "AC Tracer")
function ui_utils.setWindowVisible(windowId, visible, appName)
    appName = appName or "AC Tracer"
    local windowName = "IMGUI_LUA_" .. appName .. "_" .. windowId
    local acc = ac.accessAppWindow(windowName)

    if acc and acc:valid() then
        acc:setVisible(visible)
    end
end

--- Open a window, bringing it to foreground if already visible (no alert)
---@param windowId string Window ID (e.g., "corners", "telemetry")
---@param appName string|nil App name (default "AC Tracer")
function ui_utils.openWindow(windowId, appName)
    appName = appName or "AC Tracer"
    local windowName = "IMGUI_LUA_" .. appName .. "_" .. windowId
    local acc = ac.accessAppWindow(windowName)

    if acc and acc:valid() then
        if acc:visible() then
            -- Already visible - just bring to front
            acc:focus()
        else
            -- Not visible - make visible
            acc:setVisible(true)
        end
    end
end

--- Toggle a window's visibility (no alert message)
---@param windowId string Window ID
---@param appName string|nil App name (default "AC Tracer")
---@return boolean New visibility state
function ui_utils.toggleWindow(windowId, appName)
    appName = appName or "AC Tracer"
    local windowName = "IMGUI_LUA_" .. appName .. "_" .. windowId
    local acc = ac.accessAppWindow(windowName)

    if acc and acc:valid() then
        local newVisible = not acc:visible()
        acc:setVisible(newVisible)
        return newVisible
    end
    return false
end

--- Check if a window is visible
---@param windowId string Window ID
---@param appName string|nil App name (default "AC Tracer")
---@return boolean
function ui_utils.isWindowVisible(windowId, appName)
    appName = appName or "AC Tracer"
    local windowName = "IMGUI_LUA_" .. appName .. "_" .. windowId
    local acc = ac.accessAppWindow(windowName)
    return acc and acc:valid() and acc:visible()
end

return ui_utils
