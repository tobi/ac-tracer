-- markdown.lua - Generate coaching-friendly markdown from lap data
-- For export to AI coaching tools

local state = require('lib.core.state')
local lap = require('lib.lap')
local scoring = require('lib.core.scoring')
local corner_analysis = require('lib.windows.corner_analysis')
local ui_utils = require('lib.ui.utils')

local markdown = {}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function formatTime(timeMs)
    local timeS = timeMs / 1000
    local mins = math.floor(timeS / 60)
    local secs = timeS - mins * 60
    return string.format("%d:%05.2f", mins, secs)
end

local function formatTimeSeconds(timeS)
    local mins = math.floor(timeS / 60)
    local secs = timeS - mins * 60
    return string.format("%d:%05.2f", mins, secs)
end

local function formatSpeed(speed)
    if not speed then return "N/A" end
    return ui_utils.speedDisplay(speed)
end

local function formatDelta(delta, unit)
    if not delta then return "N/A" end
    local sign = delta >= 0 and "+" or ""
    return string.format("%s%.0f %s", sign, delta, unit or "")
end

local function formatPosDelta(meters)
    if not meters then return "N/A" end
    local sign = meters >= 0 and "+" or ""
    local direction = meters >= 0 and "later" or "earlier"
    return string.format("%.0fm %s", math.abs(meters), direction)
end

--- Get session/sim info for context
local function getSessionInfo()
    local sim = ac.getSim()
    local car = ac.getCar(0)
    if not sim or not car then return {} end

    local info = {
        track = state.track or ac.getTrackID() or "Unknown",
        car = state.car or ac.getCarID(0) or "Unknown",
        carName = ac.getCarName(0, true) or "Unknown",  -- Full car name with year
        trackLength = sim.trackLengthM,
        ambientTemp = sim.ambientTemperature,
        roadTemp = sim.roadTemperature,
        gripLevel = sim.roadGrip and (sim.roadGrip * 100) or 100,  -- roadGrip is 0-1, convert to %
        brakeBias = car.brakeBias,  -- 0-1, higher = more front
    }

    -- Time of day from sim state
    if sim.timeHours and sim.timeMinutes then
        info.timeOfDay = string.format("%02d:%02d", sim.timeHours, sim.timeMinutes)
    end

    return info
end

--- Get corner info with meters
local function getCornerMeters(corner, trackLength)
    if not corner or not trackLength then return nil, nil end
    local startM = math.floor(corner.startPos * trackLength)
    local endM = math.floor(corner.endPos * trackLength)
    return startM, endM
end

--- Sample pedal data at 5Hz through a position range
--- Also samples reference lap data at the same positions if provided
local EXPORT_SAMPLE_RATE = 5  -- Hz
local function samplePedalData(lapData, startPos, endPos, trackLength, refLap)
    if not lapData or lapData:length() < 2 then return {} end

    local samples = {}
    local startIdx, endIdx = nil, nil

    -- Find indices for this position range
    for i = 1, lapData:length() do
        local pos = lapData.pos[i]
        if lap.isInRange(pos, startPos, endPos) then
            if not startIdx then startIdx = i end
            endIdx = i
        elseif startIdx then
            break  -- Past the range
        end
    end

    if not startIdx or not endIdx then return {} end

    -- Calculate how many samples we need (5 per second)
    local startTime = lapData.times[startIdx]
    local endTime = lapData.times[endIdx]
    local duration = endTime - startTime
    local numSamples = math.max(1, math.floor(duration * EXPORT_SAMPLE_RATE))

    -- Sample at regular intervals
    for s = 0, numSamples do
        local targetTime = startTime + (s / numSamples) * duration
        -- Find closest sample
        local closestIdx = startIdx
        local closestDiff = math.abs(lapData.times[startIdx] - targetTime)

        for i = startIdx, endIdx do
            local diff = math.abs(lapData.times[i] - targetTime)
            if diff < closestDiff then
                closestDiff = diff
                closestIdx = i
            end
        end

        local pos = lapData.pos[closestIdx]
        local sample = {
            time = lapData.times[closestIdx],
            pos = pos,
            meters = math.floor(pos * trackLength),
            throttle = lapData.throttle[closestIdx],
            brake = lapData.brake[closestIdx],  -- Front brake
            brake_r = lapData.brake_r and lapData.brake_r[closestIdx] or lapData.brake[closestIdx],  -- Rear (or same as front)
            speed = lapData.speed[closestIdx],
            gear = lapData.gear and lapData.gear[closestIdx] or nil,
        }

        -- Add reference lap data at same position (if available)
         if refLap and refLap:length() > 0 then
             sample.ref_time = refLap:getTimeAtPos(pos)
             sample.ref_speed = refLap:speedAt(pos)
             sample.ref_gear = refLap:gearAt(pos)
             sample.ref_throttle = refLap:throttleAt(pos)
             sample.ref_brake = refLap:brakeAt(pos)
         end

        -- Add flags if available (in-sim only data)
        if lapData.flags and lapData.flags[closestIdx] then
            local f = lapData.flags[closestIdx]
            sample.tcActive = bit.band(f, lap.FLAGS.TC_ACTIVE) ~= 0
            sample.wheelSlip = bit.band(f, lap.FLAGS.WHEEL_SLIP) ~= 0
            sample.lockupFL = bit.band(f, lap.FLAGS.LOCKUP_FL) ~= 0
            sample.lockupFR = bit.band(f, lap.FLAGS.LOCKUP_FR) ~= 0
            sample.lockupRL = bit.band(f, lap.FLAGS.LOCKUP_RL) ~= 0
            sample.lockupRR = bit.band(f, lap.FLAGS.LOCKUP_RR) ~= 0
            sample.overlap = bit.band(f, lap.FLAGS.OVERLAP) ~= 0
        end

        table.insert(samples, sample)
    end

    return samples
