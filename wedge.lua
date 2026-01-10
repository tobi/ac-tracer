-- wedge.lua - Score wedge rendering
-- Provides both full-size gauge and compact wedge rendering

local theme = require('theme')

local wedge = {}

--------------------------------------------------------------------------------
-- Full-size score gauge (for corner analysis window)
--------------------------------------------------------------------------------

--- Draw a full-size score gauge (pill/badge style with score number)
---@param cx number Center X position
---@param cy number Center Y position
---@param radius number Gauge radius (used to determine size)
---@param score number Score value (0-100)
function wedge.drawGauge(cx, cy, radius, score)
    -- Convert radius to pill dimensions
    local width = radius * 2.2
    local height = radius * 1.6
    local x = cx - width / 2
    local y = cy - height / 2
    
    -- Color based on score: green >80, yellow 60-80, red <60
    local color, bgColor
    if score >= 80 then
        color = theme.delta.positive
        bgColor = rgbm(0.08, 0.2, 0.08, 0.95)  -- Dark green bg
    elseif score >= 60 then
        color = theme.score.fill
        bgColor = rgbm(0.2, 0.15, 0.02, 0.95)  -- Dark gold bg
    else
        color = theme.delta.negative
        bgColor = rgbm(0.2, 0.08, 0.08, 0.95)  -- Dark red bg
    end
    
    -- Background pill
    ui.drawRectFilled(vec2(x, y), vec2(x + width, y + height), bgColor, 8)
    
    -- Score fill bar at bottom
    local barHeight = 4
    local barY = y + height - barHeight - 3
    local fillWidth = (score / 100) * (width - 8)
    
    -- Background bar
    ui.drawRectFilled(
        vec2(x + 4, barY),
        vec2(x + width - 4, barY + barHeight),
        theme.withAlpha(theme.score.bg, 0.4), 2
    )
    
    -- Filled portion
    if fillWidth > 2 then
        ui.drawRectFilled(
            vec2(x + 4, barY),
            vec2(x + 4 + fillWidth, barY + barHeight),
            theme.withAlpha(color, 0.9), 2
        )
    end
    
    -- Score text (large, centered above bar)
    local scoreText = tostring(math.floor(score))
    ui.pushFont(ui.Font.Title)
    local textSize = ui.measureText(scoreText)
    ui.setCursor(vec2(cx - textSize.x / 2, cy - textSize.y / 2 - 3))
    ui.pushStyleColor(ui.StyleColor.Text, color)
    ui.text(scoreText)
    ui.popStyleColor()
    ui.popFont()
    
    -- Border
    ui.drawRect(vec2(x, y), vec2(x + width, y + height), theme.withAlpha(color, 0.6), 8, 1.5)
end

--------------------------------------------------------------------------------
-- Compact wedge (for delta bar and other small displays)
--------------------------------------------------------------------------------

--- Draw a compact score wedge (rounded rect with score number)
---@param x number Left X position
---@param y number Top Y position
---@param width number Width of the wedge
---@param height number Height of the wedge
---@param score number Score value (0-100)
function wedge.drawCompact(x, y, width, height, score)
    local centerX = x + width / 2
    local centerY = y + height / 2
    
    -- Color based on score: green >80, yellow 60-80, red <60
    local color, bgColor
    if score >= 80 then
        color = theme.delta.positive
        bgColor = rgbm(0.1, 0.3, 0.1, 0.9)  -- Dark green bg
    elseif score >= 60 then
        color = theme.score.fill
        bgColor = rgbm(0.25, 0.2, 0.05, 0.9)  -- Dark gold bg
    else
        color = theme.delta.negative
        bgColor = rgbm(0.3, 0.1, 0.1, 0.9)  -- Dark red bg
    end
    
    -- Background pill/rounded rect
    ui.drawRectFilled(vec2(x, y), vec2(x + width, y + height), bgColor, 4)
    
    -- Score fill bar (left to right based on score)
    local fillWidth = (score / 100) * (width - 4)
    if fillWidth > 2 then
        ui.drawRectFilled(
            vec2(x + 2, y + height - 4),
            vec2(x + 2 + fillWidth, y + height - 2),
            theme.withAlpha(color, 0.8), 1
        )
    end
    
    -- Score text (centered)
    local scoreText = tostring(math.floor(score))
    ui.pushFont(ui.Font.Small)
    local textSize = ui.measureText(scoreText)
    ui.setCursor(vec2(centerX - textSize.x / 2, centerY - textSize.y / 2 - 1))
    ui.pushStyleColor(ui.StyleColor.Text, color)
    ui.text(scoreText)
    ui.popStyleColor()
    ui.popFont()
    
    -- Border
    ui.drawRect(vec2(x, y), vec2(x + width, y + height), theme.withAlpha(color, 0.5), 4, 1)
