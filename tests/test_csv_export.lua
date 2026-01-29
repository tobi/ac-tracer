-- test_csv_export.lua - Validate CSV export round-trip

local lap = require('lib.lap')
local csv_export = require('lib.lap_csv_export')
local file_utils = require('lib.core.files')

suite("CSV Export - Round Trip")

test("exports and re-imports lap data", function()
    if mock and mock.resetVfs then
        mock.resetVfs()
    end
    local l = lap.new("test_track", "test_car", "session")
    local count = 31

    for i = 1, count do
        local t = (i - 1) / lap.SAMPLE_RATE
        local pos = (i - 1) / (count - 1) * 0.99
        l.times[i] = t
        l.pos[i] = pos
        l.throttle[i] = (i - 1) / (count - 1)
        l.brake[i] = i * 2
        l.brake_r[i] = i * 2.5
        l.clutch[i] = (i % 2 == 0) and 0.2 or 0.8
        l.steering[i] = math.clamp(0.45 + (i / count) * 0.1, 0, 1)
        l.speed[i] = 100 + i
        l.gear[i] = math.min(6, math.floor(i / 5))
        l.fuel[i] = 50 - i * 0.1
        l.gforce[i] = vec3(0.02 * i, 0, 0.03 * i)
    end

    l.time = l.times[#l.times] * 1000
    l.completed = true

    local baseDir = __dirname .. "/tracks/"
    local path1, err1 = csv_export.saveLap(l, { directory = baseDir, filename = "test_export_1.csv" })
    assert_not_nil(path1, err1 or "CSV export failed")

    local loaded1 = lap.fromCSV(path1, "test_track", "test_car", 1000)
    assert_not_nil(loaded1, "CSV import failed")
    assert_equal(loaded1:length(), count, "Imported sample count should match")
    assert_near(loaded1.time, l.time, 5, "Lap time should match")

    local idx = 10
    assert_near(loaded1.throttle[idx], l.throttle[idx], 0.01, "Throttle mismatch")
    assert_near(loaded1.brake[idx], l.brake[idx], 0.5, "Brake mismatch")
    assert_near(loaded1.brake_r[idx], l.brake_r[idx], 0.5, "Brake R mismatch")
    assert_near(loaded1.speed[idx], l.speed[idx], 0.5, "Speed mismatch")
    assert_near(loaded1.steering[idx], l.steering[idx], 0.01, "Steering mismatch")
    assert_equal(loaded1.gear[idx], l.gear[idx], "Gear mismatch")
    assert_near(loaded1.gforce[idx].x, l.gforce[idx].x, 0.02, "G lat mismatch")
    assert_near(loaded1.gforce[idx].z, l.gforce[idx].z, 0.02, "G long mismatch")

    local path2, err2 = csv_export.saveLap(loaded1, { directory = baseDir, filename = "test_export_2.csv" })
    assert_not_nil(path2, err2 or "CSV export failed (second pass)")

    local loaded2 = lap.fromCSV(path2, "test_track", "test_car", 1000)
    assert_not_nil(loaded2, "CSV import failed (second pass)")
    assert_equal(loaded2:length(), loaded1:length(), "Round-trip sample count should match")
    assert_near(loaded2.time, loaded1.time, 5, "Round-trip lap time should match")
    assert_near(loaded2.throttle[idx], loaded1.throttle[idx], 0.01, "Round-trip throttle mismatch")
    assert_near(loaded2.brake[idx], loaded1.brake[idx], 0.5, "Round-trip brake mismatch")
    assert_near(loaded2.speed[idx], loaded1.speed[idx], 0.5, "Round-trip speed mismatch")
    assert_near(loaded2.steering[idx], loaded1.steering[idx], 0.01, "Round-trip steering mismatch")

    os.remove(path1)
    os.remove(path2)
end)
