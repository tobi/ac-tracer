-- lap_picker.lua - Unified lap selection UI
-- Can render as standalone window or embedded popover
-- Single source for loading CSV files and selecting laps

local lap = require('lap')
local theme = require('theme')
local file_utils = require('file_utils')

-- Deferred require to avoid circular dependency
local state = nil
local function getState()
    if not state then
        state = require('state')
    end
    return state
end

local lap_picker = {}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local isLoadingLap = false

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------

-- These can be set by the caller to handle lap selection
lap_picker.onSelectCurrent = nil   -- function(lap, index) - called when "C" pressed
lap_picker.onSelectReference = nil -- function(lap) - called when "R" pressed
lap_picker.onClose = nil           -- function() - called when dialog should close

--------------------------------------------------------------------------------
-- Internal: Load CSV and create lap
--------------------------------------------------------------------------------

local function loadCSVLap(fileInfo)
    if isLoadingLap then return nil, "Already loading" end

    isLoadingLap = true
    local st = getState()
    local trackLength = ac.getSim().trackLengthM

    local loaded, warnings = lap.fromCSV(fileInfo.path, st.track, st.car, trackLength)

    isLoadingLap = false

    if loaded then
        -- Add to history (CSV laps have csvSource marker, won't be persisted)
        table.insert(st.history, 1, loaded)

        local msg = string.format("%d:%05.2f",
            math.floor(loaded.time / 60000), (loaded.time / 1000) % 60)
        if warnings and #warnings > 0 then
            msg = msg .. " (with warnings)"
            for _, w in ipairs(warnings) do
                ac.log("lap_picker: " .. w)
            end
        end
        return loaded, msg
    else
        return nil, warnings and warnings[1] or "Failed to load CSV"
    end
end

--------------------------------------------------------------------------------
-- Draw Helpers
--------------------------------------------------------------------------------

local ROW_HEIGHT = 22
local BTN_WIDTH = 35

--- Draw a lap entry row with C (current) and R (reference) buttons
---@param x number Left edge X
---@param y number Top edge Y
---@param width number Available width
---@param lapData table Lap data
---@param idx number|string Unique identifier for buttons
---@param options table { showCurrent, showReference, isBest, isCurrent }
---@return number New Y position after row
local function drawLapRow(x, y, width, lapData, idx, options)
    local st = getState()
    options = options or {}

    local lapTimeS = lapData.time / 1000
    local mins = math.floor(lapTimeS / 60)
    local secs = lapTimeS - mins * 60

    local lapNum = (lapData.lapNumberInSession and lapData.lapNumberInSession > 0)
        and string.format("L%d ", lapData.lapNumberInSession) or ""
    local lapLabel = string.format("%s%d:%05.2f", lapNum, mins, secs)

    local isBest = options.isBest or (lapData == st.bestLap)
    local isCurrent = options.isCurrent or false

    -- Lap label
    ui.setCursor(vec2(x, y + 2))
    ui.pushFont(ui.Font.Small)

    local labelColor = theme.text.primary
    if isBest then
        labelColor = theme.status.info
    elseif isCurrent then
        labelColor = theme.status.success
    end

    ui.pushStyleColor(ui.StyleColor.Text, labelColor)
    ui.text(lapLabel)

    if isBest then
        ui.sameLine()
        ui.textColored("(ref)", theme.text.muted)
    end
    if isCurrent then
        ui.sameLine()
        ui.textColored("(cur)", theme.text.muted)
    end
    ui.popStyleColor()
    ui.popFont()

    -- Button area
    local btnAreaX = x + width - BTN_WIDTH * 2 - 15

    -- "C" button (set as current to view)
    if options.showCurrent ~= false then
        ui.setCursor(vec2(btnAreaX, y))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.success)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.successHover)
        if ui.button("C##c" .. tostring(idx), vec2(BTN_WIDTH, 18)) then
            if lap_picker.onSelectCurrent then
                lap_picker.onSelectCurrent(lapData, idx)
            end
            ac.setMessage("Current Set", string.format("%d:%05.2f", mins, secs))
        end
        ui.popStyleColor(2)
    end

    -- "R" button (set as reference)
    if options.showReference ~= false then
        ui.setCursor(vec2(btnAreaX + BTN_WIDTH + 5, y))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.reference)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.referenceHover)
        if ui.button("R##r" .. tostring(idx), vec2(BTN_WIDTH, 18)) then
            st.setBestLap(lapData)
            if lap_picker.onSelectReference then
                lap_picker.onSelectReference(lapData)
            end
            ac.setMessage("Reference Set", string.format("%d:%05.2f", mins, secs))
        end
        ui.popStyleColor(2)
    end

    return y + ROW_HEIGHT
