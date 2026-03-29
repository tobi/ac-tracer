-- AC Tracer - CSP high-performance telemetry app
-- Main script using centralized state architecture

local state = require('lib.core.state')
local settings = require('lib.core.settings')
local corner_analysis = require('lib.windows.corner_analysis')
local lap_telemetry = require('lib.windows.lap_telemetry')
local lap_picker = require('lib.windows.lap_picker')
local delta_bar = require('lib.windows.delta_bar')
local main_window = require('lib.windows.main')

local traffic = require('lib.traffic')
local training_window = require('lib.windows.training')
local ui_utils = require('lib.ui.utils')

-- Track lap number for train mode new-lap detection
local lastLapNumber = nil

-- Delay traffic init to avoid physics calls before sim is ready
local trafficInitDelay = 3  -- seconds after first update

-- History for trace display (rolling window)
local history = main_window.createHistory()
local updateTimer = 0

-- Overlap tracking state (for flag detection)
local overlapState = { startTime = nil }

-- Checkpoint load button hold tracking
local loadButtonHeldTime = 0
local loadButtonHeldTriggered = false

-- Current car reference (updated once per frame in script.update)
local currentCar = nil

function script.update(dt)
    currentCar = ac.getCar(0)
    if not currentCar then return end

    local sim = ac.getSim()
    local isReplay = sim.isReplayActive

    -- Skip all updates during pause (but allow replay)
    if sim.isPaused then return end

    -- In replay mode, update traces + ghost/delta but skip lap recording, checkpoints, etc.
    if isReplay then
        -- Keep track position current so ghost traces and delta work
        state.trackPosition = currentCar.splinePosition

        updateTimer = updateTimer + dt
        local sampleInterval = 1 / settings.sampleRate()
        if updateTimer >= sampleInterval then
            updateTimer = updateTimer - sampleInterval
            main_window.updateHistory(currentCar, history, overlapState, true)
        end
        return
    end

    -- Checkpoint keybind polling (check before state update)
    if settings.checkpointEnabled() then
        local saveButton = settings.getSaveCheckpointButton()
        local loadButton = settings.getLoadCheckpointButton()

        -- Save checkpoint on button press (pass trace history to be captured synchronously)
        if saveButton:pressed() then
            state.saveCheckpoint(history)
        end

        -- Load checkpoint: press to cycle, hold to jump to 1/N
        if loadButton:pressed() then
            loadButtonHeldTime = 0
            loadButtonHeldTriggered = false
            -- Immediate response: cycle to next checkpoint
            if state.loadCheckpoint() then
                local traceSnapshot = state.getCheckpointTraceHistory()
                main_window.restoreHistory(history, traceSnapshot)
                delta_bar.reset()
                overlapState.startTime = nil
            end
        end

        if loadButton:down() then
            loadButtonHeldTime = loadButtonHeldTime + dt
            -- Hold: jump back to checkpoint 1/N
            if loadButtonHeldTime > 0.5 and not loadButtonHeldTriggered then
                state.resetCheckpointIndex()
                if state.loadCheckpoint() then
                    local traceSnapshot = state.getCheckpointTraceHistory()
                    main_window.restoreHistory(history, traceSnapshot)
                    delta_bar.reset()
                    overlapState.startTime = nil
                end
                loadButtonHeldTriggered = true
            end
        else
            loadButtonHeldTime = 0
            loadButtonHeldTriggered = false
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

    -- Traffic: init after delay to let physics fully load
    if not traffic.isInitialized() and ac.getSim().carsCount > 1 then
        if trafficInitDelay > 0 then
            trafficInitDelay = trafficInitDelay - dt
        else
            traffic.init()
        end
    end

    -- Traffic teleport hotkey (press = deploy scenario, cycles through on repeated press)
    if traffic.isInitialized() then
        traffic.update(dt, state.trackCorners, currentCar.splinePosition, currentCar.lapCount)

        -- Detect new lap for train mode
        if lastLapNumber and currentCar.lapCount ~= lastLapNumber then
            traffic.onNewLap(state.trackCorners)
        end
        lastLapNumber = currentCar.lapCount

        local trafficButton = settings.getTrafficTeleportButton()
        if trafficButton:pressed() then
            local name = traffic.teleportScenario(state.trackCorners)
            if name then
                ac.setMessage("Traffic", name .. " → " .. traffic.nextScenario() .. " next")
            end
        end
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


function script.windowTraining(dt)
    training_window.draw(dt)
end

function script.windowDelta(dt)
    delta_bar.draw(dt, state.currentLap, state.getComparisonLap(), state.trackPosition, state.trackCorners, currentCar)
end

-- Called when app is shutting down
function script.shutdown()
    if state and state.autosaveReferenceIfFaster then
        state.autosaveReferenceIfFaster()
    end
end
