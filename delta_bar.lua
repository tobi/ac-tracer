-- delta_bar.lua - iRacing-style delta bar window
-- Shows lap time, delta vs reference lap with color-coded bar

local state = require('state')
local theme = require('theme')

local delta_bar = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local config = {
    maxDelta = 2.0,        -- Max delta shown (seconds) - bar is full at this value
    barHeight = 24,        -- Height of the delta bar
    barSmoothing = 0.08,   -- Smoothing factor for bar position (lower = smoother)
    textSmoothing = 0.06,  -- Smoothing factor for text delta (lower = smoother)
}

-- Runtime state for smooth animations
local smoothedBarWidth = 0
local smoothedDelta = 0
local displayDelta = 0

-- Speed difference tracking (2-second window)
local speedDiffHistory = {}  -- {time, speedDiff} pairs
local SPEED_WINDOW = 2.0     -- 2-second window for speed comparison
local avgSpeedDiff = 0       -- Average speed diff over window (positive = faster than ghost)
local SPEED_NEUTRAL_THRESHOLD = 2.0  -- km/h difference considered neutral (white)

-- Lap completion display
local lastLapCount = 0
local lastLapTime = 0       -- The completed lap time in ms
local lastLapDelta = 0      -- Delta at lap completion
local lapCompleteTimer = 0  -- Seconds since lap completed

-- Update throttling (2 Hz for delta, but speed updates every frame)
local updateInterval = 1 / 2
local updateTimer = 0
local lastDelta = 0

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

