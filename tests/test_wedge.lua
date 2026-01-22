-- test_wedge.lua - Tests for wedge.lua rendering helpers

suite("wedge")

test("draw functions execute without errors", function()
    ui.availableSpace = ui.availableSpace or function() return vec2(200, 100) end
    ui.drawRectFilled = ui.drawRectFilled or function() end
    ui.drawRect = ui.drawRect or function() end
    ui.drawCircleFilled = ui.drawCircleFilled or function() end
    ui.drawCircle = ui.drawCircle or function() end
    ui.pushFont = ui.pushFont or function() end
    ui.popFont = ui.popFont or function() end
    ui.setCursor = ui.setCursor or function() end
    ui.pushStyleColor = ui.pushStyleColor or function() end
    ui.popStyleColor = ui.popStyleColor or function() end
    ui.text = ui.text or function() end
    ui.measureText = ui.measureText or function(text) return vec2(#tostring(text) * 7, 10) end
    ui.pathClear = ui.pathClear or function() end
    ui.pathLineTo = ui.pathLineTo or function() end
    ui.pathFillConvex = ui.pathFillConvex or function() end
    ui.pathStroke = ui.pathStroke or function() end

    ui.Font = ui.Font or { Title = 1, Small = 2 }
    ui.StyleColor = ui.StyleColor or { Text = 1 }

    local wedge = require('lib.ui.wedge')

    wedge.drawGauge(50, 30, 12, 85)
    wedge.drawCompact(10, 10, 30, 16, 60)
    wedge.drawMinimal(10, 10, 20, 40)
end)
