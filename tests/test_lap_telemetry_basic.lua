-- test_lap_telemetry_basic.lua - Basic integration test for lap_telemetry

local lap = require('lib.lap')

suite("lap_telemetry")

test("draw runs without UI interaction", function()
    local originalCorner = package.loaded['lib.controls.corner_analysis']
    local originalCsvExport = package.loaded['lib.lap.csv_export']
    local originalLapPicker = package.loaded['lib.controls.lap_picker']
    local originalMarkdown = package.loaded['lib.ui.markdown']
    local originalLapTelemetry = package.loaded['lib.controls.lap_telemetry']

    package.loaded['lib.controls.corner_analysis'] = {
        getFrozenCornerNum = function() return 0 end,
        setViewedCorner = function() end,
    }
    package.loaded['lib.lap.csv_export'] = { saveLap = function() return "path" end }
    package.loaded['lib.controls.lap_picker'] = { drawPopover = function() end }
    package.loaded['lib.ui.markdown'] = { copyToClipboard = function() return true, "ok" end }
    package.loaded['lib.controls.lap_telemetry'] = nil

    ui.availableSpace = function() return vec2(800, 600) end
    ui.drawRectFilled = function() end
    ui.drawRect = function() end
    ui.drawLine = function() end
    ui.drawCircleFilled = function() end
    ui.drawCircle = function() end
    ui.drawTriangleFilled = function() end
    ui.drawQuadFilled = function() end
    ui.pathClear = function() end
    ui.pathLineTo = function() end
    ui.pathStroke = function() end
    ui.pushFont = function() end
    ui.popFont = function() end
    ui.pushStyleColor = function() end
    ui.popStyleColor = function() end
    ui.setCursor = function() end
    ui.measureText = function(text) return vec2(#tostring(text) * 7, 10) end
    ui.text = function() end
    ui.textColored = function() end
    ui.sameLine = function() end
    ui.invisibleButton = function() end
    ui.itemHovered = function() return false end
    ui.mousePos = function() return vec2(0, 0) end
    ui.windowPos = function() return vec2(0, 0) end
    ui.mouseClicked = function() return false end
    ui.mouseDown = function() return false end
    ui.mouseWheel = function() return 0 end
    ui.getCursor = function() return vec2(0, 0) end
    ui.setNextItemWidth = function() end
    ui.inputText = function(_, value) return value end
    ui.checkbox = function() return false end
    ui.slider = function() return nil end
    ui.pushItemWidth = function() end
    ui.popItemWidth = function() end
    ui.button = function() return false end
    ui.setTooltip = function() end
    ui.childWindow = function(_, _, fn) if fn then fn() end end

    ui.Font = ui.Font or { Main = 1, Monospace = 2, Title = 3, Small = 4 }
    ui.StyleColor = ui.StyleColor or { Text = 1 }
    ui.MouseButton = ui.MouseButton or { Left = 0, Right = 1 }

    local lap_telemetry = require('lib.controls.lap_telemetry')

    local function buildLap(sessionId, baseSpeed)
        local l = lap.new("test_track", "test_car", sessionId)
        for i = 1, 60 do
            l:addSample({
                gas = 0.6,
                brake = (i % 15 == 0) and 0.5 or 0.0,
                clutch = 0.0,
                steer = 5,
                speedKmh = baseSpeed + i,
                gear = 3 + (i % 2),
                splinePosition = (i - 1) / 59,
                lapTimeMs = i * 100,
                fuel = 50 - i * 0.05,
            })
        end
        l.time = 60000
        l.completed = true
        l.valid = true
        return l
    end

    local currentLap = buildLap("session_a", 100)
    local referenceLap = buildLap("session_b", 105)

    local context = {
        history = { currentLap },
        bestLap = referenceLap,
        bestInSession = currentLap,
        trackCorners = { { number = 1, startPos = 0.1, endPos = 0.2, name = "T1" } },
        brakeScaleBar = 100,
    }

    lap_telemetry.draw(0.016, context)

    package.loaded['lib.controls.corner_analysis'] = originalCorner
    package.loaded['lib.lap.csv_export'] = originalCsvExport
    package.loaded['lib.controls.lap_picker'] = originalLapPicker
    package.loaded['lib.ui.markdown'] = originalMarkdown
    package.loaded['lib.controls.lap_telemetry'] = originalLapTelemetry
end)