--- Draw the delta bar window
---@param dt number Delta time
function delta_bar.draw(dt)
    local car = ac.getCar(0)
    if not car then return end

    local sim = ac.getSim()
    local windowSize = ui.availableSpace()
    local centerX = windowSize.x / 2
    local padding = 10

    -- Skip updates during replay/rewind (keep showing last known values)
    local now = state.time()  -- Use session time (rewind-aware)
    if not sim.isReplayActive and not sim.isPaused then
        -- Track speed difference vs ghost every frame
        local currentPos = car.splinePosition
        local currentSpeed = car.speedKmh
        local ghostSpeed = state.getGhostValueAt('speed', currentPos)

        if ghostSpeed and ghostSpeed > 0 then
            local speedDiff = currentSpeed - ghostSpeed  -- positive = faster than ghost
            table.insert(speedDiffHistory, { time = now, diff = speedDiff })
        end

        -- Remove entries older than 2 seconds (or entries from "future" after rewind)
        while #speedDiffHistory > 0 and (now - speedDiffHistory[1].time) > SPEED_WINDOW do
            table.remove(speedDiffHistory, 1)
        end
        -- Also remove any entries with time > now (happens after rewind)
        while #speedDiffHistory > 0 and speedDiffHistory[#speedDiffHistory].time > now do
            table.remove(speedDiffHistory)
        end

        -- Calculate average speed difference over the window
        if #speedDiffHistory > 0 then
            local sum = 0
            for _, entry in ipairs(speedDiffHistory) do
                sum = sum + entry.diff
            end
            avgSpeedDiff = sum / #speedDiffHistory
        else
            avgSpeedDiff = 0
        end

        -- Throttle delta updates to 2 Hz
        updateTimer = updateTimer + dt
        if updateTimer >= updateInterval then
            updateTimer = updateTimer - updateInterval
            lastDelta = state.getDelta()  -- positive = behind/slower
        end
    end

    -- Smooth values for display
    smoothedDelta = smoothedDelta + (lastDelta - smoothedDelta) * config.textSmoothing
    displayDelta = math.floor(smoothedDelta * 100 + 0.5) / 100  -- 2 decimal places

    -- Calculate bar width
    local barWidth = windowSize.x - padding * 2
    local maxBarHalf = barWidth / 2 - 2
    local normalizedDelta = math.clamp(math.abs(smoothedDelta) / config.maxDelta, 0, 1)
    local targetFillWidth = normalizedDelta * maxBarHalf
    smoothedBarWidth = smoothedBarWidth + (targetFillWidth - smoothedBarWidth) * config.barSmoothing

    -- Color based on 2-second average speed difference vs ghost
    -- Positive avgSpeedDiff = faster than ghost = GREEN
    -- Negative avgSpeedDiff = slower than ghost = RED
    -- Near zero = WHITE (neutral)
    local barColor, textColor
    if not state.hasBestLap() then
        barColor = theme.text.muted
        textColor = theme.text.muted
    elseif avgSpeedDiff > SPEED_NEUTRAL_THRESHOLD then
        -- Faster than ghost - GREEN
        barColor = theme.delta.positive
        textColor = theme.delta.positive
    elseif avgSpeedDiff < -SPEED_NEUTRAL_THRESHOLD then
        -- Slower than ghost - RED
        barColor = theme.delta.negative
        textColor = theme.delta.negative
    else
        -- Neutral - WHITE
        barColor = theme.text.primary
        textColor = theme.text.primary
    end

    -- Detect lap completion
    local currentLapCount = car.lapCount
    if currentLapCount > lastLapCount and lastLapCount > 0 then
        -- Lap just completed - store the time and delta
        lastLapTime = car.previousLapTimeMs or 0
        lastLapDelta = displayDelta
        lapCompleteTimer = 5.0  -- Show for 5 seconds
    end
    lastLapCount = currentLapCount

    -- Update lap complete timer
    if lapCompleteTimer > 0 then
        lapCompleteTimer = lapCompleteTimer - dt
    end

    -- Layout
    local topRowY = 4
    local barY = lapCompleteTimer > 0 and 28 or 8  -- Move bar up when no lap time shown
    local bottomBoxY = barY + config.barHeight + 6

    ----------------------------------------
    -- Top row: Lap time + delta (only for 5s after completion)
    ----------------------------------------
    if lapCompleteTimer > 0 and lastLapTime > 0 then
        local lapTimeS = lastLapTime / 1000
        local mins = math.floor(lapTimeS / 60)
        local secs = lapTimeS - mins * 60

        -- Lap time text
        local lapTimeText = string.format("%d:%06.3f", mins, secs)
        ui.pushFont(ui.Font.Title)
        local lapTimeSize = ui.measureText(lapTimeText)

        -- Small delta text for top row
        local smallDeltaText = string.format("%+.2f", lastLapDelta)
        ui.pushFont(ui.Font.Main)
        local smallDeltaSize = ui.measureText(smallDeltaText)
        ui.popFont()
        ui.popFont()

        local totalTopWidth = lapTimeSize.x + 10 + smallDeltaSize.x
        local topStartX = centerX - totalTopWidth / 2

        -- Fade out in last second
        local alpha = lapCompleteTimer < 1 and lapCompleteTimer or 1

        -- Draw lap time (yellow/white)
        ui.pushFont(ui.Font.Title)
        ui.setCursor(vec2(topStartX, topRowY))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(1, 0.9, 0.2, alpha))
        ui.text(lapTimeText)
        ui.popStyleColor()
        ui.popFont()

        -- Draw small delta (colored)
        local topDeltaColor = lastLapDelta < -0.01 and theme.delta.positive or
                             (lastLapDelta > 0.01 and theme.delta.negative or theme.text.primary)
        ui.pushFont(ui.Font.Main)
        ui.setCursor(vec2(topStartX + lapTimeSize.x + 10, topRowY + 4))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(topDeltaColor.r, topDeltaColor.g, topDeltaColor.b, alpha))
        ui.text(smallDeltaText)
        ui.popStyleColor()
        ui.popFont()
    end

    ----------------------------------------
    -- Middle: Dark bar with fill
    ----------------------------------------
    local barLeft = padding
    local barRight = windowSize.x - padding

    -- Dark background bar
    ui.drawRectFilled(
        vec2(barLeft, barY),
        vec2(barRight, barY + config.barHeight),
        rgbm(0.08, 0.08, 0.12, 0.95), 6
    )

    -- Fill bar from center
    if state.hasBestLap() and smoothedBarWidth > 0.5 then
        if smoothedDelta < 0 then
            -- Ahead: green bar goes LEFT
            ui.drawRectFilled(
                vec2(centerX - smoothedBarWidth, barY + 2),
                vec2(centerX, barY + config.barHeight - 2),
                barColor, 1
            )
        else
            -- Behind: red bar goes RIGHT
            ui.drawRectFilled(
                vec2(centerX, barY + 2),
                vec2(centerX + smoothedBarWidth, barY + config.barHeight - 2),
                barColor, 1
            )
        end
    end

    -- Center line marker (thin, subtle)
    ui.drawRectFilled(
        vec2(centerX - 1, barY),
        vec2(centerX + 1, barY + config.barHeight),
        rgbm(0.8, 0.7, 0.7, 0.6), 0
    )

    ----------------------------------------
    -- Bottom: Large delta in dark box
    ----------------------------------------
    local sign = displayDelta >= 0 and "+" or ""
    local deltaText = state.hasBestLap() and string.format("%s%.2f", sign, displayDelta) or "NO REF"

    ui.pushFont(ui.Font.Title)
    local deltaSize = ui.measureText(deltaText)
    local boxPadX = 16
    local boxPadY = 4
    local boxW = deltaSize.x + boxPadX * 2
    local boxH = deltaSize.y + boxPadY * 2
    local boxX = centerX - boxW / 2
    local boxY = bottomBoxY

    -- Dark rounded box
    ui.drawRectFilled(
        vec2(boxX, boxY),
        vec2(boxX + boxW, boxY + boxH),
        rgbm(0.08, 0.08, 0.12, 0.95), 8
    )

    -- Delta text
    ui.setCursor(vec2(boxX + boxPadX, boxY + boxPadY))
    ui.pushStyleColor(ui.StyleColor.Text, textColor)
    ui.text(deltaText)
    ui.popStyleColor()
    ui.popFont()
end

--- Reset smoothing state (call on lap reset)
function delta_bar.reset()
    smoothedBarWidth = 0
    smoothedDelta = 0
    displayDelta = 0
    speedDiffHistory = {}
    avgSpeedDiff = 0
    updateTimer = 0
    lastDelta = 0
end

return delta_bar
