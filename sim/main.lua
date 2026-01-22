--[[
AC Tracer Simulator - ImGui Version
Runs ac-tracer outside of Assetto Corsa using LuaJIT-ImGui

Usage with dinau/luajitImGui (Windows):
  luajitImGui\luajitw.exe main.lua

Usage with sonoro1234/LuaJIT-ImGui:
  luajit main.lua
]]

-- Detect which ImGui binding is available
local imgui, sdl, gl

local function tryRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

-- Try different ImGui bindings
imgui = tryRequire("imgui") or tryRequire("imgui.imgui")
sdl = tryRequire("sdl2_ffi") or tryRequire("sdl")
gl = tryRequire("opengl") or tryRequire("gl")

if not imgui then
    print("ERROR: ImGui bindings not found!")
    print("Please install LuaJIT-ImGui or luajitImGui")
    print("")
    print("Options:")
    print("1. Download luajitImGui from: https://github.com/dinau/luajitImGui/releases")
    print("2. Build LuaJIT-ImGui from: https://github.com/sonoro1234/LuaJIT-ImGui")
    os.exit(1)
end

if not sdl then
    print("ERROR: SDL2 bindings not found!")
    print("Make sure LuaJIT-SDL2 is installed alongside LuaJIT-ImGui")
    os.exit(1)
end

--------------------------------------------------------------------------------
-- Setup paths for ac-tracer modules
--------------------------------------------------------------------------------

local simDir = debug.getinfo(1, "S").source:match("@(.*/)")
if not simDir then simDir = "./" end
local parentDir = simDir:match("(.*/)[^/]+/$") or "../"

-- Add parent directory to package path
package.path = parentDir .. "?.lua;" .. parentDir .. "?/init.lua;" .. package.path

--------------------------------------------------------------------------------
-- Load CSP compatibility shim BEFORE ac-tracer modules
--------------------------------------------------------------------------------

-- Create global CSP-like APIs
dofile(simDir .. "csp_shim.lua")

--------------------------------------------------------------------------------
-- Playback State
--------------------------------------------------------------------------------

local playback = {
    lap = nil,              -- Loaded lap data
    position = 0,           -- Current position (0-1)
    playing = false,        -- Is playing
    speed = 1.0,            -- Playback speed
    time = 0,               -- Current time in seconds
    lapTime = 0,            -- Total lap time in seconds
}

-- Export for csp_shim
_G._playback = playback

--------------------------------------------------------------------------------
-- Load ac-tracer modules (after shim is set up)
--------------------------------------------------------------------------------

local state, lap, settings

local function loadAcTracerModules()
    local ok, err

    ok, lap = pcall(require, 'lib.lap')
    if not ok then
        print("Warning: Could not load lap module: " .. tostring(lap))
        lap = nil
    end

    ok, state = pcall(require, 'lib.state')
    if not ok then
        print("Warning: Could not load state module: " .. tostring(state))
        state = nil
    end

    ok, settings = pcall(require, 'lib.settings')
    if not ok then
        print("Warning: Could not load settings module: " .. tostring(settings))
        settings = nil
    end
end

--------------------------------------------------------------------------------
-- Playback Functions
--------------------------------------------------------------------------------

local function loadLap(filepath)
    if not lap then return false end

    local loadedLap = lap.fromCSV(filepath)
    if loadedLap and loadedLap:length() > 10 then
        playback.lap = loadedLap
        playback.position = 0
        playback.time = 0
        playback.lapTime = loadedLap.time / 1000  -- Convert ms to seconds
        playback.playing = false

        -- Update state if available
        if state then
            state.bestLap = loadedLap
            state.currentLap = lap.new(loadedLap.track, loadedLap.car)
        end

        -- Export for csp_shim
        _G._playbackLap = loadedLap

        print(string.format("Loaded lap: %s (%d samples, %.2fs)",
            filepath, loadedLap:length(), playback.lapTime))
        return true
    end

    print("Failed to load lap: " .. filepath)
    return false
end

local function updatePlayback(dt)
    if not playback.lap or not playback.playing then return end

    -- Advance time
    playback.time = playback.time + (dt * playback.speed)

    -- Clamp to lap duration
    if playback.time >= playback.lapTime then
        playback.time = 0  -- Loop
    end

    -- Find position at current time
    local lapData = playback.lap
    local times = lapData.times
    for i = 1, #times - 1 do
        if times[i + 1] > playback.time then
            local frac = (playback.time - times[i]) / (times[i + 1] - times[i])
            playback.position = lapData.pos[i] + (lapData.pos[i + 1] - lapData.pos[i]) * frac
            break
        end
    end

    -- Update global for csp_shim
    _G._mockCarPosition = playback.position
