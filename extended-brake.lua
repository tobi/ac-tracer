-- extended-brake.lua - Enhanced brake pressure from cphys DLL
-- Falls back to car.brake if DLL is not available
-- Uses cphys_data memory-mapped file from dwrite.dll (placed in AC root)

local extended_brake = {}

-- Conversion constant: 1 PSI = 0.0689476 bar
local PSI_TO_BAR = 0.0689476

-- Max brake pressure for normalization (100 bar, same as CSV import)
local MAX_PRESSURE_BAR = 100

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
        ac.log("Extended Brake: Source: cphys DLL (dwrite.dll) - using front brake pressure, normalizing to 100 bar")

        -- Test read to verify data is actually flowing
        local testSuccess, testFront = pcall(function()
            return result.brakePressure[0]
        end)
        if testSuccess then
            local frontBar = (testFront or 0) * PSI_TO_BAR
            ac.log(string.format("Extended Brake: Initial read - Front: %.2f PSI (%.2f bar)",
                testFront or 0, frontBar))
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

--- Get front brake pressure in PSI
--- Falls back to normalized brake pedal position if DLL not available
---@param car table|nil Car state from ac.getCar() - used for fallback
---@return number Brake pressure in PSI or normalized 0-1 as fallback
---@return boolean True if returning actual PSI, false if returning normalized position
function extended_brake.getBrakePressure(car)
    if not initAttempted then init() end

    if cphysAvailable and cphysData then
        -- Try to read front brake pressure from cphys
        local success, pressure = pcall(function()
            -- brakePressure is double[2]: [0] = front, [1] = rear
            -- Use front brake pressure only (matches CSV "brake pressure f")
            return cphysData.brakePressure[0]
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
--- Converts PSI to bar, then normalizes to 100 bar max (same as CSV import)
---@param car table Car state from ac.getCar()
---@return number Normalized brake value 0-1
function extended_brake.getNormalizedBrake(car)
    local pressure, isPSI = extended_brake.getBrakePressure(car)

    if isPSI then
        -- Convert PSI to bar, then normalize to 100 bar max
        local pressureBar = pressure * PSI_TO_BAR
        return math.clamp(pressureBar / MAX_PRESSURE_BAR, 0, 1)
    else
        -- Already normalized (fallback pedal position)
        return pressure
    end
end

--- Get raw brake data with metadata (values in bar)
---@param car table Car state from ac.getCar()
---@return table { value, isPressure, unit }
function extended_brake.getBrakeData(car)
    if not initAttempted then init() end

    local data = {
        value = 0,
        isPressure = false,
        unit = "%",
    }

    if cphysAvailable and cphysData then
        local success, front = pcall(function()
            return cphysData.brakePressure[0]
        end)

        if success and front and front > 0 then
            -- Convert PSI to bar (front brake only)
            data.value = front * PSI_TO_BAR
            data.isPressure = true
            data.unit = "bar"
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
