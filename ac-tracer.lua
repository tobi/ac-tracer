-- AC Tracer - CSP high-performance telemetry app
-- Main script using centralized state architecture

local state = require('lib.core.state')
local settings = require('lib.core.settings')
local corner_analysis = require('lib.windows.corner_analysis')
local lap_telemetry = require('lib.windows.lap_telemetry')
local lap_picker = require('lib.windows.lap_picker')
local delta_bar = require('lib.windows.delta_bar')
local main_window = require('lib.windows.main')
local focus = require('lib.windows.focus')
local training_window = require('lib.windows.training')
local training_sectors = require('lib.training_sectors')

local ui_utils = require('lib.ui.utils')
local theme = require('lib.ui.theme')
local scoring = require('lib.core.scoring')

-- Pause menu overlay - persisted layout via ac.storage
local pauseLayout = ac.storage({
    statsX = -1, statsY = -1,
    telX = -1, telY = -1, telW = -1, telH = -1,
    caX = -1, caY = -1, caW = -1, caH = -1,
    caVisible = false,
}, 'pauseLayout')

local pauseWinPos = nil
local pauseWinDragging = false
local pauseWinDragOffset = vec2(0, 0)

-- Cache corner scores to avoid recomputing every frame
local pauseScoreCache = nil
local pauseScoreCacheId = 0

-- Telemetry window state (draggable + resizable)
local telWinPos = nil
local telWinSize = nil
local telDragging = false
local telDragOffset = vec2(0, 0)
local telResizing = false
local telResizeEdge = nil
local TEL_MIN_W = 400
local TEL_MIN_H = 250
local TEL_GRIP = 8

-- Corner analysis window state (draggable + resizable)
local caWinPos = nil
local caWinSize = nil
local caDragging = false
local caDragOffset = vec2(0, 0)
local caResizing = false
local caResizeEdge = nil
local caVisible = pauseLayout.caVisible or false
local CA_MIN_W = 350
local CA_MIN_H = 250

-- Save current pause window layout to storage
local function savePauseLayout()
    if pauseWinPos then
        pauseLayout.statsX = pauseWinPos.x
        pauseLayout.statsY = pauseWinPos.y
    end
    if telWinPos and telWinSize then
        pauseLayout.telX = telWinPos.x
        pauseLayout.telY = telWinPos.y
        pauseLayout.telW = telWinSize.x
        pauseLayout.telH = telWinSize.y
    end
    if caWinPos and caWinSize then
        pauseLayout.caX = caWinPos.x
        pauseLayout.caY = caWinPos.y
        pauseLayout.caW = caWinSize.x
        pauseLayout.caH = caWinSize.y
    end
    pauseLayout.caVisible = caVisible
end

local function formatLapTime(ms)
    if not ms or ms <= 0 then return '--:--.---' end
    local totalSec = ms / 1000
    local mins = math.floor(totalSec / 60)
    local secs = totalSec - mins * 60
    return string.format('%d:%06.3f', mins, secs)
end

local function computeCornerScores()
    local corners = state.trackCorners
    local hist = state.history
    local bestLap = state.bestLap
    if not corners or #corners == 0 or not bestLap then return nil end

    local refAnalysis = corner_analysis.analyzeLap(bestLap, corners)

    local results = {}
    for _, cdef in ipairs(corners) do
        local cnum = cdef.number
        local refCorner = refAnalysis[cnum]
        if not refCorner then goto continue end

        -- Best score across all history for this corner
        local bestScore = 0
        -- Last 5 valid laps average
        local recentScores = {}

        for i, histLap in ipairs(hist) do
            if histLap.valid and histLap.completed and not histLap:isEmpty() then
                local curAnalysis = corner_analysis.analyzeCorner(histLap, cdef)
                if curAnalysis then
                    local comparison = corner_analysis.compareCorners(curAnalysis, refCorner)
                    if comparison then
                        local score = scoring.calculate(comparison)
                        if score > bestScore then bestScore = score end
                        if #recentScores < 5 then
                            table.insert(recentScores, score)
                        end
                    end
                end
            end
        end

        local avgScore = 0
        if #recentScores > 0 then
            local sum = 0
            for _, s in ipairs(recentScores) do sum = sum + s end
            avgScore = sum / #recentScores
        end

        table.insert(results, {
            name = cdef.name or ('Corner ' .. cnum),
            bestScore = bestScore,
            avgScore = math.floor(avgScore),
            count = #recentScores,
        })

        ::continue::
    end
    return results
