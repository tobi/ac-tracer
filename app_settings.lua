-- Settings module for AC Tracer

local lap = require('lap')
local lap_picker = require('lap_picker')
local theme = require('theme')

local M = {}

-- Load INI config
local ini = ac.INIConfig.load(__dirname .. '/settings.ini')

-- Helper to convert INI values to boolean
local function toBool(val, default)
    if val == nil then return default end
    if type(val) == "boolean" then return val end
    if type(val) == "string" then
        local lower = val:lower()
        if lower == "true" or lower == "1" then return true end
        if lower == "false" or lower == "0" then return false end
    end
    if type(val) == "number" then return val ~= 0 end
    return default
end

-- General settings
M.useKMH = toBool(ini:get('GENERAL', 'use_kmh', true), true)

-- Telemetry window auto-hide settings
M.telemetryAutoHide = toBool(ini:get('TELEMETRY', 'auto_hide', true), true)
M.telemetryAutoHideSpeed = tonumber(ini:get('TELEMETRY', 'auto_hide_speed', 20)) or 20

-- Detection parameters
M.brakeThreshold = tonumber(ini:get('DETECTION', 'brake_threshold', 0.05)) or 0.05  -- 5% brake = brake point
M.throttleThreshold = tonumber(ini:get('DETECTION', 'throttle_threshold', 0.98)) or 0.98  -- Below 98% = lift point
M.speedDropThreshold = tonumber(ini:get('DETECTION', 'speed_drop_threshold', 0.05)) or 0.05

-- Trace settings
M.timeWindow = ini:get('TRACES', 'trace_time_window', 12)
M.sampleRate = ini:get('TRACES', 'trace_sample_rate', 15)
M.thickness = ini:get('TRACES', 'trace_thickness', 1.5)
M.steeringCap = ini:get('TRACES', 'trace_steering_cap', 180) * math.pi / 180

-- Display toggles (steering and speed default to OFF)
local rawSteering = ini:get('TRACES', 'display_steering', nil)
local rawSpeed = ini:get('TRACES', 'display_speed', nil)

M.display = {
    throttle = toBool(ini:get('TRACES', 'display_throttle', true), true),
    brake = toBool(ini:get('TRACES', 'display_brake', true), true),
    clutch = toBool(ini:get('TRACES', 'display_clutch', false), false),
    steering = toBool(rawSteering, false),
    speed = toBool(rawSpeed, false),
}

-- Colors are now provided by the theme module (require('theme'))

-- UI helper: toggle checkbox that auto-saves
function M.checkbox(label, key)
    if ui.checkbox(label, M.display[key]) then
        M.display[key] = not M.display[key]
        ini:set('TRACES', 'display_' .. key, M.display[key] and "True" or "False")
        ini:save()
    end
end

-- Settings window UI
function M.windowSettings(corner, resetButton, recordCornerButton)
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

    if ui.checkbox("Auto-hide above speed", M.telemetryAutoHide) then
        M.telemetryAutoHide = not M.telemetryAutoHide
        ini:set('TELEMETRY', 'auto_hide', M.telemetryAutoHide and "True" or "False")
        ini:save()
    end

    ui.sameLine(180)
    ui.pushItemWidth(60)
    local newSpeed = ui.slider("##autohidespeed", M.telemetryAutoHideSpeed, 5, 100, "%.0f km/h")
    if newSpeed ~= M.telemetryAutoHideSpeed then
        M.telemetryAutoHideSpeed = newSpeed
        ini:set('TELEMETRY', 'auto_hide_speed', tostring(math.floor(newSpeed)))
        ini:save()
    end
    ui.popItemWidth()
    ui.offsetCursorY(10)

    ui.separator()
    ui.offsetCursorY(10)

    -- Reference lap section (compact)
    ui.text("Reference Lap")
    ui.offsetCursorY(5)
    lap_picker.drawCompact()

    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)

    -- Hotkeys section
    ui.text("Hotkeys")
    ui.offsetCursorY(5)

    ui.text("Reset Hotkey:")
    ui.sameLine(130)
    resetButton:control(vec2(120, 0))

    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)

    corner.settingsUI(recordCornerButton)
end

return M
