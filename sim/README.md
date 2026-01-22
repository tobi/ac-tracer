# AC Tracer Simulator

Desktop simulation layer that runs ac-tracer outside of Assetto Corsa using Dear ImGui.

## Why ImGui?

CSP's `ui.*` API is literally Dear ImGui wrapped for Lua. Using actual ImGui bindings gives near-perfect API compatibility.

## Setup

### Windows (Easiest)

1. Download from [dinau/luajitImGui releases](https://github.com/dinau/luajitImGui/releases)
   - Get `luajitImGui-1.92.1.0.zip` (or latest)

2. Extract to `ac-tracer/sim/luajitImGui/`

3. Run:
   ```cmd
   cd ac-tracer\sim
   luajitImGui\luajitw.exe main.lua
   ```

### Cross-platform (Build Required)

1. Clone:
   ```bash
   git clone --recurse-submodules https://github.com/sonoro1234/LuaJIT-ImGui.git
   ```

2. Build following their instructions (requires CMake, C++ compiler)

3. Also need [LuaJIT-SDL2](https://github.com/sonoro1234/LuaJIT-SDL2)

4. Run:
   ```bash
   luajit sim/main.lua
   ```

## Usage

- **Drop CSV file** onto window to load a lap
- **Space** - Play/Pause
- **Left/Right** - Seek ±1 second
- **,/.** - Previous/Next frame
- **1-4** - Speed (0.25x/0.5x/1x/2x)
- **R** - Reset to start
- **H** - Help

## How It Works

`csp_shim.lua` provides CSP-compatible APIs:

| CSP | ImGui |
|-----|-------|
| `ui.text()` | `imgui.Text()` |
| `ui.drawRectFilled()` | `draw_list:AddRectFilled()` |
| `ac.getCar()` | Interpolated from loaded lap |

Car state is synthesized from the loaded lap data, allowing playback of recorded telemetry.

## Limitations

- No 3D rendering (`render.debugLine()`)
- No audio (`ac.AudioEvent`)
- No game physics (car state from lap data only)
