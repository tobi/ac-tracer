--[[
AC Tracer Simulator - LÖVE2D Version
Runs ac-tracer outside of Assetto Corsa

Usage:
  cd ac-tracer
  love sim/

Or on Windows/macOS, drag the sim folder onto the LÖVE application.
]]

-- Add parent directory to path for ac-tracer modules
local simDir = love.filesystem.getSource()
package.path = simDir .. "/../?.lua;" .. simDir .. "/../?/init.lua;" .. package.path

-- Load CSP compatibility layer FIRST (creates global ac, ui, render, etc.)
require('sim.csp_compat_love')

-- Now load ac-tracer modules
local lap = require('lap')
local state = require('state')
local settings = require('app_settings')
local theme = require('theme')

--------------------------------------------------------------------------------
-- Simulator State
--------------------------------------------------------------------------------

local sim = {
    -- Playback
    playback = {
        lap = nil,
        position = 0,
        playing = false,
        speed = 1.0,
        time = 0,
        lapTime = 0,
    },

    -- UI
    showHelp = false,
    showTimeline = true,

    -- Fonts
    font = nil,
    fontSmall = nil,
    fontMono = nil,
    fontLarge = nil,
}

--------------------------------------------------------------------------------
-- Playback Functions
--------------------------------------------------------------------------------

local function loadLap(filepath)
    print("Loading lap: " .. filepath)

    local loadedLap = lap.fromCSV(filepath)
    if loadedLap and loadedLap:length() > 10 then
        sim.playback.lap = loadedLap
        sim.playback.position = 0
        sim.playback.time = 0
        sim.playback.lapTime = loadedLap.time / 1000
        sim.playback.playing = false

        -- Update state
        state.bestLap = loadedLap
        state.currentLap = lap.new(loadedLap.track, loadedLap.car)

        -- Export for csp_compat
        _G._playbackLap = loadedLap

        print(string.format("Loaded: %d samples, %.2f seconds", loadedLap:length(), sim.playback.lapTime))
        return true
    end

    print("Failed to load lap")
    return false
end

local function updatePlayback(dt)
    if not sim.playback.lap or not sim.playback.playing then return end

    sim.playback.time = sim.playback.time + (dt * sim.playback.speed)

    if sim.playback.time >= sim.playback.lapTime then
        sim.playback.time = 0  -- Loop
    end

    -- Find position at time
    local lapData = sim.playback.lap
    local times = lapData.times
    for i = 1, #times - 1 do
        if times[i + 1] > sim.playback.time then
            local frac = (sim.playback.time - times[i]) / (times[i + 1] - times[i])
            sim.playback.position = lapData.pos[i] + (lapData.pos[i + 1] - lapData.pos[i]) * frac
            break
        end
    end

    _G._mockCarPosition = sim.playback.position
end

local function seekToPosition(pos)
    sim.playback.position = math.clamp(pos, 0, 1)
    if sim.playback.lap then
        sim.playback.time = sim.playback.lap:timeAt(sim.playback.position)
    end
    _G._mockCarPosition = sim.playback.position
end

local function seekByTime(delta)
    sim.playback.time = math.max(0, sim.playback.time + delta)
    if sim.playback.lapTime > 0 then
        sim.playback.time = math.min(sim.playback.time, sim.playback.lapTime)
        seekToPosition(sim.playback.time / sim.playback.lapTime)
    end
end

--------------------------------------------------------------------------------
-- LÖVE Callbacks
--------------------------------------------------------------------------------