end

--- Draw a very minimal compact wedge (filled pie slice, smallest size)
---@param x number Left X position
---@param y number Top Y position
---@param size number Size (both width and height)
---@param score number Score value (0-100)
function wedge.drawMinimal(x, y, size, score)
    local centerX = x + size / 2
    local centerY = y + size / 2
    local outerRadius = size * 0.42  -- Outer radius for the pie slice
    local innerRadius = size * 0.15  -- Inner radius (makes it a donut/wedge)
    local startAngle = math.rad(-180)  -- Start from left
    local endAngle = math.rad(0)       -- End at top
    local totalArc = endAngle - startAngle
    
    -- Determine color based on score
    local color, glowColor
    if score >= 80 then
        color = theme.delta.positive
        glowColor = rgbm(0.3, 1, 0.3, 0.6)  -- Green glow
    elseif score >= 60 then
        color = theme.score.fill
        glowColor = rgbm(1, 0.85, 0, 0.5)  -- Gold glow
    else
        color = theme.delta.negative
        glowColor = rgbm(1, 0.3, 0.3, 0.5)  -- Red glow
    end
    
    -- Background wedge (full range, subtle)
    local segments = 24
    ui.pathClear()
    ui.pathLineTo(vec2(centerX + math.cos(startAngle) * innerRadius, centerY + math.sin(startAngle) * innerRadius))
    for i = 0, segments do
        local angle = startAngle + (i / segments) * totalArc
        local px = centerX + math.cos(angle) * outerRadius
        local py = centerY + math.sin(angle) * outerRadius
        ui.pathLineTo(vec2(px, py))
    end
    ui.pathLineTo(vec2(centerX + math.cos(endAngle) * innerRadius, centerY + math.sin(endAngle) * innerRadius))
    ui.pathFillConvex(theme.withAlpha(theme.score.bg, 0.3))
    
    -- Score wedge (filled pie slice)
    if score > 0 then
        local scoreAngle = startAngle + (score / 100) * totalArc
        local scoreSegments = math.max(8, math.floor(segments * (score / 100)))
        
        ui.pathClear()
        -- Start from center (inner radius)
        ui.pathLineTo(vec2(centerX + math.cos(startAngle) * innerRadius, centerY + math.sin(startAngle) * innerRadius))
        -- Arc along outer edge
        for i = 0, scoreSegments do
            local angle = startAngle + (i / scoreSegments) * (scoreAngle - startAngle)
            local px = centerX + math.cos(angle) * outerRadius
            local py = centerY + math.sin(angle) * outerRadius
            ui.pathLineTo(vec2(px, py))
        end
        -- Back along inner edge
        if scoreAngle ~= startAngle then
            ui.pathLineTo(vec2(centerX + math.cos(scoreAngle) * innerRadius, centerY + math.sin(scoreAngle) * innerRadius))
        end
        ui.pathFillConvex(color)
        
        -- Outer edge highlight (subtle glow)
        ui.pathClear()
        for i = 0, scoreSegments do
            local angle = startAngle + (i / scoreSegments) * (scoreAngle - startAngle)
            local px = centerX + math.cos(angle) * outerRadius
            local py = centerY + math.sin(angle) * outerRadius
            ui.pathLineTo(vec2(px, py))
        end
        ui.pathStroke(glowColor, false, 1.5)
    end
    
    -- Inner ring (optional accent)
    ui.drawCircleFilled(vec2(centerX, centerY), innerRadius - 0.5, theme.withAlpha(theme.score.bg, 0.8))
    ui.drawCircle(vec2(centerX, centerY), innerRadius + 0.5, theme.withAlpha(color, 0.4), 1, 1)
end

return wedge
