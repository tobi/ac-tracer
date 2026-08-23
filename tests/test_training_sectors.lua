-- Tests for DynamicReturn-style training sector geometry and sequencing.

require('tests.mock_ac')
local training = require('lib.training_sectors')

suite("training sectors")

test("forward distance follows track direction and wraps", function()
    assert_near(training.forwardDistance(0.2, 0.5), 0.3, 0.0001)
    assert_near(training.forwardDistance(0.9, 0.1), 0.2, 0.0001)
end)

test("finish crossing is detected across start finish", function()
    assert_true(training.crossed(0.98, 0.03, 0.01))
    assert_true(not training.crossed(0.98, 0.005, 0.01))
end)

test("traversed corners are selected and sorted by end position", function()
    local corners = {
        { number = 9, name = "Late", startPos = 0.50, endPos = 0.60 },
        { number = 2, name = "Early", startPos = 0.20, endPos = 0.30 },
        { number = 4, name = "Outside", startPos = 0.75, endPos = 0.85 },
    }
    local result = training.traversedCorners(0.10, 0.70, corners)
    assert_equal(#result, 2)
    assert_equal(result[1].name, "Early")
    assert_equal(result[2].name, "Late")
end)

test("traversed corners handle a wrapping sector", function()
    local corners = {
        { number = 1, name = "Before line", endPos = 0.97 },
        { number = 2, name = "After line", endPos = 0.04 },
        { number = 3, name = "Too far", endPos = 0.30 },
    }
    local result = training.traversedCorners(0.90, 0.10, corners)
    assert_equal(#result, 2)
    assert_equal(result[1].name, "Before line")
    assert_equal(result[2].name, "After line")
end)
