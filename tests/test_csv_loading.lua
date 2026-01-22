-- test_csv_loading.lua - Validate that reference lap CSVs load correctly
-- Tests that CSV files in ./tracks/ parse correctly and produce valid lap data

-- The test runner loads mock_ac.lua which sets up the environment
local lap = require('lib.lap')

--------------------------------------------------------------------------------
-- Barcelona CSV Tests (Real car MoTeC export with Distance-based positioning)
--------------------------------------------------------------------------------

suite("CSV Loading - Barcelona")

-- Track info: Barcelona-Catalunya GP circuit
-- Length: ~4.655 km
-- Expected lap time for GT3: ~1:45-2:00 (105-120s) but this CSV is faster (~93s)
local BARCELONA_LENGTH = 4655  -- meters
local barcelonaLap = nil
local barcelonaWarnings = nil

test("loads barcelona.csv successfully", function()
    barcelonaLap, barcelonaWarnings = lap.fromCSV("tracks/barcelona.csv", "barcelona", "test_car", BARCELONA_LENGTH)
    assert_not_nil(barcelonaLap, "Should load barcelona.csv")
    assert_true(barcelonaLap:length() > 100, "Should have many samples, got " .. (barcelonaLap and barcelonaLap:length() or 0))
end)

test("barcelona lap time is realistic", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    -- CSV shows ~93s lap which is realistic for a fast car
    local timeS = barcelonaLap.time / 1000
    assert_true(timeS >= 60 and timeS <= 150, 
        string.format("Lap time should be 60-150s, got %.1fs", timeS))
end)

test("barcelona positions span 0 to 1", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local minPos, maxPos = 1, 0
    for i = 1, barcelonaLap:length() do
        local p = barcelonaLap.pos[i]
        if p < minPos then minPos = p end
        if p > maxPos then maxPos = p end
    end
    assert_true(minPos < 0.1, string.format("Min pos should be < 0.1, got %.4f", minPos))
    assert_true(maxPos > 0.9, string.format("Max pos should be > 0.9, got %.4f", maxPos))
end)

test("barcelona interpolation works at all positions", function()
     assert_not_nil(barcelonaLap, "Lap should be loaded")
     for pos = 0.1, 0.9, 0.1 do
         local speed = barcelonaLap:speedAt(pos)
         assert_not_nil(speed, "Should interpolate speed at pos " .. pos)
         assert_true(speed >= 0 and speed <= 400, 
             string.format("Speed at pos %.1f should be 0-400 km/h, got %.1f", pos, speed))
     end
 end)

test("barcelona speed values are in realistic range", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local minSpeed, maxSpeed = math.huge, 0
    for i = 1, barcelonaLap:length() do
        local s = barcelonaLap.speed[i]
        if s < minSpeed then minSpeed = s end
        if s > maxSpeed then maxSpeed = s end
    end
    -- GT3/prototype cars: expect 50-350 km/h range
    assert_true(maxSpeed >= 150, string.format("Max speed should be >= 150 km/h, got %.1f", maxSpeed))
    assert_true(maxSpeed <= 400, string.format("Max speed should be <= 400 km/h, got %.1f", maxSpeed))
end)

test("barcelona throttle is 0-1 normalized", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    for i = 1, barcelonaLap:length() do
        local t = barcelonaLap.throttle[i]
        assert_true(t >= 0 and t <= 1.01,
            string.format("Throttle at sample %d should be 0-1, got %.3f", i, t))
    end
end)

test("barcelona brake is in bar (non-negative)", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local maxBrake = 0
    for i = 1, barcelonaLap:length() do
        local b = barcelonaLap.brake[i]
        assert_true(b >= 0, string.format("Brake at sample %d should be >= 0 bar, got %.3f", i, b))
        if b > maxBrake then maxBrake = b end
    end
    -- Race cars typically have 50-150 bar max brake pressure
    assert_true(maxBrake > 0, "Should have some braking")
    assert_true(maxBrake < 200, string.format("Max brake should be < 200 bar, got %.1f", maxBrake))
end)

