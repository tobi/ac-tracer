-- LÖVE2D configuration for AC Tracer Simulator

function love.conf(t)
    t.identity = "ac-tracer-sim"
    t.version = "11.4"
    t.console = true  -- Enable console for debugging

    t.window.title = "AC Tracer Simulator"
    t.window.width = 1200
    t.window.height = 800
    t.window.resizable = true
    t.window.vsync = 1

    t.modules.audio = false  -- Not needed
    t.modules.physics = false  -- Not needed
    t.modules.joystick = false  -- Not needed
end
