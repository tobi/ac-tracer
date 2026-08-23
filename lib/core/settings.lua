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
-- Configurable hotkeys
--------------------------------------------------------------------------------

local trainingButton = ac.ControlButton('__AC_TRACER_TRAINING_SECTOR')
local racingLineButton = ac.ControlButton('__AC_TRACER_RACING_LINE')
local brakeBeepButton = ac.ControlButton('__AC_TRACER_BRAKE_BEEP_TOGGLE')
local comparisonModeButton = ac.ControlButton('__AC_TRACER_COMPARISON_MODE')

--- Get the training-sector button (save start, save finish, hold to return)
---@return ac.ControlButton
function M.getTrainingButton()
    return trainingButton
end

--- Get the reference racing-line mode button
---@return ac.ControlButton
function M.getRacingLineButton()
    return racingLineButton
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
    tracesEnabled = true, -- Rolling graph; pedals and steering remain visible when off

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

    -- Training sector and reference racing line
    trainingEnabled = true,
    racingLineMode = 0, -- 0=off, 1=blue position line, 2=relative-speed colors

    -- Brake beep system (countdown beeps before brakepoint)
    -- Values: "off", "on" (uses comparison lap)
    brakeBeepMode = "off",

    -- Lookahead traces (show future reference lap data)
    showFutureTraces = true,

    -- Comparison mode (what to compare current lap against)
    -- Values: "reference", "sessionBest", "recentBest", "bestCorners", "off"
    comparisonMode = "reference",

    -- Auto-save (background save of completed laps to AppData)
    autoSaveEnabled = true,
    autoSaveIncludeMD = true,  -- Also save .md and .json notes alongside .csv
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
function M.tracesEnabled() return config.tracesEnabled end

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

-- Training / racing line
function M.trainingEnabled() return config.trainingEnabled end
function M.racingLineMode() return math.floor(config.racingLineMode or 0) end
function M.setRacingLineMode(v) config.racingLineMode = math.floor(v or 0) % 3 end
function M.toggleRacingLineMode()
    config.racingLineMode = (math.floor(config.racingLineMode or 0) + 1) % 3
    return config.racingLineMode
end
function M.racingLineModeDisplay()
    local mode = M.racingLineMode()
    return mode == 1 and "Position" or (mode == 2 and "Relative speed" or "Off")
end

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

-- Auto-save
function M.autoSaveEnabled() return config.autoSaveEnabled end
function M.setAutoSaveEnabled(v) config.autoSaveEnabled = v end
function M.autoSaveIncludeMD() return config.autoSaveIncludeMD end
function M.setAutoSaveIncludeMD(v) config.autoSaveIncludeMD = v end

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

    configCheckbox("Show rolling traces", "tracesEnabled")
    hint("Turn off to keep only the live steering, gear and pedal display.")
    ui.dummy(vec2(0, 3))
    
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
    
    -- TRAINING SECTORS
    ui.header("Training Sectors")

    configCheckbox("Enable training sectors", "trainingEnabled")

    if config.trainingEnabled then
        labeledControl("Map / Return", CONTROL_WIDTH, function()
            trainingButton:control(vec2(CONTROL_WIDTH, 0))
        end)
        hint("First press saves the start, second saves the finish; hold to return and release to start.")
    end

    ui.dummy(vec2(0, 8))

    -- REFERENCE RACING LINE
    ui.header("Reference Racing Line")
    labeledControl("Cycle Mode", CONTROL_WIDTH, function()
        racingLineButton:control(vec2(CONTROL_WIDTH, 0))
    end)
    ui.text("Mode")
    ui.sameLine(ui.availableSpaceX() - 150)
    if ui.radioButton("Off##line", config.racingLineMode == 0) then config.racingLineMode = 0 end
    ui.sameLine()
    if ui.radioButton("Line##line", config.racingLineMode == 1) then config.racingLineMode = 1 end
    ui.sameLine()
    if ui.radioButton("Speed##line", config.racingLineMode == 2) then config.racingLineMode = 2 end
    hint("Requires a reference lap with MoTeC GPS or chassis world-position channels.")
    
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
    
    -- AUTO-SAVE
    ui.header("Auto-Save")
    
    configCheckbox("Auto-save completed laps", "autoSaveEnabled")
    if config.autoSaveEnabled then
        configCheckbox("Include MD + JSON notes", "autoSaveIncludeMD")
        hint("Saves to %APPDATA%\\ac-tracer\\")
    end
    
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