end

local function seekToPosition(pos)
    playback.position = math.max(0, math.min(1, pos))
    if playback.lap then
        playback.time = playback.lap:timeAt(playback.position)
    end
    _G._mockCarPosition = playback.position
end

local function seekByTime(deltaSeconds)
    playback.time = math.max(0, playback.time + deltaSeconds)
    if playback.lapTime > 0 then
        playback.time = math.min(playback.time, playback.lapTime)
        seekToPosition(playback.time / playback.lapTime)
    end
end

--------------------------------------------------------------------------------
-- SDL + ImGui Setup
--------------------------------------------------------------------------------

local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 800
local WINDOW_TITLE = "AC Tracer Simulator"

local window, glContext, impl
local running = true
local showHelp = false

local function initSDL()
    -- Initialize SDL
    if sdl.init(sdl.INIT_VIDEO + sdl.INIT_TIMER) ~= 0 then
        error("Failed to initialize SDL: " .. ffi.string(sdl.getError()))
    end

    -- OpenGL attributes
    sdl.gL_SetAttribute(sdl.GL_DOUBLEBUFFER, 1)
    sdl.gL_SetAttribute(sdl.GL_DEPTH_SIZE, 24)
    sdl.gL_SetAttribute(sdl.GL_STENCIL_SIZE, 8)
    sdl.gL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 2)
    sdl.gL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 2)

    -- Create window
    window = sdl.createWindow(
        WINDOW_TITLE,
        sdl.WINDOWPOS_CENTERED,
        sdl.WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        sdl.WINDOW_OPENGL + sdl.WINDOW_RESIZABLE + sdl.WINDOW_ALLOW_HIGHDPI
    )

    if window == nil then
        error("Failed to create window: " .. ffi.string(sdl.getError()))
    end

    -- Create OpenGL context
    glContext = sdl.gL_CreateContext(window)
    sdl.gL_MakeCurrent(window, glContext)
    sdl.gL_SetSwapInterval(1)  -- VSync

    -- Initialize ImGui
    if imgui.Imgui_Impl_SDL_opengl2 then
        impl = imgui.Imgui_Impl_SDL_opengl2()
        impl:Init(window, glContext)
    else
        -- Alternative initialization for different ImGui bindings
        imgui.CreateContext()
        -- Impl-specific init would go here
    end

    -- Style
    local style = imgui.GetStyle()
    style.WindowRounding = 4
    style.FrameRounding = 2

    print("SDL + ImGui initialized successfully")
end

local function processEvents()
    local event = ffi.new("SDL_Event")
    while sdl.pollEvent(event) ~= 0 do
        if impl then impl:ProcessEvent(event) end

        if event.type == sdl.QUIT then
            running = false
        elseif event.type == sdl.KEYDOWN then
            local key = event.key.keysym.sym

            if key == sdl.K_SPACE then
                playback.playing = not playback.playing
            elseif key == sdl.K_h then
                showHelp = not showHelp
            elseif key == sdl.K_r then
                playback.position = 0
                playback.time = 0
            elseif key == sdl.K_LEFT then
                seekByTime(-1)
            elseif key == sdl.K_RIGHT then
                seekByTime(1)
            elseif key == sdl.K_COMMA then
                seekByTime(-1/60)
            elseif key == sdl.K_PERIOD then
                seekByTime(1/60)
            elseif key == sdl.K_1 then
                playback.speed = 0.25
            elseif key == sdl.K_2 then
                playback.speed = 0.5
            elseif key == sdl.K_3 then
                playback.speed = 1.0
            elseif key == sdl.K_4 then
                playback.speed = 2.0
            end
        elseif event.type == sdl.DROPFILE then
            local filepath = ffi.string(event.drop.file)
            if filepath:match("%.csv$") then
                loadLap(filepath)
            end
            sdl.free(event.drop.file)
        end
    end
end

local function render()
    local io = imgui.GetIO()

    -- Clear
    gl.glViewport(0, 0, io.DisplaySize.x, io.DisplaySize.y)
    gl.glClearColor(0.1, 0.1, 0.1, 1.0)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)

    -- Start ImGui frame
    if impl then impl:NewFrame() end
    imgui.NewFrame()

    -- Draw UI
    drawMainUI()

    -- Render ImGui
    imgui.Render()
    if impl then impl:RenderDrawData(imgui.GetDrawData()) end

    -- Swap
    sdl.gL_SwapWindow(window)
end

--------------------------------------------------------------------------------
-- Main UI Drawing
--------------------------------------------------------------------------------

