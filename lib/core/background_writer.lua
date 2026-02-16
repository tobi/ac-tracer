-- background_writer.lua - Non-blocking background file writer
-- Queues write jobs and processes them incrementally across frames
-- to avoid frame drops during lap saves

local lap = require('lib.lap')
local paths = require('lib.core.paths')
-- Note: modules loaded lazily to avoid circular dependency
-- (state -> background_writer -> corner_analysis/markdown -> state)
local corner_analysis = nil
local markdown = nil
local scoring = nil

local bg_writer = {}

local function safeGetEnv(name)
    local getenv = os and os.getenv
    if not getenv or type(getenv) ~= "function" then return nil end
    return getenv(name)
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- How many CSV rows to write per frame (tune for performance)
local ROWS_PER_FRAME = 200

-- Maximum jobs in queue (oldest dropped if exceeded)
local MAX_QUEUE_SIZE = 10

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- Job queue: { {type, data, path, state}, ... }
local jobQueue = {}

-- Current job being processed
local currentJob = nil

--- Format lap time for filename (M-SS.mmm format)
local function formatLapTime(ms)
    if not ms or ms <= 0 then return "0-00.000" end
    local mins = math.floor(ms / 60000)
    local secs = (ms % 60000) / 1000
    return string.format("%d-%06.3f", mins, secs)
end

--- Format timestamp for filename
local function formatTimestamp()
    return os.date("%Y%m%d_%H%M%S")
end

--- Build autosave filename: timestamp-laptime (track and car are in directory path)
---@param lapObj table Lap instance
---@return string Filename (without path or extension)
local function buildFilename(lapObj)
    local timestamp = formatTimestamp()
    local lapTime = formatLapTime(lapObj.time or 0)
    return string.format("%s-%s", timestamp, lapTime)
end

--------------------------------------------------------------------------------
-- CSV Writing (Chunked)
--------------------------------------------------------------------------------

--- Escape CSV field
local function escapeCSV(value)
    if not value then return "" end
    local str = tostring(value)
    if str:find('[,"\n]') then
        return '"' .. str:gsub('"', '""') .. '"'
    end
    return str
end

--- Initialize a CSV write job
---@param lapObj table Lap instance
---@param basePath string Full path without extension
---@return table Job state
local function initCSVJob(lapObj, basePath)
    local path = basePath .. ".csv"
    
    -- Open file and write headers
    local f = io.open(path, "w")
    if not f then
        ac.log("bg_writer: Failed to open " .. path)
        return nil
    end
    
    -- Write MoTeC-style headers
    f:write('"Format","MoTeC CSV File"\n')
    f:write(string.format('"Sample Rate","%.3f","Hz"\n', lap.SAMPLE_RATE))
    f:write("\n")
    
    -- Column headers
    local headers = {
        "Time", "Track", "Lap Progression", "Ground Speed",
        "Driver Throttle Pos", "Brake Pressure F", "Brake Pressure R",
        "Clutch Pos", "Steering Angle", "Fuel Remaining", "Gear",
        "G Force Lat", "G Force Long",
        "Damper Travel FL", "Damper Travel FR", "Damper Travel RL", "Damper Travel RR",
        "TC Active", "Wheel Slip", "Lockup FL", "Lockup FR", "Lockup RL", "Lockup RR"
    }
    local units = {
        "s", "", "", "km/h", "%", "bar", "bar", "%", "deg", "l", "", "g", "g",
        "m", "m", "m", "m",
        "", "", "", "", "", ""
    }
    
    f:write('"' .. table.concat(headers, '","') .. '"\n')
    f:write('"' .. table.concat(units, '","') .. '"\n')
    f:write("\n")
    
    return {
        type = "csv",
        file = f,
        path = path,
        lap = lapObj,
        rowIndex = 1,
        totalRows = lapObj:length(),
        completed = false,
    }
end