end

--- Draw a CSV file entry row
---@param x number Left edge X
---@param y number Top edge Y
---@param width number Available width
---@param fileInfo table { path, filename, source, size }
---@param idx number Unique identifier
---@param options table { showCurrent, showReference }
---@return number New Y position after row
local function drawCSVRow(x, y, width, fileInfo, idx, options)
    options = options or {}

    local displayName = fileInfo.filename:gsub("%.csv$", "")
    local sizeStr = file_utils.formatFileSize(fileInfo.size)

    -- File label
    ui.setCursor(vec2(x, y + 2))
    ui.pushFont(ui.Font.Small)
    ui.pushStyleColor(ui.StyleColor.Text, theme.text.primary)
    ui.text(displayName)
    ui.popStyleColor()
    ui.sameLine()
    ui.textColored(" " .. sizeStr, theme.text.muted)
    ui.popFont()

    -- Button area
    local btnAreaX = x + width - BTN_WIDTH * 2 - 15

    -- "C" button
    if options.showCurrent ~= false then
        ui.setCursor(vec2(btnAreaX, y))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.success)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.successHover)
        if ui.button("C##csvc" .. idx, vec2(BTN_WIDTH, 18)) and not isLoadingLap then
            local loaded, msg = loadCSVLap(fileInfo)
            if loaded then
                -- loadCSVLap already adds to history
                if lap_picker.onSelectCurrent then
                    lap_picker.onSelectCurrent(loaded, 1)  -- Added at front
                end
                ac.setMessage("CSV Loaded", msg)
            else
                ac.setMessage("Error", msg)
            end
        end
        ui.popStyleColor(2)
    end

    -- "R" button
    if options.showReference ~= false then
        ui.setCursor(vec2(btnAreaX + BTN_WIDTH + 5, y))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.reference)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.referenceHover)
        if ui.button("R##csvr" .. idx, vec2(BTN_WIDTH, 18)) and not isLoadingLap then
            local loaded, msg = loadCSVLap(fileInfo)
            if loaded then
                local st = getState()
                st.setBestLap(loaded)
                if lap_picker.onSelectReference then
                    lap_picker.onSelectReference(loaded)
                end
                ac.setMessage("Reference Set", msg)
            else
                ac.setMessage("Error", msg)
            end
        end
        ui.popStyleColor(2)
    end

    return y + ROW_HEIGHT
end

--------------------------------------------------------------------------------
-- Public: Draw as Popover
--------------------------------------------------------------------------------

