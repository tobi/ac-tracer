-- lap_picker.lua - Unified lap selection UI
-- Can render as standalone window or embedded popover
-- Single source for loading CSV files and selecting laps

local lap = require('lib.lap')
local theme = require('lib.ui.theme')
local file_utils = require('lib.core.files')
local motec = require('lib.motec_ld_parser')

-- Deferred require to avoid circular dependency
local state = nil
local function getState()
    if not state then
        state = require('lib.core.state')
    end
    return state
end

local lap_picker = {}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local isLoadingLap = false

-- MoTeC import state
local motecSession = nil     -- Parsed MoTeC session (from parseFile)
local motecLaps = nil        -- Laps array from session
local motecFastestIdx = nil  -- Index of fastest lap
local motecStatus = nil      -- Status message for UI feedback
local motecImporting = false -- Currently importing a lap

-- Collapsed section state
local collapsedSections = {}

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------

-- These can be set by the caller to handle lap selection
-- Callbacks are now passed via options to drawPopover/drawLapRow/drawCSVRow
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
        -- CSV laps are not added to history - just returned for use as reference
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
-- Draw Constants
--------------------------------------------------------------------------------

local ROW_HEIGHT = 22
local BTN_WIDTH = 35

--------------------------------------------------------------------------------
-- Internal: MoTeC Import
--------------------------------------------------------------------------------

local function openMotecFileDialog()
    os.openFileDialog({
        title = "Import MoTeC Session",
        fileTypes = {
            { name = "MoTeC Log Files", mask = "*.ld" },
        },
        addAllFilesFileType = false,
        defaultFolder = "C:\\MoTeC\\Logged Data",
    }, function(err, filename)
        if err then
            motecStatus = "Error: " .. tostring(err)
            return
        end
        if not filename then return end -- cancelled

        motecStatus = "Parsing..."
        local session, parseErr = motec.parseFile(filename)
        if not session then
            motecStatus = "Error: " .. (parseErr or "Unknown error")
            return
        end

        if #session.laps == 0 then
            motecStatus = "No laps found in session"
            return
        end

        motecSession = session
        motecLaps = session.laps
        motecFastestIdx = motec.findFastestLap(session.laps)
        motecStatus = nil
    end)
end

local function importMotecLap(lapIndex)
    if motecImporting or not motecSession then return end
    motecImporting = true

    local st = getState()
    local paths = require('lib.core.paths')
    local refsDir = paths.referencesDir(st.track, st.car)
    paths.ensureDirs(st.track, st.car)

    local filename = motec.buildExportFilename(motecSession, lapIndex)
    local outputPath = refsDir .. filename
    local trackName = st.track

    local path, exportErr = motec.exportLapAsCSV(motecSession, lapIndex, outputPath, trackName)
    if not path then
        motecStatus = "Export failed: " .. (exportErr or "Unknown error")
        motecImporting = false
        return
    end

    -- Invalidate cache so new CSV appears in file list
    file_utils.invalidateCache()

    -- Load through pipeline and set as reference
    local trackLength = ac.getSim().trackLengthM
    local loaded, warnings = lap.fromCSV(outputPath, st.track, st.car, trackLength)

    if loaded then
        st.setBestLap(loaded)
        local lapTime = motecLaps[lapIndex].timeFormatted
        ac.setMessage("MoTeC Imported", lapTime)
        motecStatus = nil
        -- Close the MoTeC sub-dialog
        motecSession = nil
        motecLaps = nil
        motecFastestIdx = nil
    else
        local warnMsg = warnings and warnings[1] or "Failed to load exported CSV"
        motecStatus = "Load failed: " .. warnMsg
    end

    motecImporting = false
end

local function closeMotecDialog()
    motecSession = nil
    motecLaps = nil
    motecFastestIdx = nil
    motecStatus = nil
end

