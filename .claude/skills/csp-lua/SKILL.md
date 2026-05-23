---
name: csp-lua
description: CSP (Custom Shaders Patch) Lua API reference and workflow for Assetto Corsa modding. Use when writing, reviewing, debugging, or testing CSP Lua code, including Assetto Corsa Lua apps, ac.*, ui.*, render.*, physics.*, io.*, web.*, storage, app windows, telemetry, track/car state, memory-mapped files, LuaJIT/FFI, and AC Tracer-specific CSP integration.
---

# CSP Lua

Use this skill for Assetto Corsa Custom Shaders Patch Lua work. Prefer local bundled references first; they match the installed SDK snapshot better than memory or web snippets.

## Workflow

1. Read the repo instructions first when working inside a project, especially `AGENTS.md` or `CLAUDE.md`.
2. Search the local API before inventing names:
   ```powershell
   .\.claude\skills\csp-lua\scripts\find-api.ps1 "ac.getCar"
   .\.claude\skills\csp-lua\scripts\find-api.ps1 "function ui.slider"
   rg -n "StateCar|splinePosition|trackLengthM" .\.claude\skills\csp-lua\reference\lib.lua
   ```
3. Prefer the smaller SDK source files when you know the namespace:
   - `reference/sdk/common/ac_state.lua`: car/sim/session state.
   - `reference/sdk/common/ac_ui.lua`: `ui.*`, windows, settings, controls.
   - `reference/sdk/common/ac_storage.lua` and `.d.lua`: persistent storage.
   - `reference/sdk/common/io.lua` and `.d.lua`: CSP file APIs.
   - `reference/sdk/common/ac_render.lua`: `render.*` drawing callbacks.
   - `reference/sdk/common/ac_physics*.lua`: `physics.*`, AI, reset, car control.
   - `reference/sdk/common/ac_web*.lua` and `lib_web.lua`: HTTP/web APIs.
   - `reference/sdk/common/ac_audio*.lua`: audio events.
   - `reference/lib.lua`: generated complete EmmyLua API, enums, classes, overloads.
4. Implement with immediate-mode CSP patterns, then run local Lua tests or syntax checks where available.
5. If debugging in-game behavior, inspect filtered CSP logs:
   ```powershell
   .\.claude\skills\csp-lua\scripts\logs.ps1 -l 80 -only ERROR
   .\.claude\skills\csp-lua\scripts\logs.ps1 -l 120
   ```

## Non-Negotiables

- Do not put shell execution in CSP runtime code. Avoid `io.popen`, `os.execute`, `start`, `cmd`, PowerShell, and external CLI calls from Lua. Use CSP APIs such as `io.open`, `io.save`, `io.load`, `io.scanDir`, `io.createDir`, `web.*`, `ac.*`, and `physics.*`.
- Do not guess API names. Search `reference/lib.lua` or `reference/sdk/**` before using unfamiliar CSP APIs.
- Keep runtime work small in `script.update(dt)` and UI draw callbacks. Expensive parsing, scans, and bulk serialization should be throttled, cached, or moved out of per-frame paths.
- Use `script.*` callbacks, not legacy global callbacks, unless maintaining old code. CSP looks up and caches callback functions.
- Treat AC/CSP code as LuaJIT 2.1 with Lua 5.1 behavior plus CSP extensions, not stock Lua 5.4.

## App Structure

Lua apps live in `assettocorsa/apps/lua/<app-id>/` with a `manifest.ini` and `<app-id>.lua` entry file. The official CSP Lua app wiki describes app folders, `manifest.ini`, lazy loading, window callbacks, UI callbacks, render callbacks, and `script.update(dt)`.

Typical manifest window:
```ini
[ABOUT]
NAME = My App
AUTHOR = ...
VERSION = 1.0
DESCRIPTION = ...

[CORE]
LAZY = PARTIAL

[WINDOW_MAIN]
ID = main
NAME = My App
FUNCTION_MAIN = windowMain
FUNCTION_SETTINGS = windowSettings
SIZE = 400, 240
FLAGS = SETTINGS
```

