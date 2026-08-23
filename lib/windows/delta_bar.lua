-- delta_bar.lua - iRacing-style delta bar window
-- Shows lap time, delta vs reference lap with color-coded bar

local theme = require('lib.ui.theme')
local corner_analysis = require('lib.windows.corner_analysis')
local wedge = require('lib.ui.wedge')
local state = require('lib.core.state')

local delta_bar = {}

--- Return valid corner definitions in physical track sequence.
--- CSV row order and corner numbers are deliberately ignored.
function delta_bar.getCornerDisplayOrder(corners)
    local ordered = {}
    for _, corner in ipairs(corners or {}) do
        if corner.endPos ~= nil then ordered[#ordered + 1] = corner end
    end
    table.sort(ordered, function(a, b)
        if a.endPos == b.endPos then return (a.number or 0) < (b.number or 0) end
        return a.endPos < b.endPos
    end)
    return ordered
end

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

-- Outlap tracking: outlap only while pit limiter is active (exiting pits)
-- Once S/F is crossed without pit limiter, it's a real lap
local isOutlap = false
local prevLapCount = -1

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
---@param currentLap table Current lap data
---@param referenceLap table Reference lap data
---@param currentPos number Current spline position
---@param corners table|nil Array of corner definitions (to know total corner count)
---@param car table|nil Car state from ac.getCar(0), falls back to fetching if not provided
function delta_bar.draw(dt, currentLap, referenceLap, currentPos, corners, car)
    car = car or ac.getCar(0)
    if not car then return end

    local sim = ac.getSim()
    local windowSize = ui.availableSpace()
    local centerX = windowSize.x / 2
    local padding = 10

    -- Outlap detection: only an outlap if the S/F crossing happened with pit limiter on
    -- Once you cross S/F without pit limiter, you're on a real lap
    if car.lapCount ~= prevLapCount then
        -- S/F crossing just happened
        if car.speedLimiterInAction then
            -- Crossed S/F while pit limiter active = still outlap (exiting pits)
            isOutlap = true
        else
            -- Crossed S/F normally = real lap start
            isOutlap = false
        end
        prevLapCount = car.lapCount
    end

    -- Skip updates during pause (but allow replay)
    if not sim.isPaused then
        -- Throttle delta updates to 2 Hz
        updateTimer = updateTimer + dt
        if updateTimer >= updateInterval then
            updateTimer = updateTimer - updateInterval
            if referenceLap and currentPos and not isOutlap then
                local currentTimeS = car.lapTimeMs / 1000
                local refTimeS = referenceLap:getTimeAtPos(currentPos)
                lastDelta = currentTimeS - (refTimeS or currentTimeS)
            else
                lastDelta = 0
            end
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

    -- Color based on delta time
    -- Green at 0.0 (even/ahead), direct gradient to red when behind
    local barColor, textColor
    local hasRef = referenceLap and referenceLap:length() > 10 and not isOutlap
    if not hasRef then
        barColor = theme.text.muted
        textColor = theme.text.muted
    elseif smoothedDelta <= 0 then
        -- Ahead or even - GREEN
        barColor = theme.delta.positive
        textColor = theme.delta.positive
    elseif smoothedDelta >= 0.2 then
        -- Behind by 0.2s or more - RED
        barColor = theme.delta.negative
        textColor = theme.delta.negative
    else
        -- Direct gradient from green to red (0 to 0.2s behind)
        local t = smoothedDelta / 0.2  -- 0 to 1
        local green = theme.delta.positive
        local red = theme.delta.negative
        barColor = rgbm(
            green.r + (red.r - green.r) * t,
            green.g + (red.g - green.g) * t,
            green.b + (red.b - green.b) * t,
            1
        )
        textColor = barColor
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
    local cornerScoresHeight = 20  -- Height for corner score wedges (including spacing)
    local wedgeY = lapCompleteTimer > 0 and 30 or 8  -- Y position for wedges
    local barY = wedgeY + cornerScoresHeight  -- Bar starts below wedges
    local bottomBoxY = barY + config.barHeight + 6

    ----------------------------------------
    -- Top row: Lap time + delta (only for 5s after completion)
    ----------------------------------------
    if lapCompleteTimer > 0 and lastLapTime > 0 then
        local lapTimeS = lastLapTime / 1000
        local mins = math.floor(lapTimeS / 60)
        local secs = lapTimeS - mins * 60

        -- Lap time text (monospace for clean digits)
        local lapTimeText = string.format("%d:%06.3f", mins, secs)
        ui.pushFont(ui.Font.Monospace)
        local lapTimeSize = ui.measureText(lapTimeText)

        -- Small delta text for top row
        local smallDeltaText = string.format("%+.2f", lastLapDelta)
        local smallDeltaSize = ui.measureText(smallDeltaText)
        ui.popFont()

        local totalTopWidth = lapTimeSize.x + 12 + smallDeltaSize.x
        local topStartX = centerX - totalTopWidth / 2

        -- Fade out in last second
        local alpha = lapCompleteTimer < 1 and lapCompleteTimer or 1

        -- Draw lap time (yellow/white)
        ui.pushFont(ui.Font.Monospace)
        ui.setCursor(vec2(topStartX, topRowY))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(1, 0.9, 0.2, alpha))
        ui.text(lapTimeText)
        ui.popStyleColor()

        -- Draw small delta (colored, same font)
        local topDeltaColor = lastLapDelta < -0.01 and theme.delta.positive or
                             (lastLapDelta > 0.01 and theme.delta.negative or theme.text.primary)
        ui.setCursor(vec2(topStartX + lapTimeSize.x + 12, topRowY))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(topDeltaColor.r, topDeltaColor.g, topDeltaColor.b, alpha))
        ui.text(smallDeltaText)
        ui.popStyleColor()
        ui.popFont()
    end

    ----------------------------------------
    -- Corner score wedges (above bar)
    -- Positioned by corner number: first corner on left, last on right
    ----------------------------------------
    local recentScores = corner_analysis.getRecentCornerScores()
    local orderedCorners = delta_bar.getCornerDisplayOrder(corners)
    local numCorners = #orderedCorners
    
    if recentScores and #recentScores > 0 and numCorners > 0 then
        local wedgeWidth = 24   -- Larger width for visibility
        local wedgeHeight = 16  -- Height for score text
        local availableWidth = windowSize.x - padding * 2 - wedgeWidth  -- Leave room for wedge width
        
        -- Build a lookup of scores by corner number
        local scoreByCorner = {}
        for _, scoreData in ipairs(recentScores) do
            if scoreData and scoreData.cornerNum and scoreData.score then
                scoreByCorner[scoreData.cornerNum] = scoreData.score
            end
        end
        
        -- Draw wedges by corner end position, not CSV row/number order.
        for displayIndex, corner in ipairs(orderedCorners) do
            local score = scoreByCorner[corner.number]
            if score then
                local t = numCorners > 1 and ((displayIndex - 1) / (numCorners - 1)) or 0.5
                local wedgeX = padding + t * availableWidth
                wedge.drawCompact(wedgeX, wedgeY, wedgeWidth, wedgeHeight, score)
            end
        end
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
    if hasRef and smoothedBarWidth > 0.5 then
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
    local deltaText
    if isOutlap then
        deltaText = "OUTLAP"
    elseif hasRef then
        deltaText = string.format("%s%.2f", sign, displayDelta)
    else
        deltaText = "NO REF"
    end

    ui.pushFont(ui.Font.Title)
    local deltaSize = ui.measureText(deltaText)
    local boxPadX = 14
    local boxPadY = 6
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

--- Reset smoothing state after a lap reset or training-sector return.
function delta_bar.reset()
    smoothedBarWidth = 0
    smoothedDelta = 0
    displayDelta = 0
    updateTimer = 0
    lastDelta = 0
    
    -- Reset lap tracking to current car state
    local car = ac.getCar(0)
    if car then
        lastLapCount = car.lapCount
    end
    
    -- Clear lap completion display
    lapCompleteTimer = 0
end

return delta_bar
