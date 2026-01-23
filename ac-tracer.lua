-- AC Tracer - CSP high-performance telemetry app
-- Main script using centralized state architecture

local state = require('lib.core.state')
local settings = require('lib.core.settings')
local corner_analysis = require('lib.windows.corner_analysis')
local lap_telemetry = require('lib.windows.lap_telemetry')
local lap_picker = require('lib.windows.lap_picker')
local delta_bar = require('lib.windows.delta_bar')
local main_window = require('lib.windows.main')
local ui_utils = require('lib.ui.utils')

-- History for trace display (rolling window)
local history = main_window.createHistory()
local updateTimer = 0

-- Overlap tracking state (for flag detection)
local overlapState = { startTime = nil }

-- Current car reference (updated once per frame in script.update)
local currentCar = nil

function script.update(dt)
    currentCar = ac.getCar(0)
    if not currentCar then return end

    local sim = ac.getSim()

    -- Skip all updates during pause or replay (TimeShift rewind)
    if sim.isPaused or sim.isReplayActive then return end

    -- Checkpoint keybind polling (check before state update)
    if settings.checkpointEnabled() then
        local saveButton = settings.getSaveCheckpointButton()
        local loadButton = settings.getLoadCheckpointButton()

        -- Save checkpoint on button press (pass trace history to be captured synchronously)
        if saveButton:pressed() then
            state.saveCheckpoint(history)
        end

        -- Load checkpoint on button press
        if loadButton:pressed() and state.hasCheckpoint() then
            if state.loadCheckpoint() then
                -- Restore trace history from checkpoint snapshot
                local traceSnapshot = state.getCheckpointTraceHistory()
                main_window.restoreHistory(history, traceSnapshot)

                -- Reset delta bar smoothing
                delta_bar.reset()

                -- Reset overlap tracking
                overlapState.startTime = nil
            end
        end
    end

    -- Brake beep toggle hotkey
    local brakeBeepButton = settings.getBrakeBeepButton()
    if brakeBeepButton:pressed() then
        local newMode = settings.toggleBrakeBeepMode()
        ac.setMessage("Brake Beep", settings.brakeBeepModeDisplay())
    end

    -- Comparison mode toggle hotkey
    local comparisonModeButton = settings.getComparisonModeButton()
    if comparisonModeButton:pressed() then
        local newMode = settings.toggleComparisonMode()
        ac.setMessage("Comparison", settings.comparisonModeDisplay())
    end

    -- Update centralized state (handles lap recording, completion, best lap)
    state.update(dt, currentCar)

    -- Update history for trace display
    updateTimer = updateTimer + dt
    local sampleInterval = 1 / settings.sampleRate()
    if updateTimer >= sampleInterval then
        updateTimer = updateTimer - sampleInterval
        main_window.updateHistory(currentCar, history, overlapState)
    end

    -- Update corner analysis (live tracking)
    corner_analysis.update(currentCar, state.currentLap, state.getComparisonLap(), state.trackCorners)

    -- Draw brake markers on track (3D rendering)
    main_window.drawBrakeMarkers(currentCar)

    -- Auto-hide telemetry window when above speed threshold (traces always visible)
    if settings.telemetryAutoHide() then
        ui_utils.updateAutoHide(dt, currentCar.speedKmh, settings.telemetryAutoHideSpeed(), {"telemetry"})
    end
end

function script.windowMain(dt)
    main_window.draw(dt, currentCar, history)
end

function script.windowSettings(dt)
    settings.windowSettings()
end

function script.windowCorners(dt)
    -- corner_analysis.update() handles corner tracking internally
    corner_analysis.draw(dt, state.currentLap, state.getComparisonLap(), state.trackCorners)
end

function script.windowTelemetry(dt)
    lap_telemetry.draw(dt, state)
end

function script.windowReferenceLap(dt)
    -- Reference lap picker only shows R button (no C button)
    lap_picker.showCurrentButton = false
    lap_picker.draw(dt)
end

function script.windowDelta(dt)
    delta_bar.draw(dt, state.currentLap, state.getComparisonLap(), state.trackPosition, state.trackCorners)
end

-- Called when app is shutting down
function script.shutdown()
    if state and state.autosaveReferenceIfFaster then
        state.autosaveReferenceIfFaster()
    end
end