end

--- Generate CSV from pedal samples
local function generatePedalCSV(samples, hasFlags, hasGear, hasRefData)
    if #samples == 0 then return "" end

    local lines = {}

    -- Header: meters first, then time/ref_time, then data pairs (value,ref_value)
    -- ref_ columns are the reference lap data at same track position
    local header = "meters,time"
    if hasRefData then
        header = header .. ",ref_time"
    end
    header = header .. ",speed"
    if hasRefData then
        header = header .. ",ref_speed"
    end
    header = header .. ",gear"
    if hasRefData then
        header = header .. ",ref_gear"
    end
    header = header .. ",throttle"
    if hasRefData then
        header = header .. ",ref_throttle"
    end
    header = header .. ",brake_f"
    if hasRefData then
        header = header .. ",ref_brake_f"
    end
    header = header .. ",brake_r"
    if hasFlags then
        header = header .. ",tc,slip,lockup,overlap"
    end
    table.insert(lines, header)

    -- Data rows
    for _, s in ipairs(samples) do
        local gearStr = s.gear and tostring(s.gear) or ""
        local row = string.format("%d,%.1f", s.meters, s.time)

        -- Interleave ref_time
        if hasRefData then
            row = row .. "," .. (s.ref_time and string.format("%.1f", s.ref_time) or "")
        end

        -- Speed and ref_speed
        row = row .. string.format(",%.0f", s.speed)
        if hasRefData then
            row = row .. "," .. (s.ref_speed and string.format("%.0f", s.ref_speed) or "")
        end

        -- Gear and ref_gear
        row = row .. "," .. gearStr
        if hasRefData then
            local refGear = s.ref_gear and tostring(math.floor(s.ref_gear + 0.5)) or ""
            row = row .. "," .. refGear
        end

        -- Throttle and ref_throttle
        row = row .. string.format(",%.2f", s.throttle)
        if hasRefData then
            row = row .. "," .. (s.ref_throttle and string.format("%.2f", s.ref_throttle) or "")
        end

        -- Brake_f and ref_brake_f
        row = row .. string.format(",%.2f", s.brake)
        if hasRefData then
            row = row .. "," .. (s.ref_brake and string.format("%.2f", s.ref_brake) or "")
        end

        -- Brake_r (no ref for rear brake)
        row = row .. string.format(",%.2f", s.brake_r)

        if hasFlags then
            local tc = s.tcActive and "1" or "0"
            local slip = s.wheelSlip and "1" or "0"
            local lockup = ""
            if s.lockupFL or s.lockupFR or s.lockupRL or s.lockupRR then
                local wheels = {}
                if s.lockupFL then table.insert(wheels, "FL") end
                if s.lockupFR then table.insert(wheels, "FR") end
                if s.lockupRL then table.insert(wheels, "RL") end
                if s.lockupRR then table.insert(wheels, "RR") end
                lockup = table.concat(wheels, "+")
            end
            local overlap = s.overlap and "1" or "0"
            row = row .. "," .. tc .. "," .. slip .. "," .. lockup .. "," .. overlap
        end

        table.insert(lines, row)
    end

    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Main Export Function
--------------------------------------------------------------------------------

