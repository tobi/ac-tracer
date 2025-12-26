# Traces App - Architecture & Data Structures

This document describes the desired architecture, data structures, and data flow for the Traces app.

---

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Lap Data Structure](#lap-data-structure)
- [Game State](#game-state)
- [Corner Data Structures](#corner-data-structures)
- [Data Flow](#data-flow)
- [Window Functions](#window-functions)
- [Implementation Status](#implementation-status)

---

YOU ALSO MUST USE THE [SKILL.md](./SKILL.md) file, and update it when it points you into the wrong place.  

---

## Architecture Overview

The app follows a centralized state architecture where:

1. **Game State** (`state`) holds all current session data
2. **`script.update(dt)`** updates the game state (sampling, lap completion, corner detection)
3. **Window functions** receive `(dt, car, state)` and only render UI based on state
4. **No scattered state** - all lap data, history, and references live in one place

This separation ensures:
- Clean data flow (state updates → UI renders)
- Easy debugging (inspect state at any point)
- Testability (mock state for UI testing)
- Consistency across all windows

---

## Lap Data Structure


A lap is a complete recording of driver inputs and telemetry data over one circuit of the track. All laps share this structure, whether recorded in-game, loaded from CSV, or imported externally.

```lua
lap = {
    -- Metadata
    track = string,         -- Track ID (e.g., "ks_nordschleife")
    car = string,           -- Car ID (e.g., "ks_porsche_911_gt3_r")
    sessionId = string,     -- Session identifier (e.g., "1735123456_1234")
    completed = boolean,    -- true if lap crossed start/finish with data from 0% to 99%
    valid = boolean,        -- true if lap should be considered (false for, resets, partial)
    time = number,          -- Total lap time in milliseconds
    fuelLeftAtStart = number, -- Fuel at lap start in liters (for fuel strategy)
    lapNumberInSession = number, -- Which lap number in this session (1, 2, 3...)
    
    -- Telemetry arrays (all synchronized, same length, sampled at 15 Hz)
    throttle = { number, ... },  -- Throttle input (0.0 to 1.0)
    brake = { number, ... },     -- Brake input (0.0 to 1.0)
    clutch = { number, ... },    -- Clutch input (0.0 to 1.0, inverted: 1.0 = pressed)
    steering = { number, ... },  -- Steering input (0.0 to 1.0, normalized, 0.5 = straight)
    speed = { number, ... },     -- Speed in km/h
    pos = { number, ... },       -- Spline position (0.0 to 1.0)
    times = { number, ... },     -- Elapsed lap time in seconds at each sample
    tcActive = { boolean, ... }  -- Traction control active at each sample
}
```

### Field Details

| Field | Type | Range/Units | Description |
|-------|------|-------------|-------------|
| `track` | string | - | Track ID from AC |
| `car` | string | - | Car ID from AC |
| `sessionId` | string | - | Session identifier for grouping laps |
| `completed` | boolean | - | Has data spanning full lap (0% to 99% positions) |
| `valid` | boolean | - | Should be used for comparisons (no cuts, resets) |
| `time` | number | milliseconds | Total lap time (last sample time - first sample time) |
| `fuelLeftAtStart` | number | liters | Fuel level when crossing start line |
| `lapNumberInSession` | number | 1, 2, 3... | Which lap number in this session |
| `throttle[i]` | number | 0.0-1.0 | Throttle position at sample i |
| `brake[i]` | number | 0.0-1.0 | Brake pressure at sample i |
| `clutch[i]` | number | 0.0-1.0 | Clutch position (inverted: 1.0 = foot on pedal) |
| `steering[i]` | number | 0.0-1.0 | Steering angle normalized (0.5 = straight) |
| `speed[i]` | number | km/h | Ground speed at sample i |
| `pos[i]` | number | 0.0-1.0 | Track spline position at sample i |
| `times[i]` | number | seconds | Elapsed lap time at sample i |
| `tcActive[i]` | boolean | - | Traction control active at sample i |

### Sampling

- **Sample Rate**: 15 Hz (66.67ms between samples)
- **Typical Lap**: ~1400 samples for a 90-second lap
- All arrays are synchronized: `throttle[i]`, `brake[i]`, etc. correspond to the same moment

### Steering Normalization

Steering is stored normalized to 0.0-1.0 for consistent storage and display:

```lua
-- Recording (degrees to normalized):
steering = clamp(0.5 - rad(steerDeg) / (2 * steeringCap), 0, 1)

-- Playback (normalized to degrees):
steerDeg = (0.5 - steering) * 2 * steeringCap * 180 / pi
```

Where `steeringCap` = 180° (π radians) by default.

### Position-Based Indexing

All lap comparisons use **position-based matching**, not time-based. This ensures accurate trace overlay even when lap times differ:

```lua
-- Get value at specific track position (interpolates between samples)
function lap:getValueAtPos(field, targetPos)
    -- Binary search for surrounding samples
    -- Linear interpolation between them
end
```

---

## Game State

The centralized game state holds all session data. This is the single source of truth for all windows.

```lua
state = {
    -- Session info
    track = string,              -- Current track ID
    car = string,                -- Current car ID
    sessionId = string,          -- Unique session ID (e.g., "1735123456_1234")
    
    -- Track data
    trackCorners = {             -- Array of corner definitions
        {
            number = number,     -- Corner number (1, 2, 3, ...)
            name = string,       -- Display name (e.g., "Bus Stop")
            startPos = number,   -- Spline position where corner starts
            endPos = number,     -- Spline position where corner ends
            apexPos = number     -- Spline position of apex
        },
        ...
    },
    
    -- Current position
    lapNumber = number,          -- Current lap count
    trackPosition = number,      -- Current spline position (0.0 to 1.0)
    
    -- Lap data
    currentLap = lap,            -- Partially filled lap being recorded
    history = { lap, ... },      -- Recent completed laps (persisted, max 20)
    historyReferences = { lap, ... }, -- External laps loaded from CSV (for comparison)
    
    -- Reference lap
    bestLap = lap,               -- Best lap (from history or external)
    bestLapCorners = {           -- Pre-computed corner analysis for bestLap
        [cornerNumber] = {
            entrySpeed = number,
            apexSpeed = number,
            exitSpeed = number,
            brakePos = number,   -- or nil where we START applying break
            apexPos = number,
            liftOffPos = number, -- or nil where we STOP being on full throttle
            maxSteeringDeg = number
        },
        ...
    },
    
    -- Manual corner recording
    cornerRecording = boolean,   -- Currently recording a corner?
    cornerRecordStart = number,  -- Spline position where recording started
    cornerRecordTime = number    -- Time when recording started
}
```

### State Updates

State is updated in `script.update(dt)`:

```lua
function script.update(dt)
    local car = ac.getCar(0)
    if not car then return end
    
    -- Update current lap recording
    state.currentLap = updateCurrentLap(state.currentLap, car, dt)
    
    -- Check for lap completion
    if lapJustCompleted(car) then
        local completedLap = finalizeCurrentLap(state.currentLap, car)
        
        -- Add to history
        table.insert(state.history, 1, completedLap)
        pruneHistory(state.history, 20)  -- Keep last 20
        
        -- Update best if faster
        if completedLap.valid and isFaster(completedLap, state.bestLap) then
            state.bestLap = completedLap
            state.bestLapCorners = analyzeCorners(completedLap, state.trackCorners)
        end
        
        -- Reset current lap
        state.currentLap = createEmptyLap(state.track, state.car)
    end
    
    -- Update track position
    state.trackPosition = car.splinePosition
    state.lapNumber = car.lapCount
end
```

### Persistence

- **`history`**: Persisted to `ac.storage` as JSON, loaded on app start
- **`historyReferences`**: Not persisted (loaded fresh each session from CSV)
- **`bestLap`**: Derived from history or set explicitly from external source
- **`trackCorners`**: Persisted to `settings.ini` or separate corners file

---

## Corner Data Structures

### Corner Definition

A corner is defined by its track positions:

```lua
corner = {
    number = number,      -- Corner number for ordering (1, 2, 3, ...)
    name = string,        -- Display name (e.g., "Bus Stop", defaults to "Corner N")
    startPos = number,    -- Spline position where corner starts (0.0 to 1.0)
    endPos = number,      -- Spline position where corner ends (0.0 to 1.0)
    apexPos = number      -- Spline position of the apex (0.0 to 1.0)
}
```

### Completed Corner Analysis

When a corner is exited, statistics are computed for display:

```lua
completedCorner = {
    -- Identification
    number = number,              -- Corner number for ordering
    name = string,                -- Display name (e.g., "Bus Stop")
    
    -- Reference (bestLap) data
    refEntrySpeed = number,       -- km/h
    refApexSpeed = number,        -- km/h
    refExitSpeed = number,        -- km/h
    refBrakePos = number,         -- spline position (or nil) where braking starts
    refApexPos = number,          -- spline position of apex
    refLiftOffPos = number,       -- spline position (or nil) where throttle lift starts
    refMaxSteeringDeg = number,   -- degrees
    
    -- Current lap data
    currentEntrySpeed = number,
    currentApexSpeed = number,
    currentExitSpeed = number,
    currentBrakePos = number,
    currentLiftOffPos = number,
    currentApexPos = number, 
    currentMaxSteeringDeg = number,
    currentSpeeds = { { pos, speed }, ... },  -- For mini speed graph
    
    -- Deltas (current - reference)
    timeDelta = number,           -- seconds (positive = slower)
    entrySpeedDelta = number,     -- km/h (positive = faster)
    apexSpeedDelta = number,      -- km/h (positive = faster)
    exitSpeedDelta = number,      -- km/h (positive = faster)
    brakePosDeltaM = number,      -- meters (positive = later braking)
    liftOffPosDeltaM = number,    -- meters (positive = later lift)
    steeringDelta = number        -- degrees (positive = more steering)
}
```

---

## Data Flow

### 1. Session Initialization

```
App Start
    ↓
Load settings.ini
    ↓
Load corners from storage
    ↓
Load history from ac.storage
    ↓
Set bestLap = fastest valid lap from history
    ↓
Initialize state
```

### 2. Per-Frame Update Loop

```
script.update(dt)
    ↓
Sample at 15 Hz → append to state.currentLap arrays
    ↓
Check lap completion → finalize, add to history, update bestLap
    ↓
Update corner detection → track which corner we're in
    ↓
Update corner stats → entry/apex/exit tracking
```

### 3. Window Rendering

```
script.windowMain(dt)
    ↓
Read state.currentLap, state.bestLap
    ↓
Render traces, wheel, bars, corner zones
    ↓
(No state mutation)

script.windowCorners(dt)
    ↓
Read state.bestLapCorners, corner_analysis
    ↓
Render corner analysis
    ↓
(No state mutation)

script.windowTelemetry(dt)
    ↓
Read state.history, state.historyReferences
    ↓
User selects laps to compare
    ↓
Render full-lap telemetry comparison
    ↓
(No state mutation)
```

### 4. CSV Import Flow

```
User selects CSV file
    ↓
load_csv.loadFile(path)
    ↓
Parse & normalize to lap structure
    ↓
Add to state.historyReferences
    ↓
Optionally set as state.bestLap
```

---

## Window Functions

All windows follow the same signature pattern:

```lua
function script.windowMain(dt)
    local car = ac.getCar(0)
    traces.draw(dt, car, state)
end

function script.windowCorners(dt)
    local car = ac.getCar(0)
    corner_analysis.draw(dt, car, state)
end

function script.windowTelemetry(dt)
    local car = ac.getCar(0)
    lap_telemetry.draw(dt, car, state)
end

function script.windowSettings(dt)
    settings.draw(dt, state)
end
```

This pattern:
- Passes all necessary context explicitly
- Makes dependencies clear
- Enables testing with mock state

---

## Implementation Status

### Completed ✓

1. **`lap.lua` module** - Complete lap data structure
   - `lap.new(track, car)` - constructor
   - `lap:addSample(car)` - record from car state
   - `lap:getValueAtPos(field, pos)` - interpolate at position
   - `lap:getTimeAtPos(pos)` - time at position
   - `lap:getDeltaVs(refLap, pos)` - delta calculation
   - `lap:getTracesAt(positions)` - bulk trace extraction
   - `lap:findBrakePoint()`, `lap:findLiftPoint()`, `lap:findMaxSteering()` - corner analysis
   - `lap:serialize()`, `lap.deserialize()` - persistence
   - `lap.fromCSV(filePath)` - CSV import
   - `lap.normalizeSteer()`, `lap.steerToDegrees()` - steering conversion

2. **`state.lua` module** - Centralized state (single source of truth)
   - All lap data: `currentLap`, `history`, `historyReferences`, `bestLap`
   - All corner data: `trackCorners`, `bestLapCorners`
   - All persistence: corners to file/storage, best lap to storage
   - `state.update(dt, car)` - main update loop
   - `state.init(car)` - session initialization
   - Corner recording: `startCornerRecording()`, `stopCornerRecording()`
   - Ghost API: `getDelta()`, `getGhostSteering()`, `getGhostTraces()`
   - CSV loading: `loadCSV()`, `loadCSVAsBest()`

3. **`corner.lua`** - Corner recording UI
   - Provides `handleRecordButton()`, `settingsUI()` 
   - All state queries delegate to `state`

4. **`corner_analysis.lua`** - All corner-specific logic
   - `analyzeCorner(lap, cornerDef)` - analyze one corner from a lap
   - `analyzeLap(lap)` - analyze all corners in a lap
   - `compareCorners(current, reference)` - compare corner data
   - `update(car)` - live corner tracking during driving
   - `draw()` - renders speed comparison graphs and scoring
   - Uses `state` directly via require

6. **`traces.lua`** - Main script
   - Calls `state.update(dt, car)` in main loop
   - Orchestrates all windows

7. **`lap_telemetry.lua`** - MoTeC-style telemetry UI
   - Reads completed laps from `state.history`
   - Uses `state` and `settings` directly via require

8. **`app_settings.lua`** - Settings UI
   - CSV loading via `lap.fromCSV()` and `state.setBestLap()`
   - Uses `state` directly via require

9. **`scoring.lua`** - Corner score calculation
   - Pure functions, no state dependency

### Deleted

- `load_csv.lua` - Functionality merged into `lap.fromCSV()`
- `ghost.lua` - Functionality merged into `state.lua`

### Future Improvements

- Add lap comparison helpers: `lap.compare(lap1, lap2)`
- Add lap validation helpers

---

## File Structure

```
traces/
├── tracks/
│   ├── corners.csv           # All corner definitions (all tracks in one file)
│   └── trackname.csv         # Reference lap CSVs (MoTeC export)
└── ...
```

### Corner Files (`corners.csv`)

Manual corner definitions are saved in a single CSV file with format:

```csv
track,name,start,end
ks_nordschleife,Corner 1,0.123456,0.134567
ks_nordschleife,Karussell,0.234567,0.256789
ks_monza,Corner 1,0.045678,0.067890
```

When saving corners, any existing corners for the same track are removed before writing the new ones. This prevents duplicates and allows easy updates.

---

## Notes

- **All sampling is 15 Hz** - consistent across recording, CSV import, and display
- **Position-based matching** - ghost traces matched by track position, not time
- **Normalized inputs** - all 0.0-1.0 for consistent display
- **Time in milliseconds** - internal storage uses ms for precision
- **Corner files** - saved as `tracks/corners.csv`

---

## Architecture (v2.0)

All modules use `state` and `lap` directly via `require()`. No init functions, no compatibility wrappers.

```
┌─────────────────────────────────────────────────────────────┐
│                      traces.lua (main)                       │
│  - Calls state.update(dt, car) each frame                   │
│  - Orchestrates window rendering                            │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │   state.lua  │ │   lap.lua    │ │ scoring.lua  │
      │ (all state)  │ │ (lap object) │ │ (pure funcs) │
      └──────────────┘ └──────────────┘ └──────────────┘
              │               │
              └───────┬───────┘
                      ▼
      ┌──────────────────────────────────────────┐
      │  UI Modules (all use state via require)  │
      │  - corner.lua                            │
      │  - corner_analysis.lua                   │
      │  - lap_telemetry.lua                     │
      │  - app_settings.lua                      │
      └──────────────────────────────────────────┘
```

**Migration complete.** All state now lives in `state.lua` and `lap.lua`.

---

## Debugging & Logs

### CSP Log Location

CSP logs all Lua errors to:

```
C:\Users\<USERNAME>\Documents\Assetto Corsa\logs\custom_shaders_patch.log (Username is likely "ASR")
```

### Reading Errors

**PowerShell - Last 1000 lines with ERROR filter:**
```powershell
Get-Content "C:\Users\ASR\Documents\Assetto Corsa\logs\custom_shaders_patch.log" -Tail 1000 | Select-String "ERROR"
```

**Filter for traces.lua errors only:**
```powershell
Get-Content "C:\Users\ASR\Documents\Assetto Corsa\logs\custom_shaders_patch.log" -Tail 1000 | Select-String "ERROR.*traces\.lua"
```

**Watch log in real-time:**
```powershell
Get-Content "C:\Users\ASR\Documents\Assetto Corsa\logs\custom_shaders_patch.log" -Wait | Select-String "ERROR"
```

### Common Error Patterns

| Error | Cause | Fix |
|-------|-------|-----|
| `attempt to index global 'X' (a nil value)` | Undefined variable | Check spelling, add `local` or proper prefix |
| `attempt to call field 'X' (a nil value)` | Missing function | Check module exports and requires |
| `error loading module 'X'` | Syntax error in file | Check file for typos, missing `end` |

### Log Format

```
TIMESTAMP [PID] | LEVEL | Message
2025-12-26T12:57:52:597 [29592] | ERROR | Failed to call `windowMain`: ...traces.lua:273: ...
```

- **LEVEL**: DEBUG, PERF, WARN, ERROR
- Errors include stack trace with file:line information
