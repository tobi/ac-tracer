-- test_csv_parser.lua - Tests for csv_parser.lua module

local csv_parser = require('lib.lap.csv_parser')

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
