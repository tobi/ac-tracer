-- extended-brake.lua - Enhanced brake pressure from cphys DLL
-- Falls back to car.brake if DLL is not available
-- Uses cphys_data memory-mapped file from dwrite.dll (placed in AC root)

local extended_brake = {}

-- Try to read the cphys_data memory-mapped file
-- The DLL provides brakePressure as double2 (front, rear) in PSI
local cphysData = nil
local cphysAvailable = false
local initAttempted = false

-- Structure definition matching the DLL's output
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

--- Initialize the extended brake module
--- Attempts to connect to the cphys_data memory-mapped file
local function init()
    if initAttempted then return end
    initAttempted = true

    ac.log("Extended Brake: Attempting to connect to cphys_data memory-mapped file...")

    -- Try to read the memory-mapped file
    local success, result = pcall(function()
        return ac.readMemoryMappedFile("cphys_data", CPHYS_STRUCT, false)
    end)

    if success and result then
        cphysData = result
        cphysAvailable = true
        ac.log("Extended Brake: SUCCESS - cphys_data connected, brake pressure telemetry enabled")
        ac.log("Extended Brake: Source: cphys DLL (dwrite.dll) - using actual brake pressure in PSI")
    else
        cphysAvailable = false
        ac.log("Extended Brake: cphys_data not available - falling back to brake pedal position")
        ac.log("Extended Brake: To enable pressure telemetry, place dwrite.dll in AC root folder")
    end
end

-- Initialize on module load so status is logged at startup
init()

--- Check if extended brake pressure is available
---@return boolean True if cphys DLL data is available
function extended_brake.isAvailable()
    if not initAttempted then init() end
    return cphysAvailable
end

--- Get brake pressure in PSI (front wheel average or specified wheel)
--- Falls back to normalized brake pedal position if DLL not available
---@param car table|nil Car state from ac.getCar() - used for fallback
---@param wheel number|nil Optional wheel index (1-4, front-left, front-right, rear-left, rear-right)
---                         If nil, returns average of front brakes
---@return number Brake pressure in PSI (0-2000 typical range) or normalized 0-1 as fallback
---@return boolean True if returning actual PSI, false if returning normalized position
function extended_brake.getBrakePressure(car, wheel)
    if not initAttempted then init() end

    if cphysAvailable and cphysData then
        -- Try to read brake pressure from cphys
        local success, pressure = pcall(function()
            -- brakePressure is double2: (1) = front, (2) = rear
            if wheel then
                -- Wheels 1-2 are front, 3-4 are rear
                if wheel <= 2 then
                    return cphysData.brakePressure(1)  -- Front pressure
                else
                    return cphysData.brakePressure(2)  -- Rear pressure
                end
            else
                -- Return front pressure (most relevant for driver feel)
                return cphysData.brakePressure(1)
            end
        end)

        if success and pressure and pressure > 0 then
            return pressure, true
        end
    end

    -- Fallback to car brake position
    if car then
        return car.brake, false
    end

    return 0, false
end

--- Get normalized brake value (0-1) regardless of source
--- Uses brake pressure if available, otherwise pedal position
---@param car table Car state from ac.getCar()
---@param maxPressure number|nil Maximum pressure for normalization (default 2000 PSI)
---@return number Normalized brake value 0-1
function extended_brake.getNormalizedBrake(car, maxPressure)
    maxPressure = maxPressure or 2000  -- Typical max brake pressure in PSI

    local pressure, isPSI = extended_brake.getBrakePressure(car)

    if isPSI then
        -- Normalize PSI to 0-1 range
        return math.clamp(pressure / maxPressure, 0, 1)
    else
        -- Already normalized
        return pressure
    end
end

--- Get raw brake data with metadata
---@param car table Car state from ac.getCar()
---@return table { value, isPressure, unit, frontPressure, rearPressure }
function extended_brake.getBrakeData(car)
    if not initAttempted then init() end

    local data = {
        value = 0,
        isPressure = false,
        unit = "%",
        frontPressure = nil,
        rearPressure = nil,
    }

    if cphysAvailable and cphysData then
        local success, front, rear = pcall(function()
            return cphysData.brakePressure(1), cphysData.brakePressure(2)
        end)

        if success and front and front > 0 then
            data.value = front
            data.isPressure = true
            data.unit = "PSI"
            data.frontPressure = front
            data.rearPressure = rear
            return data
        end
    end

    -- Fallback
    if car then
        data.value = car.brake * 100  -- Convert to percentage
        data.unit = "%"
    end

    return data
end

--- Get status information for debugging/display
---@return table { available, source, status }
function extended_brake.getStatus()
    if not initAttempted then init() end

    return {
        available = cphysAvailable,
        source = cphysAvailable and "cphys DLL" or "car.brake",
        status = cphysAvailable and "connected" or "fallback mode"
    }
end

return extended_brake
