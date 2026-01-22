# AC Tracer Simulator

A desktop simulation layer that runs ac-tracer outside of Assetto Corsa using Dear ImGui - the same UI library that CSP uses internally.

## Why ImGui?

CSP's `ui.*` API is literally **Dear ImGui** wrapped for Lua. Using actual ImGui bindings gives us near-perfect API compatibility:

| CSP API | ImGui API | Notes |
|---------|-----------|-------|
| `ui.text()` | `imgui.Text()` | Direct match |
| `ui.button()` | `imgui.Button()` | Direct match |
| `ui.drawRectFilled()` | `ImDrawList:AddRectFilled()` | Draw list API |
| `ui.pathLineTo()` | `ImDrawList:PathLineTo()` | Path drawing |
| `ui.slider()` | `imgui.SliderFloat()` | Direct match |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ac-tracer code (unchanged)               │
│   ac-tracer.lua, state.lua, lap.lua, corner_analysis.lua   │
└─────────────────────────────────────────────────────────────┘
                              │
                    uses require()
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   csp_shim.lua                              │
│   Thin wrapper: ui.text() → imgui.Text(), etc.             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   LuaJIT-ImGui                              │
│   SDL2 + OpenGL + Dear ImGui via LuaJIT FFI                │
└─────────────────────────────────────────────────────────────┘
```

## Setup Options

### Option 1: luajitImGui (Windows - Easiest)

Pre-built binaries for Windows. No compilation needed.

1. Download from [dinau/luajitImGui releases](https://github.com/dinau/luajitImGui/releases)
   - Get `luajitImGui-1.92.1.0.zip` (or latest)

2. Extract to `ac-tracer/sim/luajitImGui/`

3. Run the simulator:
   ```cmd
   cd ac-tracer\sim
   luajitImGui\luajitw.exe main.lua
   ```

### Option 2: LuaJIT-ImGui (Cross-platform - Build Required)

Full cross-platform support but requires building from source.

1. Clone the repository:
   ```bash
   git clone --recurse-submodules https://github.com/sonoro1234/LuaJIT-ImGui.git
   ```

2. Build following their instructions (requires CMake, C++ compiler)

3. Also need [LuaJIT-SDL2](https://github.com/sonoro1234/LuaJIT-SDL2)

4. Run:
   ```bash
   luajit sim/main.lua
   ```

### Option 3: LÖVE2D Fallback (Cross-platform - Easy)

If you can't get ImGui working, there's a LÖVE2D fallback that provides approximate rendering. Not 100% compatible but useful for basic testing.

1. Install LÖVE2D from https://love2d.org

2. Run:
   ```bash
   cd ac-tracer
   love sim/
   ```

## Files

```
sim/
├── main.lua           # Entry point for ImGui version
├── main_love.lua      # Entry point for LÖVE2D fallback
├── csp_shim.lua       # CSP API → ImGui translation layer
├── playback.lua       # Lap playback and timeline
├── conf.lua           # LÖVE2D configuration (for fallback)
└── README.md          # This file
```

## Features

- **Lap Playback**: Load CSV laps and play back in realtime
- **Timeline Scrubbing**: Click and drag to scrub through lap data
- **Speed Control**: 0.25x, 0.5x, 1x, 2x playback speed
- **All Windows**: Main traces, corner analysis, telemetry
- **Controls work unchanged**: ac-tracer code runs without modification

## Controls

| Key | Action |
|-----|--------|
| Space | Play/Pause |
| Left/Right | Seek ±1 second |
| ,/. | Previous/Next frame |
| 1-4 | Speed (0.25x/0.5x/1x/2x) |
| R | Reset to start |
| L | Load lap file |
| Tab | Cycle windows |
| H | Help |

## CSP API Compatibility

The `csp_shim.lua` file provides these CSP APIs using ImGui:

### Fully Implemented

- **Drawing**: `ui.drawRectFilled`, `ui.drawRect`, `ui.drawLine`, `ui.drawCircle`, `ui.drawCircleFilled`, `ui.drawTriangleFilled`
- **Path**: `ui.pathClear`, `ui.pathLineTo`, `ui.pathArcTo`, `ui.pathStroke`, `ui.pathFillConvex`
- **Text**: `ui.text`, `ui.textColored`, `ui.textAligned`, `ui.dwriteDrawTextClipped`
- **Layout**: `ui.availableSpace`, `ui.setCursor`, `ui.getCursor`, `ui.sameLine`
- **Controls**: `ui.button`, `ui.slider`, `ui.checkbox`, `ui.inputText`
- **Input**: `ui.mousePos`, `ui.mouseClicked`, `ui.mouseDown`, `ui.rectHovered`
- **Styling**: `ui.pushFont`, `ui.popFont`, `ui.pushStyleColor`, `ui.popStyleColor`

### Stubbed (No-op)

- **3D Rendering**: `render.debugLine` (no 3D viewport)
- **Audio**: `ac.AudioEvent` (no audio playback)
- **Checkpoint**: `ac.saveCarStateAsync`, `ac.loadCarState` (no game state)

### Game State

Car and sim state are synthesized from the loaded lap:

```lua
-- In playback.lua
ac.getCar = function(index)
    local pos = playback.position
    return {
        speedKmh = lap:speedAt(pos),
        splinePosition = pos,
        gas = lap:throttleAt(pos),
        brake = lap:brakeAt(pos) / 100,
        gear = lap:gearAt(pos),
        -- ...etc
    }
end
```

## Development

### Adding New CSP APIs

Edit `csp_shim.lua` to add mappings:

```lua
-- Example: Add ui.newFunction()
ui.newFunction = function(arg1, arg2)
    -- Map to ImGui equivalent
    return imgui.SomeFunction(arg1, arg2)
end
```

### ImGui Draw List API

CSP's drawing functions map to ImGui's draw list:

```lua
-- CSP:
ui.drawRectFilled(vec2(0,0), vec2(100,100), rgbm(1,0,0,1))

-- ImGui equivalent:
local draw_list = imgui.GetWindowDrawList()
draw_list:AddRectFilled(
    imgui.ImVec2(0, 0),
    imgui.ImVec2(100, 100),
    imgui.GetColorU32(1, 0, 0, 1)
)
```

## Limitations

1. **No 3D rendering** - `render.debugLine()` for brake markers won't show
2. **No DWrite fonts** - Uses ImGui's default font instead
3. **No audio** - `ac.AudioEvent` is stubbed
4. **No game physics** - Car state comes from lap data only

## Troubleshooting

### "imgui not found"
Make sure LuaJIT-ImGui is properly installed and in your Lua path.

### "SDL2 not found"
Install SDL2 development libraries:
- Windows: Included in luajitImGui download
- Linux: `sudo apt install libsdl2-dev`
- macOS: `brew install sdl2`

### Drawing doesn't appear
Check that you're using the correct coordinate system. ImGui uses absolute screen coordinates, not relative to the window.

## References

- [Dear ImGui](https://github.com/ocornut/imgui)
- [LuaJIT-ImGui](https://github.com/sonoro1234/LuaJIT-ImGui)
- [luajitImGui (Windows binaries)](https://github.com/dinau/luajitImGui)
- [CSP Lua Documentation](https://github.com/ac-custom-shaders-patch/acc-lua-docs)