Typical entry file:
```lua
local state = { clicks = 0 }

function script.update(dt)
  local car = ac.getCar(0)
  if not car then return end
end

function script.windowMain(dt)
  if ui.button('Click') then
    state.clicks = state.clicks + 1
  end
  ui.text('Clicks: ' .. state.clicks)
end
```

`script.update(dt)` runs every frame even when app windows are closed, depending on app laziness. Window functions run only when their windows are visible. `UI_CALLBACKS` draw outside app windows and need an explicit `ui.transparentWindow()` or `ui.toolWindow()`.

## Core State APIs

Use `ac.getSim()` for global simulation state:
- `sim.dt`: simulation delta in seconds; can be `0` while paused.
- `sim.time`: total AC time in milliseconds.
- `sim.gameTime`: total AC time in seconds.
- `sim.trackLengthM`: track length in meters.
- `sim.isPaused`, `sim.isOnlineRace`, `sim.currentSessionIndex`, `sim.sessionTimeLeft`.
- `sim.rainIntensity`, `sim.roadGrip`, `sim.connectedCars`.

Use `ac.getCar(index)` for car state; index `0` is the player:
- `car.speedKmh`, `car.splinePosition`, `car.lapCount`, `car.lapTimeMs`, `car.bestLapTimeMs`.
- `car.gas`, `car.brake`, `car.clutch`, `car.steer`, `car.gear`, `car.handbrake`.
- `car.isLapValid`, `car.resetCounter`, `car.lastLapCutsCount`, `car.collisionDepth`, `car.isInPitlane`.
- `car.racePosition`, `car.fuel`, tyre/wheel fields, contact/slip fields; search `StateCar` for the full list.

Track and car helpers:
```lua
local trackId = ac.getTrackID()      -- preferred spelling
local carId = ac.getCarID(0)
local carName = ac.getCarName(0, true)
local meters = ac.getSim().trackLengthM or 0
local world = ac.trackProgressToWorldCoordinate(0.25)
local progress = ac.worldCoordinateToTrackProgress(world)
local sectorName = ac.getTrackSectorName(0.25)
```

`ac.getSim().trackId` is not a valid substitute for `ac.getTrackID()`.

## Files And Storage

Use CSP `io.*` APIs in runtime code:
```lua
io.createDir(path)
local f = io.open(path, 'w')
if f then
  f:write(data)
  f:close()
end

local data = io.load(path, '')
io.save(path, data, true)            -- ensure parent folders
local exists = io.exists(path)
local isFile = io.fileExists(path)
local isDir = io.dirExists(path)
local attrs = io.getAttributes(path)
```

Directory scan callback pattern:
```lua
io.scanDir(folder, '*.csv', function(fileName, attrs)
  if not attrs.isDirectory then
    -- fileName is the item name, not always a fully normalized app path.
  end
end)
```

Prefer typed `ac.storage(layout, keyPrefix)` for app settings:
```lua
local settings = ac.storage({
  enabled = true,
  opacity = 0.85,
  pos = vec2(100, 100),
  color = rgbm(0.2, 0.7, 1, 1)
}, 'my-app:')

settings.enabled = false             -- auto-saved after change
```

`ac.storage('key', default)` returns an `ac.StoredValue` with `:get()` and `:set(value)`. Direct `ac.storage.key = value` behaves like string-only localStorage; use it only for simple string cache entries.

## UI Patterns

CSP UI is immediate-mode, based on Dear ImGui. Draw the full UI every frame from current state. Widgets return changes; update state immediately.

### UX Principles For CSP Apps

