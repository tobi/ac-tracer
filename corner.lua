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

function corner.settingsUI(recordButton)
    ui.text("Corner Detection")
    ui.separator()

    ui.text("Record Corner:")
    ui.sameLine(130)
    recordButton:control(vec2(120, 0))

    ui.offsetCursorY(5)
    ui.textColored("Hold to record, tap to skip number", rgbm(1, 1, 1, 0.5))

    ui.offsetCursorY(10)

    if corner.hasManualCorners() then
        ui.text(string.format("Manual: %d corners", state.getCornerCount()))
        
        ui.offsetCursorY(5)
        ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.2, 0.5, 0.2, 0.8))
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 0.7, 0.3, 1))
        if ui.button("Save to File", vec2(90, 0)) then
            if state.saveCornersToFile() then
                ac.setMessage("Corners Saved", "Saved to tracks folder")
            end
        end
        ui.popStyleColor(2)
        
        ui.sameLine()
        ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.6, 0.2, 0.2, 0.8))
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.8, 0.3, 0.3, 1))
        if ui.button("Clear", vec2(60, 0)) then
            corner.clearManualCorners()
        end
        ui.popStyleColor(2)
    else
        ui.text(string.format("Auto-detected: %d corners", corner.getCornerCount()))
        ui.textColored("Use hotkey to record manually", rgbm(1, 1, 1, 0.5))
    end

    if corner.isRecording() then
        ui.offsetCursorY(5)
        ui.textColored("RECORDING...", rgbm(1, 0.3, 0.3, 1))
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
