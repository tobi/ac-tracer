-- test_csv_parser.lua - Tests for csv_parser.lua module

local csv_parser = require('lib.lap_csv_parser')
local lap = require('lib.lap')

suite("csv_parser.parseFile")

test("parses a simple Lap Progression CSV", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_lap.csv"

    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pos","Steering Angle","Gear"',
        '"s","","km/h","%","%","deg",""',
        '',
        '0,0.01,100,100,0,0,3',
        '1,0.20,110,100,0,0,3',
        '2,0.50,120,90,10,0,3',
        '3,0.80,130,80,20,5,4',
        '4,0.95,140,70,30,10,4',
        '5,0.02,150,60,40,15,4',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do
        f:write(line .. "\n")
    end
    f:close()

    local result, warnings = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result)
    assert_true(result.completed)
    assert_near(result.time, 5000, 0.1, "Lap time should be ~5s")
    assert_equal(result.sampleRate, 10)
    assert_not_nil(result.csvSource)
    assert_equal(result.csvSource.speed, "speed")

    os.remove(path)
end)

test("preserves chassis world position channels for reference line", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_world_path.csv"
    local lines = {
        '"Sample Rate","2"',
        '"Time","Lap Progression","Ground Speed","Driver Throttle Pos","Brake Pos","Steering Angle","Gear","Chassis World Pos X","Chassis World Pos Y","Chassis World Pos Z"',
        '"s","","km/h","%","%","deg","","m","m","m"',
        '',
        '0,0.01,100,100,0,0,3,10,2,20',
        '1,0.25,110,100,0,0,3,20,2,30',
        '2,0.50,120,100,0,0,4,30,2,40',
        '3,0.75,130,100,0,0,4,40,2,50',
        '4,0.95,140,100,0,0,5,50,2,60',
        '5,0.02,150,100,0,0,5,60,2,70',
    }
    local f = io.open(path, "w")
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()
    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result)
    assert_true(#result.data.world_x > 0)
    assert_true(#result.data.world_z > 0)
    assert_equal(result.csvSource.world_x, "chassis world pos x")
    local imported = lap.fromCSV(path, "test_track", "test_car", 5000)
    assert_not_nil(imported)
    assert_equal(#imported.worldPos, imported:length())
    assert_near(imported.worldPos[1].x, 10, 0.01)
    os.remove(path)
end)

--------------------------------------------------------------------------------
-- Position percentage normalization
--------------------------------------------------------------------------------

suite("csv_parser: position percentage detection")

test("normalizes Lap Progression from 0-100% to 0-1 when unit is '%'", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_pos_pct.csv"

    -- MoTeC-style CSV where Lap Progression is in percentage (0-100) with "%" unit
    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pos","Steering Angle","Gear"',
        '"s","%","km/h","%","%","deg",""',
        '',
        '0,1,100,100,0,0,3',
        '1,20,110,100,0,0,3',
        '2,50,120,90,10,0,3',
        '3,80,130,80,20,5,4',
        '4,95,140,70,30,10,4',
        '5,2,150,60,40,15,4',   -- wraps around: new lap
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")
    assert_true(result.completed, "Lap should be completed")

    -- All positions must be in 0-1 range after normalization
    for i, pos in ipairs(result.data.pos) do
        assert_true(pos >= 0 and pos <= 1,
            string.format("Position[%d] = %.3f should be in 0-1 range (was percentage before normalization)", i, pos))
    end

    -- Mid-lap position should be near 0.5, not 50
    local midIdx = math.floor(#result.data.pos / 2)
    assert_true(result.data.pos[midIdx] < 1.0,
        string.format("Mid-lap position = %.3f should be < 1.0 (not raw percentage)", result.data.pos[midIdx]))

    os.remove(path)
end)

test("normalizes Lap Progression from 0-100 to 0-1 via heuristic (no unit row)", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_pos_pct_heuristic.csv"

    -- CSV without unit row where values are clearly > 1 (percentage)
    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pos","Steering Angle","Gear"',
        '',
        '0,1,100,0.9,0,0,3',
        '1,20,110,1.0,0,0,3',
        '2,50,120,0.8,10,0,3',
        '3,80,130,0.7,20,5,4',
        '4,95,140,0.6,30,10,4',
        '5,2,150,0.5,40,15,4',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")

    for i, pos in ipairs(result.data.pos) do
        assert_true(pos >= 0 and pos <= 1,
            string.format("Position[%d] = %.3f should be in 0-1 range (heuristic detection)", i, pos))
    end

    os.remove(path)
end)

--------------------------------------------------------------------------------
-- Throttle column priority
--------------------------------------------------------------------------------

suite("csv_parser: throttle column selection")

test("prefers 'Driver Throttle Pos' over 'Throttle Pos' when both present", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_throttle_priority.csv"

    -- CSV with both throttle columns - "Throttle Pos" has high values even during braking
    -- (ECU-controlled plate stays open for TC), "Driver Throttle Pos" shows actual pedal
    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Throttle Pos","Driver Throttle Pos","Brake Pos","Steering Angle","Gear"',
        '"s","","km/h","%","%","%","deg",""',
        '',
        -- Full throttle zone: both agree
        '0,0.01,200,95,95,0,0,4',
        '1,0.20,210,98,98,0,0,4',
        -- Braking zone: ECU throttle stays high (TC), driver pedal is off
        '2,0.50,180,87,0,80,15,3',
        '3,0.65,120,90,0,95,25,2',
        '4,0.80,100,85,5,60,20,2',
        -- Back on throttle
        '5,0.95,130,92,80,0,5,3',
        '6,0.02,160,95,95,0,0,4',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")

    -- Verify the correct column was selected
    assert_equal(result.csvSource.throttle, "driver throttle pos",
        "Should select 'Driver Throttle Pos' over 'Throttle Pos'")

    -- During heavy braking (samples near pos 0.50-0.65), throttle should be near zero
    -- If the parser incorrectly picked "Throttle Pos", these would be ~0.87-0.90
    for i, pos in ipairs(result.data.pos) do
        if pos > 0.45 and pos < 0.70 then
            local thr = result.data.throttle[i]
            assert_true(thr < 0.10,
                string.format("Throttle at pos %.3f = %.3f should be near zero during braking (driver pedal off)", pos, thr))
        end
    end

    os.remove(path)
end)

--------------------------------------------------------------------------------
-- Throttle percentage normalization
--------------------------------------------------------------------------------

suite("csv_parser: throttle normalization")

test("normalizes throttle from 0-100% to 0-1 when unit is '%'", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_throttle_pct.csv"

    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pos","Steering Angle","Gear"',
        '"s","","km/h","%","%","deg",""',
        '',
        '0,0.01,100,100,0,0,3',
        '1,0.20,110,95,0,0,3',
        '2,0.50,120,0,80,0,3',
        '3,0.80,130,50,0,5,4',
        '4,0.95,140,100,0,10,4',
        '5,0.02,150,100,0,15,4',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")

    -- All throttle values must be in 0-1 range
    for i, thr in ipairs(result.data.throttle) do
        assert_true(thr >= 0 and thr <= 1,
            string.format("Throttle[%d] = %.3f should be in 0-1 range", i, thr))
    end

    -- 100% input should become 1.0
    assert_near(result.data.throttle[1], 1.0, 0.01,
        "100% throttle should normalize to 1.0")

    -- 0% input should become 0.0
    local found_zero = false
    for _, thr in ipairs(result.data.throttle) do
        if thr < 0.01 then found_zero = true break end
    end
    assert_true(found_zero, "0% throttle should normalize to ~0.0")

    os.remove(path)
end)

test("does NOT clamp throttle values near 1% to 100% (old heuristic bug)", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_throttle_clamp_bug.csv"

    -- Regression test: old code had `if throttle > 1 and throttle <= 2 then throttle = 1`
    -- This turned 1.03% (nearly zero pedal) into 1.0 (100% throttle)
    -- Use many samples in the braking zone to ensure resampled values stay low
    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pos","Steering Angle","Gear"',
        '"s","","km/h","%","%","deg",""',
        '',
        '0,0.01,200,100,0,0,4',
        '1,0.15,210,98,0,0,4',
        '2,0.25,200,1.03,80,10,3',
        '3,0.35,180,1.03,90,15,3',
        '4,0.45,150,0.8,95,20,3',
        '5,0.55,120,1.5,90,25,2',
        '6,0.65,110,1.03,80,25,2',
        '7,0.75,120,1.5,50,15,2',
        '8,0.85,140,60,0,5,3',
        '9,0.95,180,100,0,0,4',
        '10,0.02,200,100,0,0,4',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")

    -- Values of 1.03% and 1.5% should be near zero, NOT clamped to 1.0
    for i, pos in ipairs(result.data.pos) do
        if pos > 0.30 and pos < 0.75 then
            local thr = result.data.throttle[i]
            assert_true(thr < 0.10,
                string.format("Throttle at pos %.3f = %.3f should be near zero (1.03%% input), not clamped to 1.0", pos, thr))
        end
    end

    os.remove(path)
end)

--------------------------------------------------------------------------------
-- Integration: throttle/brake coherence
--------------------------------------------------------------------------------

suite("csv_parser: throttle/brake coherence")

test("throttle is near-zero when brake is high (no impossible overlap)", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_coherence.csv"

    -- Simulate a lap with clear braking zones where throttle should be off
    -- Use plenty of samples to ensure proper lap detection
    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pressure F","Steering Angle","Gear"',
        '"s","","km/h","%","psi","deg",""',
        '',
        -- Full throttle straight
        '0,0.01,250,100,0,0,5',
        '0.5,0.05,255,100,0,0,5',
        '1,0.10,260,100,0,0,5',
        '1.5,0.15,265,100,0,0,5',
        '2,0.20,270,100,0,0,5',
        '2.5,0.25,265,100,0,0,5',
        -- Hard braking zone (driver fully off throttle, heavy brake)
        '3,0.30,250,0,800,0,4',
        '3.5,0.33,220,0,1000,5,3',
        '4,0.35,200,0,1000,10,3',
        '4.5,0.38,175,0,1100,15,3',
        '5,0.40,150,0,1200,20,2',
        '5.5,0.43,135,0,1000,22,2',
        '6,0.45,120,0,900,25,2',
        -- Trail braking into corner
        '6.5,0.48,115,2,600,28,2',
        '7,0.50,110,5,400,30,2',
        '7.5,0.55,112,30,100,25,2',
        -- Accelerating out
        '8,0.60,120,60,0,15,3',
        '8.5,0.65,140,80,0,10,3',
        '9,0.70,160,100,0,5,3',
        '9.5,0.75,180,100,0,2,4',
        '10,0.80,200,100,0,0,4',
        '10.5,0.85,220,100,0,0,5',
        '11,0.90,240,100,0,0,5',
        '11.5,0.95,250,100,0,0,5',
        '12,0.02,260,100,0,0,5',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")
    assert_true(result.completed, "Lap should be completed")

    -- In heavy braking zones (brake > 50 bar), throttle must be low
    for i = 1, #result.data.pos do
        local brk = result.data.brake[i]
        local thr = result.data.throttle[i]
        if brk > 50 then
            assert_true(thr < 0.15,
                string.format("At pos %.3f: brake=%.1f bar but throttle=%.3f - should be near zero during heavy braking",
                    result.data.pos[i], brk, thr))
        end
    end

    -- On straights (brake = 0), throttle should be high
    local found_full_throttle = false
    for i = 1, #result.data.pos do
        if result.data.brake[i] < 1 and result.data.throttle[i] > 0.9 then
            found_full_throttle = true
            break
        end
    end
    assert_true(found_full_throttle, "Should have full throttle on straights")

    os.remove(path)
end)

--------------------------------------------------------------------------------
-- Brake pressure unit conversion
--------------------------------------------------------------------------------

suite("csv_parser: brake pressure conversion")

test("converts brake pressure from PSI to bar", function()
    io.createDir("tests/tmp")
    local path = "tests/tmp/test_brake_psi.csv"

    local lines = {
        '"Sample Rate","10"',
        '"Time","Lap Progression","Speed","Driver Throttle Pos","Brake Pressure F","Steering Angle","Gear"',
        '"s","","km/h","%","psi","deg",""',
        '',
        '0,0.01,200,100,0,0,4',
        '1,0.30,250,100,0,0,5',
        '2,0.50,180,0,1000,15,3',   -- 1000 PSI = ~68.9 bar
        '3,0.70,120,0,1450,25,2',   -- 1450 PSI = ~100 bar
        '4,0.90,160,80,0,5,3',
        '5,0.02,200,100,0,0,4',
    }

    local f = io.open(path, "w")
    assert_not_nil(f)
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()

    local result = csv_parser.parseFile(path, nil, 10, nil)
    assert_not_nil(result, "Should parse successfully")

    -- Find max brake value - should be roughly 1450 * 0.0689476 ≈ 100 bar
    local maxBrake = 0
    for _, b in ipairs(result.data.brake) do
        if b > maxBrake then maxBrake = b end
    end

    assert_near(maxBrake, 1450 * 0.0689476, 5,
        string.format("Max brake should be ~%.1f bar (1450 PSI converted), got %.1f", 1450 * 0.0689476, maxBrake))

    -- Brake should never be in raw PSI range (hundreds/thousands)
    for i, b in ipairs(result.data.brake) do
        assert_true(b < 200,
            string.format("Brake[%d] = %.1f looks like unconverted PSI (should be in bar)", i, b))
    end

    os.remove(path)
end)
