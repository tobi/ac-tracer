-- Tests for automatic corner detection from lap telemetry
-- Compares detected corners against known track corner maps

local lap = require('lap')

--------------------------------------------------------------------------------
-- Corner Detection Logic (copied from state.lua for testability)
--------------------------------------------------------------------------------

local function isSteeringCentered(steering)
    local STEERING_CENTER_THRESHOLD = 0.042  -- ~15°
    return math.abs(steering - 0.5) < STEERING_CENTER_THRESHOLD
end

--- Auto-detect corners from a lap's telemetry
--- Detects both braking zones AND lift-off corners with lateral G
---@param lapData table Lap instance
---@param trackLength number Track length in meters
---@return table Array of corner definitions
local function detectCorners(lapData, trackLength)
    if not lapData or lapData:length() < 30 then return {} end

    -- Detection parameters (hardcoded defaults - same as app_settings.lua)
    local SPEED_DROP_THRESHOLD = 0.05   -- 5% speed drop to qualify as corner
    local BRAKE_THRESHOLD = 5           -- bar - minimum brake to start corner detection
    local THROTTLE_ON_THRESHOLD = 0.98  -- 98% throttle = full throttle
    local LEAD_DISTANCE = 50
    local EXIT_TIME = 0.3               -- Short exit - detect more corners
    local EXIT_TIME_THROTTLE_ONLY = 0.8 -- Short throttle-only exit
    
    -- Lift-off corner detection parameters
    local LIFT_THROTTLE_THRESHOLD = 0.7  -- Throttle below this = lifting
    local LIFT_LAT_G_THRESHOLD = 0.5     -- Minimum lateral G to qualify as corner (lowered from 0.8)
    local LIFT_DURATION_MIN = 0.2        -- Minimum lift duration in seconds (lowered from 0.3)

    trackLength = trackLength or 5000
    local leadSpline = LEAD_DISTANCE / trackLength

    local corners = {}
    local i = 1
    local numSamples = lapData:length()
    
    -- Helper to check if position is inside any existing corner
    local function isInsideCorner(pos)
        for _, c in ipairs(corners) do
            if c.startPos <= c.endPos then
                if pos >= c.startPos and pos <= c.endPos then return true end
            else
                -- Handle wrap-around
                if pos >= c.startPos or pos <= c.endPos then return true end
            end
        end
        return false
    end
    
    -- Helper to find exit point from a given index
    local function findExitIdx(startIdx, apexIdx)
        local exitIdx = apexIdx
        local exitConditionStart = nil
        local throttleOnlyStart = nil
        local apexTime = (apexIdx - 1) / lap.SAMPLE_RATE

        for m = apexIdx, numSamples do
            local sTime = (m - 1) / lap.SAMPLE_RATE
            local sThrottle = lapData.throttle[m]
            local sSteering = lapData.steering[m]

            if isSteeringCentered(sSteering) and sThrottle >= THROTTLE_ON_THRESHOLD then
                if not exitConditionStart then exitConditionStart = sTime end
                if (sTime - exitConditionStart) >= EXIT_TIME then
                    return m
                end
            else
                exitConditionStart = nil
            end

            if sThrottle >= THROTTLE_ON_THRESHOLD then
                if not throttleOnlyStart then throttleOnlyStart = sTime end
                if (sTime - throttleOnlyStart) >= EXIT_TIME_THROTTLE_ONLY then
                    return m
                end
            else
                throttleOnlyStart = nil
            end

            if (sTime - apexTime) > 15 then
                return m
            end
        end
        return exitIdx
    end
    
    -- Helper to get lateral G at index
    local function getLatG(idx)
        if lapData.gforce and lapData.gforce[idx] then
            return math.abs(lapData.gforce[idx].x)
        end
        return 0
    end

    -- Pass 1: Detect braking zones
    while i < numSamples do
        local brake = lapData.brake[i]
        local pos = lapData.pos[i]
        local speed = lapData.speed[i]

        if brake >= BRAKE_THRESHOLD then
            local brakePos = pos
            local entryIdx = i
            local maxSpeedBeforeBrake = speed

            -- Look back for entry point
            local j = i - 1
            while j >= 1 do
                if lapData.speed[j] > maxSpeedBeforeBrake then
                    maxSpeedBeforeBrake = lapData.speed[j]
                end
                local posDiff = brakePos - lapData.pos[j]
                if posDiff < 0 then posDiff = posDiff + 1 end
                if posDiff >= leadSpline then
                    entryIdx = j
                    break
                end
                j = j - 1
            end

            -- Find apex (minimum speed)
            local apexIdx = i
            local apexSpeed = speed
            local k = i + 1
            while k <= numSamples do
                if lapData.speed[k] < apexSpeed then
                    apexSpeed = lapData.speed[k]
                    apexIdx = k
                end
                if lapData.speed[k] > apexSpeed * 1.3 then break end
                k = k + 1
            end

            -- Check if qualifies as corner
            local speedDrop = (maxSpeedBeforeBrake - apexSpeed) / maxSpeedBeforeBrake
            if speedDrop >= SPEED_DROP_THRESHOLD and maxSpeedBeforeBrake > 50 then
                local exitIdx = findExitIdx(entryIdx, apexIdx)

                table.insert(corners, {
                    startPos = lapData.pos[entryIdx],
                    endPos = lapData.pos[exitIdx],
                    apexPos = lapData.pos[apexIdx],
                    apexSpeed = apexSpeed,
                    entrySpeed = maxSpeedBeforeBrake,
                    endIdx = exitIdx,
                    type = "brake"
                })

                i = exitIdx + 1
            else
                i = i + 1
            end
        else
            i = i + 1
        end
    end

    -- Pass 2: Detect lift-off corners (throttle lift + lateral G)
    -- Only if we have g-force data
    local liftCornersFound = 0
    if lapData.gforce and #lapData.gforce > 0 then
        i = 1
        while i < numSamples do
            local throttle = lapData.throttle[i]
            local latG = getLatG(i)
            local pos = lapData.pos[i]
            
            -- Check for lift with significant lateral G, not already in a corner
            local insideCorner = isInsideCorner(pos)
            
            if throttle < LIFT_THROTTLE_THRESHOLD and latG >= LIFT_LAT_G_THRESHOLD and not insideCorner then
                local liftStartIdx = i
                local liftStartTime = (i - 1) / lap.SAMPLE_RATE
                
                -- Find apex (minimum speed during lift)
                local apexIdx = i
                local apexSpeed = lapData.speed[i]
                local maxLatG = latG
                local liftEndIdx = i
                local maxSpeedBefore = lapData.speed[i]
                
                -- Scan forward while lifting or turning
                local k = i + 1
                while k <= numSamples do
                    local kThrottle = lapData.throttle[k]
                    local kLatG = getLatG(k)
                    
                    -- Still in corner if throttle < threshold OR significant lateral G
                    if kThrottle < LIFT_THROTTLE_THRESHOLD or kLatG >= LIFT_LAT_G_THRESHOLD * 0.5 then
                        if lapData.speed[k] < apexSpeed then
                            apexSpeed = lapData.speed[k]
                            apexIdx = k
                        end
                        if kLatG > maxLatG then
                            maxLatG = kLatG
                        end
                        liftEndIdx = k
                        k = k + 1
                    else
                        break
                    end
                end
                
                local liftDuration = (liftEndIdx - liftStartIdx) / lap.SAMPLE_RATE
                
                -- Qualify if sustained lift with good lateral G
                if liftDuration >= LIFT_DURATION_MIN and maxLatG >= LIFT_LAT_G_THRESHOLD then
                    -- Look back for entry point
                    local entryIdx = liftStartIdx
                    local j = liftStartIdx - 1
                    while j >= 1 do
                        if lapData.speed[j] > maxSpeedBefore then
                            maxSpeedBefore = lapData.speed[j]
                        end
                        local posDiff = lapData.pos[liftStartIdx] - lapData.pos[j]
                        if posDiff < 0 then posDiff = posDiff + 1 end
                        if posDiff >= leadSpline then
                            entryIdx = j
                            break
                        end
                        j = j - 1
                    end
                    
                    local exitIdx = findExitIdx(entryIdx, apexIdx)
                    
                    -- Only add if not overlapping with existing corners
                    local startPos = lapData.pos[entryIdx]
                    local endPos = lapData.pos[exitIdx]
                    local startInside = isInsideCorner(startPos)
                    local endInside = isInsideCorner(endPos)
                    
                    if not startInside and not endInside then
                        liftCornersFound = liftCornersFound + 1
                        table.insert(corners, {
                            startPos = startPos,
                            endPos = endPos,
                            apexPos = lapData.pos[apexIdx],
                            apexSpeed = apexSpeed,
                            entrySpeed = maxSpeedBefore,
                            endIdx = exitIdx,
                            type = "lift"
                        })
                    end
                    
                    i = liftEndIdx + 1
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    
    -- Sort corners by start position and assign numbers
    table.sort(corners, function(a, b) return a.startPos < b.startPos end)
    for idx, c in ipairs(corners) do
        c.number = idx
        c.name = "Corner " .. idx
    end

    return corners