end

ui.onExclusiveHUD(function(mode)
    if mode ~= 'pause' then return end

    local screen = ac.getUI().windowSize
    local corners = state.trackCorners or {}
    -- Dynamic height: header + laps + corners table
    local histCount = state.history and #state.history or 0
    local lapRows = math.min(histCount, 8)
    local cornerRows = #corners
    local winW = 320
    local winH = 120 + lapRows * 22 + 20 + math.max(cornerRows, 1) * 22 + 80
    winH = math.min(winH, screen.y - 80)

    if not pauseWinPos then
        if pauseLayout.statsX >= 0 then
            pauseWinPos = vec2(pauseLayout.statsX, pauseLayout.statsY)
        else
            pauseWinPos = vec2(10, 30)
        end
    end

    local uiState = ac.getUI()
    local mousePos = uiState.mousePos
    local mouseDown = uiState.isMouseLeftKeyDown
    local mouseClicked = uiState.isMouseLeftKeyClicked

    -- Drag on title bar (top 28px)
    local inTitle = mousePos.x >= pauseWinPos.x and mousePos.x <= pauseWinPos.x + winW
        and mousePos.y >= pauseWinPos.y and mousePos.y <= pauseWinPos.y + 28
    if mouseClicked and inTitle then
        pauseWinDragging = true
        pauseWinDragOffset = vec2(mousePos.x - pauseWinPos.x, mousePos.y - pauseWinPos.y)
    end
    if pauseWinDragging then
        if mouseDown then
            pauseWinPos.x = math.max(0, math.min(screen.x - winW, mousePos.x - pauseWinDragOffset.x))
            pauseWinPos.y = math.max(0, math.min(screen.y - winH, mousePos.y - pauseWinDragOffset.y))
        else
            pauseWinDragging = false
            savePauseLayout()
        end
    end

    -- Recompute corner scores when history changes
    local cacheId = histCount
    if pauseScoreCacheId ~= cacheId then
        pauseScoreCache = computeCornerScores()
        pauseScoreCacheId = cacheId
    end

    -- Stats panel: draw background manually, then content
    ui.drawRectFilled(pauseWinPos, pauseWinPos + vec2(winW, winH), rgbm(0.08, 0.08, 0.1, 0.92), 6)
    ui.drawRect(pauseWinPos, pauseWinPos + vec2(winW, winH), rgbm(0.3, 0.3, 0.4, 0.5), 6)

    ui.setCursorScreenPos(pauseWinPos + vec2(8, 8))
    ui.pushFont(ui.Font.Title)
    ui.text('AC Tracer')
    ui.popFont()

    ui.setCursorScreenPos(pauseWinPos + vec2(0, 32))
    ui.beginGroup()
    ui.offsetCursorX(8)

    -- === LAP TIMES ===
    ui.offsetCursorY(2)
    ui.pushFont(ui.Font.Small)
    ui.textColored('LAP TIMES', rgbm(0.5, 0.8, 1, 1))
    ui.popFont()

    local hist = state.history or {}
    if #hist == 0 then
        ui.textColored('  No laps yet', rgbm(1, 1, 1, 0.4))
    else
        local bestTime = state.bestLap and state.bestLap.time or 0
        for i = 1, math.min(#hist, 8) do
            local l = hist[i]
            local t = formatLapTime(l.time)
            local isBest = bestTime > 0 and l.time > 0 and math.abs(l.time - bestTime) < 1
            local color = isBest and rgbm(0.3, 1, 0.3, 1) or (l.valid and rgbm(1, 1, 1, 0.9) or rgbm(1, 1, 1, 0.4))
            ui.textColored(string.format('  %d. %s%s', i, t, isBest and '  *' or ''), color)
        end
    end

    ui.offsetCursorY(6)
    ui.textColored('─────────────────────────', rgbm(0.3, 0.3, 0.4, 0.5))
    ui.offsetCursorY(2)

    -- === CORNER SCORES ===
    ui.pushFont(ui.Font.Small)
    ui.textColored('CORNER SCORES  (last 5 avg vs best)', rgbm(0.5, 0.8, 1, 1))
    ui.popFont()

    if not pauseScoreCache or #pauseScoreCache == 0 then
        ui.textColored('  No corner data', rgbm(1, 1, 1, 0.4))
    else
        for _, c in ipairs(pauseScoreCache) do
            local trend = ''
            local trendColor = rgbm(1, 1, 1, 0.5)
            if c.count >= 2 then
                local diff = c.avgScore - c.bestScore
                if diff >= 3 then
                    trend = ' ^^'
                    trendColor = rgbm(0.3, 1, 0.3, 1)
                elseif diff >= 0 then
                    trend = ' ='
                    trendColor = rgbm(1, 1, 1, 0.6)
                elseif diff >= -5 then
                    trend = ' v'
                    trendColor = rgbm(1, 0.7, 0.3, 1)
                else
                    trend = ' vv'
                    trendColor = rgbm(1, 0.3, 0.3, 1)
                end
            end

            local nameW = 140
            local scoreText = string.format('%3d / %3d', c.avgScore, c.bestScore)
            ui.text(string.format('  %-14s', c.name))
            ui.sameLine(nameW)
            ui.text(scoreText)
            ui.sameLine(0, 2)
            ui.textColored(trend, trendColor)
        end
    end

    ui.endGroup()

    -- === TELEMETRY WINDOW (pause-only, draggable + resizable) ===
    if not telWinSize then
        if pauseLayout.telW >= TEL_MIN_W then
            telWinSize = vec2(pauseLayout.telW, pauseLayout.telH)
        else
            telWinSize = vec2(800, 600)
        end
    end
    if not telWinPos then
        if pauseLayout.telX >= 0 then
            telWinPos = vec2(pauseLayout.telX, pauseLayout.telY)
        else
            telWinPos = vec2(pauseWinPos.x + winW + 15, 30)
        end
    end

    -- Hit tests
    local mx, my = mousePos.x, mousePos.y
    local tx, ty = telWinPos.x, telWinPos.y
    local tw, th = telWinSize.x, telWinSize.y

    local onRight = mx >= tx + tw - TEL_GRIP and mx <= tx + tw and my >= ty and my <= ty + th
    local onBottom = my >= ty + th - TEL_GRIP and my <= ty + th and mx >= tx and mx <= tx + tw
    local onCorner = onRight and onBottom
    local onTitleBar = mx >= tx and mx <= tx + tw and my >= ty and my <= ty + 28
        and not onRight and not onBottom

    if mouseClicked then
        if onCorner then
            telResizing = true
            telResizeEdge = 'rb'
        elseif onRight then
            telResizing = true
            telResizeEdge = 'r'
        elseif onBottom then
            telResizing = true
            telResizeEdge = 'b'
        elseif onTitleBar then
            telDragging = true
            telDragOffset = vec2(mx - tx, my - ty)
        end
    end

    if telResizing then
        if mouseDown then
            if telResizeEdge == 'r' or telResizeEdge == 'rb' then
                telWinSize.x = math.max(TEL_MIN_W, mx - tx)
            end
            if telResizeEdge == 'b' or telResizeEdge == 'rb' then
                telWinSize.y = math.max(TEL_MIN_H, my - ty)
            end
        else
            telResizing = false
            savePauseLayout()
        end
    end

    if telDragging then
        if mouseDown then
            telWinPos.x = math.max(0, math.min(screen.x - telWinSize.x, mx - telDragOffset.x))
            telWinPos.y = math.max(0, math.min(screen.y - telWinSize.y, my - telDragOffset.y))
        else
            telDragging = false
            savePauseLayout()
        end
    end

    -- Draw telemetry background
    ui.drawRectFilled(telWinPos, telWinPos + telWinSize, rgbm(0.08, 0.08, 0.1, 0.95), 4)
    ui.drawRect(telWinPos, telWinPos + telWinSize, rgbm(0.3, 0.3, 0.4, 0.5), 4)

    -- Draw telemetry content inside a child window for clipping
    ui.setCursorScreenPos(telWinPos)
    ui.beginChild('pause_tel', telWinSize, false, ui.WindowFlags.NoScrollbar + ui.WindowFlags.NoScrollWithMouse)
    local ok, err = pcall(lap_telemetry.draw, 0, state, {
        openCornerAnalysis = function()
            caVisible = true
            savePauseLayout()
        end,
    })
    if not ok then
        ui.textColored('Telemetry error: ' .. tostring(err), rgbm(1, 0.3, 0.3, 1))
    end
    ui.endChild()

    -- Resize grip
    local g = telWinPos + telWinSize
    ui.drawLine(g - vec2(12, 0), g - vec2(0, 12), rgbm(1, 1, 1, 0.3), 1.5)
    ui.drawLine(g - vec2(8, 0), g - vec2(0, 8), rgbm(1, 1, 1, 0.3), 1.5)
    ui.drawLine(g - vec2(4, 0), g - vec2(0, 4), rgbm(1, 1, 1, 0.3), 1.5)

    -- === CORNER ANALYSIS WINDOW (pause-only, toggled by button) ===
    if caVisible then
        if not caWinSize then
            if pauseLayout.caW >= CA_MIN_W then
                caWinSize = vec2(pauseLayout.caW, pauseLayout.caH)
            else
                caWinSize = vec2(500, 380)
            end
        end
        if not caWinPos then
            if pauseLayout.caX >= 0 then
                caWinPos = vec2(pauseLayout.caX, pauseLayout.caY)
            else
                caWinPos = vec2(pauseWinPos.x, pauseWinPos.y + winH + 10)
                if caWinPos.y + caWinSize.y > screen.y - 10 then
                    caWinPos.y = screen.y - caWinSize.y - 10
                end
            end
        end

        -- Keep restored layouts reachable after resolution/monitor changes.
        caWinPos.x = math.max(0, math.min(math.max(0, screen.x - caWinSize.x), caWinPos.x))
        caWinPos.y = math.max(0, math.min(math.max(0, screen.y - caWinSize.y), caWinPos.y))

        local cx, cy = caWinPos.x, caWinPos.y
        local cw, ch = caWinSize.x, caWinSize.y

        local caOnRight = mx >= cx + cw - TEL_GRIP and mx <= cx + cw and my >= cy and my <= cy + ch
        local caOnBottom = my >= cy + ch - TEL_GRIP and my <= cy + ch and mx >= cx and mx <= cx + cw
        local caOnCorner = caOnRight and caOnBottom
        local caOnTitle = mx >= cx and mx <= cx + cw and my >= cy and my <= cy + 28
            and not caOnRight and not caOnBottom

        if mouseClicked then
            if caOnCorner then
                caResizing = true
                caResizeEdge = 'rb'
            elseif caOnRight then
                caResizing = true
                caResizeEdge = 'r'
            elseif caOnBottom then
                caResizing = true
                caResizeEdge = 'b'
            elseif caOnTitle then
                caDragging = true
                caDragOffset = vec2(mx - cx, my - cy)
            end
        end

        if caResizing then
            if mouseDown then
                if caResizeEdge == 'r' or caResizeEdge == 'rb' then
                    caWinSize.x = math.max(CA_MIN_W, mx - cx)
                end
                if caResizeEdge == 'b' or caResizeEdge == 'rb' then
                    caWinSize.y = math.max(CA_MIN_H, my - cy)
                end
            else
                caResizing = false
                savePauseLayout()
            end
        end

        if caDragging then
            if mouseDown then
                caWinPos.x = math.max(0, math.min(screen.x - caWinSize.x, mx - caDragOffset.x))
                caWinPos.y = math.max(0, math.min(screen.y - caWinSize.y, my - caDragOffset.y))
            else
                caDragging = false
                savePauseLayout()
            end
        end

        -- Draw corner analysis background
        ui.drawRectFilled(caWinPos, caWinPos + caWinSize, rgbm(0.08, 0.08, 0.1, 0.95), 4)
        ui.drawRect(caWinPos, caWinPos + caWinSize, rgbm(0.3, 0.3, 0.4, 0.5), 4)

        ui.setCursorScreenPos(caWinPos)
        ui.beginChild('pause_ca', caWinSize, false, ui.WindowFlags.NoScrollbar + ui.WindowFlags.NoScrollWithMouse)
        local ok, err = pcall(corner_analysis.draw, 0, state.currentLap, state.getComparisonLap(), state.trackCorners)
        if not ok then
            ui.textColored('Corner analysis error: ' .. tostring(err), rgbm(1, 0.3, 0.3, 1))
        end
        ui.endChild()

        -- Resize grip
        local g = caWinPos + caWinSize
        ui.drawLine(g - vec2(12, 0), g - vec2(0, 12), rgbm(1, 1, 1, 0.3), 1.5)
        ui.drawLine(g - vec2(8, 0), g - vec2(0, 8), rgbm(1, 1, 1, 0.3), 1.5)
        ui.drawLine(g - vec2(4, 0), g - vec2(0, 4), rgbm(1, 1, 1, 0.3), 1.5)
    end

end)

-- Traffic module (lazy-loaded only when AI cars detected)
local traffic = nil
local trafficButton = nil
local lastLapNumber = nil
local trafficChecked = false  -- only check for AI cars once


-- History for trace display (rolling window)
local history = main_window.createHistory()
local updateTimer = 0

-- Overlap tracking state (for flag detection)
local overlapState = { startTime = nil }

-- Current car reference (updated once per frame in script.update)
local currentCar = nil

-- Focus window: tracks last-known content state so we only call setVisible on transitions
local focusContentLastFrame = nil

function script.update(dt)
    currentCar = ac.getCar(0)
    if not currentCar then return end

    local sim = ac.getSim()
    local isReplay = sim.isReplayActive

    -- Trace and telemetry state follows simulation time. Replay and a zero-speed
    -- simulation must not keep a rolling trace alive.
    if sim.isPaused or isReplay or (sim.dt or 0) <= 0 then return end

    -- DynamicReturn-style training sector: hold reloads the selected start,
    -- release begins timing. The same key maps start then finish in map mode.
    local teleported = training_sectors.update(sim.dt or dt, currentCar, state.trackCorners,
        settings.getTrainingButton(), settings.trainingEnabled())
    if teleported then
        main_window.clearHistory(history)
        delta_bar.reset()
        overlapState.startTime = nil
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

    -- Traffic: entirely disabled unless AI cars are in the session
    -- Lazy-load module and button only once, only if AI cars detected
    if not trafficChecked then
        if ac.getSim().carsCount > 1 then
            traffic = require('lib.traffic')
            trafficButton = ac.ControlButton('__AC_TRACER_TRAFFIC_TELEPORT')
        end
        trafficChecked = true
    end

    if traffic and trafficButton then
        if trafficButton:pressed() then
            if not traffic.isInitialized() then
                traffic.init()
            end
            local name = traffic.teleportScenario(state.trackCorners)
            if name then
                ac.setMessage("Traffic", name .. " → " .. traffic.nextScenario() .. " next")
            end
        end

        if traffic.isInitialized() then
            traffic.update(dt, state.trackCorners, currentCar.splinePosition, currentCar.lapCount)
            if lastLapNumber and currentCar.lapCount ~= lastLapNumber then
                traffic.onNewLap(state.trackCorners)
            end
            lastLapNumber = currentCar.lapCount
        end
    end

    -- Update centralized state (handles lap recording, completion, best lap)
    state.update(dt, currentCar)

    -- Update history only while the rolling graph is enabled.
    if settings.tracesEnabled() then
        updateTimer = updateTimer + (sim.dt or dt)
        local sampleInterval = 1 / settings.sampleRate()
        if updateTimer >= sampleInterval then
            updateTimer = updateTimer - sampleInterval
            main_window.updateHistory(currentCar, history, overlapState)
        end
    end

    local racingLineButton = settings.getRacingLineButton()
    if racingLineButton:pressed() then
        settings.toggleRacingLineMode()
        ac.setMessage("Reference racing line", settings.racingLineModeDisplay())
    end

    -- Update corner analysis (live tracking)
    corner_analysis.update(currentCar, state.currentLap, state.getComparisonLap(), state.trackCorners, dt)

    -- Hide focus window entirely when no notes/images exist for this track.
    -- Only act on transitions to avoid fighting manual toggles every frame.
    local hasFocus = focus.hasContent()
    if hasFocus ~= focusContentLastFrame then
        ui_utils.setWindowVisible("focus", hasFocus)
        focusContentLastFrame = hasFocus
    end

    -- Auto-hide telemetry/focus windows when above speed threshold
    -- (traces always visible). Focus only joins the auto-hide list when
    -- it has content; otherwise it's already force-hidden above.
    if settings.telemetryAutoHide() then
        local autoHideIds = hasFocus and {"telemetry", "focus"} or {"telemetry"}
        ui_utils.updateAutoHide(dt, currentCar.speedKmh, settings.telemetryAutoHideSpeed(), autoHideIds)
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

function script.windowCornerSequence(dt)
    corner_analysis.drawSequenceDots(dt)
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
    delta_bar.draw(dt, state.currentLap, state.getComparisonLap(), state.trackPosition, state.trackCorners, currentCar)
end

function script.windowFocus(dt)
    focus.draw(dt)
end

function script.windowTraining(dt)
    training_window.draw(dt)
end

-- Called when app is shutting down
function script.shutdown()
    if state and state.autosaveReferenceIfFaster then
        state.autosaveReferenceIfFaster()
    end
end