- Design settings windows as forms, not piles of controls. Use consistent label columns, control widths, section headers, and vertical rhythm.
- Put common controls first. Put destructive or rarely used actions at the bottom, separated from routine settings.
- Align related controls on the same x positions. Avoid random `sameLine()` offsets that only fit one text length.
- Keep labels stable and use hidden IDs (`##id`) for controls whose visible text changes.
- Prefer native controls over text buttons:
  - `ui.checkbox` for booleans.
  - `ui.slider` for bounded numeric values.
  - `ui.combo` and `ui.selectable` for modes.
  - `ui.radioButton` for 2-4 mutually exclusive choices that benefit from being visible.
  - `ui.colorPicker` or `ui.colorButton` for colors.
  - `ui.inputText` for short strings or filters.
  - `ui.iconButton` with `ui.Icons.*` for compact tool actions.
  - `ac.ControlButton(...):control(size)` for user-bindable hotkeys.
- Reserve plain `ui.button` for commands: load, save, reset, import, clear, open, close.
- Add tooltips for icon-only buttons, destructive actions, and controls whose effect is not obvious.
- Use margins and spacing deliberately: small gaps inside dense HUDs, larger gaps between settings sections.
- Keep HUD windows glanceable. Minimize labels, use consistent units, and prefer aligned numeric columns.
- Do not redraw large custom charts with thousands of individual calls unless cached or throttled; immediate-mode draw calls have real cost.

### Settings Windows

Use `ui.addSettings()` for app settings available from the CSP taskbar/settings UI. Include stable `id`, icon, and size. Use `padding` if the default spacing feels cramped.

```lua
local openSettings = ui.addSettings({
  name = 'AC Tracer Settings',
  id = 'ac-tracer-settings',
  icon = ui.Icons.Settings,
  size = {
    default = vec2(460, 520),
    min = vec2(380, 360)
  },
  padding = vec2(14, 12)
}, function()
  drawSettings()
end)
```

The returned function can be called with commands:
```lua
openSettings('open')
openSettings('toggle')
local isOpen = openSettings('opened')
```

Use `ui.header()` and `ui.separator()` to structure settings. For many settings, use tabs:
```lua
ui.tabBar('settings-tabs', function()
  ui.tabItem('Display', function()
    drawDisplaySettings()
  end)
  ui.tabItem('Telemetry', function()
    drawTelemetrySettings()
  end)
  ui.tabItem('Hotkeys', function()
    drawHotkeySettings()
  end)
end)
```

Use collapsible groups (`ui.treeNode`) for advanced or experimental options:
```lua
ui.treeNode('Advanced', function()
  drawAdvancedSettings()
end)
```

### Form Rows And Alignment

Prefer a small local row helper for settings screens. It keeps labels, controls, and margins consistent.

```lua
local LABEL_W = 170
local CONTROL_W = 220
local ROW_GAP = 6

local function formRow(label, drawControl, tooltip)
  ui.alignTextToFramePadding()
  ui.text(label)
  if tooltip and ui.itemHovered() then ui.setTooltip(tooltip) end
  ui.sameLine(LABEL_W)
  ui.setNextItemWidth(CONTROL_W)
  local changed, value = drawControl()
  ui.offsetCursorY(ROW_GAP)
  return changed, value
end

formRow('Trace length', function()
  local value, changed = ui.slider('##traceLength', settings.traceLength, 5, 30, '%.0f s', true)
  if changed then settings.traceLength = value end
  return changed, value
end)

formRow('Comparison mode', function()
  local index, changed = ui.combo('##comparisonMode', settings.modeIndex, 0, {
    'Best lap',
    'Previous lap',
    'Reference lap'
  })
  if changed then settings.modeIndex = index end
  return changed, index
end)
```

For right-aligned controls in narrow panels, compute from available width:
```lua
local controlWidth = 180
ui.text('Opacity')
ui.sameLine(math.max(120, ui.availableSpaceX() - controlWidth))
ui.setNextItemWidth(controlWidth)
settings.opacity = ui.slider('##opacity', settings.opacity, 0, 1, '%.2f')
```

Use `ui.columns()` sparingly for table-like data. Always restore to one column:
```lua
ui.columns(3, false, 'lap-columns')
ui.text('Lap'); ui.nextColumn()
ui.text('Time'); ui.nextColumn()
ui.text('Delta'); ui.nextColumn()
ui.separator()
-- rows...
ui.columns(1)
```

