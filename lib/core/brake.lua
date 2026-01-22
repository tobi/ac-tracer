-- extended-brake.lua - Enhanced brake pressure from cphys DLL
-- Falls back to car.brake if DLL is not available
-- Uses cphys_data memory-mapped file from dwrite.dll (placed in AC root)
--
-- CONVENTION: All brake values are returned in BAR (not normalized 0-1)
-- - With cphys DLL: actual brake pressure in bar
-- - Without DLL: pedal position * 100 (assumes 100% = 100 bar)

local extended_brake = {}

-- Conversion constant: 1 PSI = 0.0689476 bar
local PSI_TO_BAR = 0.0689476

-- Fallback assumption: 100% pedal = 100 bar
local FALLBACK_MAX_BAR = 100

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

--- Get front brake pressure in BAR
--- Falls back to pedal position * 100 if DLL not available
---@param car table|nil Car state from ac.getCar() - used for fallback
---@return number Brake pressure in bar
---@return boolean True if returning actual pressure from DLL
function extended_brake.getBrakePressureBar(car)
    if not initAttempted then init() end

    if cphysAvailable and cphysData then
        -- Try to read front brake pressure from cphys (returns PSI)
        local success, pressurePSI = pcall(function()
            -- brakePressure is double[2]: [0] = front, [1] = rear
            return cphysData.brakePressure[0]
        end)

        if success and pressurePSI and pressurePSI > 0 then
            return pressurePSI * PSI_TO_BAR, true
        end
    end

    -- Fallback: assume 100% pedal = 100 bar
    if car then
        return car.brake * FALLBACK_MAX_BAR, false
    end

    return 0, false
end

-- Legacy alias for compatibility
extended_brake.getBrakePressure = extended_brake.getBrakePressureBar

--- Get normalized brake value (0-1) for legacy code
--- DEPRECATED: Use getBrakePressureBar() and divide by your scale
---@param car table Car state from ac.getCar()
---@return number Normalized brake value 0-1 (based on 100 bar max)
function extended_brake.getNormalizedBrake(car)
    local pressureBar = extended_brake.getBrakePressureBar(car)
    return math.clamp(pressureBar / FALLBACK_MAX_BAR, 0, 1)
end

--- Get raw brake data with metadata (always in bar)
---@param car table Car state from ac.getCar()
---@return table { value, isFromDLL, unit }
function extended_brake.getBrakeData(car)
    local pressureBar, isFromDLL = extended_brake.getBrakePressureBar(car)
    return {
        value = pressureBar,
        isFromDLL = isFromDLL,
        unit = "bar",
    }
end

--- Get front and rear brake pressure in bar
--- Falls back to pedal * 100 for both if DLL not available
---@param car table Car state from ac.getCar()
---@return number frontBar Front brake pressure in bar
---@return number rearBar Rear brake pressure in bar
---@return boolean isFromDLL True if returning actual pressure from DLL
function extended_brake.getFrontRearBar(car)
    if not initAttempted then init() end

    if cphysAvailable and cphysData then
        local success, frontPSI, rearPSI = pcall(function()
            return cphysData.brakePressure[0], cphysData.brakePressure[1]
        end)

        if success and frontPSI and rearPSI then
            return frontPSI * PSI_TO_BAR, rearPSI * PSI_TO_BAR, true
        end
    end

    -- Fallback: assume 100% pedal = 100 bar for both
    local pedal = car and car.brake or 0
    local fallbackBar = pedal * FALLBACK_MAX_BAR
    return fallbackBar, fallbackBar, false
end

-- Legacy alias
extended_brake.getFrontRearPressure = extended_brake.getFrontRearBar

--- Get normalized front and rear brake values (0-1)
--- DEPRECATED: Use getFrontRearBar() and divide by your scale
---@param car table Car state from ac.getCar()
---@return number frontNorm Normalized front brake 0-1
---@return number rearNorm Normalized rear brake 0-1
function extended_brake.getNormalizedFrontRear(car)
    local frontBar, rearBar = extended_brake.getFrontRearBar(car)
    return math.clamp(frontBar / FALLBACK_MAX_BAR, 0, 1),
           math.clamp(rearBar / FALLBACK_MAX_BAR, 0, 1)
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
