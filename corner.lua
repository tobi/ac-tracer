-- corner.lua - Corner detection module
-- Uses state.lua for all storage and persistence

local state = require('state')

local corner = {}

-- Exported icons for UI consistency
corner.ICON_CUSTOM = "✓"
corner.ICON_AUTO = "⚡"
corner.ICON_NONE = "○"

-- Track button state for recording
local recordButtonWasDown = nil

--------------------------------------------------------------------------------
-- Manual Corner Recording
--------------------------------------------------------------------------------

function corner.onRecordButtonDown(splinePos)
    state.startCornerRecording(splinePos)
end

function corner.onRecordButtonUp(splinePos)
    state.stopCornerRecording(splinePos)
end

function corner.isRecording()
    return state.isRecordingCorner()
end

function corner.hasManualCorners()
    return state.hasCorners()
end

function corner.getCornerCount()
    return state.getCornerCount()
end

function corner.clearManualCorners()
    state.clearCorners()
end

--------------------------------------------------------------------------------
-- Settings UI
--------------------------------------------------------------------------------

local settings = require('app_settings')

-- UI Colors (consistent with lap_telemetry)
local colors = {
    textDim = rgbm(0.6, 0.6, 0.6, 1),
    textBright = rgbm(1, 1, 1, 1),
    textHighlight = rgbm(0.5, 0.8, 1, 1),
    textWarning = rgbm(1, 0.8, 0.3, 1),
    textSuccess = rgbm(0.4, 1, 0.4, 1),
    textError = rgbm(1, 0.3, 0.3, 1),
    separator = rgbm(0.3, 0.3, 0.3, 0.6),
    numberValue = rgbm(0.3, 0.8, 1, 1),
}

local LINE_HEIGHT = 18

function corner.settingsUI(recordButton)
    local startCursor = ui.getCursor()
    local contentWidth = ui.availableSpaceX()
    
    -- Section header
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textBright)
    ui.text("Corner Detection")
    ui.popStyleColor()
    ui.popFont()
    
    ui.offsetCursorY(3)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), colors.separator, 1)
    ui.offsetCursorY(8)
    
    -- Current track info
    local trackId = state.track or ac.getTrackID() or "Unknown"
    local trackName = trackId:gsub("_", " "):gsub("^%l", string.upper)
    
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("Track:")
    ui.popStyleColor()
    ui.sameLine(50)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textHighlight)
    ui.text(trackName)
    ui.popStyleColor()
    ui.popFont()
    
    ui.offsetCursorY(4)
    
    -- Corner status
    local cornerCount = state.getCornerCount()
    local hasManual = corner.hasManualCorners()
    
    ui.pushFont(ui.Font.Small)
    if hasManual then
        -- Has custom corners
        ui.pushStyleColor(ui.StyleColor.Text, colors.textSuccess)
        ui.text(string.format("✓ %d custom corners defined", cornerCount))
        ui.popStyleColor()
    elseif cornerCount > 0 then
        -- Using auto-detected corners
        ui.pushStyleColor(ui.StyleColor.Text, colors.textWarning)
        ui.text(string.format("⚡ %d auto-detected corners", cornerCount))
        ui.popStyleColor()
        ui.offsetCursorY(2)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("(from best lap - may be inaccurate)")
        ui.popStyleColor()
    else
        -- No corners yet
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("No corners defined yet")
        ui.popStyleColor()
        ui.offsetCursorY(2)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textWarning)
        ui.text("Complete a lap to auto-detect corners")
        ui.popStyleColor()
    end
    ui.popFont()
    
    ui.offsetCursorY(10)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), colors.separator, 1)
    ui.offsetCursorY(8)
    
    -- Manual recording hotkey
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("Record Hotkey:")
    ui.popStyleColor()
    ui.popFont()
    ui.sameLine(95)
    recordButton:control(vec2(110, 0))
    
    ui.offsetCursorY(4)
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("Hold while driving through corner")
    ui.popStyleColor()
    ui.popFont()
    
    ui.offsetCursorY(10)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), colors.separator, 1)
    ui.offsetCursorY(8)
    
    -- Edit corners info and button
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("Edit corners in Lap Telemetry view")
    ui.popStyleColor()
    ui.popFont()
    
    ui.offsetCursorY(5)
    ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.35, 0.5, 1))
    ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.45, 0.6, 1))
    if ui.button("Open Lap Telemetry", vec2(140, 22)) then
        -- Toggle the telemetry window via CSP API
        local acc = ac.accessAppWindow("IMGUI_LUA_AC Tracer_telemetry")
        if acc and acc:valid() then
            acc:setVisible(true)
        end
    end
    ui.popStyleColor(2)
    
    if hasManual then
        ui.sameLine()
        ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.5, 0.15, 0.15, 1))
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.6, 0.2, 0.2, 1))
        if ui.button("Clear", vec2(50, 22)) then
            corner.clearManualCorners()
        end
        ui.popStyleColor(2)
    end
    
    -- Recording indicator
    if corner.isRecording() then
        ui.offsetCursorY(10)
        ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), colors.separator, 1)
        ui.offsetCursorY(8)
        
        local alpha = 0.6 + 0.4 * math.sin(os.clock() * 6)
        local recColor = rgbm(1, 0.2, 0.2, alpha)
        
        ui.pushFont(ui.Font.Main)
        ui.pushStyleColor(ui.StyleColor.Text, recColor)
        ui.text("● RECORDING CORNER")
        ui.popStyleColor()
        ui.popFont()
    end
end

--------------------------------------------------------------------------------
-- Update (handle record button)
--------------------------------------------------------------------------------

function corner.handleRecordButton(car, recordCornerButton)
    local recordButtonDown = recordCornerButton:down() == true
    if recordButtonWasDown == nil then
        recordButtonWasDown = recordButtonDown
    elseif recordButtonDown and not recordButtonWasDown then
        corner.onRecordButtonDown(car.splinePosition)
    elseif not recordButtonDown and recordButtonWasDown then
        corner.onRecordButtonUp(car.splinePosition)
    end
    recordButtonWasDown = recordButtonDown
end

--------------------------------------------------------------------------------
-- Corner Queries (delegate to state)
--------------------------------------------------------------------------------

function corner.isInCorner(pos)
    return state.isInCorner(pos)
end

function corner.getCornerInfo(num)
    return state.getCornerInfo(num)
end

function corner.getCornerList()
    return state.trackCorners
end

function corner.getCornersForPositions(positions)
    return state.getCornersForPositions(positions)
end

return corner