function love.load()
    -- Fonts
    sim.font = love.graphics.newFont(14)
    sim.fontSmall = love.graphics.newFont(11)
    sim.fontMono = love.graphics.newFont(13)
    sim.fontLarge = love.graphics.newFont(24)

    love.graphics.setFont(sim.font)

    -- Initialize state
    state.init({ id = function() return "sim_car" end })

    -- Try to load first CSV from tracks folder
    local parentDir = love.filesystem.getSource() .. "/../"
    local tracksDir = parentDir .. "tracks"

    -- Check if tracks directory exists and has files
    local info = love.filesystem.getInfo("../tracks")
    if info then
        local files = love.filesystem.getDirectoryItems("../tracks")
        for _, f in ipairs(files or {}) do
            if f:match("%.csv$") then
                loadLap(parentDir .. "tracks/" .. f)
                break
            end
        end
    end

    print("AC Tracer Simulator ready. Press H for help.")
end

function love.update(dt)
    updatePlayback(dt)
    state.update(dt, ac.getCar(0))
end

function love.draw()
    local w, h = love.graphics.getDimensions()

    -- Background
    love.graphics.setBackgroundColor(0.08, 0.08, 0.08)
    love.graphics.clear()

    -- Main trace area
    drawTraceWindow(10, 30, 600, 250)

    -- Info panel
    drawInfoPanel(620, 30, 250, 150)

    -- Timeline at bottom
    if sim.showTimeline then
        drawTimeline(10, h - 90, w - 20, 80)
    end

    -- Status bar
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(sim.fontSmall)
    love.graphics.print("H - Help | Space - Play/Pause | Drop CSV to load", 10, 5)

    -- Help overlay
    if sim.showHelp then
        drawHelp()
    end
end

function love.keypressed(key)
    if key == "space" then
        sim.playback.playing = not sim.playback.playing
    elseif key == "h" then
        sim.showHelp = not sim.showHelp
    elseif key == "r" then
        sim.playback.position = 0
        sim.playback.time = 0
        _G._mockCarPosition = 0
    elseif key == "left" then
        seekByTime(-1)
    elseif key == "right" then
        seekByTime(1)
    elseif key == "," then
        seekByTime(-1/60)
    elseif key == "." then
        seekByTime(1/60)
    elseif key == "1" then
        sim.playback.speed = 0.25
    elseif key == "2" then
        sim.playback.speed = 0.5
    elseif key == "3" then
        sim.playback.speed = 1.0
    elseif key == "4" then
        sim.playback.speed = 2.0
    elseif key == "t" then
        sim.showTimeline = not sim.showTimeline
    elseif key == "escape" then
        if sim.showHelp then
            sim.showHelp = false
        else
            love.event.quit()
        end
    end
end

function love.filedropped(file)
    local path = file:getFilename()
    if path:match("%.csv$") then
        loadLap(path)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local w, h = love.graphics.getDimensions()
        -- Check timeline click
        if sim.showTimeline and y > h - 90 then
            local timelineX, timelineW = 10, w - 20
            local barY, barH = h - 50, 20
            if y >= barY and y <= barY + barH then
                local relX = (x - timelineX) / timelineW
                seekToPosition(relX)
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        local w, h = love.graphics.getDimensions()
        if sim.showTimeline and y > h - 90 then
            local timelineX, timelineW = 10, w - 20
            local relX = (x - timelineX) / timelineW
            seekToPosition(relX)
        end
    end
end

--------------------------------------------------------------------------------
-- Drawing Functions
--------------------------------------------------------------------------------