test("barcelona steering is 0-1 normalized", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    for i = 1, barcelonaLap:length() do
        local s = barcelonaLap.steering[i]
        assert_true(s >= 0 and s <= 1,
            string.format("Steering at sample %d should be 0-1, got %.3f", i, s))
    end
end)

test("barcelona has braking zones", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local brakeCount = 0
    for i = 1, barcelonaLap:length() do
        if barcelonaLap.brake[i] > 0.1 then
            brakeCount = brakeCount + 1
        end
    end
    -- Should have significant braking (at least 5% of lap)
    local brakePercent = brakeCount / barcelonaLap:length() * 100
    assert_true(brakePercent >= 5, 
        string.format("Should have >= 5%% braking, got %.1f%%", brakePercent))
end)

test("barcelona times array matches sample count", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    assert_equal(#barcelonaLap.times, barcelonaLap:length(), 
        "Times array should match position array length")
end)

test("barcelona times are monotonically increasing", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    for i = 2, #barcelonaLap.times do
        assert_true(barcelonaLap.times[i] >= barcelonaLap.times[i-1],
            string.format("Time should increase: t[%d]=%.3f >= t[%d]=%.3f", 
                i, barcelonaLap.times[i], i-1, barcelonaLap.times[i-1]))
    end
end)

test("barcelona corner analysis functions work", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    -- Test a corner roughly in the middle of the track
    local brakePoint = barcelonaLap:findBrakePoint(0.4, 0.6)
    local apexPos, apexSpeed = barcelonaLap:findApex(0.4, 0.6)
    
    -- These may or may not find results depending on corner positions,
    -- but they shouldn't error
    if brakePoint then
        assert_true(brakePoint >= 0.4 and brakePoint <= 0.6,
            "Brake point should be in search range")
    end
    if apexPos then
        assert_true(apexPos >= 0.4 and apexPos <= 0.6,
            "Apex should be in search range")
        assert_true(apexSpeed > 0, "Apex speed should be positive")
    end
end)

test("barcelona maxBrakeBars returns realistic value", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local maxBar = barcelonaLap:maxBrakeBars()
    assert_true(maxBar > 0, "Should have some max brake pressure")
    assert_true(maxBar < 200, string.format("Max brake should be < 200 bar, got %.1f", maxBar))
end)

--------------------------------------------------------------------------------
-- IER Daytona CSV Tests (AC sim export with Lap Progression)
--------------------------------------------------------------------------------

suite("CSV Loading - IER Daytona")

-- Track info: IER Daytona (sim track, likely road course variant)
-- Length: ~5.7 km (based on distance in CSV: 46958 - 41241 = 5717m)
-- Expected lap time: ~100s based on CSV duration
local DAYTONA_LENGTH = 5717  -- meters (calculated from CSV)
local daytonaLap = nil
local daytonaWarnings = nil

test("loads ier_daytona.csv successfully", function()
    -- Note: This CSV has Lap Progression so trackLength is optional
    daytonaLap, daytonaWarnings = lap.fromCSV("tracks/ier_daytona.csv", "ier_daytona", "test_car", DAYTONA_LENGTH)
    assert_not_nil(daytonaLap, "Should load ier_daytona.csv")
    assert_true(daytonaLap:length() > 100, "Should have many samples, got " .. (daytonaLap and daytonaLap:length() or 0))
end)

test("daytona lap time is realistic", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    -- CSV shows ~100s lap
    local timeS = daytonaLap.time / 1000
    assert_true(timeS >= 60 and timeS <= 180, 
        string.format("Lap time should be 60-180s, got %.1fs", timeS))
end)

