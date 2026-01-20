-- mock_ac.lua - Mock CSP/AC environment for testing
-- Provides stub implementations of ac.*, ui.*, etc.

-- Create global namespaces that CSP provides
ac = ac or {}
ui = ui or {}
render = render or {}
physics = physics or {}
bit = bit or {}

-- Mock __dirname (CSP provides this as the script's directory)
__dirname = __dirname or "."

-- Math extensions CSP provides
math.clamp = math.clamp or function(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

math.sign = math.sign or function(v)
    if v > 0 then return 1 end
    if v < 0 then return -1 end
    return 0
end

math.lerp = math.lerp or function(a, b, t)
    return a + (b - a) * t
end

math.saturate = math.saturate or function(v)
    return math.clamp(v, 0, 1)
end

math.round = math.round or function(v, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(v * mult + 0.5) / mult
end

-- Bit operations fallback
-- Lua 5.4 has native operators, Lua 5.3 has bit32, LuaJIT has bit
-- We provide a pure-Lua fallback that works everywhere
if not bit.band then
    -- Simple fallback using arithmetic (works for small values)
    bit.band = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 and b > 0 do
            if a % 2 == 1 and b % 2 == 1 then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
    bit.bor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if a % 2 == 1 or b % 2 == 1 then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
    bit.bxor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if (a % 2 == 1) ~= (b % 2 == 1) then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
    bit.bnot = function(a) return -1 - a end
    bit.lshift = function(a, n) return a * (2 ^ n) end
    bit.rshift = function(a, n) return math.floor(a / (2 ^ n)) end
end

-- Mock ac.ControlButton for hotkey bindings
ac.ControlButton = function(name, defaults)
    return {
        pressed = function() return false end,
        down = function() return false end,
        control = function(self, size) end,
    }
end

-- Mock ac functions
ac.log = function(msg)
    -- Silent by default, can be enabled for debugging
    -- print("[AC LOG] " .. tostring(msg))
end

ac.warn = function(msg)
    print("[AC WARN] " .. tostring(msg))
end

ac.error = function(msg)
    print("[AC ERROR] " .. tostring(msg))
end

-- Mock sim state
local mockSim = {
    trackLengthM = 5000,
    dt = 1/60,
    isPaused = false,
    time = 0,
    gameTime = 0,
}

ac.getSim = function()
    return mockSim
end

-- Mock car state  
local mockCar = {
    id = "test_car",
    speedKmh = 100,
    splinePosition = 0.5,
    lapCount = 1,
    lapTimeMs = 30000,
    bestLapTimeMs = 90000,
    gas = 0.5,
    brake = 0.2,
    clutch = 0.0,
    steer = 0,
    gear = 3,
    fuel = 50,
    isLapValid = true,
    resetCounter = 0,
    wheelsOutside = 0,
    tractionControlInAction = false,
    isEngineLimiterOn = false,
    wheels = {
        [0] = { slip = 0.05, ndSlip = 0.05 },
        [1] = { slip = 0.05, ndSlip = 0.05 },
        [2] = { slip = 0.05, ndSlip = 0.05 },
        [3] = { slip = 0.05, ndSlip = 0.05 },
    },
    acceleration = { x = 0, y = 0, z = 0 },
    brakeBias = 0.55,
    tractionControlMode = 5,
    tractionControl2 = 50,
}

ac.getCar = function(index)
    return mockCar
end

ac.getTrackID = function()
    return "test_track"
end

-- Mock memory-mapped file reading (for cphys DLL / dwrite.dll)
-- Returns nil to simulate DLL not being present (fallback mode)
ac.readMemoryMappedFile = function(name, struct, readOnly)
    -- Return nil to trigger fallback to car.brake
    return nil
end

-- Mock storage (in-memory)
local storageData = {}

ac.storage = setmetatable({}, {
    __index = function(t, k)
        return storageData[k]
    end,
    __newindex = function(t, k, v)
        storageData[k] = v
    end,
    __call = function(t, defaults, prefix)
        -- Return a table that auto-persists (simplified mock)
        -- prefix is optional and ignored in mock (would be used for key namespacing)
        local data = {}
        for k, v in pairs(defaults) do
            local storageKey = prefix and (prefix .. k) or k
            data[k] = storageData[storageKey] or v
        end
        return setmetatable(data, {
            __newindex = function(self, k, v)
                rawset(self, k, v)
                local storageKey = prefix and (prefix .. k) or k
                storageData[storageKey] = v
            end
        })
    end
})

-- Mock stringify (JSON-like serialization)
stringify = stringify or {}

-- Simple table serializer for testing (produces Lua table literals)
local function serializeValue(v, seen)
    local t = type(v)
    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        if seen[v] then return "nil" end  -- Avoid cycles
        seen[v] = true
        local parts = {}
        local isArray = true
        local maxIdx = 0
        for k, _ in pairs(v) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                isArray = false
            else
                maxIdx = math.max(maxIdx, k)
            end
        end
        if isArray and maxIdx == #v then
            -- Array-like
            for i = 1, #v do
                table.insert(parts, serializeValue(v[i], seen))
            end
        else
            -- Dictionary-like
            for k, val in pairs(v) do
                local keyStr
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. serializeValue(k, seen) .. "]"
                end
                table.insert(parts, keyStr .. "=" .. serializeValue(val, seen))
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    else
        return "nil"  -- functions, userdata, etc.
    end
end

stringify.binary = function(data)
    return serializeValue(data, {})
end

stringify.parse = function(str)
    if not str or str == "" then return nil end
    -- Try to evaluate as Lua table literal (unsafe but ok for tests)
    local fn, err = load("return " .. str)
    if fn then
        local ok, result = pcall(fn)
        if ok then return result end
    end
    return nil
end

stringify.tryParse = function(str, default)
    local result = stringify.parse(str)
    return result or default
end

-- Allow stringify(data) as shorthand
setmetatable(stringify, {
    __call = function(t, data)
        return serializeValue(data, {})
    end
})

-- Mock vec2/vec3/vec4 constructors
vec2 = function(x, y)
    return { x = x or 0, y = y or 0 }
end

vec3 = function(x, y, z)
    return { x = x or 0, y = y or 0, z = z or 0 }
end

vec4 = function(x, y, z, w)
    return { x = x or 0, y = y or 0, z = z or 0, w = w or 0 }
end

-- Mock rgb/rgbm colors
rgb = function(r, g, b)
    return { r = r or 0, g = g or 0, b = b or 0 }
end

local function make_rgbm(r, g, b, m)
    return { r = r or 0, g = g or 0, b = b or 0, mult = m or 1 }
end

rgbm = setmetatable({
    colors = {
        white = make_rgbm(1, 1, 1, 1),
        black = make_rgbm(0, 0, 0, 1),
        red = make_rgbm(1, 0, 0, 1),
        green = make_rgbm(0, 1, 0, 1),
        blue = make_rgbm(0, 0, 1, 1),
        yellow = make_rgbm(1, 1, 0, 1),
    }
}, {
    __call = function(_, r, g, b, m)
        return make_rgbm(r, g, b, m)
    end
})

-- Helper to update mock car state
local mock = {}

function mock.setCar(overrides)
    for k, v in pairs(overrides) do
        mockCar[k] = v
    end
end

function mock.setSim(overrides)
    for k, v in pairs(overrides) do
        mockSim[k] = v
    end
end

function mock.resetCar()
    mockCar = {
        id = "test_car",
        speedKmh = 100,
        splinePosition = 0.5,
        lapCount = 1,
        lapTimeMs = 30000,
        bestLapTimeMs = 90000,
        gas = 0.5,
        brake = 0.2,
        clutch = 0.0,
        steer = 0,
        gear = 3,
        fuel = 50,
        isLapValid = true,
        resetCounter = 0,
        wheelsOutside = 0,
        tractionControlInAction = false,
        isEngineLimiterOn = false,
        wheels = {
            [0] = { slip = 0.05, ndSlip = 0.05 },
            [1] = { slip = 0.05, ndSlip = 0.05 },
            [2] = { slip = 0.05, ndSlip = 0.05 },
            [3] = { slip = 0.05, ndSlip = 0.05 },
        },
        acceleration = { x = 0, y = 0, z = 0 },
        brakeBias = 0.55,
        tractionControlMode = 5,
        tractionControl2 = 50,
    }
end

function mock.clearStorage()
    storageData = {}
end

-- Mock extended-brake module (stub that returns car.brake converted to bar)
-- Convention: 100% pedal = 100 bar
local FALLBACK_MAX_BAR = 100
package.loaded['extended-brake'] = {
    isAvailable = function() return false end,
    -- New bar-based API
    getBrakePressureBar = function(car) 
        local pedal = car and car.brake or 0
        return pedal * FALLBACK_MAX_BAR, false 
    end,
    getFrontRearBar = function(car) 
        local pedal = car and car.brake or 0
        local bar = pedal * FALLBACK_MAX_BAR
        return bar, bar, false 
    end,
    getBrakeData = function(car) 
        local pedal = car and car.brake or 0
        return { value = pedal * FALLBACK_MAX_BAR, isFromDLL = false, unit = "bar" } 
    end,
    -- Legacy aliases (now call bar versions)
    getBrakePressure = function(car) 
        local pedal = car and car.brake or 0
        return pedal * FALLBACK_MAX_BAR, false 
    end,
    getFrontRearPressure = function(car) 
        local pedal = car and car.brake or 0
        local bar = pedal * FALLBACK_MAX_BAR
        return bar, bar, false 
    end,
    -- Normalized (legacy)
    getNormalizedBrake = function(car) return car and car.brake or 0 end,
    getNormalizedFrontRear = function(car) local b = car and car.brake or 0; return b, b end,
    getStatus = function() return { available = false, source = "car.brake", status = "fallback mode" } end,
}

-- Mock app_settings module (settings are accessed via functions)
package.loaded['app_settings'] = {
    brakeThreshold = function() return 5 end,
    throttleThreshold = function() return 0.98 end,
    useKMH = function() return true end,
    setUseKMH = function(v) end,
    maxHistoryLaps = function() return 20 end,
    showFlagMarker = function(name) return false end,
    telemetryShowLateralG = function() return false end,
    telemetryShowLongG = function() return false end,
    telemetryShowSpeed = function() return true end,
    telemetryShowThrottle = function() return true end,
    telemetryShowBrake = function() return true end,
    telemetryShowSteering = function() return true end,
    telemetryShowGear = function() return true end,
}

-- Mock theme module (minimal stub for corner_analysis)
package.loaded['theme'] = {
    bg = { window = rgbm(0.1, 0.1, 0.1, 1), graph = rgbm(0.15, 0.15, 0.15, 1), panel = rgbm(0.12, 0.12, 0.12, 1) },
    text = { primary = rgbm(1, 1, 1, 1), muted = rgbm(0.6, 0.6, 0.6, 1) },
    delta = { positive = rgbm(0, 1, 0, 1), negative = rgbm(1, 0, 0, 1), neutral = rgbm(1, 1, 1, 1) },
    corner = { faster = rgbm(0, 0.8, 0, 0.6), slower = rgbm(0.8, 0, 0, 0.6), onSpeed = rgbm(0.5, 0.5, 0.5, 0.4), focusedBorder = rgbm(0.3, 0.5, 1, 1) },
    marker = { brake = rgbm(1, 0, 0, 1), brakeRef = rgbm(1, 0.3, 0.3, 0.6), apex = rgbm(1, 1, 0, 1), apexRef = rgbm(1, 1, 0.3, 0.6), lift = rgbm(0, 1, 0, 1), liftRef = rgbm(0.3, 1, 0.3, 0.6) },
    score = { bg = rgbm(0.3, 0.3, 0.3, 1), fill = rgbm(0, 0.8, 0.4, 1) },
    trace = { throttle = rgbm(0, 1, 0, 1), brake = rgbm(1, 0, 0, 1), fuel = rgbm(1, 0.6, 0, 1) },
    ghost = { throttle = rgbm(0, 0.5, 0, 0.5), brake = rgbm(0.5, 0, 0, 0.5) },
    grid = { major = rgbm(0.4, 0.4, 0.4, 1), line = rgbm(0.3, 0.3, 0.3, 0.5) },
    withAlpha = function(color, alpha) return rgbm(color.r, color.g, color.b, alpha) end,
}

-- NOTE: ui_utils is NOT mocked here - it loads the real module
-- This allows test_ui_utils.lua to test the actual implementation

-- Mock CSP io extensions using LuaJIT FFI for directory operations
local ffi = require("ffi")

-- Windows API declarations for directory listing
ffi.cdef[[
    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef void* HANDLE;
    typedef const char* LPCSTR;
    
    // FILETIME is two DWORDs
    typedef struct {
        DWORD dwLowDateTime;
        DWORD dwHighDateTime;
    } FILETIME;
    
    typedef struct {
        DWORD dwFileAttributes;
        FILETIME ftCreationTime;
        FILETIME ftLastAccessTime;
        FILETIME ftLastWriteTime;
        DWORD nFileSizeHigh;
        DWORD nFileSizeLow;
        DWORD dwReserved0;
        DWORD dwReserved1;
        char cFileName[260];
        char cAlternateFileName[14];
    } WIN32_FIND_DATAA;
    
    HANDLE FindFirstFileA(LPCSTR lpFileName, WIN32_FIND_DATAA* lpFindFileData);
    BOOL FindNextFileA(HANDLE hFindFile, WIN32_FIND_DATAA* lpFindFileData);
    BOOL FindClose(HANDLE hFindFile);
    DWORD GetFileAttributesA(LPCSTR lpFileName);
    BOOL CreateDirectoryA(LPCSTR lpPathName, void* lpSecurityAttributes);
]]

local INVALID_HANDLE_VALUE = ffi.cast("HANDLE", -1)
local FILE_ATTRIBUTE_DIRECTORY = 0x10
local INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF

-- io.fileExists - check if file exists
io.fileExists = io.fileExists or function(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- io.dirExists - check if directory exists using Windows API
io.dirExists = io.dirExists or function(path)
    local attrs = ffi.C.GetFileAttributesA(path)
    if attrs == INVALID_FILE_ATTRIBUTES then
        return false
    end
    return bit.band(attrs, FILE_ATTRIBUTE_DIRECTORY) ~= 0
end

-- io.scanDir - scan directory for files matching pattern using Windows API
io.scanDir = io.scanDir or function(path, pattern)
    -- Normalize path and add wildcard
    path = path:gsub("/", "\\")
    if path:sub(-1) ~= "\\" then path = path .. "\\" end
    
    local searchPattern = path .. (pattern or "*")
    
    local findData = ffi.new("WIN32_FIND_DATAA")
    local handle = ffi.C.FindFirstFileA(searchPattern, findData)
    
    if handle == INVALID_HANDLE_VALUE then
        return nil
    end
    
    local files = {}
    repeat
        local name = ffi.string(findData.cFileName)
        -- Skip . and .. directories
        if name ~= "." and name ~= ".." then
            -- Skip directories, only return files
            if bit.band(findData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY) == 0 then
                table.insert(files, name)
            end
        end
    until ffi.C.FindNextFileA(handle, findData) == 0
    
    ffi.C.FindClose(handle)
    
    return #files > 0 and files or nil
end

-- io.createDir - create directory if missing
io.createDir = io.createDir or function(path)
    if io.dirExists(path) then
        return true
    end
    ffi.C.CreateDirectoryA(path, nil)
    return io.dirExists(path)
end

-- io.fileSize - get file size in bytes
io.fileSize = io.fileSize or function(path)
    local f = io.open(path, "rb")
    if f then
        local size = f:seek("end")
        f:close()
        return size
    end
    return -1
end

return mock
