-- Settings module for AC Tracer
-- Uses ac.storage for automatic persistence (no manual save needed)
-- All settings accessed via accessor functions for live updates

local lap_picker = require('lib.windows.lap_picker')
local theme = require('lib.ui.theme')

-- Deferred require to avoid circular dependency (ui_utils requires settings)
local ui_utils = nil
local function getUiUtils()
    if not ui_utils then
        ui_utils = require('lib.ui.utils')
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
local comparisonModeButton = ac.ControlButton('__AC_TRACER_COMPARISON_MODE')

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
    telemetryShowLateralG = false,  -- Show lateral G trace in telemetry

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
    -- Values: "off", "on" (uses comparison lap)
    brakeBeepMode = "off",

    -- Brake marker system (3D line on track at brakepoint)
    -- Values: "off", "next" (next corner only), "all" (all visible corners)
    brakeMarkerMode = "next",

    -- Lookahead traces (show future reference lap data)
    showFutureTraces = true,

    -- Comparison mode (what to compare current lap against)
    -- Values: "reference", "sessionBest", "recentBest", "bestCorners", "off"
    comparisonMode = "reference",
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

--- Toggle brake beep mode: off <-> on
function M.toggleBrakeBeepMode()
    local current = config.brakeBeepMode or "off"
    config.brakeBeepMode = (current == "off") and "on" or "off"
    return config.brakeBeepMode
end

--- Get display name for brake beep mode
function M.brakeBeepModeDisplay()
    local mode = config.brakeBeepMode or "off"
    return (mode == "on") and "On" or "Off"
end

-- Brake marker system (3D line on track)
--- Get brake marker mode: "off", "next", or "all"
function M.brakeMarkerMode() return config.brakeMarkerMode or "next" end

--- Set brake marker mode
function M.setBrakeMarkerMode(mode) config.brakeMarkerMode = mode end

-- Lookahead/future traces from reference lap
function M.showFutureTraces() return config.showFutureTraces end
function M.setShowFutureTraces(v) config.showFutureTraces = v end

-- Comparison mode (what to compare current lap against)
--- Get comparison mode: "reference", "sessionBest", "recentBest", "bestCorners", "off"
function M.comparisonMode() return config.comparisonMode or "reference" end

--- Set comparison mode
function M.setComparisonMode(mode) config.comparisonMode = mode end

--- Get the comparison mode button (for polling in main loop)
---@return ac.ControlButton
function M.getComparisonModeButton()
    return comparisonModeButton
end

--- Toggle comparison mode: reference -> sessionBest -> recentBest -> bestCorners -> off -> reference
function M.toggleComparisonMode()
    local current = config.comparisonMode or "reference"
    if current == "reference" then
        config.comparisonMode = "sessionBest"
    elseif current == "sessionBest" then
        config.comparisonMode = "recentBest"
    elseif current == "recentBest" then
        config.comparisonMode = "bestCorners"
    elseif current == "bestCorners" then
        config.comparisonMode = "off"
    else
        config.comparisonMode = "reference"
    end
    return config.comparisonMode
end

--- Get display name for comparison mode
function M.comparisonModeDisplay()
    local mode = config.comparisonMode or "reference"
    if mode == "reference" then return "Reference Lap"
    elseif mode == "sessionBest" then return "Session Best"
    elseif mode == "recentBest" then return "Recent Best"
    elseif mode == "bestCorners" then return "Best Corners"
    else return "Off"
    end
end

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

local CONTROL_WIDTH = 120  -- Width for keybind controls
local SLIDER_WIDTH = 80    -- Width for sliders

-- Helper: Label on left, control right-aligned
local function labeledControl(label, controlWidth, controlFn)
    ui.text(label)
    ui.sameLine(ui.availableSpaceX() - controlWidth)
    controlFn()
end

-- Helper: Hint text below a control
local function hint(text)
    ui.pushFont(ui.Font.Small)
    ui.textColored(text, theme.text.muted)
    ui.popFont()
end

-- Helper: Checkbox that auto-toggles config value
local function configCheckbox(label, key)
    if ui.checkbox(label, config[key]) then
        config[key] = not config[key]
    end
end

