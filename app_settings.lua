-- Settings module for AC Tracer
-- Uses ac.storage for automatic persistence (no manual save needed)
-- All settings accessed via accessor functions for live updates

local lap_picker = require('lap_picker')
local theme = require('theme')

-- Deferred require to avoid circular dependency (ui_utils requires settings)
local ui_utils = nil
local function getUiUtils()
    if not ui_utils then
        ui_utils = require('ui_utils')
    end
    return ui_utils
end

local M = {}

--------------------------------------------------------------------------------
-- Checkpoint Keybinds (using ac.ControlButton for configurable keys)
--------------------------------------------------------------------------------

local saveCheckpointButton = ac.ControlButton('__AC_TRACER_SAVE_CHECKPOINT')
local loadCheckpointButton = ac.ControlButton('__AC_TRACER_LOAD_CHECKPOINT')
local brakeBeepButton = ac.ControlButton('__AC_TRACER_BRAKE_BEEP_TOGGLE')

--- Get the save checkpoint button (for polling in main loop)
---@return ac.ControlButton
function M.getSaveCheckpointButton()
    return saveCheckpointButton
end

--- Get the load checkpoint button (for polling in main loop)
---@return ac.ControlButton
function M.getLoadCheckpointButton()
    return loadCheckpointButton
end

--- Get the brake beep toggle button (for polling in main loop)
---@return ac.ControlButton
function M.getBrakeBeepButton()
    return brakeBeepButton
end

--------------------------------------------------------------------------------
-- Persistent Config (ac.storage auto-saves on assignment)
--------------------------------------------------------------------------------

local config = ac.storage({
    -- Display toggles (which traces to show)
    displayThrottle = true,
    displayBrake = true,
    displayClutch = false,
    displaySteering = false,
    displaySpeed = false,
    displayGear = false,  -- Stepped gear trace (discrete values)

    -- Units
    useKMH = true,

    -- Trace display (rolling buffer in main window)
    timeWindow = 12,      -- seconds of history to show
    sampleRate = 20,      -- Hz for trace display (visual only, not lap recording)

    -- History
    maxHistoryLaps = 50,  -- max laps to retain in memory

    -- Telemetry window
    telemetryAutoHide = true,
    telemetryAutoHideSpeed = 20,
    telemetryShowLateralG = true,  -- Show lateral G trace in telemetry

    -- Flag markers (shown in trace window and telemetry)
    showTCMarkers = false,
    showLockupMarkers = true,
    showWheelSlipMarkers = false,
    showOverlapMarkers = false,

    -- Detection thresholds (hidden from UI - advanced tuning)
    brakeThreshold = 5,        -- bar - when to consider "braking"
    throttleThreshold = 0.98,  -- 0-1 - when to consider "full throttle"
    speedDropThreshold = 0.05, -- fraction - corner detection sensitivity

    -- Checkpoint system
    checkpointEnabled = true,  -- Enable/disable checkpoint save/load

    -- Brake beep system (countdown beeps before brakepoint)
    -- Values: "off", "ref" (reference lap), "session" (best in session)
    brakeBeepMode = "off",

    -- Brake marker system (3D line on track at brakepoint)
    -- Values: "off", "next" (next corner only), "all" (all visible corners)
    brakeMarkerMode = "next",

    -- Lookahead traces (show future reference lap data)
    showFutureTraces = true,
}, "ac_tracer/")

--------------------------------------------------------------------------------
-- Accessor Functions (always return current value from config)
--------------------------------------------------------------------------------

-- Display toggles
function M.displayThrottle() return config.displayThrottle end
function M.displayBrake() return config.displayBrake end
function M.displayClutch() return config.displayClutch end
function M.displaySteering() return config.displaySteering end
function M.displaySpeed() return config.displaySpeed end
function M.displayGear() return config.displayGear end

-- Units
function M.useKMH() return config.useKMH end
function M.setUseKMH(v) config.useKMH = v end

-- Trace display
function M.timeWindow() return config.timeWindow end
function M.sampleRate() return config.sampleRate end

-- History
function M.maxHistoryLaps() return config.maxHistoryLaps end

-- Telemetry window
function M.telemetryAutoHide() return config.telemetryAutoHide end
function M.telemetryAutoHideSpeed() return config.telemetryAutoHideSpeed end
function M.telemetryShowLateralG() return config.telemetryShowLateralG end

-- Detection thresholds
function M.brakeThreshold() return config.brakeThreshold end
function M.throttleThreshold() return config.throttleThreshold end
function M.speedDropThreshold() return config.speedDropThreshold end

-- Checkpoint system
function M.checkpointEnabled() return config.checkpointEnabled end