--- Generate markdown export for coaching
---@param currentLap table The lap to analyze (your lap)
---@param referenceLap table|nil Optional reference lap for comparison
---@return string Markdown text
function markdown.generate(currentLap, referenceLap)
    if not currentLap then return "No lap data available." end

    local lines = {}
    local sim = ac.getSim()
    local sessionInfo = getSessionInfo()
    local trackLength = sessionInfo.trackLength or 5000
    local corners = state.trackCorners or {}

    -- Helper to add a line
    local function add(text)
        table.insert(lines, text)
    end

    local function addBlank()
        table.insert(lines, "")
    end

    -- Header
    add("# Lap Telemetry Export")
    addBlank()
    add("**Sim:** Assetto Corsa")
    add(string.format("**Track:** %s (%.0fm)", sessionInfo.track, trackLength))
    add(string.format("**Car:** %s", sessionInfo.carName))
    if sessionInfo.brakeBias then
        add(string.format("**Brake Bias:** %.1f%% front", sessionInfo.brakeBias * 100))
    end
    if sessionInfo.timeOfDay then
        add(string.format("**Time of Day:** %s", sessionInfo.timeOfDay))
    end
    if sessionInfo.gripLevel then
        add(string.format("**Track Grip:** %.0f%%", sessionInfo.gripLevel))
    end
    if sessionInfo.ambientTemp then
        add(string.format("**Ambient Temp:** %.0f°C", sessionInfo.ambientTemp))
    end
    if sessionInfo.roadTemp then
        add(string.format("**Road Temp:** %.0f°C", sessionInfo.roadTemp))
    end
    addBlank()
    add(string.format("*Tailor your advice to this car: %s*", sessionInfo.carName))
    addBlank()

    -- Corner definitions
    if #corners > 0 then
        add("## Corner Definitions")
        addBlank()
        add("| Corner | Name | Start | End | Length |")
        add("|--------|------|-------|-----|--------|")
        for _, c in ipairs(corners) do
            local startM, endM = getCornerMeters(c, trackLength)
            if startM and endM then
                local length = endM - startM
                if length < 0 then length = length + trackLength end
                add(string.format("| %d | %s | %dm | %dm | %dm |",
                    c.number, c.name or "-", startM, endM, length))
            end
        end
        addBlank()
    end

    -- Helper to format corner title - only show number if name is generic
    local function formatCornerTitle(corner)
        local hasCustomName = corner.name and corner.name ~= "" and corner.name ~= ("Corner " .. corner.number)
        if hasCustomName then
            return corner.name
        else
            return "Corner " .. corner.number
        end
    end

    -- Lap comparison section
    add("---")
    addBlank()
    add("## Lap Comparison")
    addBlank()

    -- Show both laps side by side
    add(string.format("**Your Lap Time:** %s", formatTime(currentLap.time)))
    if referenceLap then
        add(string.format("**Reference Lap Time:** %s", formatTime(referenceLap.time)))
        local delta = (currentLap.time - referenceLap.time) / 1000
        local sign = delta >= 0 and "+" or ""
        add(string.format("**Delta:** %s%.3fs", sign, delta))
    end
    addBlank()

     -- Start line comparison
     local startSpeed = currentLap:speedAt(0.001) or currentLap.speed[1]
     if referenceLap then
         local refStartSpeed = referenceLap:speedAt(0.001) or referenceLap.speed[1]
         add(string.format("**Start:** You %s, Ref %s", formatSpeed(startSpeed), formatSpeed(refStartSpeed)))
     else
         add(string.format("**Start:** %s", formatSpeed(startSpeed)))
     end
    addBlank()

    -- Check if we have flags data (in-sim only) and gear data
    local hasFlags = currentLap.flags and #currentLap.flags > 0
    local hasGear = currentLap.gear and #currentLap.gear > 0

    -- Analyze each corner using corner_analysis module
    for _, corner in ipairs(corners) do
        -- Use corner_analysis module for detailed analysis
        local currentAnalysis = corner_analysis.analyzeCorner(currentLap, corner)
        local refAnalysis = referenceLap and corner_analysis.analyzeCorner(referenceLap, corner) or nil
        local comparison = (currentAnalysis and refAnalysis) and
            corner_analysis.compareCorners(currentAnalysis, refAnalysis) or nil

        if currentAnalysis then
            local startM = math.floor(corner.startPos * trackLength)
            local endM = math.floor(corner.endPos * trackLength)

            add(string.format("### %s", formatCornerTitle(corner)))

            -- Reference lap summary (compact, at top of corner)
            if refAnalysis then
                local refSummary = string.format("**Ref:** Entry %s", formatSpeed(refAnalysis.entrySpeed))
                if refAnalysis.brakePos then
                    refSummary = refSummary .. string.format(", brake %dm", math.floor(refAnalysis.brakePos * trackLength))
                end
                if refAnalysis.apexPos then
                    refSummary = refSummary .. string.format(", apex %s", formatSpeed(refAnalysis.apexSpeed))
                end
                refSummary = refSummary .. string.format(", exit %s", formatSpeed(refAnalysis.exitSpeed))
                if refAnalysis.minGear then
                    refSummary = refSummary .. string.format(", G%d", refAnalysis.minGear)
                end
                add(refSummary)
                addBlank()
            end

            -- Entry
            local entryLine = string.format("- **Entry** at %dm, %s, time %.2fs",
                startM, formatSpeed(currentAnalysis.entrySpeed), currentAnalysis.entryTime or 0)
            if comparison and comparison.entrySpeedDelta then
                entryLine = entryLine .. string.format(" (%s vs ref)", ui_utils.speedDeltaDisplay(comparison.entrySpeedDelta, true))
            end
            add(entryLine)

            -- Lift point
            if currentAnalysis.liftOffPos then
                local liftM = math.floor(currentAnalysis.liftOffPos * trackLength)
                local liftLine = string.format("- **Lift throttle** at %dm", liftM)
                if comparison and comparison.refLiftOffPos and comparison.currentLiftOffPos then
                    local deltaM = (comparison.currentLiftOffPos - comparison.refLiftOffPos) * trackLength
                    liftLine = liftLine .. string.format(" (%s)", formatPosDelta(deltaM))
                end
                add(liftLine)
            end

            -- Brake point
            if currentAnalysis.brakePos then
                local brakeM = math.floor(currentAnalysis.brakePos * trackLength)
                local brakeLine = string.format("- **Brake** at %dm", brakeM)
                if comparison and comparison.refBrakePos and comparison.currentBrakePos then
                    local deltaM = (comparison.currentBrakePos - comparison.refBrakePos) * trackLength
                    brakeLine = brakeLine .. string.format(" (%s)", formatPosDelta(deltaM))
                end
                add(brakeLine)
            end

            -- Apex
            if currentAnalysis.apexPos then
                local apexM = math.floor(currentAnalysis.apexPos * trackLength)
                local apexLine = string.format("- **Apex** at %dm, %s", apexM, formatSpeed(currentAnalysis.apexSpeed))
                if comparison and comparison.apexSpeedDelta then
                    apexLine = apexLine .. string.format(" (%s)", ui_utils.speedDeltaDisplay(comparison.apexSpeedDelta, true))
                end
                add(apexLine)
            end

            -- Exit
            local exitLine = string.format("- **Exit** at %dm, %s, time %.2fs",
                endM, formatSpeed(currentAnalysis.exitSpeed), currentAnalysis.exitTime or 0)
            if comparison and comparison.exitSpeedDelta then
                exitLine = exitLine .. string.format(" (%s vs ref)", ui_utils.speedDeltaDisplay(comparison.exitSpeedDelta, true))
            end
            add(exitLine)

            -- Max steering
            if currentAnalysis.maxSteeringDeg and currentAnalysis.maxSteeringDeg > 0 then
                local steerLine = string.format("- **Max steering:** %.0f°", currentAnalysis.maxSteeringDeg)
                if comparison and comparison.steeringDelta and math.abs(comparison.steeringDelta) > 5 then
                    steerLine = steerLine .. string.format(" (%s° vs ref)", formatDelta(comparison.steeringDelta, ""))
                end
                add(steerLine)
            end

            -- Corner time delta and score
            if comparison and comparison.timeDelta then
                local sign = comparison.timeDelta >= 0 and "+" or ""
                add(string.format("- **Corner time delta:** %s%.3fs", sign, comparison.timeDelta))
            end

            -- Calculate score using scoring module
            if comparison then
                local score = scoring.calculate(comparison)
                local brakeMeters, liftMeters = scoring.getMeterDeltas(comparison)
                local currentCoast, refCoast, coastDelta = scoring.getCoastDistances(comparison)

                add(string.format("- **Corner Score:** %d/100", score))

                -- Coast distance if significant
                if currentCoast and currentCoast > 10 and coastDelta and math.abs(coastDelta) > 5 then
                    local direction = coastDelta >= 0 and "more" or "less"
                    add(string.format("- **Coast distance:** %.0fm (%.0fm %s than ref)",
                        currentCoast, math.abs(coastDelta), direction))
                end

                -- Overlap time (pedal overlap > 100ms)
                if comparison.currentOverlapTime and comparison.currentOverlapTime > 0 then
                    add(string.format("- **Pedal overlap:** %.2fs", comparison.currentOverlapTime))
                end

                -- Gear difference (highlight if using different gear than reference)
                if comparison.currentMinGear and comparison.refMinGear then
                    if comparison.gearDelta and comparison.gearDelta ~= 0 then
                        local direction = comparison.gearDelta > 0 and "higher" or "lower"
                        add(string.format("- **Min gear:** %d (ref: %d) - %d gear %s",
                            comparison.currentMinGear, comparison.refMinGear,
                            math.abs(comparison.gearDelta), direction))
                    else
                        add(string.format("- **Min gear:** %d", comparison.currentMinGear))
                    end
                elseif comparison.currentMinGear then
                    add(string.format("- **Min gear:** %d", comparison.currentMinGear))
                end
            end

            -- TC and lockup events (in-sim only)
            if hasFlags then
                -- TC event count
                local tcCount = currentLap:countFlagInRange(corner.startPos, corner.endPos, lap.FLAGS.TC_ACTIVE)
                if tcCount > 0 then
                    add(string.format("- **TC activations:** %d samples (%.0fms)", tcCount, tcCount * 1000 / lap.SAMPLE_RATE))
                end

                -- Wheel lockups
                local hasLockup, lockupWheels = currentLap:hasLockupInRange(corner.startPos, corner.endPos)
                if hasLockup and lockupWheels then
                    local wheels = {}
                    if lockupWheels.fl then table.insert(wheels, "FL") end
                    if lockupWheels.fr then table.insert(wheels, "FR") end
                    if lockupWheels.rl then table.insert(wheels, "RL") end
                    if lockupWheels.rr then table.insert(wheels, "RR") end
                    add(string.format("- **Wheel lockups:** %s", table.concat(wheels, ", ")))
                end
            end

            -- Pedal trace CSV (5Hz sampling)
            addBlank()
            add("<details>")
            add("<summary>Pedal Data (5Hz sampling)</summary>")
            addBlank()
            -- Explain ref_ columns if reference lap is available
            local hasRefData = referenceLap and referenceLap:length() > 0
            if hasRefData then
                add("*ref_ columns = reference lap data at same track position for direct comparison*")
                addBlank()
            end
            add("```csv")
            local samples = samplePedalData(currentLap, corner.startPos, corner.endPos, trackLength, referenceLap)
            add(generatePedalCSV(samples, hasFlags, hasGear, hasRefData))
            add("```")
            addBlank()
            add("</details>")
            addBlank()
        end
    end

    -- Summary
    add("---")
    addBlank()
    add("## Coaching Instructions")
    addBlank()
    add("**Driver Level:** Semi-pro / experienced sim racer who knows this car well.")
    addBlank()
    add("**Communication Style:** Race engineer debrief - be direct, data-driven, and specific.")
    add("Skip basic driving theory. The driver understands weight transfer, racing lines, and")
    add("throttle/brake fundamentals. Focus on what the telemetry shows vs the reference lap.")
    addBlank()
    add("**Analyze:**")
    add("1. Where am I losing time? Quantify it (e.g., \"3 tenths lost in T4-T5 complex\")")
    add("2. Brake point deltas - meters early/late, and whether that's costing time")
    add("3. Minimum corner speeds vs reference - where am I leaving speed on the table?")
    add("4. Throttle pickup timing - am I waiting too long to get back on power?")
    add("5. Coast phase issues - excessive coast = lost time")
    if hasFlags then
        add("6. Lockups and TC events - are they causing time loss or are they acceptable?")
    end
    addBlank()
    add("**Output:** Prioritized list of 2-3 actionable changes for the next stint.")
    add("Focus on biggest time gains first. Be specific: \"Brake 5m later into T3\" not \"brake later.\"")
    addBlank()

    return table.concat(lines, "\n")
end

--- Copy markdown to clipboard
---@param currentLap table The lap to analyze
---@param referenceLap table|nil Optional reference lap
---@return boolean success
---@return string message
function markdown.copyToClipboard(currentLap, referenceLap)
    if not currentLap then
        return false, "No lap data to export"
    end

    local text = markdown.generate(currentLap, referenceLap)
    ac.setClipboardText(text)

    local corners = state.trackCorners or {}
    return true, string.format("Copied to clipboard (%d corners, %.1fKB)",
        #corners, #text / 1024)
end

return markdown