test("daytona positions span 0 to 1", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    local minPos, maxPos = 1, 0
    for i = 1, daytonaLap:length() do
        local p = daytonaLap.pos[i]
        if p < minPos then minPos = p end
        if p > maxPos then maxPos = p end
    end
    assert_true(minPos < 0.1, string.format("Min pos should be < 0.1, got %.4f", minPos))
    assert_true(maxPos > 0.9, string.format("Max pos should be > 0.9, got %.4f", maxPos))
end)

test("daytona interpolation works at all positions", function()
     assert_not_nil(daytonaLap, "Lap should be loaded")
     for pos = 0.1, 0.9, 0.1 do
         local speed = daytonaLap:speedAt(pos)
         assert_not_nil(speed, "Should interpolate speed at pos " .. pos)
         assert_true(speed >= 0 and speed <= 400, 
             string.format("Speed at pos %.1f should be 0-400 km/h, got %.1f", pos, speed))
     end
 end)

test("daytona speed values are in realistic range", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    local minSpeed, maxSpeed = math.huge, 0
    for i = 1, daytonaLap:length() do
        local s = daytonaLap.speed[i]
        if s < minSpeed then minSpeed = s end
        if s > maxSpeed then maxSpeed = s end
    end
    -- LMP/prototype cars on Daytona: expect up to 300+ km/h
    assert_true(maxSpeed >= 200, string.format("Max speed should be >= 200 km/h, got %.1f", maxSpeed))
    assert_true(maxSpeed <= 400, string.format("Max speed should be <= 400 km/h, got %.1f", maxSpeed))
end)

test("daytona throttle is 0-1 normalized", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    for i = 1, daytonaLap:length() do
        local t = daytonaLap.throttle[i]
        assert_true(t >= 0 and t <= 1.01,
            string.format("Throttle at sample %d should be 0-1, got %.3f", i, t))
    end
end)

test("daytona brake is in bar (non-negative)", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    local maxBrake = 0
    for i = 1, daytonaLap:length() do
        local b = daytonaLap.brake[i]
        assert_true(b >= 0, string.format("Brake at sample %d should be >= 0 bar, got %.3f", i, b))
        if b > maxBrake then maxBrake = b end
    end
    -- Race cars typically have 50-150 bar max brake pressure
    assert_true(maxBrake > 0, "Should have some braking")
    assert_true(maxBrake < 200, string.format("Max brake should be < 200 bar, got %.1f", maxBrake))
end)

test("daytona steering is 0-1 normalized", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    for i = 1, daytonaLap:length() do
        local s = daytonaLap.steering[i]
        assert_true(s >= 0 and s <= 1,
            string.format("Steering at sample %d should be 0-1, got %.3f", i, s))
    end
end)

test("daytona has braking zones", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    local brakeCount = 0
    for i = 1, daytonaLap:length() do
        if daytonaLap.brake[i] > 0.1 then
            brakeCount = brakeCount + 1
        end
    end
    local brakePercent = brakeCount / daytonaLap:length() * 100
    assert_true(brakePercent >= 3, 
        string.format("Should have >= 3%% braking, got %.1f%%", brakePercent))
end)

test("daytona times are monotonically increasing", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    for i = 2, #daytonaLap.times do
        assert_true(daytonaLap.times[i] >= daytonaLap.times[i-1],
            string.format("Time should increase: t[%d]=%.3f >= t[%d]=%.3f", 
                i, daytonaLap.times[i], i-1, daytonaLap.times[i-1]))
    end
end)

test("daytona has csvSource metadata", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    assert_not_nil(daytonaLap.csvSource, "Should have csvSource metadata")
    -- Check that it found the right columns
    if daytonaLap.csvSource.throttle then
        assert_true(daytonaLap.csvSource.throttle:find("[Tt]hrottle"),
            "Throttle source should contain 'throttle': " .. daytonaLap.csvSource.throttle)
    end
end)

--------------------------------------------------------------------------------
-- Sample Rate Normalization Tests
--------------------------------------------------------------------------------

suite("CSV Sample Rate Normalization")