function drawTraceWindow(x, y, w, h)
    -- Window background
    love.graphics.setColor(0.12, 0.12, 0.12, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 4)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", x, y, w, h, 4)

    -- Title
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", x, y, w, 24, 4)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(sim.fontSmall)
    love.graphics.print("Main Traces", x + 8, y + 5)

    if not sim.playback.lap then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(sim.font)
        love.graphics.printf("No lap loaded\n\nDrop a CSV file to load", x, y + h/2 - 30, w, "center")
        return
    end

    local lapData = sim.playback.lap
    local pos = sim.playback.position

    -- Content area
    local cx, cy = x + 10, y + 30
    local cw, ch = w - 20, h - 40

    -- Graph area
    local graphW = cw * 0.7
    local graphH = ch - 30

    -- Draw graph background
    love.graphics.setColor(0.06, 0.06, 0.06)
    love.graphics.rectangle("fill", cx, cy, graphW, graphH)

    -- Draw traces around current position
    local windowSize = 120  -- samples
    local centerIdx = math.floor(pos * lapData:length())
    local startIdx = math.max(1, centerIdx - windowSize/2)
    local endIdx = math.min(lapData:length(), startIdx + windowSize)
    local n = endIdx - startIdx

    if n > 2 then
        local maxSpeed = 300
        for i = startIdx, endIdx do
            if (lapData.speed[i] or 0) > maxSpeed * 0.9 then
                maxSpeed = (lapData.speed[i] or 0) * 1.1
            end
        end

        -- Draw each trace type
        local function drawTrace(getData, color, maxVal)
            love.graphics.setColor(unpack(color))
            love.graphics.setLineWidth(1.5)
            local points = {}
            for i = startIdx, endIdx do
                local px = cx + (i - startIdx) / n * graphW
                local val = getData(i) or 0
                local py = cy + graphH - (val / maxVal) * graphH
                table.insert(points, px)
                table.insert(points, py)
            end
            if #points >= 4 then
                love.graphics.line(points)
            end
        end

        -- Speed (blue, faded)
        drawTrace(function(i) return lapData.speed[i] end, {0.3, 0.5, 0.8, 0.5}, maxSpeed)

        -- Throttle (green)
        drawTrace(function(i) return lapData.throttle[i] end, {0.2, 0.8, 0.2, 0.9}, 1)

        -- Brake (red)
        drawTrace(function(i) return (lapData.brake[i] or 0) / 100 end, {0.9, 0.2, 0.2, 0.9}, 1)

        -- Steering (yellow)
        drawTrace(function(i) return lapData.steering[i] end, {0.8, 0.8, 0.2, 0.7}, 1)
    end

    -- Center line (current position)
    local centerX = cx + graphW / 2
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(centerX, cy, centerX, cy + graphH)

    -- Throttle/Brake bars
    local barW = 35
    local barX = cx + graphW + 20

    local throttle = lapData:throttleAt(pos)
    local brake = lapData:brakeAt(pos) / 100

    -- Throttle
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", barX, cy, barW, graphH)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", barX, cy + graphH * (1 - throttle), barW, graphH * throttle)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", barX, cy, barW, graphH)

    -- Brake
    barX = barX + barW + 10
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", barX, cy, barW, graphH)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, cy + graphH * (1 - brake), barW, graphH * brake)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", barX, cy, barW, graphH)

    -- Legend
    local legendY = cy + graphH + 5
    love.graphics.setFont(sim.fontSmall)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print("Throttle", cx + 5, legendY)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.print("Brake", cx + 70, legendY)
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("Steering", cx + 120, legendY)
    love.graphics.setColor(0.3, 0.5, 0.8)
    love.graphics.print("Speed", cx + 190, legendY)
end

function drawInfoPanel(x, y, w, h)
    -- Background
    love.graphics.setColor(0.12, 0.12, 0.12, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 4)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", x, y, w, h, 4)

    -- Title
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", x, y, w, 24, 4)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(sim.fontSmall)
    love.graphics.print("Current Data", x + 8, y + 5)

    if not sim.playback.lap then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("--", x + w/2 - 10, y + h/2)
        return
    end

    local lapData = sim.playback.lap
    local pos = sim.playback.position

    local speed = lapData:speedAt(pos)
    local gear = lapData:gearAt(pos)
    local throttle = lapData:throttleAt(pos) * 100
    local brake = lapData:brakeAt(pos)

    love.graphics.setFont(sim.font)
    love.graphics.setColor(1, 1, 1)

    local cy = y + 35
    love.graphics.print(string.format("Speed: %d km/h", math.floor(speed)), x + 10, cy)
    cy = cy + 22
    love.graphics.print(string.format("Gear: %d", gear), x + 10, cy)
    cy = cy + 22
    love.graphics.print(string.format("Throttle: %.0f%%", throttle), x + 10, cy)
    cy = cy + 22
    love.graphics.print(string.format("Brake: %.0f bar", brake), x + 10, cy)
