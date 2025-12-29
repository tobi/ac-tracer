-- delta_bar.lua - iRacing-style delta bar window
-- Shows time delta vs reference lap with color-coded speed comparison

local state = require('state')
local theme = require('theme')

local delta_bar = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local config = {
    maxDelta = 2.0,        -- Max delta shown (seconds) - bar is full at this value
    barHeight = 20,        -- Height of the delta bar
    smoothing = 0.15,      -- Smoothing factor for color transitions (0-1)
    displayUpdateRate = 0.1, -- Update display every 100ms (10 Hz)
}

-- Runtime state
local lastSpeedDiff = 0
local lastDisplayDelta = 0
local displayUpdateTimer = 0

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

--- Draw the delta bar window
---@param dt number Delta time
function delta_bar.draw(dt)
    local car = ac.getCar(0)
    if not car then return end

    local windowSize = ui.availableSpace()
    local centerX = windowSize.x / 2
    local centerY = windowSize.y / 2

    -- Get delta vs best lap
    local delta = state.getDelta()  -- positive = behind/slower
    local currentPos = car.splinePosition
    local currentSpeed = car.speedKmh

    -- Throttle display updates to reduce jitter (10 Hz)
    displayUpdateTimer = displayUpdateTimer + dt
    if displayUpdateTimer >= config.displayUpdateRate then
        displayUpdateTimer = 0
        lastDisplayDelta = delta
    end
    local displayDelta = lastDisplayDelta

    -- Get ghost speed at same position for relative speed comparison
    local ghostSpeed = state.getGhostValueAt('speed', currentPos)
    local speedDiff = 0
    if ghostSpeed and ghostSpeed > 0 then
        speedDiff = currentSpeed - ghostSpeed  -- positive = gaining
    end

    -- Smooth the speed difference for less jittery colors
    lastSpeedDiff = lastSpeedDiff + (speedDiff - lastSpeedDiff) * config.smoothing
    local smoothedSpeedDiff = lastSpeedDiff

    -- Calculate bar width based on delta time
    local maxBarWidth = (windowSize.x / 2) - 40  -- Leave room for text
    local normalizedDelta = math.clamp(math.abs(delta) / config.maxDelta, 0, 1)
    local barWidth = normalizedDelta * maxBarWidth

    -- Determine color based on relative speed
    local speedThreshold = 5  -- km/h difference for full saturation
    local colorIntensity = math.clamp(math.abs(smoothedSpeedDiff) / speedThreshold, 0.3, 1)

    local barColor
    if smoothedSpeedDiff > 0.5 then
        -- Gaining time (faster than ghost) - GREEN
        barColor = rgbm(0.1, 0.9 * colorIntensity, 0.1, 0.9)
    elseif smoothedSpeedDiff < -0.5 then
        -- Losing time (slower than ghost) - RED
        barColor = rgbm(0.9 * colorIntensity, 0.1, 0.1, 0.9)
    else
        -- Neutral (same speed) - use delta to determine base color
        if delta < 0 then
            barColor = theme.withAlpha(theme.delta.positive, 0.7)
        else
            barColor = theme.withAlpha(theme.delta.negative, 0.7)
        end
    end

    -- Draw the delta bar
    local barY = centerY - config.barHeight / 2
    local barTop = barY
    local barBottom = barY + config.barHeight

    -- Center line (subtle)
    ui.drawLine(
        vec2(centerX, barTop - 5),
        vec2(centerX, barBottom + 5),
        rgbm(1, 1, 1, 0.4), 2
    )

    if state.hasBestLap() and math.abs(delta) > 0.001 then
        if delta < 0 then
            -- Ahead: bar goes LEFT from center
            ui.drawRectFilled(
                vec2(centerX - barWidth, barTop),
                vec2(centerX, barBottom),
                barColor, 2
            )
            ui.drawRect(
                vec2(centerX - barWidth, barTop),
                vec2(centerX, barBottom),
                rgbm(1, 1, 1, 0.3), 2, 1
            )
        else
            -- Behind: bar goes RIGHT from center
            ui.drawRectFilled(
                vec2(centerX, barTop),
                vec2(centerX + barWidth, barBottom),
                barColor, 2
            )
            ui.drawRect(
                vec2(centerX, barTop),
                vec2(centerX + barWidth, barBottom),
                rgbm(1, 1, 1, 0.3), 2, 1
            )
        end
    end

    -- Delta time text (centered below bar)
    local textY = barBottom + 8
    local sign = displayDelta >= 0 and "+" or ""
    local deltaText = string.format("%s%.1f", sign, displayDelta)

    -- Text color
    local textColor
    if not state.hasBestLap() then
        textColor = theme.text.muted
        deltaText = "NO REF"
    elseif displayDelta < -0.05 then
        textColor = theme.delta.positive
    elseif displayDelta > 0.05 then
        textColor = theme.delta.negative
    else
        textColor = theme.text.primary
    end

    -- Draw delta text with shadow
    ui.pushFont(ui.Font.Title)
    local textSize = ui.measureText(deltaText)
    local textX = centerX - textSize.x / 2

    -- Shadow
    ui.setCursor(vec2(textX + 1, textY + 1))
    ui.pushStyleColor(ui.StyleColor.Text, rgbm(0, 0, 0, 0.7))
    ui.text(deltaText)
    ui.popStyleColor()

    -- Main text
    ui.setCursor(vec2(textX, textY))
    ui.pushStyleColor(ui.StyleColor.Text, textColor)
    ui.text(deltaText)
    ui.popStyleColor()
    ui.popFont()

    -- Speed difference indicator (above bar)
    if state.hasBestLap() and ghostSpeed then
        local speedText = string.format("%+.0f", smoothedSpeedDiff)
        ui.pushFont(ui.Font.Small)
        local speedTextSize = ui.measureText(speedText)
        local speedTextX = centerX - speedTextSize.x / 2
        local speedTextY = barTop - 15

        local speedTextColor
        if smoothedSpeedDiff > 1 then
            speedTextColor = theme.withAlpha(theme.delta.positive, 0.8)
        elseif smoothedSpeedDiff < -1 then
            speedTextColor = theme.withAlpha(theme.delta.negative, 0.8)
        else
            speedTextColor = theme.withAlpha(theme.text.secondary, 0.5)
        end

        ui.setCursor(vec2(speedTextX, speedTextY))
        ui.pushStyleColor(ui.StyleColor.Text, speedTextColor)
        ui.text(speedText)
        ui.popStyleColor()
        ui.popFont()
    end
end

--- Reset smoothing state (call on lap reset)
function delta_bar.reset()
    lastSpeedDiff = 0
    lastDisplayDelta = 0
    displayUpdateTimer = 0
end

return delta_bar