--- Process one chunk of CSV rows
---@param job table Job state
---@return boolean done True if job is complete
local function processCSVChunk(job)
    local f = job.file
    local lapObj = job.lap
    local count = lapObj:length()
    
    local startRow = job.rowIndex
    local endRow = math.min(startRow + ROWS_PER_FRAME - 1, count)
    
    for i = startRow, endRow do
        local timeS = (lapObj.times and lapObj.times[i]) or ((i - 1) / lap.SAMPLE_RATE)
        local pos = lapObj.pos and lapObj.pos[i] or (i - 1) / (count - 1)
        local throttle = lapObj.throttle and lapObj.throttle[i] or 0
        local brake = lapObj.brake and lapObj.brake[i] or 0
        local brakeR = (lapObj.brake_r and lapObj.brake_r[i]) or brake
        local clutchInverted = lapObj.clutch and lapObj.clutch[i] or 0
        local steeringNorm = lapObj.steering and lapObj.steering[i] or 0.5
        local speed = lapObj.speed and lapObj.speed[i] or 0
        local gear = lapObj.gear and lapObj.gear[i] or 0
        local fuel = lapObj:fuelAt(pos) or 0
        local g = lapObj.gforce and lapObj.gforce[i] or nil
        local gLat = g and g.x or 0
        local gLong = g and g.z or 0
        
        -- Suspension travel (FL, FR, RL, RR)
        local susp = lapObj.suspension and lapObj.suspension[i] or nil
        local suspFL = susp and susp[1] or 0
        local suspFR = susp and susp[2] or 0
        local suspRL = susp and susp[3] or 0
        local suspRR = susp and susp[4] or 0
        
        -- Flags (TC, slip, lockups) - in-sim only data
        local flags = lapObj.flags and lapObj.flags[i] or 0
        local tcActive = (bit.band(flags, lap.FLAGS.TC_ACTIVE) ~= 0) and 1 or 0
        local wheelSlip = (bit.band(flags, lap.FLAGS.WHEEL_SLIP) ~= 0) and 1 or 0
        local lockupFL = (bit.band(flags, lap.FLAGS.LOCKUP_FL) ~= 0) and 1 or 0
        local lockupFR = (bit.band(flags, lap.FLAGS.LOCKUP_FR) ~= 0) and 1 or 0
        local lockupRL = (bit.band(flags, lap.FLAGS.LOCKUP_RL) ~= 0) and 1 or 0
        local lockupRR = (bit.band(flags, lap.FLAGS.LOCKUP_RR) ~= 0) and 1 or 0
        
        -- Convert to CSV values
        local throttlePct = throttle * 100
        local clutchPct = (1 - clutchInverted) * 100
        local steeringDeg = lap.steerToDegrees(steeringNorm)
        
        f:write(string.format("%.3f,%s,%.6f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.3f,%d,%.3f,%.3f,%.6f,%.6f,%.6f,%.6f,%d,%d,%d,%d,%d,%d\n",
            timeS,
            escapeCSV(lapObj.track or ""),
            pos,
            speed,
            throttlePct,
            brake,
            brakeR,
            clutchPct,
            steeringDeg,
            fuel,
            gear or 0,
            gLat,
            gLong,
            suspFL,
            suspFR,
            suspRL,
            suspRR,
            tcActive,
            wheelSlip,
            lockupFL,
            lockupFR,
            lockupRL,
            lockupRR
        ))
    end
    
    job.rowIndex = endRow + 1
    
    if job.rowIndex > count then
        f:close()
        job.completed = true
        ac.log(string.format("bg_writer: CSV complete - %s (%d rows)", job.path, count))
        return true
    end
    
    return false
end

--------------------------------------------------------------------------------
-- Markdown Writing (Single Frame)
--------------------------------------------------------------------------------

