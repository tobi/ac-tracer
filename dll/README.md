# Extended Brake Pressure DLL

This folder should contain `dwrite.dll` - the cphys data provider DLL that enables extended brake pressure telemetry.

## Installation

1. Obtain `dwrite.dll` from IER Client Resources
2. Place it in this folder
3. The GitHub workflow will automatically include it in releases

## What it does

The DLL creates a memory-mapped file called `cphys_data` that provides:
- Brake pressure (PSI) - front and rear
- Tire forces (FX, FY)
- Carcass temperatures
- Slip angles and ratios
- Suspension data (damper travel, toe)
- Engine data (torque, throttle)
- IMU acceleration data
- Downforce and drag values

## Manual Installation

If not using the packaged release, copy `dwrite.dll` to your Assetto Corsa root folder (where `AssettoCorsa.exe` is located).