--- Draw the lap picker as a popover dialog
---@param x number Dialog left edge
---@param y number Dialog top edge
---@param width number Dialog width
---@param height number Dialog height
---@param options table { showCurrent, showReference, maxSessionLaps, maxPrevLaps, maxCSVFiles }
function lap_picker.drawPopover(x, y, width, height, options)
    local st = getState()
    options = options or {}
    local showCurrent = options.showCurrent ~= false
    local showReference = options.showReference ~= false
    local maxSessionLaps = options.maxSessionLaps or 5
    local maxPrevLaps = options.maxPrevLaps or 4
    local maxCSVFiles = options.maxCSVFiles or 8

    -- Dialog background
    ui.drawRectFilled(vec2(x, y), vec2(x + width, y + height), theme.bg.overlay, 4)
    ui.drawRect(vec2(x, y), vec2(x + width, y + height), theme.grid.major, 2)

    local padding = 10
    local contentX = x + padding
    local contentW = width - padding * 2
    local py = y + padding

    -- Header
    ui.setCursor(vec2(contentX, py))
    ui.pushFont(ui.Font.Main)
    ui.textColored("Load Lap", theme.text.primary)
    ui.popFont()

    -- Column headers
    if showCurrent or showReference then
        ui.sameLine(x + contentW - BTN_WIDTH * 2 - 5)
        ui.pushFont(ui.Font.Small)
        if showCurrent then
            ui.textColored("Cur", theme.text.muted)
            ui.sameLine(x + contentW - BTN_WIDTH + 5)
        end
        if showReference then
            ui.textColored("Ref", theme.text.muted)
        end
        ui.popFont()
    end
    py = py + 25

    ui.drawLine(vec2(contentX, py), vec2(contentX + contentW, py), theme.grid.separator, 1)
    py = py + 10

    -- Current Session Laps
    ui.setCursor(vec2(contentX, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("This Session", theme.status.success)
    ui.popFont()
    py = py + 18

    local currentSessionLaps = st.getCurrentSessionLaps()
    if #currentSessionLaps > 0 then
        local shown = 0
        for _, entry in ipairs(currentSessionLaps) do
            if shown < maxSessionLaps then
                py = drawLapRow(contentX, py, contentW, entry.lap, entry.index, {
                    showCurrent = showCurrent,
                    showReference = showReference,
                })
                shown = shown + 1
            end
        end
    else
        ui.setCursor(vec2(contentX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No laps yet", theme.text.muted)
        ui.popFont()
        py = py + 20
    end

    py = py + 5
    ui.drawLine(vec2(contentX, py), vec2(contentX + contentW, py), theme.grid.separator, 1)
    py = py + 10

    -- Previous Session Laps
    ui.setCursor(vec2(contentX, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("Previous Sessions", theme.status.info)
    ui.popFont()
    py = py + 18

    local prevSessionLaps = st.getPreviousSessionLaps()
    if #prevSessionLaps > 0 then
        local shown = 0
        for _, entry in ipairs(prevSessionLaps) do
            if shown < maxPrevLaps then
                py = drawLapRow(contentX, py, contentW, entry.lap, entry.index + 1000, {
                    showCurrent = showCurrent,
                    showReference = showReference,
                })
                shown = shown + 1
            end
        end
    else
        ui.setCursor(vec2(contentX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No saved laps", theme.text.muted)
        ui.popFont()
        py = py + 20
    end

    py = py + 5
    ui.drawLine(vec2(contentX, py), vec2(contentX + contentW, py), theme.grid.separator, 1)
    py = py + 10

    -- CSV Files
    ui.setCursor(vec2(contentX, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored("CSV Files", theme.status.warning)
    ui.popFont()
    py = py + 18

    local files = file_utils.scanCSVFiles()
    if #files > 0 then
        for j, fileInfo in ipairs(files) do
            if j <= maxCSVFiles and py < y + height - 40 then
                py = drawCSVRow(contentX, py, contentW, fileInfo, j, {
                    showCurrent = showCurrent,
                    showReference = showReference,
                })
            end
        end
    else
        ui.setCursor(vec2(contentX + 10, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No CSV files found", theme.text.muted)
        ui.popFont()
        py = py + 20
    end

    -- Close button
    py = y + height - 30
    ui.setCursor(vec2(contentX, py))
    if ui.button("Close##picker", vec2(contentW, 0)) then
        if lap_picker.onClose then
            lap_picker.onClose()
        end
    end
end

--------------------------------------------------------------------------------
-- Public: Draw as Standalone Window
--------------------------------------------------------------------------------

-- Option to hide C button (set by window function)
lap_picker.showCurrentButton = true

--- Draw the lap picker as a full window (for reference lap selection)
function lap_picker.draw(dt)
    local st = getState()
    local windowSize = ui.availableSpace()
    local padding = 10
    local contentW = windowSize.x - padding * 2
    local showC = lap_picker.showCurrentButton

    -- Background
    ui.drawRectFilled(vec2(0, 0), windowSize, theme.bg.panel, 0)

    local headerHeight = 0

    -- Header with current reference
    ui.pushFont(ui.Font.Main)
    ui.setCursor(vec2(padding, padding))
    ui.textColored("Reference Lap", theme.text.primary)
    ui.popFont()
    headerHeight = headerHeight + 22

    -- Current reference status
    if st.hasBestLap() then
        local bestTime = st.getBestLapTime()
        local bestLap = st.getBestLap()
        ui.setCursor(vec2(padding, padding + headerHeight))
        ui.pushFont(ui.Font.Small)
        ui.textColored(file_utils.formatLapTime(bestTime * 1000), theme.status.success)
        ui.sameLine()
        ui.textColored(" (" .. bestLap:length() .. " pts)", theme.text.muted)
        ui.popFont()

        -- Clear button
        ui.sameLine(windowSize.x - padding - 45)
        if ui.button("Clear", vec2(40, 18)) then
            st.resetBestLap()
        end
    else
        ui.setCursor(vec2(padding, padding + headerHeight))
        ui.pushFont(ui.Font.Small)
        ui.textColored("No reference loaded", theme.status.warning)
        ui.popFont()
    end
    headerHeight = headerHeight + 24

    ui.drawLine(vec2(padding, padding + headerHeight), vec2(windowSize.x - padding, padding + headerHeight), theme.grid.separator, 1)
    headerHeight = headerHeight + 8

    -- Column headers
    ui.setCursor(vec2(padding, padding + headerHeight))
    ui.pushFont(ui.Font.Small)
    ui.textColored("Lap", theme.text.muted)
    if showC then
        ui.sameLine(windowSize.x - BTN_WIDTH * 2 - padding - 15)
        ui.textColored("C", theme.text.muted)
    end
    ui.sameLine(windowSize.x - BTN_WIDTH - padding - 5)
    ui.textColored("R", theme.text.muted)
    ui.popFont()
    headerHeight = headerHeight + 16

    -- Row options based on showCurrentButton
    local rowOptions = { showCurrent = showC, showReference = true }

    -- Scrollable content area
    local scrollAreaY = padding + headerHeight
    local scrollAreaHeight = windowSize.y - scrollAreaY - padding
    ui.setCursor(vec2(0, scrollAreaY))

    ui.childWindow('lap_picker_scroll', vec2(windowSize.x, scrollAreaHeight), function()
        local py = 0

        -- Current Session
        ui.setCursor(vec2(padding, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("This Session", theme.status.success)
        ui.popFont()
        py = py + 16

        local currentSessionLaps = st.getCurrentSessionLaps()
        if #currentSessionLaps > 0 then
            for _, entry in ipairs(currentSessionLaps) do
                py = drawLapRow(padding, py, contentW, entry.lap, entry.index, rowOptions)
            end
        else
            ui.setCursor(vec2(padding + 10, py))
            ui.pushFont(ui.Font.Small)
            ui.textColored("No laps yet", theme.text.muted)
            ui.popFont()
            py = py + 18
        end

        py = py + 6
        ui.drawLine(vec2(padding, py), vec2(contentW + padding, py), theme.grid.separator, 1)
        py = py + 8

        -- Previous Sessions
        ui.setCursor(vec2(padding, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("Previous Sessions", theme.status.info)
        ui.popFont()
        py = py + 16

        local prevSessionLaps = st.getPreviousSessionLaps()
        if #prevSessionLaps > 0 then
            for _, entry in ipairs(prevSessionLaps) do
                py = drawLapRow(padding, py, contentW, entry.lap, entry.index + 1000, rowOptions)
            end
        else
            ui.setCursor(vec2(padding + 10, py))
            ui.pushFont(ui.Font.Small)
            ui.textColored("No saved laps", theme.text.muted)
            ui.popFont()
            py = py + 18
        end

        py = py + 6
        ui.drawLine(vec2(padding, py), vec2(contentW + padding, py), theme.grid.separator, 1)
        py = py + 8

        -- CSV Files
        ui.setCursor(vec2(padding, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored("CSV Files (tracks/)", theme.status.warning)
        ui.popFont()
        py = py + 16

        local files = file_utils.scanCSVFiles()
        if #files > 0 then
            for j, fileInfo in ipairs(files) do
                py = drawCSVRow(padding, py, contentW, fileInfo, j, rowOptions)
            end
        else
            ui.setCursor(vec2(padding + 10, py))
            ui.pushFont(ui.Font.Small)
            ui.textColored("No CSV files in tracks/", theme.text.muted)
            ui.popFont()
        end
    end)
end

--------------------------------------------------------------------------------
-- Public: Compact UI (for settings embed)
--------------------------------------------------------------------------------

--- Draw a compact reference lap status for embedding in settings
function lap_picker.drawCompact()
    local st = getState()

    if st.hasBestLap() then
        local bestTime = st.getBestLapTime()
        if bestTime then
            ui.text("Reference: " .. file_utils.formatLapTime(bestTime * 1000))
        end
        ui.sameLine(180)
        if ui.button("Clear##ref", vec2(50, 0)) then
            st.resetBestLap()
        end
    else
        ui.textColored("No reference lap", theme.text.muted)
    end
end

--------------------------------------------------------------------------------
-- Public: Utilities
--------------------------------------------------------------------------------

--- Refresh file cache
function lap_picker.refresh()
    file_utils.invalidateCache()
end

--- Check if currently loading
function lap_picker.isLoading()
    return isLoadingLap
end

return lap_picker
