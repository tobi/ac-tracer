-- Reference Lap module for AC Tracer
-- Provides a clean lap picker window (replaces popup)

local lap = require('lap')

-- Deferred require to avoid circular dependency
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
local isLoadingRef = false
local scrollOffset = 0

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function formatLapTime(ms)
    if not ms or ms <= 0 then return "--:--.---" end
    local mins = math.floor(ms / 60000)
    local secs = (ms % 60000) / 1000
    return string.format("%d:%06.3f", mins, secs)
end

local function formatFileSize(bytes)
    if not bytes then return "" end
    if bytes < 1024 then return bytes .. "B" end
    if bytes < 1024 * 1024 then return string.format("%.1fKB", bytes / 1024) end
    return string.format("%.1fMB", bytes / (1024 * 1024))
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
    local seenFiles = {}  -- Track by lowercase filename to avoid duplicates

    -- Scan directories for CSV files
    local searchPaths = {
        { path = __dirname .. "/tracks/", source = "tracks" },
        { path = "C:\\MoTeC\\Logged Data\\", source = "motec" },
    }

    for _, dir in ipairs(searchPaths) do
        if io.dirExists(dir.path) then
            local csvFiles = io.scanDir(dir.path, "*.csv")
            if csvFiles then
                for _, filename in ipairs(csvFiles) do
                    local lowerName = filename:lower()
                    if not seenFiles[lowerName] then
                        seenFiles[lowerName] = true
                        local fullPath = dir.path .. filename
                        table.insert(ghostFiles, {
                            filename = filename,
                            path = fullPath,
                            source = dir.source,
                            size = io.fileSize(fullPath)
                        })
                    end
                end
            end
        end
    end

    -- Sort by filename
    table.sort(ghostFiles, function(a, b) return a.filename < b.filename end)

    ghostFilesLastScan = now
    return ghostFiles
end

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

