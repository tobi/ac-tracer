# Traces

A high-performance driver input telemetry and analysis app for Assetto Corsa, built with CSP Lua.

![Traces Screenshot](assets/telemetry.png)

## Installation

All you need to do is [download the zip file](https://github.com/tobi/ac-tracer/archive/refs/heads/master.zip) from github.com/tobi/ac-tracer/ and drag & drop it onto Content Manager.

## Features

### 🏁 Professional Analysis
- **Real-time Telemetry**: Visualize Throttle, Brake, Clutch, and Steering traces live as you drive.
- **Corner Analysis**: Automatic detection of corners with detailed breakdowns of:
  - **Entry Speed** (max speed before braking)
  - **Apex Speed** (minimum speed)
  - **Exit Speed** (max speed on exit)
  - **Braking Points** & **Lift-off Points**
- **Live Deltas**: Instant feedback on time gained/lost and speed differences vs reference.

![Corner Analysis](assets/Screenshot%202025-12-26%20155821.png)

### 📊 Data Import & Export
- **MoTeC CSV Support**: Load reference laps directly from MoTeC CSV file exports to compare against real-world data or other simulators.
- **Automatic History**: Your best laps are automatically saved and loaded for every car/track combination.

![Data Import](assets/Screenshot%202025-12-26%20160022.png)

### 👻 Smart Comparison
- **Ghost Traces**: Faint reference lines show exactly what the faster lap did.
- **Position-Based Sync**: Traces align by track position, not time, ensuring perfect overlays even if you drive slower or stop.
- **Steering Visualization**: See the ghost's steering angle overlaid on your own.

## Configuration

The app is highly configurable via `settings.ini` or the in-game settings window:

- Toggle specific traces (Throttle, Brake, Steering, etc.)
- Adjust time window and sample rates
- Customize units (km/h vs mph)
- Manage reference laps

## Hotkeys

Bind a key to **Reset Best Lap** in Content Manager:
- Settings → Assetto Corsa → Controls → Patch → find `APP_TRACES_RESET_BEST`