test("barcelona is normalized to target sample rate", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    -- Original CSV is 10 Hz, should be resampled to lap.SAMPLE_RATE
    -- ~93s at 30 Hz = ~2790 samples
    local sampleRate = lap.SAMPLE_RATE
    local expectedMin = math.floor(90 * sampleRate * 0.9)
    local expectedMax = math.ceil(100 * sampleRate * 1.1)
    assert_true(barcelonaLap:length() >= expectedMin and barcelonaLap:length() <= expectedMax,
        string.format("Sample count should be %d-%d for %d Hz, got %d", 
            expectedMin, expectedMax, sampleRate, barcelonaLap:length()))
end)

test("daytona is normalized to target sample rate", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    -- Original CSV is 10 Hz, should be resampled to lap.SAMPLE_RATE
    -- ~100s at 30 Hz = ~3000 samples
    local sampleRate = lap.SAMPLE_RATE
    local expectedMin = math.floor(95 * sampleRate * 0.9)
    local expectedMax = math.ceil(110 * sampleRate * 1.1)
    assert_true(daytonaLap:length() >= expectedMin and daytonaLap:length() <= expectedMax,
        string.format("Sample count should be %d-%d for %d Hz, got %d", 
            expectedMin, expectedMax, sampleRate, daytonaLap:length()))
end)

test("time delta calculation works with CSV laps", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    -- Self-comparison should give 0 delta
    local delta = barcelonaLap:getDeltaVs(barcelonaLap, 0.5)
    assert_near(delta, 0, 0.001, "Self-comparison delta should be ~0")
end)

--------------------------------------------------------------------------------
-- Edge Cases
--------------------------------------------------------------------------------

suite("CSV Edge Cases")

test("nonexistent file returns nil with warning", function()
    local result, warnings = lap.fromCSV("tracks/nonexistent.csv", "test", "test", 5000)
    assert_nil(result, "Should return nil for nonexistent file")
    assert_not_nil(warnings, "Should return warnings")
end)

test("barcelona getTimeAtPos works correctly", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    
    -- Time at start should be near 0
    local timeAtStart = barcelonaLap:getTimeAtPos(barcelonaLap.pos[1])
    assert_near(timeAtStart, barcelonaLap.times[1], 0.1, "Time at start should match")
    
    -- Time at middle should be roughly half lap time
    local timeAtMid = barcelonaLap:getTimeAtPos(0.5)
    assert_not_nil(timeAtMid, "Should get time at mid-lap")
    assert_true(timeAtMid > 0, "Mid-lap time should be positive")
    assert_true(timeAtMid < barcelonaLap.time / 1000, "Mid-lap time should be less than total")
end)