local colors = {
    bg = rgbm(0.08, 0.08, 0.10, 0.98),
    sectionBg = rgbm(0.12, 0.12, 0.14, 1),
    text = rgbm(0.9, 0.9, 0.9, 1),
    textDim = rgbm(0.5, 0.5, 0.5, 1),
    textBright = rgbm(1, 1, 1, 1),
    accent = rgbm(0.3, 0.6, 1, 1),
    success = rgbm(0.4, 0.9, 0.4, 1),
    warning = rgbm(1, 0.7, 0.3, 1),
    refColor = rgbm(0.5, 0.7, 1, 1),
    curColor = rgbm(0.5, 1, 0.5, 1),
    csvColor = rgbm(0.8, 0.6, 0.4, 1),
    separator = rgbm(0.2, 0.2, 0.25, 1),
    btnCur = rgbm(0.2, 0.4, 0.2, 1),
    btnCurHover = rgbm(0.3, 0.5, 0.3, 1),
    btnRef = rgbm(0.2, 0.2, 0.4, 1),
    btnRefHover = rgbm(0.3, 0.3, 0.5, 1),
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
end

--------------------------------------------------------------------------------
-- Full Window UI
--------------------------------------------------------------------------------

function M.draw(dt)
    local st = getState()
    local windowSize = ui.availableSpace()
    local padding = 10
    local rowHeight = 22
    local btnW = 35
    local labelW = windowSize.x - btnW * 2 - padding * 3 - 20

    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, colors.bg, 0)

    local py = padding

    -- Header with current reference
    ui.pushFont(ui.Font.Main)
    ui.setCursor(vec2(padding, py))
    ui.textColored("Reference Lap", colors.textBright)
    ui.popFont()
    py = py + 22

    -- Current reference status
    if st.hasBestLap() then
        local bestTime = st.getBestLapTime()
        local bestLap = st.getBestLap()
        ui.setCursor(vec2(padding, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored(formatLapTime(bestTime * 1000), colors.success)
        ui.sameLine()
        ui.textColored(" (" .. bestLap:length() .. " pts)", colors.textDim)
        ui.popFont()

        -- Clear button
        ui.sameLine(windowSize.x - padding - 45)
        if ui.button("Clear", vec2(40, 18)) then
            st.resetBestLap()
        end
    else
        ui.setCursor(vec2(padding, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No reference loaded", colors.warning)
        ui.popFont()
    end
    py = py + 24

    -- Separator
    ui.drawLine(vec2(padding, py), vec2(windowSize.x - padding, py), colors.separator, 1)
    py = py + 8

    -- Column headers
    ui.setCursor(vec2(padding, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("Lap", colors.textDim)
    ui.sameLine(windowSize.x - btnW * 2 - padding - 15)
    ui.textColored("C", colors.textDim)
    ui.sameLine(windowSize.x - btnW - padding - 5)
    ui.textColored("R", colors.textDim)
    ui.popFont()
    py = py + 16

    -- Helper to draw a lap entry
    local function drawLapEntry(lapData, idx, prefix, labelColor)
        local lapTimeS = lapData.time / 1000
        local mins = math.floor(lapTimeS / 60)
        local secs = lapTimeS - mins * 60
        local lapNum = (lapData.lapNumberInSession and lapData.lapNumberInSession > 0)
            and string.format("L%d ", lapData.lapNumberInSession) or ""
        local lapLabel = string.format("%s%s%d:%05.2f", lapNum, prefix, mins, secs)
        local isBest = lapData == st.bestLap

        ui.setCursor(vec2(padding, py + 2))
        ui.pushFont(ui.Font.Small)
        ui.pushStyleColor(ui.StyleColor.Text, isBest and colors.refColor or labelColor)
        ui.text(lapLabel)
        if isBest then
            ui.sameLine()
            ui.textColored("(ref)", colors.textDim)
        end
        ui.popStyleColor()
        ui.popFont()

        -- "C" button (set as current to view)
        ui.setCursor(vec2(windowSize.x - btnW * 2 - padding - 10, py))
        ui.pushStyleColor(ui.StyleColor.Button, colors.btnCur)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.btnCurHover)
        if ui.button("C##c" .. idx, vec2(btnW, 18)) then
            -- This would need integration with lap_telemetry's selectedLapIndex
            -- For now, just add to history at front
            table.insert(st.history, 1, lapData)
            ac.setMessage("Viewing", string.format("%d:%05.2f", mins, secs))
        end
        ui.popStyleColor(2)

        -- "R" button (set as reference)
        ui.sameLine()
        ui.pushStyleColor(ui.StyleColor.Button, colors.btnRef)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.btnRefHover)
        if ui.button("R##r" .. idx, vec2(btnW, 18)) then
            st.setBestLap(lapData)
            ac.setMessage("Reference Set", string.format("%d:%05.2f", mins, secs))
        end
        ui.popStyleColor(2)

        py = py + rowHeight
    end

    -- Current Session Laps
    ui.setCursor(vec2(padding, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("This Session", colors.curColor)
    ui.popFont()
    py = py + 16

    local currentSessionLaps = st.getCurrentSessionLaps()
    if #currentSessionLaps > 0 then
        local shown = 0
        for _, entry in ipairs(currentSessionLaps) do
            if shown < 6 and py < windowSize.y - 150 then
                drawLapEntry(entry.lap, entry.index, "", colors.text)
                shown = shown + 1
            end
        end
    else
        ui.setCursor(vec2(padding + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No laps yet", colors.textDim)
        ui.popFont()
        py = py + 18
    end

    py = py + 6
    ui.drawLine(vec2(padding, py), vec2(windowSize.x - padding, py), colors.separator, 1)
    py = py + 8

    -- Previous Session Laps
    ui.setCursor(vec2(padding, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("Previous Sessions", colors.refColor)
    ui.popFont()
    py = py + 16

    local prevSessionLaps = st.getPreviousSessionLaps()
    if #prevSessionLaps > 0 then
        local shown = 0
        for _, entry in ipairs(prevSessionLaps) do
            if shown < 4 and py < windowSize.y - 100 then
                drawLapEntry(entry.lap, entry.index + 1000, "", colors.text)
                shown = shown + 1
            end
        end
    else
        ui.setCursor(vec2(padding + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No saved laps", colors.textDim)
        ui.popFont()
        py = py + 18
    end

    py = py + 6
    ui.drawLine(vec2(padding, py), vec2(windowSize.x - padding, py), colors.separator, 1)
    py = py + 8

    -- CSV Files
    ui.setCursor(vec2(padding, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("CSV Files (tracks/)", colors.csvColor)
    ui.popFont()
    py = py + 16

    local files = scanGhostFiles()
    if #files > 0 then
        for j, fileInfo in ipairs(files) do
            if py < windowSize.y - 30 then
                local displayName = fileInfo.filename:gsub("%.csv$", "")

                ui.setCursor(vec2(padding, py + 2))
                ui.pushFont(ui.Font.Small)
                ui.pushStyleColor(ui.StyleColor.Text, colors.text)
                ui.text(displayName)
                ui.popStyleColor()

                -- Size hint
                ui.sameLine()
                ui.textColored(" " .. formatFileSize(fileInfo.size), colors.textDim)
                ui.popFont()

                -- "C" button
                ui.setCursor(vec2(windowSize.x - btnW * 2 - padding - 10, py))
                ui.pushStyleColor(ui.StyleColor.Button, colors.btnCur)
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.btnCurHover)
                if ui.button("C##csvc" .. j, vec2(btnW, 18)) and not isLoadingRef then
                    isLoadingRef = true
                    local trackLength = ac.getSim().trackLengthM
                    local loaded, warnings = lap.fromCSV(fileInfo.path, st.track, st.car, trackLength)
                    if loaded then
                        table.insert(st.history, 1, loaded)
                        table.insert(st.historyReferences, loaded)
                        local msg = string.format("%d:%05.2f",
                            math.floor(loaded.time / 60000), (loaded.time / 1000) % 60)
                        ac.setMessage("CSV Loaded", msg)
                    else
                        ac.setMessage("Error", warnings and warnings[1] or "Failed")
                    end
                    isLoadingRef = false
                end
                ui.popStyleColor(2)

                -- "R" button
                ui.sameLine()
                ui.pushStyleColor(ui.StyleColor.Button, colors.btnRef)
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.btnRefHover)
                if ui.button("R##csvr" .. j, vec2(btnW, 18)) and not isLoadingRef then
                    isLoadingRef = true
                    local trackLength = ac.getSim().trackLengthM
                    local loaded, warnings = lap.fromCSV(fileInfo.path, st.track, st.car, trackLength)
                    if loaded then
                        st.setBestLap(loaded)
                        table.insert(st.historyReferences, loaded)
                        local msg = string.format("%d:%05.2f",
                            math.floor(loaded.time / 60000), (loaded.time / 1000) % 60)
                        ac.setMessage("Reference Set", msg)
                    else
                        ac.setMessage("Error", warnings and warnings[1] or "Failed")
                    end
                    isLoadingRef = false
                end
                ui.popStyleColor(2)

                py = py + rowHeight
            end
        end
    else
        ui.setCursor(vec2(padding + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No CSV files in tracks/", colors.textDim)
        ui.popFont()
    end
end

--------------------------------------------------------------------------------
-- Refresh file list
--------------------------------------------------------------------------------

function M.refresh()
    ghostFiles = nil
end

return M
