-- corner.lua - Corner detection module
-- Uses state.lua for all storage and persistence

local state = require('lib.state')
local theme = require('lib.ui.theme')
local ui_utils = require('lib.ui.utils')

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

local settings = require('lib.settings')

local LINE_HEIGHT = 18

function corner.settingsUI(recordButton)
    local startCursor = ui.getCursor()
    local contentWidth = ui.availableSpaceX()

    -- Section header
    ui_utils.textFont("Corner Detection", ui.Font.Main, theme.text.primary)
    ui.offsetCursorY(3)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), theme.grid.separator, 1)
    ui.offsetCursorY(8)

    -- Current track info
    local trackId = state.track or ac.getTrackID() or "Unknown"
    local trackName = trackId:gsub("_", " "):gsub("^%l", string.upper)
    ui.pushFont(ui.Font.Small)
    ui_utils.labelValue("Track:", trackName, 50, theme.text.muted, theme.text.highlight)
    ui.popFont()

    ui.offsetCursorY(4)

    -- Corner status
    local cornerCount = state.getCornerCount()
    local hasManual = corner.hasManualCorners()

    ui.pushFont(ui.Font.Small)
    if hasManual then
        ui_utils.text(string.format("✓ %d custom corners defined", cornerCount), theme.status.success)
    elseif cornerCount > 0 then
        ui_utils.text(string.format("⚡ %d auto-detected corners", cornerCount), theme.status.warning)
        ui.offsetCursorY(2)
        ui_utils.text("(from best lap - may be inaccurate)", theme.text.muted)
    else
        ui_utils.text("No corners defined yet", theme.text.muted)
        ui.offsetCursorY(2)
        ui_utils.text("Complete a lap to auto-detect corners", theme.status.warning)
    end
    ui.popFont()

    ui.offsetCursorY(10)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), theme.grid.separator, 1)
    ui.offsetCursorY(8)

    -- Manual recording hotkey
    ui_utils.textFont("Record Hotkey:", ui.Font.Small, theme.text.muted)
    ui.sameLine(95)
    recordButton:control(vec2(110, 0))

    ui.offsetCursorY(4)
    ui_utils.textFont("Hold while driving through corner", ui.Font.Small, theme.text.muted)

    ui.offsetCursorY(10)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), theme.grid.separator, 1)
    ui.offsetCursorY(8)

    -- Edit corners info and button
    ui_utils.textFont("Edit corners in Lap Telemetry view", ui.Font.Small, theme.text.muted)

    ui.offsetCursorY(5)
    ui.pushStyleColor(ui.StyleColor.Button, theme.button.primary)
    ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.primaryHover)
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
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.danger)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.dangerHover)
        if ui.button("Clear", vec2(50, 22)) then
            corner.clearManualCorners()
        end
        ui.popStyleColor(2)
    end

    -- Recording indicator
    if corner.isRecording() then
        ui.offsetCursorY(10)
        ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(contentWidth, 0), theme.grid.separator, 1)
        ui.offsetCursorY(8)

        local alpha = 0.6 + 0.4 * math.sin(os.clock() * 6)
        local recColor = theme.withAlpha(theme.status.recording, alpha)
        ui_utils.textFont("● RECORDING CORNER", ui.Font.Main, recColor)
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