--- Write markdown file for a lap using the full corner analysis
---@param lapObj table Lap instance
---@param basePath string Full path without extension
---@param referenceLap table|nil Optional reference lap for comparison
---@return boolean Success
local function writeMD(lapObj, basePath, referenceLap)
    if not markdown then
        markdown = require('lib.ui.markdown')
    end
    local content = markdown.generate(lapObj, referenceLap)
    if not content or content == "" then
        ac.log("bg_writer: MD generation returned empty content")
        return false
    end
    local path = basePath .. ".md"
    local f = io.open(path, "w")
    if not f then
        ac.log("bg_writer: Failed to open " .. path)
        return false
    end
    f:write(content)
    f:close()
    ac.log("bg_writer: MD complete - " .. path)
    return true
end

--------------------------------------------------------------------------------
-- JSON Notes Writing (Single Frame)
--------------------------------------------------------------------------------

--- Extract base filename from full path (e.g. "car-timestamp-laptime")
---@param basePath string Full path without extension
---@return string Base filename
local function getBaseFilename(basePath)
    return basePath:match("([^/\\]+)$") or "lap"
end

--- Build compact JSON payload: header metadata + corners with notes only.
--- Telemetry lives in the CSV - look up traces by position from that file.
---@param lapObj table Lap instance
---@param basePath string Full path without extension
---@param options table { referenceLap, trackCorners }
---@return string|nil JSON string or nil on error
local function buildJSONPayload(lapObj, basePath, options)
    if not corner_analysis then
        corner_analysis = require('lib.windows.corner_analysis')
    end

    local baseName = getBaseFilename(basePath)
    local corners = options.trackCorners or {}
    local refLap = options.referenceLap

    -- Session info from sim (may be nil if not in-sim)
    local sim = ac.getSim()
    local car = ac.getCar(0)
    local trackLength = sim and sim.trackLengthM or 5000

    -- Tire temps/pressures (may be nil if not in-sim or wheels unavailable)
    local tireTemps, tirePressures = nil, nil
    pcall(function()
        if car and car.wheels then
            local w = car.wheels
            tireTemps = {
                fl = w[0] and w[0].tyreCoreTemperature or nil,
                fr = w[1] and w[1].tyreCoreTemperature or nil,
                rl = w[2] and w[2].tyreCoreTemperature or nil,
                rr = w[3] and w[3].tyreCoreTemperature or nil,
            }
            tirePressures = {
                fl = w[0] and w[0].tyrePressure or nil,
                fr = w[1] and w[1].tyrePressure or nil,
                rl = w[2] and w[2].tyrePressure or nil,
                rr = w[3] and w[3].tyrePressure or nil,
            }
        end
    end)

    local payload = {
        version = 1,
        lap = lapObj.time,
        lapFile = baseName,
        telemetryCsv = baseName .. ".csv",
        car = lapObj.car or "unknown",
        carName = car and ac.getCarName(0, true) or nil,
        track = lapObj.track or "unknown",
        trackLength = trackLength,
        sessionId = lapObj.sessionId,
        lapNumberInSession = lapObj.lapNumberInSession,
        valid = lapObj.valid,
        savedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        fuelLevel = lapObj.fuelLeftAtStart,
        grip = sim and sim.roadGrip and (sim.roadGrip * 100) or nil,
        brakeBias = car and car.brakeBias or nil,
        ambientTemp = sim and sim.ambientTemperature or nil,
        roadTemp = sim and sim.roadTemperature or nil,
        timeOfDay = (sim and sim.timeHours and sim.timeMinutes)
            and string.format("%02d:%02d", sim.timeHours, sim.timeMinutes) or nil,
        tireTemps = tireTemps,
        tirePressures = tirePressures,
        referenceLap = refLap and (function()
            if not refLap.sourceFile or type(refLap.sourceFile) ~= "string" then return nil end
            local fn = refLap.sourceFile:match("([^/\\]+)$")
            if not fn or fn == "" then return nil end
            return fn:gsub("%.csv$", "")
        end)() or nil,
        referenceLapTime = refLap and refLap.time or nil,
        delta = refLap and (lapObj.time - refLap.time) / 1000 or nil,
        startSpeed = lapObj:speedAt(0.001) or (lapObj.speed and lapObj.speed[1]) or nil,
        corners = {},
    }

    -- Build corners array: startPos, endPos, metrics, notes (no telemetry samples - use CSV)
    if not scoring then
        scoring = require('lib.core.scoring')
    end
    for _, corner in ipairs(corners) do
        if corner.startPos and corner.endPos then
            local currentAnalysis = corner_analysis.analyzeCorner(lapObj, corner)
            local refAnalysis = refLap and corner_analysis.analyzeCorner(refLap, corner) or nil
            local comparison = (currentAnalysis and refAnalysis) and
                corner_analysis.compareCorners(currentAnalysis, refAnalysis) or nil
            local notes = corner_analysis.collectNotes(comparison, lapObj, refLap)

            local notesOut = {}
            if notes then
                for _, n in ipairs(notes) do
                    if n and n.text then
                        table.insert(notesOut, { text = n.text, severity = n.severity or "info" })
                    end
                end
            end

            local cornerOut = {
                number = corner.number,
                name = corner.name or ("Corner " .. tostring(corner.number)),
                startPos = corner.startPos,
                endPos = corner.endPos,
                notes = notesOut,
            }
            -- Per-corner metrics
            if currentAnalysis then
                cornerOut.entrySpeed = currentAnalysis.entrySpeed
                cornerOut.apexSpeed = currentAnalysis.apexSpeed
                cornerOut.exitSpeed = currentAnalysis.exitSpeed
                cornerOut.brakePos = currentAnalysis.brakePos
                cornerOut.liftOffPos = currentAnalysis.liftOffPos
                cornerOut.minGear = currentAnalysis.minGear
            end
            if refAnalysis then
                cornerOut.refEntrySpeed = refAnalysis.entrySpeed
                cornerOut.refApexSpeed = refAnalysis.apexSpeed
                cornerOut.refExitSpeed = refAnalysis.exitSpeed
            end
            if comparison then
                cornerOut.timeDelta = comparison.timeDelta
                cornerOut.score = scoring.calculate(comparison)
            end

            table.insert(payload.corners, cornerOut)
        end
    end

    -- CSP provides JSON globally
    if not JSON or not JSON.stringify then
        ac.log("bg_writer: JSON.stringify not available")
        return nil
    end
    return JSON.stringify(payload)