-- Brake beep system
--- Get brake beep mode: "off", "ref", or "session"
function M.brakeBeepMode() return config.brakeBeepMode or "off" end

--- Set brake beep mode
function M.setBrakeBeepMode(mode) config.brakeBeepMode = mode end

--- Toggle brake beep mode: off -> ref -> session -> off
function M.toggleBrakeBeepMode()
    local current = config.brakeBeepMode or "off"
    if current == "off" then
        config.brakeBeepMode = "ref"
    elseif current == "ref" then
        config.brakeBeepMode = "session"
    else
        config.brakeBeepMode = "off"
    end
    return config.brakeBeepMode
end

--- Get display name for brake beep mode
function M.brakeBeepModeDisplay()
    local mode = config.brakeBeepMode or "off"
    if mode == "ref" then return "Reference Lap"
    elseif mode == "session" then return "Session Best"
    else return "Off"
    end
end

-- Brake marker system (3D line on track)
--- Get brake marker mode: "off", "next", or "all"
function M.brakeMarkerMode() return config.brakeMarkerMode or "next" end

--- Set brake marker mode
function M.setBrakeMarkerMode(mode) config.brakeMarkerMode = mode end

-- Lookahead/future traces from reference lap
function M.showFutureTraces() return config.showFutureTraces end
function M.setShowFutureTraces(v) config.showFutureTraces = v end

--------------------------------------------------------------------------------
-- Flag Marker Accessors
--------------------------------------------------------------------------------

--- Check if a flag marker type is enabled
---@param flag string Flag type: 'TC', 'Lockup', 'WheelSlip', 'Overlap'
---@return boolean
function M.showFlagMarker(flag)
    local key = 'show' .. flag .. 'Markers'
    return config[key] or false
end

--- Toggle a flag marker type
---@param flag string Flag type: 'TC', 'Lockup', 'WheelSlip', 'Overlap'
function M.toggleFlagMarker(flag)
    local key = 'show' .. flag .. 'Markers'
    config[key] = not config[key]
end

--------------------------------------------------------------------------------
-- Settings Window UI
--------------------------------------------------------------------------------

local function sectionHeader(text)
    ui.pushFont(ui.Font.Small)
    ui.textColored(text, theme.text.muted)
    ui.popFont()
    ui.offsetCursorY(4)
end

local function checkbox(label, getter, setter)
    if ui.checkbox(label, getter()) then
        setter(not getter())
    end
end