--- Draw the MoTeC lap selection sub-dialog
---@param x number Left edge
---@param py number Current Y position
---@param contentW number Available width
---@param maxY number Maximum Y before clipping
---@return number New Y position
local function drawMotecLapSelector(x, py, contentW, maxY)
    local header = motecSession.header

    -- Session info
    ui.setCursor(vec2(x, py))
    ui.pushFont(ui.Font.Small)
    if header.driver and header.driver ~= "" then
        ui.textColored(header.driver, theme.text.primary)
        ui.sameLine()
        ui.textColored(" - ", theme.text.muted)
        ui.sameLine()
    end
    ui.textColored(header.venue or "Unknown Track", theme.text.secondary)
    ui.popFont()
    py = py + 16

    ui.setCursor(vec2(x, py))
    ui.pushFont(ui.Font.Small)
    ui.textColored(string.format("%d laps found", #motecLaps), theme.text.muted)
    ui.popFont()
    py = py + 16

    -- Lap list
    for i, lapInfo in ipairs(motecLaps) do
        if py >= maxY - ROW_HEIGHT then break end

        local isFastest = (i == motecFastestIdx)

        ui.setCursor(vec2(x, py + 2))
        ui.pushFont(ui.Font.Small)

        local labelColor = isFastest and theme.corner.faster or theme.text.primary
        ui.pushStyleColor(ui.StyleColor.Text, labelColor)
        ui.text(string.format("Lap %d", i))
        ui.popStyleColor()

        ui.sameLine()
        ui.pushStyleColor(ui.StyleColor.Text, labelColor)
        ui.text(lapInfo.timeFormatted)
        ui.popStyleColor()

        if isFastest then
            ui.sameLine()
            ui.textColored("(fastest)", theme.text.muted)
        end

        ui.popFont()

        -- Import button
        local btnX = x + contentW - 55
        ui.setCursor(vec2(btnX, py))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.reference)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.referenceHover)
        if ui.button("Import##ml" .. i, vec2(50, 18)) and not motecImporting then
            importMotecLap(i)
        end
        ui.popStyleColor(2)

        py = py + ROW_HEIGHT
    end

    -- Status message
    if motecStatus then
        ui.setCursor(vec2(x, py + 2))
        ui.pushFont(ui.Font.Small)
        ui.textColored(motecStatus, theme.status.error)
        ui.popFont()
        py = py + 18
    end

    -- Back button
    py = py + 4
    ui.setCursor(vec2(x, py))
    if ui.button("Back##motec", vec2(60, 18)) then
        closeMotecDialog()
    end
    py = py + ROW_HEIGHT

    return py
end

--- Draw the "Import MoTeC .ld" button and sub-dialog
---@param x number Left edge
---@param py number Current Y position
---@param contentW number Available width
---@param maxY number Maximum Y
---@return number New Y position
local function drawMotecImportSection(x, py, contentW, maxY)
    if motecSession and motecLaps then
        -- Show lap selection sub-dialog
        return drawMotecLapSelector(x, py, contentW, maxY)
    end

    -- Import button
    ui.setCursor(vec2(x, py))
    ui.pushStyleColor(ui.StyleColor.Button, theme.button.primary)
    ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.primaryHover)
    if ui.button("Import MoTeC .ld##motec_open", vec2(contentW, 20)) then
        openMotecFileDialog()
    end
    ui.popStyleColor(2)
    py = py + 24

    if motecStatus then
        ui.setCursor(vec2(x, py))
        ui.pushFont(ui.Font.Small)
        ui.textColored(motecStatus, theme.status.error)
        ui.popFont()
        py = py + 16
    end

    return py
end

--------------------------------------------------------------------------------
-- Draw Helpers
--------------------------------------------------------------------------------

--- Draw a section header with optional collapse toggle
---@return boolean expanded True if section is expanded
local function drawSectionHeader(contentX, py, contentW, label, color, sectionKey)
    local expanded = not collapsedSections[sectionKey]

    ui.setCursor(vec2(contentX, py))
    ui.pushFont(ui.Font.Small)

    if sectionKey then
        local arrow = expanded and "v " or "> "
        ui.pushStyleColor(ui.StyleColor.Text, color)
        if ui.textWrapped(arrow .. label) then end
        ui.popStyleColor()

        -- Make the header clickable
        local headerMin = vec2(contentX, py)
        local headerMax = vec2(contentX + contentW, py + 16)
        if ui.rectHovered(headerMin, headerMax) and ui.mouseClicked() then
            collapsedSections[sectionKey] = expanded
            expanded = not expanded
        end
    else
        ui.textColored(label, color)
    end

    ui.popFont()
    return expanded