function M.windowSettings()
    -- TRACES
    ui.header("Traces")
    
    -- Trace toggles in a 2x3 grid
    configCheckbox("Throttle", "displayThrottle")
    ui.sameLine(90)
    configCheckbox("Brake", "displayBrake")
    ui.sameLine(165)
    configCheckbox("Clutch", "displayClutch")
    
    configCheckbox("Steering", "displaySteering")
    ui.sameLine(90)
    configCheckbox("Speed", "displaySpeed")
    ui.sameLine(165)
    configCheckbox("Gear", "displayGear")
    
    ui.dummy(vec2(0, 4))
    
    -- Window slider - right aligned
    ui.text("Time Window")
    ui.sameLine(ui.availableSpaceX() - SLIDER_WIDTH)
    ui.setNextItemWidth(SLIDER_WIDTH)
    local newWindow = ui.slider("##timewindow", config.timeWindow, 5, 30, "%.0f sec")
    if newWindow ~= config.timeWindow then config.timeWindow = newWindow end
    
    -- Rate slider - right aligned
    ui.text("Sample Rate")
    ui.sameLine(ui.availableSpaceX() - SLIDER_WIDTH)
    ui.setNextItemWidth(SLIDER_WIDTH)
    local newRate = ui.slider("##samplerate", config.sampleRate, 10, 60, "%.0f Hz")
    if newRate ~= config.sampleRate then config.sampleRate = newRate end
    
    ui.dummy(vec2(0, 2))
    configCheckbox("Show future traces from reference lap", "showFutureTraces")
    
    ui.dummy(vec2(0, 8))
    
    -- UNITS & HISTORY
    ui.header("Units & History")
    
    ui.text("Speed")
    ui.sameLine(ui.availableSpaceX() - 100)
    if ui.radioButton("km/h", config.useKMH) then config.useKMH = true end
    ui.sameLine()
    if ui.radioButton("mph", not config.useKMH) then config.useKMH = false end
    
    ui.text("Max History")
    ui.sameLine(ui.availableSpaceX() - SLIDER_WIDTH)
    ui.setNextItemWidth(SLIDER_WIDTH)
    local newMax = ui.slider("##maxlaps", config.maxHistoryLaps, 10, 100, "%.0f laps")
    if newMax ~= config.maxHistoryLaps then config.maxHistoryLaps = math.floor(newMax) end
    
    ui.dummy(vec2(0, 8))
    
    -- MARKERS
    ui.header("Flag Markers")
    
    configCheckbox("Traction Control", "showTCMarkers")
    ui.sameLine(140)
    configCheckbox("Lockups", "showLockupMarkers")
    
    configCheckbox("Wheel Slip", "showWheelSlipMarkers")
    ui.sameLine(140)
    configCheckbox("Pedal Overlap", "showOverlapMarkers")
    
    ui.dummy(vec2(0, 8))
    
    -- TELEMETRY WINDOW
    ui.header("Telemetry Window")
    
    ui.text("Auto-hide Speed")
    ui.sameLine(ui.availableSpaceX() - SLIDER_WIDTH)
    ui.setNextItemWidth(SLIDER_WIDTH)
    local newSpeed = ui.slider("##autohidespeed", config.telemetryAutoHideSpeed, 5, 100, 
        config.useKMH and "%.0f km/h" or "%.0f mph")
    if newSpeed ~= config.telemetryAutoHideSpeed then config.telemetryAutoHideSpeed = newSpeed end
    
    configCheckbox("Auto-hide when driving", "telemetryAutoHide")
    
    ui.dummy(vec2(0, 8))
    
    -- CHECKPOINT
    ui.header("Checkpoint")
    
    configCheckbox("Enable checkpoint system", "checkpointEnabled")
    
    if config.checkpointEnabled then
        labeledControl("Save", CONTROL_WIDTH, function() 
            saveCheckpointButton:control(vec2(CONTROL_WIDTH, 0)) 
        end)
        labeledControl("Load", CONTROL_WIDTH, function() 
            loadCheckpointButton:control(vec2(CONTROL_WIDTH, 0)) 
        end)
        hint("Save position, then Load to teleport back")
    end
    
    ui.dummy(vec2(0, 8))
    
    -- BRAKE BEEP
    ui.header("Brake Beep")
    
    local brakeBeepOn = config.brakeBeepMode == "on"
    if ui.checkbox("Enable brake beeps", brakeBeepOn) then
        config.brakeBeepMode = brakeBeepOn and "off" or "on"
    end
    
    labeledControl("Toggle Hotkey", CONTROL_WIDTH, function() 
        brakeBeepButton:control(vec2(CONTROL_WIDTH, 0)) 
    end)
    hint("Audio countdown to brakepoint (uses comparison lap)")
    
    ui.dummy(vec2(0, 8))
    
    -- BRAKE MARKER
    ui.header("Brake Marker")
    
    if ui.radioButton("Off##marker", config.brakeMarkerMode == "off") then config.brakeMarkerMode = "off" end
    if ui.radioButton("Next Corner##marker", config.brakeMarkerMode == "next") then config.brakeMarkerMode = "next" end
    if ui.radioButton("All Corners##marker", config.brakeMarkerMode == "all") then config.brakeMarkerMode = "all" end
    
    hint("Red line on track at brakepoint")
    
    ui.dummy(vec2(0, 8))
    
    -- COMPARISON MODE
    ui.header("Comparison Mode")
    
    if ui.radioButton("Reference Lap##comp", config.comparisonMode == "reference") then config.comparisonMode = "reference" end
    if ui.radioButton("Session Best##comp", config.comparisonMode == "sessionBest") then config.comparisonMode = "sessionBest" end
    if ui.radioButton("Recent Best##comp", config.comparisonMode == "recentBest") then config.comparisonMode = "recentBest" end
    if ui.radioButton("Best Corners##comp", config.comparisonMode == "bestCorners") then config.comparisonMode = "bestCorners" end
    if ui.radioButton("Off##comp", config.comparisonMode == "off") then config.comparisonMode = "off" end
    
    labeledControl("Toggle Hotkey", CONTROL_WIDTH, function() 
        comparisonModeButton:control(vec2(CONTROL_WIDTH, 0)) 
    end)
    hint("Ghost traces, delta, and corner analysis source")
    
    ui.dummy(vec2(0, 8))
    
    -- REFERENCE LAP
    ui.header("Reference Lap")
    
    lap_picker.drawCompact()
    
    ui.dummy(vec2(0, 4))
    if ui.button("Open Lap Picker...", vec2(-1, 0)) then
        getUiUtils().openWindow("referencelap")
    end
end

return M
