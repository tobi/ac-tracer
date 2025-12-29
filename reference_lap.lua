-- Reference Lap module for AC Tracer
-- Handles CSV/ghost file loading with standalone or embedded rendering

local lap = require('lap')

-- Deferred require to avoid circular dependency (state -> app_settings -> reference_lap -> state)
local state = nil
local function getState()
    if not state then
        state = require('state')
    end
    return state
end

local M = {}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local ghostFiles = nil
local ghostFilesLastScan = 0
local ghostCache = {}  -- Cache: filename -> lap
local isLoadingGhost = false
local selectedFile = nil  -- Currently selected file for preview
local scrollY = 0

-- File info cache for preview
local fileInfo = {}  -- filename -> { lapTime, samples, track, car }

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function getTrackGhostName()
    local trackId = ac.getTrackID()
    if not trackId then return nil end
    return trackId:gsub("[/\\:]", "_") .. ".csv"
end

local function formatLapTime(ms)
    if not ms or ms <= 0 then return "--:--.---" end
    local mins = math.floor(ms / 60000)
    local secs = (ms % 60000) / 1000
    return string.format("%d:%06.3f", mins, secs)
end

--------------------------------------------------------------------------------
-- File Scanning
--------------------------------------------------------------------------------

local function scanGhostFiles()
    local now = os.clock()
    if ghostFiles and (now - ghostFilesLastScan) < 5 then
        return ghostFiles
    end

    ghostFiles = {}
    local tracksPath = __dirname .. "/tracks/"

    -- Priority: track-specific file first
    local trackGhost = getTrackGhostName()
    if trackGhost and fileExists(tracksPath .. trackGhost) then
        table.insert(ghostFiles, trackGhost)
    end

    -- Scan for all CSV files in tracks folder
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

local function getFileInfo(filename)
    if fileInfo[filename] then
        return fileInfo[filename]
    end

    -- Quick scan of first few lines to get metadata
    local tracksPath = __dirname .. "/tracks/"
    local f = io.open(tracksPath .. filename, "r")
    if not f then return nil end

    local info = {
        lapTime = nil,
        samples = 0,
        track = nil,
        car = nil
    }

    -- Count lines (rough sample count)
    local lineCount = 0
    for _ in f:lines() do
        lineCount = lineCount + 1
    end
    info.samples = math.max(0, lineCount - 1)  -- Subtract header

    f:close()
    fileInfo[filename] = info
    return info
end

--------------------------------------------------------------------------------
-- Loading
--------------------------------------------------------------------------------

local function loadGhostFile(filename)
    if isLoadingGhost then return false end
    isLoadingGhost = true

    local st = getState()

    -- Check cache first
    local lapData = ghostCache[filename]

    if lapData then
        -- Cache hit
        st.setBestLap(lapData)
        ac.setMessage("Ghost Loaded", "Loaded " .. lapData:length() .. " samples (cached)")
    else
        -- Cache miss - parse CSV using lap module
        local filePath = __dirname .. "/tracks/" .. filename
        lapData = lap.fromCSV(filePath, st.track, st.car)

        if lapData then
            ghostCache[filename] = lapData
            st.setBestLap(lapData)
            ac.setMessage("Ghost Loaded", "Loaded " .. lapData:length() .. " samples from " .. filename)
        else
            ac.setMessage("Load Error", "Failed to load " .. filename)
            isLoadingGhost = false
            return false
        end
    end

    isLoadingGhost = false
    return true
end

--------------------------------------------------------------------------------
-- UI Colors
--------------------------------------------------------------------------------

local colors = {
    bg = rgbm(0.12, 0.12, 0.14, 1),
    cardBg = rgbm(0.16, 0.16, 0.18, 1),
    cardBgHover = rgbm(0.20, 0.20, 0.22, 1),
    cardBgSelected = rgbm(0.18, 0.22, 0.28, 1),
    accent = rgbm(0.3, 0.6, 1.0, 1),
    accentDim = rgbm(0.2, 0.4, 0.7, 0.8),
    text = rgbm(0.9, 0.9, 0.9, 1),
    textDim = rgbm(0.6, 0.6, 0.6, 1),
    textMuted = rgbm(0.4, 0.4, 0.4, 1),
    success = rgbm(0.3, 0.8, 0.3, 1),
    warning = rgbm(1.0, 0.7, 0.2, 1),
    separator = rgbm(0.25, 0.25, 0.28, 1),
}

--------------------------------------------------------------------------------
-- Compact UI (for settings embed)
--------------------------------------------------------------------------------