end

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

    local lapLabel = (lapData.lapNumberInSession and lapData.lapNumberInSession > 0)
        and string.format("Lap %d", lapData.lapNumberInSession) or "Lap"
    local timeLabel = string.format("%d:%05.2f", mins, secs)

    local isBest = options.isBest or (lapData == st.bestLap)
    local isCurrent = options.isCurrent or false

    -- Button area
    local btnAreaX = x + width - BTN_WIDTH * 2 - 15

    -- Lap label (left) and time (right-aligned in label area)
    ui.setCursor(vec2(x, y + 2))
    ui.pushFont(ui.Font.Small)

    local labelColor = theme.text.primary
    if isBest then
        labelColor = theme.corner.faster
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

    local timeWidth = ui.measureText(timeLabel).x
    local timeX = btnAreaX - timeWidth - 10
    local minTimeX = x + ui.measureText(lapLabel).x + 8
    if timeX < minTimeX then
        timeX = minTimeX
    end
    ui.setCursor(vec2(timeX, y + 2))
    ui.pushStyleColor(ui.StyleColor.Text, labelColor)
    ui.text(timeLabel)
    ui.popStyleColor()
    ui.popFont()

    -- "C" button (set as current to view)
    if options.showCurrent ~= false then
        ui.setCursor(vec2(btnAreaX, y))
        ui.pushStyleColor(ui.StyleColor.Button, theme.button.success)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, theme.button.successHover)
        if ui.button("C##c" .. tostring(idx), vec2(BTN_WIDTH, 18)) then
            if options.onSelectCurrent then
                options.onSelectCurrent(lapData, idx)
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
            if options.onSelectReference then
                options.onSelectReference(lapData)
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
---@param fileInfo table { path, filename, source, size, lapTimeMs }
---@param idx number|string Unique identifier
---@param options table { showCurrent, showReference }
---@return number New Y position after row
local function drawCSVRow(x, y, width, fileInfo, idx, options)
    options = options or {}

    -- Show lap time if parseable, otherwise filename
    local displayName
    if fileInfo.lapTimeMs then
        displayName = file_utils.formatLapTime(fileInfo.lapTimeMs)
    else
        displayName = fileInfo.filename:gsub("%.csv$", "")
    end
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
        if ui.button("C##csvc" .. tostring(idx), vec2(BTN_WIDTH, 18)) and not isLoadingLap then
            local loaded, msg = loadCSVLap(fileInfo)
            if loaded then
                if options.onSelectCurrent then
                    options.onSelectCurrent(loaded)
                end
                ac.setMessage("Lap loaded from CSV", msg)
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
        if ui.button("R##csvr" .. tostring(idx), vec2(BTN_WIDTH, 18)) and not isLoadingLap then
            local loaded, msg = loadCSVLap(fileInfo)
            if loaded then
                local st = getState()
                st.setBestLap(loaded)
                if options.onSelectReference then
                    options.onSelectReference(loaded)
                end
                ac.setMessage("Reference loaded from CSV", msg)
            else
                ac.setMessage("Error", msg)
            end
        end
        ui.popStyleColor(2)
    end

    return y + ROW_HEIGHT
end

--- Draw a separator line
local function drawSeparator(contentX, py, contentW)
    ui.drawLine(vec2(contentX, py), vec2(contentX + contentW, py), theme.grid.separator, 1)
    return py + 8
end