end

--------------------------------------------------------------------------------
-- Barcelona Corner Detection Test
--------------------------------------------------------------------------------

suite("Corner Detection - Barcelona")

-- Barcelona-Catalunya GP circuit
-- 16 official corners (see track map)
-- Length: ~4.655 km
local BARCELONA_LENGTH = 4655

-- Actual braking zone positions from MoTeC CSV data analysis
-- The spline starts at start/finish line on the main straight
-- These positions are based on actual brake application points in the CSV
local BARCELONA_CORNERS = {
    { name = "Turn 1 (Elf)",       pos = 0.15 },   -- First braking zone after main straight (~683m)
    { name = "Turn 5 (Seat)",      pos = 0.34 },   -- Second major braking (~1579m)
    { name = "Turn 7 (Campsa)",    pos = 0.43 },   -- Third braking zone (~1988m)
    { name = "Turn 9",             pos = 0.52 },   -- Fourth braking (~2433m)
    { name = "Turn 10 (La Caixa)", pos = 0.60 },   -- Hairpin approach (~2799m)
    { name = "Turn 12 (Europcar)", pos = 0.72 },   -- Major braking for stadium (~3325m)
    { name = "Turn 13",            pos = 0.79 },   -- Secondary braking (~3663m)
    { name = "Turn 16 (Catalunya)",pos = 0.90 },   -- Final corner braking (~4201m)
}