end

--- Write JSON notes file alongside CSV (compact, easy to parse)
---@param lapObj table Lap instance
---@param basePath string Full path without extension
---@param options table { referenceLap, trackCorners }
---@return boolean Success
local function writeJSON(lapObj, basePath, options)
    options = options or {}
    local content = buildJSONPayload(lapObj, basePath, options)
    if not content then
        ac.log("bg_writer: JSON build failed")
        return false
    end

    local path = basePath .. ".json"
    local f = io.open(path, "w")
    if not f then
        ac.log("bg_writer: Failed to open " .. path)
        return false
    end

    f:write(content)
    f:close()
    ac.log("bg_writer: JSON complete - " .. path)
    return true
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Track last saved lap to prevent duplicate saves
local lastSavedLapId = nil

--- Queue a lap for background saving (CSV + optional JSON notes)
---@param lapObj table Lap instance
---@param options table|nil { includeJSON: bool, referenceLap: table, trackCorners: table }
---@return boolean True if queued successfully
function bg_writer.queueLapSave(lapObj, options)
    -- Validate lap has meaningful data
    if not lapObj then
        ac.log("bg_writer: Skipped save - no lap object")
        return false
    end
    
    local lapLength = lapObj:length()
    if lapLength < 100 then
        ac.log(string.format("bg_writer: Skipped save - lap too short (%d samples)", lapLength))
        return false
    end
    
    -- Require valid lap time
    if not lapObj.time or lapObj.time <= 0 then
        ac.log("bg_writer: Skipped save - no valid lap time")
        return false
    end
    
    -- Prevent duplicate saves of the same lap (using time + session + length as ID)
    local lapId = string.format("%s_%d_%d", lapObj.sessionId or "", lapObj.time or 0, lapLength)
    if lapId == lastSavedLapId then
        ac.log("bg_writer: Skipped save - duplicate lap detected")
        return false
    end
    lastSavedLapId = lapId
    
    options = options or {}
    
    -- Ensure track/car directory structure exists
    paths.ensureDirs(lapObj.track, lapObj.car)
    local dir = paths.autosaveDir(lapObj.track, lapObj.car)
    local basePath = dir .. buildFilename(lapObj)
    
    -- Add CSV job to queue
    local csvJob = initCSVJob(lapObj, basePath)
    if csvJob then
        table.insert(jobQueue, csvJob)
        
        -- Trim queue if too long
        while #jobQueue > MAX_QUEUE_SIZE do
            local dropped = table.remove(jobQueue, 1)
            if dropped.file then
                dropped.file:close()
            end
            ac.log("bg_writer: Dropped old job from queue")
        end
    end
    
    -- Write MD and JSON notes immediately (small files, no chunking needed)
    -- Wrap in pcall to prevent errors from breaking the save
    if options.includeJSON then
        local opts = {
            referenceLap = options.referenceLap,
            trackCorners = options.trackCorners,
        }
        local ok, err = pcall(function()
            writeMD(lapObj, basePath, options.referenceLap)
        end)
        if not ok then
            ac.log("bg_writer: MD generation failed - " .. tostring(err))
        end
        ok, err = pcall(function()
            writeJSON(lapObj, basePath, opts)
        end)
        if not ok then
            ac.log("bg_writer: JSON generation failed - " .. tostring(err))
        end
    end
    
    ac.log(string.format("bg_writer: Queued lap save - %s (queue: %d)", basePath, #jobQueue))
    return true
end

--- Process pending jobs (call every frame from update loop)
--- Processes one chunk per frame to avoid frame drops
function bg_writer.update()
    -- Pick up next job if none active
    if not currentJob and #jobQueue > 0 then
        currentJob = table.remove(jobQueue, 1)
    end
    
    if not currentJob then return end
    
    -- Process current job
    local done = false
    
    if currentJob.type == "csv" then
        done = processCSVChunk(currentJob)
    else
        -- Unknown job type, skip it
        done = true
    end
    
    if done then
        currentJob = nil
    end
end

--- Get queue status
---@return number pending Number of pending jobs
---@return boolean active True if currently writing
function bg_writer.getStatus()
    local pending = #jobQueue
    local active = currentJob ~= nil
    return pending, active
end

--- Get the autosave directory for a track/car
---@param trackId string
---@param carId string
---@return string Path to data/{track}/{car}/autosave/
function bg_writer.getSaveDir(trackId, carId)
    return paths.autosaveDir(trackId or "unknown", carId or "unknown")
end

--- Flush all pending jobs synchronously (for clean shutdown)
function bg_writer.flush()
    -- Complete current job
    while currentJob do
        if currentJob.type == "csv" then
            processCSVChunk(currentJob)
            if currentJob.completed then
                currentJob = nil
            end
        else
            currentJob = nil
        end
    end
    
    -- Process remaining queue
    while #jobQueue > 0 do
        currentJob = table.remove(jobQueue, 1)
        while currentJob do
            if currentJob.type == "csv" then
                processCSVChunk(currentJob)
                if currentJob.completed then
                    currentJob = nil
                end
            else
                currentJob = nil
            end
        end
    end
    
    ac.log("bg_writer: Flushed all pending jobs")
end

--------------------------------------------------------------------------------
-- Test Exports (for unit testing internal functions)
--------------------------------------------------------------------------------

bg_writer._testExports = {
    formatLapTime = formatLapTime,
    buildFilename = buildFilename,
}

return bg_writer