function M.drawCompact()
    local st = getState()

    -- Current reference info
    if st.hasBestLap() then
        local bestTime = st.getBestLapTime()
        if bestTime then
            ui.text("Reference: " .. formatLapTime(bestTime * 1000))
        end
        ui.sameLine(180)
        if ui.button("Clear##ref", vec2(50, 0)) then
            st.resetBestLap()
        end
    else
        ui.textColored("No reference lap", colors.textDim)
    end

    ui.offsetCursorY(5)

    -- Quick load buttons
    local files = scanGhostFiles()
    if #files == 0 then
        ui.textColored("No CSV files in tracks/", colors.textMuted)
    else
        for i, filename in ipairs(files) do
            if i > 3 then
                ui.textColored("+" .. (#files - 3) .. " more...", colors.textMuted)
                break
            end

            local displayName = filename:gsub("%.csv$", "")
            if #displayName > 25 then
                displayName = displayName:sub(1, 22) .. "..."
            end

            if ui.button(displayName, vec2(180, 0)) then
                loadGhostFile(filename)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Full Window UI
--------------------------------------------------------------------------------

function M.draw(dt)
    local st = getState()
    local windowSize = ui.availableSpace()
    local padding = 12
    local cardHeight = 60
    local cardGap = 6

    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, colors.bg, 0)

    -- Header
    ui.pushFont(ui.Font.Title)
    ui.setCursor(vec2(padding, padding))
    ui.text("Reference Lap")
    ui.popFont()

    -- Current reference status
    local headerY = padding + 30
    ui.setCursor(vec2(padding, headerY))

    if st.hasBestLap() then
        local bestTime = st.getBestLapTime()
        local bestLap = st.getBestLap()

        -- Status card
        local statusHeight = 50
        ui.drawRectFilled(
            vec2(padding, headerY),
            vec2(windowSize.x - padding, headerY + statusHeight),
            colors.cardBg, 4
        )

        -- Left side: lap time
        ui.pushFont(ui.Font.Title)
        ui.setCursor(vec2(padding + 12, headerY + 10))
        ui.textColored(formatLapTime(bestTime * 1000), colors.success)
        ui.popFont()

        -- Right side: clear button
        local btnWidth = 60
        ui.setCursor(vec2(windowSize.x - padding - btnWidth - 12, headerY + 12))
        if ui.button("Clear", vec2(btnWidth, 26)) then
            st.resetBestLap()
        end

        -- Samples info
        ui.pushFont(ui.Font.Small)
        ui.setCursor(vec2(padding + 100, headerY + 16))
        ui.textColored(bestLap:length() .. " samples", colors.textDim)
        ui.popFont()

        headerY = headerY + statusHeight + 10
    else
        -- No reference card
        local statusHeight = 40
        ui.drawRectFilled(
            vec2(padding, headerY),
            vec2(windowSize.x - padding, headerY + statusHeight),
            rgbm(0.18, 0.15, 0.12, 1), 4
        )
        ui.setCursor(vec2(padding + 12, headerY + 11))
        ui.textColored("No reference lap loaded", colors.warning)

        headerY = headerY + statusHeight + 10
    end

    -- Separator
    ui.drawLine(
        vec2(padding, headerY),
        vec2(windowSize.x - padding, headerY),
        colors.separator, 1
    )
    headerY = headerY + 10

    -- Section title
    ui.pushFont(ui.Font.Main)
    ui.setCursor(vec2(padding, headerY))
    ui.textColored("Available Files", colors.textDim)
    ui.popFont()
    headerY = headerY + 22

    -- File list
    local files = scanGhostFiles()
    local listTop = headerY
    local listHeight = windowSize.y - headerY - padding

    if #files == 0 then
        ui.setCursor(vec2(padding, listTop + 20))
        ui.textColored("No CSV files found in tracks/ folder", colors.textMuted)

        ui.pushFont(ui.Font.Small)
        ui.setCursor(vec2(padding, listTop + 40))
        ui.textColored("Place .csv files exported from MoTeC or similar", colors.textMuted)
        ui.setCursor(vec2(padding, listTop + 54))
        ui.textColored("in the app's tracks/ folder", colors.textMuted)
        ui.popFont()
    else
        local y = listTop
        for _, filename in ipairs(files) do
            if y + cardHeight > windowSize.y - padding then
                break  -- Stop if we'd overflow
            end

            local isSelected = selectedFile == filename
            local isHovered = ui.rectHovered(vec2(padding, y), vec2(windowSize.x - padding, y + cardHeight))

            -- Card background
            local cardColor = isSelected and colors.cardBgSelected or (isHovered and colors.cardBgHover or colors.cardBg)
            ui.drawRectFilled(
                vec2(padding, y),
                vec2(windowSize.x - padding, y + cardHeight),
                cardColor, 4
            )

            -- Selection indicator
            if isSelected then
                ui.drawRectFilled(
                    vec2(padding, y),
                    vec2(padding + 3, y + cardHeight),
                    colors.accent, 4
                )
            end

            -- Filename
            local displayName = filename:gsub("%.csv$", "")
            ui.setCursor(vec2(padding + 12, y + 8))
            ui.textColored(displayName, colors.text)

            -- File info
            local info = getFileInfo(filename)
            if info then
                ui.pushFont(ui.Font.Small)
                ui.setCursor(vec2(padding + 12, y + 28))
                local infoText = info.samples .. " samples"
                if info.lapTime then
                    infoText = formatLapTime(info.lapTime) .. " · " .. infoText
                end
                ui.textColored(infoText, colors.textDim)
                ui.popFont()
            end

            -- Track-specific indicator
            local trackGhost = getTrackGhostName()
            if filename == trackGhost then
                ui.pushFont(ui.Font.Small)
                local tag = "CURRENT TRACK"
                local tagSize = ui.measureText(tag)
                ui.setCursor(vec2(windowSize.x - padding - tagSize.x - 50, y + 10))
                ui.textColored(tag, colors.accent)
                ui.popFont()
            end

            -- Load button
            local btnWidth = 50
            ui.setCursor(vec2(windowSize.x - padding - btnWidth - 12, y + 18))
            if ui.button("Load##" .. filename, vec2(btnWidth, 24)) then
                loadGhostFile(filename)
            end

            -- Click to select
            if isHovered and ui.mouseClicked(0) then
                selectedFile = filename
            end

            -- Double-click to load
            if isHovered and ui.mouseDoubleClicked(0) then
                loadGhostFile(filename)
            end

            y = y + cardHeight + cardGap
        end
    end
end

--------------------------------------------------------------------------------
-- Window function for standalone rendering
--------------------------------------------------------------------------------

function M.windowReferenceLap(dt)
    M.draw(dt)
end

--------------------------------------------------------------------------------
-- Refresh file list
--------------------------------------------------------------------------------

function M.refresh()
    ghostFiles = nil
    fileInfo = {}
end

return M
