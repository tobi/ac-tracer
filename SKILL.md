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

### `ac.getSim().trackLengthM`
Returns track length in meters.

```lua
local trackLength = ac.getSim().trackLengthM
```

## Car Information

### `ac.getCar(index)`
Returns car state for the specified car index (0 = player).

Key fields:
- `car.id` - Car identifier
- `car.speedKmh` - Speed in km/h
- `car.splinePosition` - Position on track (0-1)
- `car.lapCount` - Number of completed laps
- `car.lapTimeMs` - Current lap time in milliseconds
- `car.gas` - Throttle (0-1)
- `car.brake` - Brake (0-1)
- `car.clutch` - Clutch (0-1, 0 = engaged)
- `car.steer` - Steering angle in degrees
- `car.gear` - Current gear

## Hotkeys

### `ac.ControlButton(name)`
Creates a bindable hotkey control.

```lua
local myButton = ac.ControlButton('__APP_MYAPP_HOTKEY')

-- Check if pressed this frame
if myButton:pressed() then ... end

-- Check if currently held
if myButton:down() then ... end

-- Render binding control in settings
myButton:control(vec2(120, 0))
```

## Storage

### `ac.storage[key]`
Persistent key-value storage that survives game restarts.

```lua
-- Save
ac.storage["myKey"] = stringify(myData)

-- Load
local data = stringify.parse(ac.storage["myKey"])
```

## Logging

### `ac.log(message)`
Writes to CSP log.

```lua
ac.log("My message")
```

## Sources

- [CSP Lua SDK](https://github.com/ac-custom-shaders-patch/acc-lua-sdk)
- [CSP Default Apps](https://github.com/ac-custom-shaders-patch/app-csp-defaults)
