-- ui_utils.lua - Shared UI drawing utilities
-- Common drawing helpers used across multiple windows

local theme = require('theme')

local ui_utils = {}

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
-- Speed Formatting
--------------------------------------------------------------------------------

--- Format speed value
---@param speed number Speed in km/h
---@param unit string|nil Unit to append (default "km/h")
---@return string Formatted speed
function ui_utils.formatSpeed(speed, unit)
    if not speed then return "--" end
    unit = unit or "km/h"
    return string.format("%.0f %s", speed, unit)
end

--- Format speed delta with sign
---@param delta number Speed delta in km/h
---@return string Formatted delta (e.g., "+5", "-12")
function ui_utils.formatSpeedDelta(delta)
    if not delta then return "--" end
    local sign = delta >= 0 and "+" or ""
    return string.format("%s%.0f", sign, delta)
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

return ui_utils