end

function drawTimeline(x, y, w, h)
    -- Background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 4)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", x, y, w, h, 4)

    -- Status text
    love.graphics.setFont(sim.fontSmall)
    local statusColor = sim.playback.playing and {0.2, 0.8, 0.2} or {0.8, 0.5, 0.2}
    love.graphics.setColor(unpack(statusColor))
    love.graphics.print(sim.playback.playing and "Playing" or "Paused", x + 10, y + 8)

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("%.2fx", sim.playback.speed), x + 80, y + 8)

    if not sim.playback.lap then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No lap loaded - drop a CSV file", x + 150, y + 8)
        return
    end

    -- Time display
    love.graphics.setColor(0.8, 0.8, 0.8)
    local timeStr = string.format("%.2f / %.2f", sim.playback.time, sim.playback.lapTime)
    love.graphics.print(timeStr, x + w - 100, y + 8)

    -- Progress bar
    local barY = y + 30
    local barH = 20

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", x + 10, barY, w - 20, barH, 3)

    love.graphics.setColor(0.3, 0.5, 0.8)
    love.graphics.rectangle("fill", x + 10, barY, (w - 20) * sim.playback.position, barH, 3)

    -- Playhead
    local playheadX = x + 10 + (w - 20) * sim.playback.position
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", playheadX - 2, barY - 3, 4, barH + 6, 2)

    -- Buttons
    local btnY = y + 55
    local btnW, btnH = 60, 22

    -- Play/Pause
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", x + 10, btnY, btnW, btnH, 3)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(sim.playback.playing and "Pause" or "Play", x + 20, btnY + 4)

    -- Speed buttons
    local speeds = {0.25, 0.5, 1.0, 2.0}
    local labels = {"0.25x", "0.5x", "1x", "2x"}
    for i, spd in ipairs(speeds) do
        local bx = x + 80 + (i-1) * 50
        love.graphics.setColor(sim.playback.speed == spd and {0.3, 0.5, 0.8} or {0.25, 0.25, 0.25})
        love.graphics.rectangle("fill", bx, btnY, 45, btnH, 3)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(labels[i], bx + 8, btnY + 4)
    end
end

function drawHelp()
    local w, h = love.graphics.getDimensions()

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Help box
    local boxW, boxH = 420, 360
    local boxX, boxY = (w - boxW) / 2, (h - boxH) / 2

    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8)
    love.graphics.setColor(0.4, 0.6, 1.0)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8)

    -- Title
    love.graphics.setFont(sim.fontLarge)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("AC Tracer Simulator", boxX, boxY + 15, boxW, "center")

    -- Controls
    love.graphics.setFont(sim.font)
    love.graphics.setColor(0.9, 0.9, 0.9)
    local controls = {
        "Space       Play/Pause",
        "Left/Right  Seek +/- 1 second",
        ",/.         Previous/Next frame",
        "1/2/3/4     Speed (0.25x/0.5x/1x/2x)",
        "R           Reset to start",
        "T           Toggle timeline",
        "H           Toggle this help",
        "Escape      Close help / Quit",
        "",
        "Drop a CSV file onto the window to load.",
        "",
        "CSV files should be in MoTeC format or",
        "AC Tracer's native export format.",
    }

    local lineY = boxY + 60
    for _, line in ipairs(controls) do
        love.graphics.print(line, boxX + 25, lineY)
        lineY = lineY + 22
    end

    -- Close hint
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Press H or Escape to close", boxX, boxY + boxH - 35, boxW, "center")
end
