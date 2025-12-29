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
-- Using C FFI syntax - arrays for multi-value fields
local CPHYS_STRUCT = [[
float FX[4];
float FY[4];
float carcassTemp[4];
float slipAngle[4];
float slipRatio[4];
float vkm[4];
float yawAngle;
float rollAngle;
float downforce[2];
float drag;
float accIMU[3];
float toe[4];
float damperTravel[4];
float engTorque;
float engThrottle;
double brakePressure[2];
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

        -- Test read to verify data is actually flowing
        local testSuccess, testFront, testRear = pcall(function()
            return result.brakePressure[0], result.brakePressure[1]
        end)
        if testSuccess then
            local total = (testFront or 0) + (testRear or 0)
            ac.log(string.format("Extended Brake: Initial read - Front: %.2f, Rear: %.2f, Total: %.2f PSI",
                testFront or 0, testRear or 0, total))
        else
            ac.log("Extended Brake: WARNING - Connected but failed to read brake pressure values")
        end
    else
        cphysAvailable = false
        ac.log("Extended Brake: cphys_data not available - falling back to brake pedal position")
        ac.log("Extended Brake: To enable pressure telemetry, place dwrite.dll in AC root folder")

        -- Diagnostic: Try to understand WHY it failed
        if not success then
            ac.log("Extended Brake: pcall failed - error: " .. tostring(result))
        elseif not result then
            ac.log("Extended Brake: readMemoryMappedFile returned nil (file doesn't exist or wrong format)")
        end

        -- Try some alternative memory-mapped file names the DLL might use
        local altNames = {"cphys", "acCphys", "ac_cphys", "Local\\cphys_data", "Global\\cphys_data"}
        for _, name in ipairs(altNames) do
            local altSuccess, altResult = pcall(function()
                return ac.readMemoryMappedFile(name, CPHYS_STRUCT, false)
            end)
            if altSuccess and altResult then
                ac.log("Extended Brake: Found alternative MMF name: " .. name)
                cphysData = altResult
                cphysAvailable = true
                break
            end
        end

        if not cphysAvailable then
            ac.log("Extended Brake: No memory-mapped file found with any known name")
            ac.log("Extended Brake: Check that dwrite.dll is in AC root and AC was restarted")
        end
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
            -- brakePressure is double[2]: [0] = front, [1] = rear
            if wheel then
                -- Wheels 1-2 are front, 3-4 are rear
                if wheel <= 2 then
                    return cphysData.brakePressure[0]  -- Front pressure
                else
                    return cphysData.brakePressure[1]  -- Rear pressure
                end
            else
                -- Return total brake pressure (front + rear)
                return cphysData.brakePressure[0] + cphysData.brakePressure[1]
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
---@param maxPressure number|nil Maximum pressure for normalization (default 4000 PSI for front+rear combined)
---@return number Normalized brake value 0-1
function extended_brake.getNormalizedBrake(car, maxPressure)
    maxPressure = maxPressure or 4000  -- Typical max combined brake pressure (front + rear) in PSI

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
            return cphysData.brakePressure[0], cphysData.brakePressure[1]
        end)

        if success and front then
            local total = (front or 0) + (rear or 0)
            if total > 0 then
                data.value = total
                data.isPressure = true
                data.unit = "PSI"
                data.frontPressure = front
                data.rearPressure = rear
                return data
            end
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