function M.windowSettings()
    local windowWidth = ui.availableSpaceX()
    
    -- TRACES section
    sectionHeader("TRACES")
    
    -- Row 1: Throttle, Brake, Clutch
    if ui.checkbox("Throttle", config.displayThrottle) then
        config.displayThrottle = not config.displayThrottle
    end
    ui.sameLine(100)
    if ui.checkbox("Brake", config.displayBrake) then
        config.displayBrake = not config.displayBrake
    end
    ui.sameLine(180)
    if ui.checkbox("Clutch", config.displayClutch) then
        config.displayClutch = not config.displayClutch
    end
    
    -- Row 2: Steering, Speed, Gear
    if ui.checkbox("Steering", config.displaySteering) then
        config.displaySteering = not config.displaySteering
    end
    ui.sameLine(100)
    if ui.checkbox("Speed", config.displaySpeed) then
        config.displaySpeed = not config.displaySpeed
    end
    ui.sameLine(180)
    if ui.checkbox("Gear", config.displayGear) then
        config.displayGear = not config.displayGear
    end
    
    ui.offsetCursorY(6)
    
    -- Trace parameters
    ui.text("Window:")
    ui.sameLine(60)
    ui.setNextItemWidth(50)
    local newWindow = ui.slider("##timewindow", config.timeWindow, 5, 30, "%.0f s")
    if newWindow ~= config.timeWindow then
        config.timeWindow = newWindow
    end
    
    ui.sameLine(140)
    ui.text("Rate:")
    ui.sameLine(175)
    ui.setNextItemWidth(50)
    local newRate = ui.slider("##samplerate", config.sampleRate, 10, 60, "%.0f Hz")
    if newRate ~= config.sampleRate then
        config.sampleRate = newRate
    end
    
    ui.offsetCursorY(6)
    
    if ui.checkbox("Show future traces from ref", config.showFutureTraces) then
        config.showFutureTraces = not config.showFutureTraces
    end
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- UNITS section
    sectionHeader("UNITS")
    
    ui.text("Speed:")
    ui.sameLine(60)
    if ui.radioButton("km/h", config.useKMH) then
        config.useKMH = true
    end
    ui.sameLine(120)
    if ui.radioButton("mph", not config.useKMH) then
        config.useKMH = false
    end
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- HISTORY section
    sectionHeader("HISTORY")
    
    ui.text("Max laps:")
    ui.sameLine(70)
    ui.setNextItemWidth(60)
    local newMax = ui.slider("##maxlaps", config.maxHistoryLaps, 10, 100, "%.0f")
    if newMax ~= config.maxHistoryLaps then
        config.maxHistoryLaps = math.floor(newMax)
    end
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- MARKERS section
    sectionHeader("MARKERS")
    
    if ui.checkbox("Traction Control", config.showTCMarkers) then
        config.showTCMarkers = not config.showTCMarkers
    end
    ui.sameLine(140)
    if ui.checkbox("Lockups", config.showLockupMarkers) then
        config.showLockupMarkers = not config.showLockupMarkers
    end
    
    if ui.checkbox("Wheel Slip", config.showWheelSlipMarkers) then
        config.showWheelSlipMarkers = not config.showWheelSlipMarkers
    end
    ui.sameLine(140)
    if ui.checkbox("Pedal Overlap", config.showOverlapMarkers) then
        config.showOverlapMarkers = not config.showOverlapMarkers
    end
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- TELEMETRY WINDOW section
    sectionHeader("TELEMETRY WINDOW")
    
    if ui.checkbox("Auto-hide above", config.telemetryAutoHide) then
        config.telemetryAutoHide = not config.telemetryAutoHide
    end
    ui.sameLine(130)
    ui.setNextItemWidth(50)
    local newSpeed = ui.slider("##autohidespeed", config.telemetryAutoHideSpeed, 5, 100, "%.0f")
    if newSpeed ~= config.telemetryAutoHideSpeed then
        config.telemetryAutoHideSpeed = newSpeed
    end
    ui.sameLine()
    ui.text(config.useKMH and "km/h" or "mph")
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- CHECKPOINT section
    sectionHeader("CHECKPOINT (Practice Rewind)")
    
    if ui.checkbox("Enable checkpoint system", config.checkpointEnabled) then
        config.checkpointEnabled = not config.checkpointEnabled
    end
    
    if config.checkpointEnabled then
        ui.offsetCursorY(4)
        ui.text("Save:")
        ui.sameLine(50)
        saveCheckpointButton:control(vec2(120, 0))
        
        ui.text("Load:")
        ui.sameLine(50)
        loadCheckpointButton:control(vec2(120, 0))
        
        ui.offsetCursorY(2)
        ui.pushFont(ui.Font.Small)
        ui.textColored("Press Save to capture position, Load to teleport back.", theme.text.muted)
        ui.popFont()
    end
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- BRAKE BEEP section
    sectionHeader("BRAKE BEEP (Audio Cue)")
    
    ui.text("Mode:")
    ui.sameLine(50)
    if ui.radioButton("Off##beep", config.brakeBeepMode == "off") then
        config.brakeBeepMode = "off"
    end
    ui.sameLine(90)
    if ui.radioButton("Ref##beep", config.brakeBeepMode == "ref") then
        config.brakeBeepMode = "ref"
    end
    ui.sameLine(140)
    if ui.radioButton("Session##beep", config.brakeBeepMode == "session") then
        config.brakeBeepMode = "session"
    end
    
    ui.offsetCursorY(4)
    ui.text("Toggle:")
    ui.sameLine(50)
    brakeBeepButton:control(vec2(120, 0))
    
    ui.offsetCursorY(2)
    ui.pushFont(ui.Font.Small)
    ui.textColored("Beeps countdown to brakepoint from selected lap.", theme.text.muted)
    ui.popFont()
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- BRAKE MARKER section
    sectionHeader("BRAKE MARKER (Track Line)")
    
    ui.text("Mode:")
    ui.sameLine(50)
    if ui.radioButton("Off##marker", config.brakeMarkerMode == "off") then
        config.brakeMarkerMode = "off"
    end
    ui.sameLine(90)
    if ui.radioButton("Next##marker", config.brakeMarkerMode == "next") then
        config.brakeMarkerMode = "next"
    end
    ui.sameLine(145)
    if ui.radioButton("All##marker", config.brakeMarkerMode == "all") then
        config.brakeMarkerMode = "all"
    end
    
    ui.offsetCursorY(2)
    ui.pushFont(ui.Font.Small)
    ui.textColored("Shows red line on track at brakepoint from ref lap.", theme.text.muted)
    ui.popFont()
    
    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- REFERENCE LAP section
    sectionHeader("REFERENCE LAP")
    
    lap_picker.drawCompact()
    
    ui.offsetCursorY(5)
    if ui.button("Load Reference Lap...", vec2(150, 0)) then
        getUiUtils().openWindow("referencelap")
    end
end

return M