local barcelonaLap = nil

test("loads barcelona.csv for corner detection", function()
    barcelonaLap = lap.fromCSV("tracks/barcelona.csv", "barcelona", "test_car", BARCELONA_LENGTH)
    assert_not_nil(barcelonaLap, "Should load barcelona.csv")
    assert_true(barcelonaLap:length() > 100, "Should have samples")
end)

test("detects corners from barcelona lap", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    
    local detected = detectCorners(barcelonaLap, BARCELONA_LENGTH)
    
    -- Print detected corners for analysis
    print("\n=== Detected Corners ===")
    print(string.format("Expected: %d corners, Detected: %d corners", #BARCELONA_CORNERS, #detected))
    print("")
    
    for i, c in ipairs(detected) do
        local posMeters = math.floor(c.startPos * BARCELONA_LENGTH)
        local endMeters = math.floor(c.endPos * BARCELONA_LENGTH)
        local apexMeters = math.floor((c.apexPos or c.startPos) * BARCELONA_LENGTH)
        print(string.format("  Corner %2d: pos %.3f-%.3f (apex %.3f) | %4dm-%4dm | entry %3.0f km/h -> apex %3.0f km/h",
            i, c.startPos, c.endPos, c.apexPos or 0,
            posMeters, endMeters,
            c.entrySpeed or 0, c.apexSpeed or 0))
    end
    print("")
    
    -- Algorithm detects braking zones - one per significant brake application.
    -- Barcelona has 8 significant braking zones in this lap.
    assert_true(#detected >= 6, "Should detect at least 6 corners, got " .. #detected)
    assert_true(#detected <= 12, "Should detect at most 12 corners, got " .. #detected)
end)

test("detected corners are in order", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    
    local detected = detectCorners(barcelonaLap, BARCELONA_LENGTH)
    
    -- Verify corners are in ascending position order
    local prevEnd = 0
    for i, c in ipairs(detected) do
        assert_true(c.startPos >= prevEnd * 0.9,  -- Allow some overlap
            string.format("Corner %d starts (%.3f) before previous ends (%.3f)", 
                i, c.startPos, prevEnd))
        assert_true(c.endPos > c.startPos or c.endPos < 0.1,  -- Handle wrap-around
            string.format("Corner %d end (%.3f) should be after start (%.3f)", 
                i, c.endPos, c.startPos))
        prevEnd = c.endPos
    end
end)

test("corner positions match known corners approximately", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    
    local detected = detectCorners(barcelonaLap, BARCELONA_LENGTH)
    
    -- For each expected corner, find the closest detected corner
    local TOLERANCE = 0.05  -- 5% of track (~230m tolerance)
    local matchedCount = 0
    local unmatchedExpected = {}
    
    print("\n=== Corner Matching Analysis ===")
    
    for _, expected in ipairs(BARCELONA_CORNERS) do
        local bestMatch = nil
        local bestDist = 1
        
        for _, det in ipairs(detected) do
            -- Check if apex is close to expected position
            local apexPos = det.apexPos or ((det.startPos + det.endPos) / 2)
            local dist = math.abs(apexPos - expected.pos)
            if dist < bestDist then
                bestDist = dist
                bestMatch = det
            end
        end
        
        if bestMatch and bestDist <= TOLERANCE then
            matchedCount = matchedCount + 1
            print(string.format("  [MATCH] %s (%.3f) -> Corner %d (apex %.3f) dist=%.3f",
                expected.name, expected.pos, bestMatch.number, 
                bestMatch.apexPos or 0, bestDist))
        else
            table.insert(unmatchedExpected, expected)
            if bestMatch then
                print(string.format("  [MISS]  %s (%.3f) -> nearest Corner %d (apex %.3f) dist=%.3f > %.3f",
                    expected.name, expected.pos, bestMatch.number, 
                    bestMatch.apexPos or 0, bestDist, TOLERANCE))
            else
                print(string.format("  [MISS]  %s (%.3f) -> no match found",
                    expected.name, expected.pos))
            end
        end
    end
    
    print(string.format("\nMatched: %d/%d corners (%.0f%%)", 
        matchedCount, #BARCELONA_CORNERS, 
        matchedCount / #BARCELONA_CORNERS * 100))
    
    -- With corrected corner positions based on actual braking zones, we should match most.
    assert_true(matchedCount >= 6, 
        string.format("Should match at least 6 corners, matched %d", matchedCount))
end)

test("corner analysis functions work on detected corners", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    
    local detected = detectCorners(barcelonaLap, BARCELONA_LENGTH)
    assert_true(#detected > 0, "Should have detected corners")
    
    local corner = detected[1]
    
    -- Test that lap analysis functions work with detected corner ranges
    local brakePoint = barcelonaLap:findBrakePoint(corner.startPos, corner.endPos)
    local apex = barcelonaLap:findApex(corner.startPos, corner.endPos)
    local maxSteer = barcelonaLap:findMaxSteering(corner.startPos, corner.endPos)
    local minGear = barcelonaLap:findMinGear(corner.startPos, corner.endPos)
    
    -- At least some of these should return values for a real corner
    local hasData = brakePoint or apex or maxSteer or minGear
    assert_true(hasData, "Corner analysis functions should return data")
    
    if apex then
        print(string.format("\n  Corner 1 apex: pos=%.3f speed=%.0f km/h", apex, barcelonaLap:speedAt(apex) or 0))
    end
    if minGear then
        print(string.format("  Corner 1 min gear: %d", minGear))
    end
end)