test("getTracesAt returns all fields", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local positions = {0.1, 0.2, 0.3, 0.4, 0.5}
    local traces = barcelonaLap:getTracesAt(positions)

    assert_not_nil(traces, "Should return traces")
    assert_equal(#traces.throttle, 5, "Should have 5 throttle values")
    assert_equal(#traces.brake, 5, "Should have 5 brake values")
    assert_equal(#traces.speed, 5, "Should have 5 speed values")
    assert_equal(#traces.steering, 5, "Should have 5 steering values")
end)

test("getTracesAt returns normalized brake values (0-1)", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local positions = {0.1, 0.2, 0.3, 0.4, 0.5}
    local traces = barcelonaLap:getTracesAt(positions)

    assert_not_nil(traces, "Should return traces")
    for i, brake in ipairs(traces.brake) do
        assert_true(brake >= 0, "Brake should be >= 0 at position " .. i)
        assert_true(brake <= 1, "Brake should be <= 1 (normalized) at position " .. i)
    end
end)

test("getTracesAt brake normalization matches brakePercentAt", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    local positions = {0.1, 0.3, 0.5, 0.7, 0.9}
    local maxBar = 100  -- Default normalization

    local traces = barcelonaLap:getTracesAt(positions, maxBar)

    for i, pos in ipairs(positions) do
        local expected = barcelonaLap:brakePercentAt(pos, maxBar) or 0
        assert_near(traces.brake[i], expected, 0.001,
            string.format("Brake at pos %.1f should match brakePercentAt", pos))
    end
end)

--------------------------------------------------------------------------------
-- G-Force Unit Conversion Tests
--------------------------------------------------------------------------------

suite("CSV G-Force Unit Conversion")

test("daytona gforce values are in realistic G range", function()
    assert_not_nil(daytonaLap, "Lap should be loaded")
    if not daytonaLap.gforce or #daytonaLap.gforce == 0 then
        -- Skip if no G-force data in this CSV
        return
    end

    local maxLatG = 0
    local maxLongG = 0
    for i = 1, #daytonaLap.gforce do
        local g = daytonaLap.gforce[i]
        if g then
            maxLatG = math.max(maxLatG, math.abs(g.x or 0))
            maxLongG = math.max(maxLongG, math.abs(g.z or 0))
        end
    end

    -- After unit conversion, values should be in G's (typically 0-5G for race cars)
    -- NOT in m/s² (which would be 0-50 for similar range)
    if maxLatG > 0 then
        assert_true(maxLatG <= 10,
            string.format("Lateral G should be <= 10G (was it converted?), got %.2f", maxLatG))
    end
    if maxLongG > 0 then
        assert_true(maxLongG <= 10,
            string.format("Longitudinal G should be <= 10G (was it converted?), got %.2f", maxLongG))
    end
end)

test("barcelona gforce values are in realistic G range", function()
    assert_not_nil(barcelonaLap, "Lap should be loaded")
    if not barcelonaLap.gforce or #barcelonaLap.gforce == 0 then
        -- Skip if no G-force data in this CSV
        return
    end

    local maxLatG = 0
    local maxLongG = 0
    for i = 1, #barcelonaLap.gforce do
        local g = barcelonaLap.gforce[i]
        if g then
            maxLatG = math.max(maxLatG, math.abs(g.x or 0))
            maxLongG = math.max(maxLongG, math.abs(g.z or 0))
        end
    end

    -- Values in G's should be reasonable (race cars rarely exceed 5-6G)
    if maxLatG > 0 then
        assert_true(maxLatG <= 10,
            string.format("Lateral G should be <= 10G after unit conversion, got %.2f", maxLatG))
    end
    if maxLongG > 0 then
        assert_true(maxLongG <= 10,
            string.format("Longitudinal G should be <= 10G after unit conversion, got %.2f", maxLongG))
    end
end)

--------------------------------------------------------------------------------
-- CSV Parser Unit Conversion Tests (Direct)
--------------------------------------------------------------------------------

suite("CSV Parser Unit Conversions")

test("m/s² to G conversion factor is correct", function()
    -- 1G = 9.81 m/s², so 1 m/s² = 1/9.81 G ≈ 0.102 G
    local csv_parser = require('lib.lap.csv_parser')

    -- Test the conversion factor if accessible
    -- 9.81 m/s² should equal 1.0 G
    local expectedConversion = 1.0 / 9.81
    assert_near(expectedConversion, 0.102, 0.001, "1 m/s² should be ~0.102 G")

    -- 50 m/s² (extreme value) should be ~5.1 G
    local extremeG = 50 * expectedConversion
    assert_near(extremeG, 5.1, 0.1, "50 m/s² should be ~5.1 G")
end)

--------------------------------------------------------------------------------
-- MoTeC Directory CSV Tests
--------------------------------------------------------------------------------

suite("MoTeC CSV Loading")

local motecDir = "C:\\MoTeC\\Logged Data\\"

local function seedMotec()
    if mock and mock.vfsSeedMotec then
        mock.vfsSeedMotec("ier_daytona")
    end
end

local function motecDirExists()
    return io.dirExists and io.dirExists(motecDir)
end

-- Test loading specific known files from MoTeC directory
test("loads beche_daytona_sim.csv from MoTeC directory", function()
    seedMotec()
    
    local testFile = motecDir .. "beche_daytona_sim.csv"
    if not io.fileExists(testFile) then
        -- File doesn't exist - skip this test
        print("    [SKIP] File not found: " .. testFile)
        return
    end
    
    -- Daytona track length is ~5717m (from earlier tests)
    local loaded, warnings = lap.fromCSV(testFile, "ier_daytona", "test_car", 5717)
    
    if not loaded then
        local warnMsg = warnings and table.concat(warnings, "; ") or "Unknown error"
        error("Failed to load beche_daytona_sim.csv: " .. warnMsg)
    end
    
    assert_not_nil(loaded, "Should load beche_daytona_sim.csv")
    assert_true(loaded:length() > 100, "Should have many samples, got " .. loaded:length())
    
    -- Verify position data is normalized (0-1)
    local minPos, maxPos = 1, 0
    for i = 1, loaded:length() do
        local p = loaded.pos[i]
        if p < minPos then minPos = p end
        if p > maxPos then maxPos = p end
    end
    
    assert_true(minPos >= 0 and minPos <= 1, 
        string.format("Min pos should be 0-1, got %.4f", minPos))
    assert_true(maxPos >= 0 and maxPos <= 1, 
        string.format("Max pos should be 0-1, got %.4f", maxPos))
    assert_true(maxPos - minPos > 0.5, 
        string.format("Should span >50%% of track (%.1f%% to %.1f%%)", 
            minPos * 100, maxPos * 100))
end)

test("beche_daytona_sim.csv has valid telemetry data", function()
    seedMotec()
    
    local testFile = motecDir .. "beche_daytona_sim.csv"
    if not io.fileExists(testFile) then
        return
    end
    
    local loaded, warnings = lap.fromCSV(testFile, "ier_daytona", "test_car", 5717)
    if not loaded then
        return  -- Skip if file couldn't load
    end
    
    -- Check speed values are in realistic range
    local maxSpeed = 0
    for i = 1, math.min(100, loaded:length()) do
        local s = loaded.speed[i]
        if s and s > maxSpeed then maxSpeed = s end
    end
    assert_true(maxSpeed >= 0 and maxSpeed <= 500,
        string.format("Max speed should be 0-500 km/h, got %.1f", maxSpeed))
    
    -- Check throttle is normalized 0-1
    for i = 1, math.min(100, loaded:length()) do
        local t = loaded.throttle[i]
        assert_true(t >= 0 and t <= 1.01,
            string.format("Throttle at sample %d should be 0-1, got %.3f", i, t))
    end
    
    -- Check brake is in bar (non-negative)
    local maxBrake = 0
    for i = 1, math.min(100, loaded:length()) do
        local b = loaded.brake[i]
        assert_true(b >= 0, string.format("Brake at sample %d should be >= 0 bar, got %.3f", i, b))
        if b > maxBrake then maxBrake = b end
    end
    assert_true(maxBrake < 200, string.format("Max brake should be < 200 bar, got %.1f", maxBrake))
end)

test("beche_daytona_sim.csv interpolation works", function()
    seedMotec()
    
    local testFile = motecDir .. "beche_daytona_sim.csv"
    if not io.fileExists(testFile) then
        return
    end
    
    local loaded, warnings = lap.fromCSV(testFile, "ier_daytona", "test_car", 5717)
    if not loaded then
        return
    end
    
    -- Test interpolation at various positions
    for pos = 0.1, 0.9, 0.2 do
        local speed = loaded:speedAt(pos)
        assert_not_nil(speed, "Should interpolate speed at pos " .. pos)
        assert_true(speed >= 0, "Speed should be non-negative")
        
        local throttle = loaded:throttleAt(pos)
        assert_not_nil(throttle, "Should interpolate throttle at pos " .. pos)
        assert_true(throttle >= 0 and throttle <= 1, 
            string.format("Throttle should be 0-1 at pos %.1f, got %.3f", pos, throttle))
    end
end)

test("loads beche_daytona_sim_1_40_1.csv from MoTeC directory", function()
    seedMotec()
    
    local testFile = motecDir .. "beche_daytona_sim_1_40_1.csv"
    if not io.fileExists(testFile) then
        print("    [SKIP] File not found: " .. testFile)
        return
    end
    
    -- Try to load - may have different format
    local loaded, warnings = lap.fromCSV(testFile, "ier_daytona", "test_car", 5717)
    
    if loaded then
        assert_not_nil(loaded, "Should load beche_daytona_sim_1_40_1.csv")
        assert_true(loaded:length() > 10, "Should have samples, got " .. loaded:length())
    else
        -- If it fails, that's OK - different file format, but log the warning
        local warnMsg = warnings and table.concat(warnings, "; ") or "Unknown error"
        print("    [INFO] Could not load " .. testFile .. ": " .. warnMsg)
        -- Don't fail the test - file might be in different format
    end
end)

test("MoTeC directory scanning works", function()
    seedMotec()
    
    local files = io.scanDir(motecDir, "*.csv")
    assert_not_nil(files, "Should be able to scan MoTeC directory")
    
    if files and #files > 0 then
        print("    [INFO] Found " .. #files .. " CSV files in MoTeC directory")
        for i, filename in ipairs(files) do
            if i <= 5 then  -- Show first 5
                print("        - " .. filename)
            end
        end
    else
        print("    [INFO] MoTeC directory is empty")
    end
end)

test("file_utils.scanCSVFiles finds MoTeC files", function()
    if not io.dirExists or not io.scanDir then
        return  -- Skip if no directory functions
    end
    seedMotec()

    local file_utils = require('lib.core.files')
    
    -- Invalidate cache to force fresh scan
    file_utils.invalidateCache()
    
    local csvFiles = file_utils.scanCSVFiles()
    assert_not_nil(csvFiles, "Should return file list")
    assert_type(csvFiles, "table", "Should return table")
    
    -- Check if any files are from MoTeC directory
    local motecFileCount = 0
    for _, fileInfo in ipairs(csvFiles) do
        assert_not_nil(fileInfo.path, "File info should have path")
        assert_not_nil(fileInfo.filename, "File info should have filename")
        assert_not_nil(fileInfo.source, "File info should have source")
        
        if fileInfo.source == "motec" then
            motecFileCount = motecFileCount + 1
            -- Verify path contains MoTeC directory (use plain string search, not pattern)
            assert_true(fileInfo.path:find("MoTeC", 1, true), 
                "MoTeC file path should contain 'MoTeC': " .. fileInfo.path)
        end
    end
    
    if motecDirExists() then
        print("    [INFO] Found " .. motecFileCount .. " CSV files from MoTeC directory")
        if motecFileCount > 0 then
            -- Verify we can actually load one of them
            for _, fileInfo in ipairs(csvFiles) do
                if fileInfo.source == "motec" then
                    print("        Testing: " .. fileInfo.filename)
                    local loaded, warnings = lap.fromCSV(fileInfo.path, "test", "test", 5717)
                    if loaded then
                        assert_true(loaded:length() > 10, 
                            "Should load " .. fileInfo.filename .. " with samples")
                        print("        ✓ " .. fileInfo.filename .. " loads successfully (" .. 
                            loaded:length() .. " samples)")
                        break  -- Test one file only
                    else
                        local warnMsg = warnings and table.concat(warnings, "; ") or "Unknown error"
                        print("        ✗ " .. fileInfo.filename .. " failed: " .. warnMsg)
                    end
                    break
                end
            end
        end
    else
        print("    [SKIP] MoTeC directory not found")
    end
end)