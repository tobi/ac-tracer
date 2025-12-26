-- Settings module for Traces app

local state = require('state')
local lap = require('lap')

local M = {}

-- Load INI config
local ini = ac.INIConfig.load(__dirname .. '/settings.ini')

-- Ghost file loader
local ghostFiles = nil
local ghostFilesLastScan = 0
local showGhostPicker = false
local isLoadingGhost = false
local ghostCache = {}  -- Cache: filename -> lap

-- Check if a file exists
local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Get track-based ghost filename (CSV)
local function getTrackGhostName()
    local trackId = ac.getTrackID()
    if not trackId then return nil end
    return trackId:gsub("[/\\:]", "_") .. ".csv"
end

-- Scan for CSV ghost files in tracks folder
local function scanGhostFiles()
    local now = os.clock()
    if ghostFiles and (now - ghostFilesLastScan) < 5 then
        return ghostFiles
    end
    
    ghostFiles = {}
    local tracksPath = __dirname .. "/tracks/"
    
    local trackGhost = getTrackGhostName()
    if trackGhost and fileExists(tracksPath .. trackGhost) then
        table.insert(ghostFiles, trackGhost)
    end
    
    local knownFiles = {"ier_daytona.csv"}
    for _, filename in ipairs(knownFiles) do
        if fileExists(tracksPath .. filename) then
            local found = false
            for _, existing in ipairs(ghostFiles) do
                if existing == filename then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(ghostFiles, filename)
            end
        end
    end
    
    ghostFilesLastScan = now
    return ghostFiles
end

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

-- Telemetry auto-hide settings
M.telemetryAutoHide = toBool(ini:get('TELEMETRY', 'auto_hide', true), true)
M.telemetryAutoHideSpeed = tonumber(ini:get('TELEMETRY', 'auto_hide_speed', 100)) or 100

-- Colors
M.colors = {
    throttle = rgbm(0, 1, 0, 0.85),
    brake = rgbm(1, 0, 0, 0.85),
    clutch = rgbm(0, 0.4, 1, 0.85),
    steering = rgbm(0.7, 0.7, 0.7, 0.85),
    speed = rgbm(0.5, 0.5, 0.5, 0.5),
    grid = rgbm(16/255, 12/255, 8/255, 0.9),
    wheelBg = rgbm(0, 0, 0, 0.6),
    wheelCenter = rgbm(0.2, 0.2, 0.2, 0.0),
    wheelIndicator = rgbm(1, 1, 0, 1),
    background = rgbm(0.12, 0.12, 0.12, 1.0),
    deltaPos = rgbm(1, 0.2, 0.2, 1),
    deltaNeg = rgbm(0.2, 1, 0.2, 1),
    ghostThrottle = rgbm(0, 1, 0, 0.25),
    ghostBrake = rgbm(1, 0, 0, 0.25),
    ghostClutch = rgbm(0, 0.4, 1, 0.25),
    ghostSteering = rgbm(0.7, 0.7, 0.7, 0.25),
    ghostSpeed = rgbm(0.5, 0.5, 0.5, 0.2),
    ghostWheel = rgbm(0.5, 0.5, 0.5, 0.4),
    cornerOutline = rgbm(1, 1, 1, 0.15),
    cornerText = rgbm(1, 1, 1, 0.8),
    apexLine = rgbm(1, 1, 0, 0.5),
    startFinishLine = rgbm(1, 1, 1, 0.4),
}

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
    ui.text("Ghost Lap")
    ui.separator()

    ui.text("Reset Hotkey:")
    ui.sameLine(130)
    resetButton:control(vec2(120, 0))

    ui.offsetCursorY(5)
    ui.separator()
    ui.offsetCursorY(10)
    
    -- Trace visibility toggles
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
    ui.offsetCursorY(5)
    ui.text("Lap Telemetry")
    ui.offsetCursorY(5)
    
    if ui.checkbox("Auto-hide at speed", M.telemetryAutoHide) then
        M.telemetryAutoHide = not M.telemetryAutoHide
        ini:set('TELEMETRY', 'auto_hide', M.telemetryAutoHide and "True" or "False")
        ini:save()
    end
    
    if M.telemetryAutoHide then
        ui.sameLine(160)
        ui.setNextItemWidth(60)
        local newSpeed = ui.slider("##autohidespeed", M.telemetryAutoHideSpeed, 50, 200, "%.0f")
        if newSpeed ~= M.telemetryAutoHideSpeed then
            M.telemetryAutoHideSpeed = newSpeed
            ini:set('TELEMETRY', 'auto_hide_speed', tostring(math.floor(newSpeed)))
            ini:save()
        end
        ui.sameLine()
        ui.text("km/h")
    end
    
    ui.offsetCursorY(5)

    if state.hasBestLap() then
        local bestTime = state.getBestLapTime()
        if bestTime then
            local mins = math.floor(bestTime / 60)
            local secs = bestTime - mins * 60
            ui.text(string.format("Best: %d:%06.3f", mins, secs))
        end
        ui.sameLine(130)
        if ui.button("Reset##ghost", vec2(80, 0)) then
            state.resetBestLap()
        end
    else
        ui.textColored("No best lap recorded", rgbm(1, 1, 1, 0.5))
    end

    -- Ghost import section
    ui.offsetCursorY(5)
    
    if ui.button("Load Ghost...", vec2(100, 0)) then
        showGhostPicker = not showGhostPicker
        if showGhostPicker then
            ghostFiles = nil
        end
    end
    
    if showGhostPicker then
        ui.offsetCursorY(5)
        local files = scanGhostFiles()
        
        if #files == 0 then
            ui.textColored("No CSV files in tracks/", rgbm(1, 1, 1, 0.5))
        else
            ui.textColored("Select CSV to load:", rgbm(1, 1, 1, 0.7))
            for _, filename in ipairs(files) do
                if ui.button(filename, vec2(220, 0)) and not isLoadingGhost then
                    isLoadingGhost = true
                    showGhostPicker = false
                    
                    -- Check cache first
                    local lapData = ghostCache[filename]
                    
                    if lapData then
                        -- Cache hit
                        state.setBestLap(lapData)
                        ac.setMessage("Ghost Loaded", "Loaded " .. lapData:length() .. " samples (cached)")
                    else
                        -- Cache miss - parse CSV using lap module
                        local filePath = __dirname .. "/tracks/" .. filename
                        lapData = lap.fromCSV(filePath, state.track, state.car)
                        
                        if lapData then
                            ghostCache[filename] = lapData
                            state.setBestLap(lapData)
                            ac.setMessage("Ghost Loaded", "Loaded " .. lapData:length() .. " samples from " .. filename)
                        else
                            ac.setMessage("Load Error", "Failed to load " .. filename)
                        end
                    end
                    
                    isLoadingGhost = false
                end
            end
        end
        
        ui.offsetCursorY(3)
        if ui.button("Cancel##ghost", vec2(60, 0)) then
            showGhostPicker = false
        end
    end

    ui.offsetCursorY(10)
    ui.separator()
    ui.offsetCursorY(10)

    corner.settingsUI(recordCornerButton)
end

return M
