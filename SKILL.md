# CSP Lua API Reference

This file documents CSP (Custom Shaders Patch) Lua API discoveries for Assetto Corsa.

**Important:** Update this file when new APIs are discovered.

## Track Information

### `ac.getTrackID()`
Returns the track identifier string (e.g., "ks_brands_hatch-gp", "daytona").

```lua
local trackId = ac.getTrackID()
-- Returns: "ks_brands_hatch-gp"
```

**Note:** `ac.getSim().trackId` does NOT exist. Use `ac.getTrackID()` instead.

### `ac.getTrackDataFilename(filename)`
Returns the full path to a file in the track's data folder.

```lua
local path = ac.getTrackDataFilename('traffic.json')
```

### `ac.getSim()`
Returns `ac.StateSim` reference with information about the simulation state.

Key fields:
- `sim.dt` - Delta time in seconds (0 when paused, affected by replay speed)
- `sim.isPaused` - Simulation is paused
- `sim.isOnlineRace` - True if in an online session
- `sim.trackLengthM` - Track length in meters
- `sim.time` - Total time in milliseconds since AC started
- `sim.gameTime` - Total time in seconds since AC started
- `sim.sessionTimeLeft` - Remaining session time in ms
- `sim.currentSessionIndex` - 0-based session index
- `sim.rainIntensity` - Current rain intensity (0-1)
- `sim.roadGrip` - Current track grip (0-1)
- `sim.connectedCars` - Number of connected players (online)

### Spline & World Coordinates
- `ac.worldCoordinateToTrackProgress(vec3)` - Converts world position to spline position (0-1)
- `ac.trackProgressToWorldCoordinate(pos, linear)` - Converts spline position to world position
- `ac.getTrackSectorName(pos)` - Returns the name of the sector at given spline position

## Car Information

### `ac.getCar(index)`
Returns `ac.StateCar` for the specified car index (0 = player).

Key fields:
- `car.id` - Car identifier string
- `car.speedKmh` - Speed in km/h
- `car.splinePosition` - Position on track (0-1)
- `car.lapCount` - Number of completed laps
- `car.lapTimeMs` - Current lap time in milliseconds
- `car.bestLapTimeMs` - Best lap time in this session (ms)
- `car.gas` - Throttle (0-1)
- `car.brake` - Brake (0-1)
- `car.clutch` - Clutch (0-1, 1 = fully depressed)
- `car.steer` - Steering angle in degrees
- `car.gear` - Current gear (0 = N, -1 = R)
- `car.handbrake` - Handbrake (0-1)
- `car.isLapValid` - True if current lap is considered valid by AC
- `car.resetCounter` - Increments each time car is reset (teleported)
- `car.lastLapCutsCount` - Number of cuts in the last lap
- `car.collisionDepth` - Depth of current collision in meters
- `car.isInPitlane` - True if in pitlane area
- `car.racePosition` - Current position in session/race

### Car Events
- `ac.onTrackPointCrossed(carIndex, progress, callback)` - Triggered when car crosses a specific spline point
- `ac.onCarCollision(carIndex, callback)` - Triggered on collision
- `ac.onCarJumped(carIndex, callback)` - Triggered when car jumps

## Hotkeys

### `ac.ControlButton(name, defaults)`
Creates a bindable hotkey control.

```lua
local myButton = ac.ControlButton('traces/MyHotkey', {
    keyboard = { key = ui.KeyIndex.T, ctrl = true },
    gamepad = ac.GamepadButton.Y
})

-- Check if pressed this frame
if myButton:pressed() then ... end

-- Check if currently held
if myButton:down() then ... end

-- Render binding control in settings (UI function)
myButton:control(vec2(120, 0))
```

## Storage

### `ac.storage(layout, prefix)`
Advanced persistent storage with default values and automatic synchronization.

```lua
-- Define layout with defaults
local state = ac.storage({
    lastBestLap = 0,
    showTraces = true,
    colors = rgb(1, 0, 0)
}, "my_app/")

-- Access/Modify (automatically persists)
if state.showTraces then
    state.lastBestLap = currentTime
end
```

**Note:** Direct access `ac.storage[key] = value` only supports strings. Use the table-based approach for more types.

## Logging & UI

### `ac.log(message)`
Writes to CSP log.

### `ac.setMessage(title, description)`
Shows a toast-style message in the game UI.

### `ac.lapTimeToString(ms, allowHours)`
Utility to format milliseconds into "M:SS.ms" format.

## Sources

- [Full API Reference (lib.lua)](./reference/lib.lua)
- `extension/internal/lua-sdk/ac_apps/lib.lua` (Original SDK path)
- [CSP Lua SDK](https://github.com/ac-custom-shaders-patch/acc-lua-sdk)
- [CSP Default Apps](https://github.com/ac-custom-shaders-patch/app-csp-defaults)