### Rich Controls

Text input:
```lua
settings.profileName = ui.inputText('##profileName', settings.profileName, ui.InputTextFlags.None, vec2(-1, 0))
```

Combo from a string list:
```lua
local choices = { 'Off', 'Subtle', 'Normal', 'Aggressive' }
local newIndex, changed = ui.combo('##beepMode', settings.beepModeIndex, 0, choices)
if changed then settings.beepModeIndex = newIndex end
```

Combo with custom selectable rows:
```lua
ui.combo('##referenceLap', selectedName, function()
  for i, lap in ipairs(laps) do
    if ui.selectable(lap.label, i == selectedIndex) then
      selectedIndex = i
    end
  end
end)
```

Color controls:
```lua
if ui.colorButton('##traceColorPreview', settings.traceColor, ui.ColorPickerFlags.None, vec2(26, 18)) then
  showColorPicker = not showColorPicker
end
if showColorPicker then
  settings.traceColor = ui.colorPicker('##traceColor', settings.traceColor)
end
```

Icon button with tooltip:
```lua
if ui.iconButton(ui.Icons.Save, vec2(28, 28)) then
  saveConfig()
end
if ui.itemHovered() then ui.setTooltip('Save settings') end
```

Progress and status:
```lua
ui.progressBar(importProgress, vec2(-1, 0), string.format('Importing %.0f%%', importProgress * 100))
```

Context menu on the previous item:
```lua
ui.text('Reference lap')
ui.itemPopup('reference-menu', function()
  if ui.selectable('Clear reference') then clearReference() end
  if ui.selectable('Reveal file') then revealReference() end
end)
```

### Basic Widget Patterns

```lua
local newOpacity, changed = ui.slider('Opacity', settings.opacity, 0, 1, '%.2f')
if changed then settings.opacity = newOpacity end

if ui.checkbox('Enabled', settings.enabled) then
  settings.enabled = not settings.enabled
end
```

Prefer wrapper windows for app UI. Use opaque tool windows for normal tools and transparent windows for HUD overlays:
```lua
function script.windowMain(dt)
  ui.toolWindow('my-app/main', vec2(100, 100), vec2(420, 280), false, true, function()
    ui.text('Main content')
  end)
end

function script.windowHUD(dt)
  ui.transparentWindow('my-app/hud', vec2(0, 0), ui.windowSize(), true, false, function()
    ui.textColored('HUD', rgbm.colors.white)
  end)
end
```

### Layout Rules

- Pair every `pushFont`, `pushStyleVar`, `pushStyleColor`, `beginGroup`, `beginChild`, and path operation with the correct pop/end/stroke/fill.
- Use `ui.childWindow()` or `ui.beginChild()` for scrollable lists and reserve footer height with negative sizes such as `vec2(0, -32)`.
- `vec2(-1, 0)` generally means fill remaining width for widget sizes.
- Use unique hidden IDs with `##suffix` when labels repeat.
- Use `ui.measureText()` and `ui.availableSpace()` to avoid clipping in compact HUDs.
- Use `ui.alignTextToFramePadding()` before labels that sit beside framed controls.
- Avoid hard-coded magic offsets when a label/control helper or `availableSpaceX()` can compute alignment.
- Keep one visual density per window. A telemetry HUD can be dense; a settings window should breathe.
- Put `ui.separator()` between conceptual groups, not between every row.
- If a custom drawn panel has a border/background, leave at least 6-10 px inner padding before text.

Settings window:
```lua
local settingsWindow = ui.addSettings({
  name = 'My App Settings',
  id = 'my-app-settings',
  icon = ui.Icons.Settings,
  size = { default = vec2(420, 320), min = vec2(320, 220) }
}, function()
  ui.header('General')
end)
```

App window management:
```lua
local acc = ac.accessAppWindow('ac-tracer/telemetry')
if acc and acc:valid() then acc:setVisible(true) end
ac.setAppWindowVisible('ac-tracer', 'telemetry', true)
```

## Input And Hotkeys

