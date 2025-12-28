-- extended-brake.lua - Extended brake pressure data from cphys DLL
-- Reads brake pressure from memory-mapped file provided by dwrite.dll
-- Falls back to standard car.brake when DLL is not available

local extendedBrake = {}

--------------------------------------------------------------------------------
-- Memory-Mapped File Configuration
--------------------------------------------------------------------------------

-- Try to read the cphys_data memory-mapped file from dwrite.dll
-- This DLL must be placed in the assettocorsa root folder
local cphysData = nil
local initAttempted = false
local initSuccess = false

-- Structure matches the DLL's shared memory layout
local CPHYS_STRUCT = [[
    float4 FX;
    float4 FY;
    float4 carcassTemp;
    float4 slipAngle;
    float4 slipRatio;
    float4 vkm;
    float yawAngle;
    float rollAngle;
    float2 downforce;
    float drag;
    float3 accIMU;
    float4 toe;
    float4 damperTravel;
    float engTorque;
    float engThrottle;
    double2 brakePressure;
]]

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

--- Attempt to initialize the memory-mapped file connection
---@return boolean success True if connection was established
local function tryInit()
    if initAttempted then
        return initSuccess
    end

    initAttempted = true

    -- Try to read the memory-mapped file
    local ok, result = pcall(function()
        return ac.readMemoryMappedFile("cphys_data", CPHYS_STRUCT, false)
    end)

    if ok and result then
        cphysData = result
        initSuccess = true
        ac.log("AC Tracer: Extended brake data connected via cphys_data memory-mapped file")
    else
        initSuccess = false
        ac.log("AC Tracer: Extended brake data not available (dwrite.dll not installed or not running)")
    end

    return initSuccess
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Check if extended brake pressure data is available
---@return boolean available True if DLL is connected and providing data
function extendedBrake.isAvailable()
    if not initAttempted then
        tryInit()
    end
    return initSuccess and cphysData ~= nil
end

--- Get brake pressure in PSI
--- Returns front and rear brake pressure (or average depending on car setup)
---@return number|nil frontPressure Front brake pressure in PSI
---@return number|nil rearPressure Rear brake pressure in PSI
function extendedBrake.getPressure()
    if not extendedBrake.isAvailable() then
        return nil, nil
    end

    -- Access brake pressure (double2 = two double values)
    -- Index 1 = front, Index 2 = rear (Lua 1-indexed)
    local ok, front, rear = pcall(function()
        local f = cphysData.brakePressure(1)  -- Front/primary
        local r = cphysData.brakePressure(2)  -- Rear/secondary
        return f, r
    end)

    if ok then
        return front, rear
    end

    return nil, nil
end

--- Get normalized brake value (0.0 to 1.0) from pressure
--- Uses a configurable maximum pressure for normalization
---@param maxPressure number Maximum expected brake pressure in PSI (default 1500)
---@return number|nil normalized Normalized brake value (0.0 to 1.0)
function extendedBrake.getNormalized(maxPressure)
    maxPressure = maxPressure or 1500  -- Default max pressure for racing brakes

    local front, rear = extendedBrake.getPressure()
    if not front then
        return nil
    end

    -- Use the higher of front/rear as the primary brake value
    -- (most cars have more front brake bias anyway)
    local pressure = math.max(front or 0, rear or 0)

    -- Normalize to 0.0-1.0 range
    return math.clamp(pressure / maxPressure, 0, 1)
end

--- Get brake value with fallback to standard car.brake
--- This is the main function to use when recording telemetry
---@param car table Car state from ac.getCar()
---@param maxPressure number Optional max pressure for normalization
---@return number brake Brake value (0.0 to 1.0)
---@return boolean fromPressure True if value came from pressure sensor
function extendedBrake.getBrake(car, maxPressure)
    local normalized = extendedBrake.getNormalized(maxPressure)
    if normalized ~= nil then
        return normalized, true
    end

    -- Fallback to standard brake input
    return car.brake, false
end

--- Get raw pressure value for display (in PSI)
--- Returns average of front and rear pressure
---@return number|nil pressure Average brake pressure in PSI
function extendedBrake.getDisplayPressure()
    local front, rear = extendedBrake.getPressure()
    if not front then
        return nil
    end

    -- Return average for display purposes
    return (front + (rear or front)) / 2
end

--- Get full cphys data object (for accessing other telemetry)
--- Use with caution - raw access to shared memory
---@return table|nil cphysData Raw cphys data object
function extendedBrake.getRawData()
    if not extendedBrake.isAvailable() then
        return nil
    end
    return cphysData
end

--- Force re-initialization (useful if DLL was loaded after app start)
function extendedBrake.reinit()
    initAttempted = false
    initSuccess = false
    cphysData = nil
    return tryInit()
end

return extendedBrake
