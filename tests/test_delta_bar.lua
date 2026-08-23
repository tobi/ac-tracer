-- test_delta_bar.lua - Tests for delta_bar.lua module

local mock = require('tests.mock_ac')

suite("delta_bar")

test("draw and reset run without errors", function()
    local originalCorner = package.loaded['lib.windows.corner_analysis']
    local originalState = package.loaded['lib.state']
    package.loaded['lib.windows.corner_analysis'] = { getRecentCornerScores = function() return {} end }
    package.loaded['lib.state'] = { getLapTimeOffset = function() return 0 end }
    package.loaded['lib.windows.delta_bar'] = nil

    ui.availableSpace = ui.availableSpace or function() return vec2(200, 80) end
    ui.drawRectFilled = ui.drawRectFilled or function() end
    ui.drawRect = ui.drawRect or function() end
    ui.drawLine = ui.drawLine or function() end
    ui.pushFont = ui.pushFont or function() end
    ui.popFont = ui.popFont or function() end
    ui.setCursor = ui.setCursor or function() end
    ui.pushStyleColor = ui.pushStyleColor or function() end
    ui.popStyleColor = ui.popStyleColor or function() end
    ui.text = ui.text or function() end
    ui.measureText = ui.measureText or function(text) return vec2(#tostring(text) * 7, 10) end

    ui.Font = ui.Font or { Title = 1, Monospace = 2, Small = 3 }
    ui.StyleColor = ui.StyleColor or { Text = 1 }

    local delta_bar = require('lib.windows.delta_bar')

    local refLap = {
        length = function() return 20 end,
        getTimeAtPos = function(_, pos) return pos * 10 end
    }

    mock.setCar({ lapCount = 1, lapTimeMs = 5000, previousLapTimeMs = 95000 })
    delta_bar.draw(0.5, {}, refLap, 0.3, { { number = 1 } })
    delta_bar.reset()

    package.loaded['lib.windows.corner_analysis'] = originalCorner
    package.loaded['lib.state'] = originalState
end)

test("corner display order follows end position rather than CSV order", function()
    local delta_bar = require('lib.windows.delta_bar')
    local ordered = delta_bar.getCornerDisplayOrder({
        { number = 1, endPos = 0.82 },
        { number = 7, endPos = 0.21 },
        { number = 3, endPos = 0.55 },
        { number = 9 },
    })
    assert_equal(#ordered, 3)
    assert_equal(ordered[1].number, 7)
    assert_equal(ordered[2].number, 3)
    assert_equal(ordered[3].number, 1)
end)