function drawMainUI()
    local io = imgui.GetIO()
    local displayW, displayH = io.DisplaySize.x, io.DisplaySize.y

    -- Main menu bar
    if imgui.BeginMainMenuBar() then
        if imgui.BeginMenu("File") then
            if imgui.MenuItem("Load Lap...", "L") then
                -- File dialog would go here
                print("Drop a CSV file onto the window to load it")
            end
            imgui.Separator()
            if imgui.MenuItem("Quit", "Esc") then
                running = false
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Playback") then
            if imgui.MenuItem(playback.playing and "Pause" or "Play", "Space") then
                playback.playing = not playback.playing
            end
            if imgui.MenuItem("Reset", "R") then
                playback.position = 0
                playback.time = 0
            end
            imgui.Separator()
            if imgui.MenuItem("0.25x", "1", playback.speed == 0.25) then playback.speed = 0.25 end
            if imgui.MenuItem("0.5x", "2", playback.speed == 0.5) then playback.speed = 0.5 end
            if imgui.MenuItem("1x", "3", playback.speed == 1.0) then playback.speed = 1.0 end
            if imgui.MenuItem("2x", "4", playback.speed == 2.0) then playback.speed = 2.0 end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("Help") then
            if imgui.MenuItem("Show Help", "H") then
                showHelp = true
            end
            imgui.EndMenu()
        end
        imgui.EndMainMenuBar()
    end

    -- Main trace window
    imgui.SetNextWindowPos(imgui.ImVec2(10, 30), imgui.Cond_FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(600, 250), imgui.Cond_FirstUseEver)
    if imgui.Begin("Main Traces") then
        drawTraceWindow()
    end
    imgui.End()

    -- Delta window
    imgui.SetNextWindowPos(imgui.ImVec2(620, 30), imgui.Cond_FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(200, 100), imgui.Cond_FirstUseEver)
    if imgui.Begin("Delta / Position") then
        drawDeltaWindow()
    end
    imgui.End()

    -- Timeline window (bottom)
    imgui.SetNextWindowPos(imgui.ImVec2(10, displayH - 100), imgui.Cond_Always)
    imgui.SetNextWindowSize(imgui.ImVec2(displayW - 20, 90), imgui.Cond_Always)
    if imgui.Begin("Timeline", nil, imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize) then
        drawTimeline()
    end
    imgui.End()

    -- Help window
    if showHelp then
        imgui.SetNextWindowPos(imgui.ImVec2(displayW/2 - 200, displayH/2 - 150), imgui.Cond_FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond_FirstUseEver)
        if imgui.Begin("Help", showHelp_ptr) then
            imgui.Text("AC Tracer Simulator")
            imgui.Separator()
            imgui.Text("Controls:")
            imgui.BulletText("Space - Play/Pause")
            imgui.BulletText("Left/Right - Seek +/- 1 second")
            imgui.BulletText(",/. - Previous/Next frame")
            imgui.BulletText("1/2/3/4 - Speed (0.25x/0.5x/1x/2x)")
            imgui.BulletText("R - Reset to start")
            imgui.BulletText("H - Toggle help")
            imgui.Separator()
            imgui.Text("Drop a CSV file onto the window to load it.")
            imgui.Separator()
            if imgui.Button("Close") then
                showHelp = false
            end
        end
        imgui.End()
    end
end

function drawTraceWindow()
    if not playback.lap then
        imgui.Text("No lap loaded")
        imgui.Text("Drop a CSV file onto the window to load it")
        return
    end

    local lapData = playback.lap
    local pos = playback.position
    local contentSize = imgui.GetContentRegionAvail()
    local w, h = contentSize.x, contentSize.y

    -- Get values at current position
    local throttle = lapData:throttleAt(pos)
    local brake = lapData:brakeAt(pos) / 100  -- Normalize
    local speed = lapData:speedAt(pos)
    local gear = lapData:gearAt(pos)
    local steering = lapData:steeringAt(pos)

    -- Draw using ImGui
    local draw_list = imgui.GetWindowDrawList()
    local winPos = imgui.GetWindowPos()
    local cursorPos = imgui.GetCursorScreenPos()

    -- Graph area
    local graphW = w * 0.7
    local graphH = h - 40
    local graphX = cursorPos.x
    local graphY = cursorPos.y

    -- Background
    draw_list:AddRectFilled(
        imgui.ImVec2(graphX, graphY),
        imgui.ImVec2(graphX + graphW, graphY + graphH),
        imgui.GetColorU32(0.05, 0.05, 0.05, 1)
    )

    -- Draw traces (simplified - just current values as bars for now)
    local barW = 40
    local barX = graphX + graphW + 20

    -- Throttle bar
    draw_list:AddRectFilled(
        imgui.ImVec2(barX, graphY + graphH * (1 - throttle)),
        imgui.ImVec2(barX + barW, graphY + graphH),
        imgui.GetColorU32(0.2, 0.8, 0.2, 1)
    )
    draw_list:AddRect(
        imgui.ImVec2(barX, graphY),
        imgui.ImVec2(barX + barW, graphY + graphH),
        imgui.GetColorU32(0.4, 0.4, 0.4, 1)
    )

    -- Brake bar
    barX = barX + barW + 10
    draw_list:AddRectFilled(
        imgui.ImVec2(barX, graphY + graphH * (1 - brake)),
        imgui.ImVec2(barX + barW, graphY + graphH),
        imgui.GetColorU32(0.9, 0.2, 0.2, 1)
    )
    draw_list:AddRect(
        imgui.ImVec2(barX, graphY),
        imgui.ImVec2(barX + barW, graphY + graphH),
        imgui.GetColorU32(0.4, 0.4, 0.4, 1)
    )

    -- Text info
    imgui.SetCursorPosY(h - 30)
    imgui.Text(string.format("Speed: %d km/h  |  Gear: %d  |  Throttle: %.0f%%  |  Brake: %.0f%%",
        math.floor(speed), gear, throttle * 100, brake * 100))
