-- corner.lua - Corner detection module
-- Uses state.lua for all storage and persistence

local state = require('state')

local corner = {}

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

local LABEL_COL = 0       -- Label column start
local VALUE_COL = 100     -- Value column start
local LINE_HEIGHT = 20

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
    ui.drawLine(
        ui.getCursor(), 
        ui.getCursor() + vec2(contentWidth, 0), 
        colors.separator, 1
    )
    ui.offsetCursorY(8)
    
    -- Record Corner row
    local rowY = ui.getCursorY()
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("Record Corner:")
    ui.popStyleColor()
    ui.popFont()
    
    ui.setCursor(vec2(startCursor.x + VALUE_COL, rowY))
    recordButton:control(vec2(120, 0))
    
    ui.offsetCursorY(5)
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text("Hold to mark corner zone")
    ui.popStyleColor()
    ui.popFont()
    
    ui.offsetCursorY(10)
    ui.drawLine(
        ui.getCursor(), 
        ui.getCursor() + vec2(contentWidth, 0), 
        colors.separator, 1
    )
    ui.offsetCursorY(8)
    
    -- Corner count display
    local cornerCount = state.getCornerCount()
    local hasManual = corner.hasManualCorners()
    
    rowY = ui.getCursorY()
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
    ui.text(hasManual and "Manual Corners:" or "Corners:")
    ui.popStyleColor()
    ui.popFont()
    
    ui.setCursor(vec2(startCursor.x + VALUE_COL, rowY))
    ui.pushFont(ui.Font.Main)
    ui.pushStyleColor(ui.StyleColor.Text, colors.numberValue)
    ui.text(string.format("%d", cornerCount))
    ui.popStyleColor()
    ui.popFont()
    
    ui.offsetCursorY(LINE_HEIGHT)
    
    if hasManual then
        -- Action buttons for manual corners
        ui.offsetCursorY(5)
        
        ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.15, 0.4, 0.15, 1))
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.2, 0.5, 0.2, 1))
        ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(0.25, 0.55, 0.25, 1))
        if ui.button("Save to File", vec2(95, 22)) then
            if state.saveCornersToFile() then
                ac.setMessage("Corners Saved", "Saved to corners.csv")
            end
        end
        ui.popStyleColor(3)
        
        ui.sameLine(110)
        ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.5, 0.15, 0.15, 1))
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.6, 0.2, 0.2, 1))
        ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(0.65, 0.25, 0.25, 1))
        if ui.button("Clear All", vec2(70, 22)) then
            corner.clearManualCorners()
        end
        ui.popStyleColor(3)
    else
        -- Hint text when no manual corners
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, colors.textDim)
        ui.text("Use hotkey to record manually")
        ui.popStyleColor()
        ui.popFont()
    end
    
    -- Recording indicator
    if corner.isRecording() then
        ui.offsetCursorY(10)
        ui.drawLine(
            ui.getCursor(), 
            ui.getCursor() + vec2(contentWidth, 0), 
            colors.separator, 1
        )
        ui.offsetCursorY(8)
        
        -- Blinking effect using time
        local alpha = 0.6 + 0.4 * math.sin(os.clock() * 6)
        local recColor = rgbm(1, 0.2, 0.2, alpha)
        
        ui.pushFont(ui.Font.Main)
        ui.pushStyleColor(ui.StyleColor.Text, recColor)
        ui.text("● RECORDING")
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