--- Draw the grouped file sections (autosave, references, other cars, legacy/motec)
---@return number New Y position
local function drawFileSections(contentX, py, contentW, rowOptions, maxY)
    local st = getState()
    local grouped = file_utils.scanCSVFilesGrouped(st.track, st.car)

    -- Fastest Saved (top 3 from autosave)
    if #grouped.autosave > 0 then
        py = drawSeparator(contentX, py, contentW)
        local expanded = drawSectionHeader(contentX, py, contentW, "Fastest Saved", theme.status.info, nil)
        py = py + 18

        if expanded then
            local shown = 0
            for _, fileInfo in ipairs(grouped.autosave) do
                if shown >= 3 then break end
                if maxY and py > maxY - 40 then break end
                py = drawCSVRow(contentX, py, contentW, fileInfo, "auto" .. shown, rowOptions)
                shown = shown + 1
            end
        end
    end

    -- References
    if #grouped.references > 0 then
        py = drawSeparator(contentX, py, contentW)
        drawSectionHeader(contentX, py, contentW, "References", theme.status.warning, nil)
        py = py + 18

        for j, fileInfo in ipairs(grouped.references) do
            if maxY and py > maxY - 40 then break end
            py = drawCSVRow(contentX, py, contentW, fileInfo, "ref" .. j, rowOptions)
        end
    end

    -- Other Cars (collapsed by default)
    if #grouped.otherCars > 0 then
        py = drawSeparator(contentX, py, contentW)
        local expanded = drawSectionHeader(contentX, py, contentW,
            string.format("Other Cars (%d)", #grouped.otherCars),
            theme.text.muted, "other_cars")
        py = py + 18

        if expanded then
            for _, carGroup in ipairs(grouped.otherCars) do
                if maxY and py > maxY - 40 then break end
                -- Car sub-header
                ui.setCursor(vec2(contentX + 8, py))
                ui.pushFont(ui.Font.Small)
                ui.textColored(carGroup.car, theme.text.primary)
                ui.popFont()
                py = py + 16

                local shown = 0
                for _, fileInfo in ipairs(carGroup.files) do
                    if shown >= 3 then break end
                    if maxY and py > maxY - 40 then break end
                    py = drawCSVRow(contentX + 8, py, contentW - 8, fileInfo,
                        "oc_" .. carGroup.car .. "_" .. shown, rowOptions)
                    shown = shown + 1
                end
            end
        end
    end

    -- Legacy / MoTeC (collapsed by default)
    local hasLegacy = #grouped.legacy > 0 or #grouped.motec > 0
    if hasLegacy then
        py = drawSeparator(contentX, py, contentW)
        local totalLegacy = #grouped.legacy + #grouped.motec
        local expanded = drawSectionHeader(contentX, py, contentW,
            string.format("MoTeC / Legacy (%d)", totalLegacy),
            theme.text.muted, "legacy_motec")
        py = py + 18

        if expanded then
            for j, fileInfo in ipairs(grouped.legacy) do
                if maxY and py > maxY - 40 then break end
                py = drawCSVRow(contentX, py, contentW, fileInfo, "leg" .. j, rowOptions)
            end
            for j, fileInfo in ipairs(grouped.motec) do
                if maxY and py > maxY - 40 then break end
                py = drawCSVRow(contentX, py, contentW, fileInfo, "mot" .. j, rowOptions)
            end
        end
    end

    return py
end

--------------------------------------------------------------------------------
-- Public: Draw as Popover
--------------------------------------------------------------------------------

--- Draw the lap picker as a popover dialog
---@param x number Dialog left edge
---@param y number Dialog top edge
---@param width number Dialog width
---@param height number Dialog height
---@param options table { showCurrent, showReference, maxSessionLaps }
function lap_picker.drawPopover(x, y, width, height, options)
    local st = getState()
    options = options or {}
    local showCurrent = options.showCurrent ~= false
    local showReference = options.showReference ~= false
    local maxSessionLaps = options.maxSessionLaps or 20

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

    py = drawSeparator(contentX, py, contentW)

    -- Current Session Laps
    drawSectionHeader(contentX, py, contentW, "This Session", theme.status.success, nil)
    py = py + 18

    local currentSessionLaps = st.getCurrentSessionLaps()
    if #currentSessionLaps > 0 then
        local shown = 0
        for _, entry in ipairs(currentSessionLaps) do
            if shown < maxSessionLaps then
                py = drawLapRow(contentX, py, contentW, entry.lap, entry.index, {
                    showCurrent = showCurrent,
                    showReference = showReference,
                    onSelectCurrent = options.onSelectCurrent,
                    onSelectReference = options.onSelectReference,
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

    -- File sections (autosave, references, other cars, legacy)
    local rowOptions = {
        showCurrent = showCurrent,
        showReference = showReference,
        onSelectCurrent = options.onSelectCurrent,
        onSelectReference = options.onSelectReference,
    }
    py = drawFileSections(contentX, py, contentW, rowOptions, y + height)

    -- MoTeC Import
    py = py + 5
    ui.drawLine(vec2(contentX, py), vec2(contentX + contentW, py), theme.grid.separator, 1)
    py = py + 10
    py = drawMotecImportSection(contentX, py, contentW, y + height - 40)

    -- Close button
    py = y + height - 30
    ui.setCursor(vec2(contentX, py))
    if ui.button("Close##picker", vec2(contentW, 0)) then
        if options.onClose then
            options.onClose()
        elseif lap_picker.onClose then
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
        drawSectionHeader(padding, py, contentW, "This Session", theme.status.success, nil)
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

        -- File sections (autosave, references, other cars, legacy)
        py = drawFileSections(padding, py, contentW, rowOptions, nil)

        -- MoTeC Import
        py = py + 5
        ui.drawLine(vec2(padding, py), vec2(contentW + padding, py), theme.grid.separator, 1)
        py = py + 10
        py = drawMotecImportSection(padding, py, contentW, windowSize.y)
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
