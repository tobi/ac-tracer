-- Settings module for AC Tracer
-- Uses ac.storage for automatic persistence (no manual save needed)

local lap_picker = require('lap_picker')
local ui_utils = require('ui_utils')

local M = {}

-- Persistent settings using ac.storage (auto-saves on assignment)
-- Uses "ac_tracer/" prefix for all keys
local config = ac.storage({
    -- Display toggles
    displayThrottle = true,
    displayBrake = true,
    displayClutch = false,
    displaySteering = false,
    displaySpeed = false,

    -- Telemetry window
    telemetryAutoHide = true,
    telemetryAutoHideSpeed = 20,

    -- Flag annotations (telemetry window markers)
    showTCMarkers = true,
    showLockupMarkers = true,
    showWheelSlipMarkers = false,
    showOverlapMarkers = false,

    -- General
    useKMH = true,

    -- Detection thresholds
    brakeThreshold = 5,
    throttleThreshold = 0.98,
    speedDropThreshold = 0.05,

    -- Trace settings
    timeWindow = 12,
    sampleRate = 15,
    thickness = 2,
    steeringCapDeg = 180,
}, "ac_tracer/")

-- Export settings as module properties (for compatibility)
M.useKMH = config.useKMH
M.telemetryAutoHide = config.telemetryAutoHide
M.telemetryAutoHideSpeed = config.telemetryAutoHideSpeed
M.brakeThreshold = config.brakeThreshold
M.throttleThreshold = config.throttleThreshold
M.speedDropThreshold = config.speedDropThreshold
M.timeWindow = config.timeWindow
M.sampleRate = config.sampleRate
M.thickness = config.thickness
M.steeringCap = config.steeringCapDeg * math.pi / 180

-- Flag annotation settings (direct access via config)
M.flagMarkers = {
    tc = function() return config.showTCMarkers end,
    lockup = function() return config.showLockupMarkers end,
    wheelSlip = function() return config.showWheelSlipMarkers end,
    overlap = function() return config.showOverlapMarkers end,
}

-- Toggle flag marker setting
function M.toggleFlagMarker(flag)
    local key = 'show' .. flag:sub(1,1):upper() .. flag:sub(2) .. 'Markers'
    config[key] = not config[key]
end

-- Get flag marker setting
function M.showFlagMarker(flag)
    local key = 'show' .. flag:sub(1,1):upper() .. flag:sub(2) .. 'Markers'
    return config[key]
end

-- Display table (for compatibility with existing code)
M.display = {
    throttle = config.displayThrottle,
    brake = config.displayBrake,
    clutch = config.displayClutch,
    steering = config.displaySteering,
    speed = config.displaySpeed,
}

-- UI helper: toggle checkbox that auto-saves
function M.checkbox(label, key)
    local configKey = 'display' .. key:sub(1, 1):upper() .. key:sub(2)
    if ui.checkbox(label, config[configKey]) then
        config[configKey] = not config[configKey]
        M.display[key] = config[configKey]
    end
end

-- Settings window UI (simplified)
function M.windowSettings()
    ui.text("Display Traces")
    ui.offsetCursorY(5)

    M.checkbox("Throttle", "throttle")
    ui.sameLine(120)
    M.checkbox("Brake", "brake")
    ui.sameLine(200)
    M.checkbox("Steering", "steering")

    M.checkbox("Clutch", "clutch")
    ui.sameLine(120)
    M.checkbox("Speed", "speed")
    ui.offsetCursorY(10)

    ui.separator()
    ui.offsetCursorY(10)

    -- Telemetry auto-hide settings
    ui.text("Telemetry Window")
    ui.offsetCursorY(5)

    if ui.checkbox("Auto-hide above speed", config.telemetryAutoHide) then
        config.telemetryAutoHide = not config.telemetryAutoHide
        M.telemetryAutoHide = config.telemetryAutoHide
    end

    ui.sameLine(180)
    ui.pushItemWidth(60)
    local newSpeed = ui.slider("##autohidespeed", config.telemetryAutoHideSpeed, 5, 100, "%.0f km/h")
    if newSpeed ~= config.telemetryAutoHideSpeed then
        config.telemetryAutoHideSpeed = newSpeed
        M.telemetryAutoHideSpeed = config.telemetryAutoHideSpeed
    end
    ui.popItemWidth()
    ui.offsetCursorY(10)

    ui.separator()
    ui.offsetCursorY(10)

    -- Reference lap section
    ui.text("Reference Lap")
    ui.offsetCursorY(5)
    lap_picker.drawCompact()

    ui.offsetCursorY(5)
    if ui.button("Load Reference Lap...", vec2(150, 0)) then
        ui_utils.openWindow("referencelap")
    end
end

return M