end

function drawDeltaWindow()
    if not playback.lap then
        imgui.Text("--")
        return
    end

    imgui.Text(string.format("Position: %.1f%%", playback.position * 100))
    imgui.Text(string.format("Time: %.2fs / %.2fs", playback.time, playback.lapTime))
    imgui.Text(string.format("Speed: %.1fx", playback.speed))
    imgui.Text(playback.playing and "Playing" or "Paused")
end

function drawTimeline()
    local contentSize = imgui.GetContentRegionAvail()
    local w, h = contentSize.x, contentSize.y

    -- Playback status
    local statusText = playback.playing and "Playing" or "Paused"
    local speedText = string.format("%.2fx", playback.speed)
    imgui.Text(statusText .. "  |  " .. speedText)

    if not playback.lap then
        imgui.Text("No lap loaded - drop a CSV file to load")
        return
    end

    -- Time display
    local timeText = string.format("%.2f / %.2f", playback.time, playback.lapTime)
    imgui.SameLine(w - 100)
    imgui.Text(timeText)

    -- Progress slider
    imgui.PushItemWidth(w)
    local pos_arr = ffi.new("float[1]", playback.position)
    if imgui.SliderFloat("##timeline", pos_arr, 0, 1, "%.3f") then
        seekToPosition(pos_arr[0])
    end
    imgui.PopItemWidth()

    -- Play/Pause button
    if imgui.Button(playback.playing and "Pause" or "Play", imgui.ImVec2(60, 0)) then
        playback.playing = not playback.playing
    end
    imgui.SameLine()
    if imgui.Button("Reset", imgui.ImVec2(60, 0)) then
        playback.position = 0
        playback.time = 0
    end
    imgui.SameLine()
    imgui.Text("|")
    imgui.SameLine()
    if imgui.Button("0.25x", imgui.ImVec2(50, 0)) then playback.speed = 0.25 end
    imgui.SameLine()
    if imgui.Button("0.5x", imgui.ImVec2(50, 0)) then playback.speed = 0.5 end
    imgui.SameLine()
    if imgui.Button("1x", imgui.ImVec2(40, 0)) then playback.speed = 1.0 end
    imgui.SameLine()
    if imgui.Button("2x", imgui.ImVec2(40, 0)) then playback.speed = 2.0 end
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

local function cleanup()
    if impl then impl:Destroy() end
    if glContext then sdl.gL_DeleteContext(glContext) end
    if window then sdl.destroyWindow(window) end
    sdl.quit()
end

--------------------------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------------------------

local function main()
    print("AC Tracer Simulator starting...")

    -- Initialize
    initSDL()
    loadAcTracerModules()

    -- Try to load a lap from tracks folder
    local tracksDir = parentDir .. "tracks/"
    -- This would need directory scanning, which varies by binding

    print("Ready. Press H for help, drop CSV to load.")

    -- Main loop
    local lastTime = sdl.getTicks() / 1000.0
    while running do
        local currentTime = sdl.getTicks() / 1000.0
        local dt = currentTime - lastTime
        lastTime = currentTime

        processEvents()
        updatePlayback(dt)
        render()
    end

    cleanup()
    print("Goodbye!")
end

-- Run with error handling
local ok, err = xpcall(main, debug.traceback)
if not ok then
    print("Error: " .. err)
    cleanup()
    os.exit(1)
end