Use `ac.ControlButton` for bindable controls:
```lua
local toggle = ac.ControlButton('my-app/toggle', {
  keyboard = { key = ui.KeyIndex.T, ctrl = true },
  gamepad = ac.GamepadButton.Y
})

if toggle:pressed() then
  settings.enabled = not settings.enabled
end

toggle:control(vec2(160, 0))
```

For mouse input, check `ui.itemHovered()`, `ui.mouseClicked()`, `ui.mouseDown()`, `ui.mouseWheel()`, `ui.mousePos()`, and `ui.windowPos()` in the same frame you draw the hit target.

## Render And Physics

Use `render.*` only from proper render callbacks or render-safe contexts. `RENDER_CALLBACKS` in `manifest.ini` can point to `script.Draw3D(dt)` style functions. For 3D debug visuals, prefer:
```lua
render.debugLine(from, to, rgbm.colors.cyan)
render.debugSphere(center, 0.5, rgbm.colors.red)
render.debugText(pos, 'label', rgbm.colors.white, 1)
```

Use `physics.*` only when the app mode and session allow it. Check availability/permissions for invasive operations:
```lua
if physics.allowed() and ac.isCarResetAllowed() then
  physics.setCarPosition(0, pos, dir)
end
```

For AI/traffic work, search `physics.setAI*`, `ac.SpawnSet`, and `physics.teleportCarTo`. For checkpoints, prefer `ac.saveCarStateAsync()` and `ac.loadCarState()` when you need a faithful car state snapshot.

## FFI And Memory-Mapped Files

For external telemetry or shared memory, use `ac.readMemoryMappedFile(name, layout, persist)` with a declared layout. Wrap setup in `pcall`; many users will not have the mapped file or companion DLL installed.

```lua
local ok, mmf = pcall(function()
  return ac.readMemoryMappedFile('cphys_data', CPHYS_STRUCT, false)
end)
if ok and mmf then
  -- read fields defensively
end
```

Never let optional MMF failure break the app. Log once, cache unavailability, and provide a normal CSP fallback.

## Debugging

Use CSP logging APIs:
```lua
ac.log('message')
ac.warn('warning')
ac.error('error')
ac.setMessage('Title', 'Description')
```

For AC Tracer, filter logs to avoid noise from other apps:
```powershell
.\.claude\skills\csp-lua\scripts\logs.ps1 -l 80 -only ERROR
Get-Content "$env:USERPROFILE\Documents\Assetto Corsa\logs\custom_shaders_patch.log" -Tail 1000 |
  Select-String "ERROR.*ac-tracer/"
```

Common CSP Lua failures:
- `attempt to index global 'X'`: missing `local`, missing module require, or wrong namespace.
- `attempt to call field 'X'`: nonexistent CSP API or function not exported by a module.
- `error loading module`: syntax error, bad `require()` path, or module returning nothing unexpectedly.
- Window draw failure: check the first stack frame in the CSP log; repeated draw exceptions can hide later useful messages.

## Testing

For this repo, run:
```powershell
tests\run.cmd
```

If LuaJIT is available:
```powershell
luajit tests/test_runner.lua
luajit -bl lib/core/state.lua > $null
```

When adding CSP API use, update `tests/mock_ac.lua` or web mocks if local tests/browser previews need the new function. Keep mocks plain and deterministic; they do not need to emulate the whole simulator.

## Reference Sources

Bundled:
- `reference/lib.lua`: complete generated API definitions.
- `reference/sdk/`: source snapshot of `ac-custom-shaders-patch/acc-lua-sdk`.

Useful upstream links:
- `https://github.com/ac-custom-shaders-patch/acc-lua-sdk`
- `https://github.com/ac-custom-shaders-patch/acc-lua-sdk/wiki/Lua-apps`
- `https://github.com/ac-custom-shaders-patch/acc-lua-examples`
- `https://github.com/ac-custom-shaders-patch/acc-lua-internal`

Use upstream only to refresh or compare; the bundled files are the first source for implementation inside this workspace.
