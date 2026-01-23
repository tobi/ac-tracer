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

-- Capture real file system functions (for read-only fallback)
local realIoOpen = io.open
local realOsRemove = os.remove

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

-- High-precision clock fallback for tests
os.preciseClock = os.preciseClock or os.clock

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
    isReplayActive = false,
    time = 0,
    gameTime = 0,
    currentSessionIndex = 0,
}

ac.getSim = function()
    return mockSim
end

-- Mock car state
local mockCar = {
    idValue = "test_car",
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
    isLastLapValid = true,
    previousLapTimeMs = 0,
    resetCounter = 0,
    wheelsOutside = 0,
    isInPitlane = false,
    isInPit = false,
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
    id = function(self)
        return self.idValue
    end,
}

ac.getCar = function(index)
    return mockCar
end

ac.getTrackID = function()
    return "test_track"
end

ac.getCarID = function(index)
    return "test_car"
end

ac.getCarName = function(index, withYear)
    return "Test Car"
end

-- Mock checkpoint/teleport APIs
ac.isCarResetAllowed = function()
    return true
end

ac.saveCarStateAsync = function(callback)
    ac._saveCalls = (ac._saveCalls or 0) + 1
    if type(callback) == "function" then
        callback(nil, { mock = "car_state" })
    end
end

ac.loadCarState = function(state0, state1, interpolation, flags)
    -- No-op in tests
end

local carJumpedCallbacks = {}
ac.onCarJumped = function(index, callback)
    if type(callback) == "function" then
        table.insert(carJumpedCallbacks, callback)
    end
end

ac._triggerCarJumped = function()
    for _, cb in ipairs(carJumpedCallbacks) do
        cb()
    end
end

ac.setMessage = function(title, message)
    ac._messages = ac._messages or {}
    table.insert(ac._messages, { title = title, message = message })
end

-- Mock audio API used by notification.lua
ac.AudioEvent = {
    fromFile = function(opts)
        return {
            isValid = function() return true end,
            start = function() end,
            stop = function() end,
            dispose = function() end,
            volume = 1.0,
            pitch = 1.0,
            cameraInteriorMultiplier = 1.0,
            cameraExteriorMultiplier = 1.0,
            cameraTrackMultiplier = 1.0,
        }
    end
}

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
        idValue = "test_car",
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
        isLastLapValid = true,
        previousLapTimeMs = 0,
        resetCounter = 0,
        wheelsOutside = 0,
        isInPitlane = false,
        isInPit = false,
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
        id = function(self)
            return self.idValue
        end,
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
    speedDropThreshold = function() return 25 end,
    useKMH = function() return true end,
    setUseKMH = function(v) end,
    maxHistoryLaps = function() return 20 end,
    comparisonMode = function() return "reference" end,
    brakeBeepMode = function() return "off" end,
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

--------------------------------------------------------------------------------
-- Virtual FS (side-effect free for unit tests)
--------------------------------------------------------------------------------

local vfs = {
    files = {},
    dirs = {},
}

local function normalizePath(path)
    if not path then return "" end
    local norm = tostring(path):gsub("\\", "/")
    norm = norm:gsub("/+", "/")
    if #norm > 1 and norm:sub(-1) == "/" then
        norm = norm:sub(1, -2)
    end
    return norm
end

local function dirname(path)
    local norm = normalizePath(path)
    local idx = norm:match("^.*()/")
    if not idx then return "" end
    return norm:sub(1, idx - 1)
end

local function ensureDir(path)
    local norm = normalizePath(path)
    if norm == "" then return end
    if vfs.dirs[norm] then return end
    local parent = dirname(norm)
    if parent ~= "" and not vfs.dirs[parent] then
        ensureDir(parent)
    end
    vfs.dirs[norm] = true
end

local function vfsFileHandle(content, writable, path)
    local buf = content or ""
    local cursor = 1

    local function readLine()
        if cursor > #buf then return nil end
        local nextIdx = buf:find("\n", cursor, true)
        local line
        if nextIdx then
            line = buf:sub(cursor, nextIdx - 1)
            cursor = nextIdx + 1
        else
            line = buf:sub(cursor)
            cursor = #buf + 1
        end
        if line:sub(-1) == "\r" then
            line = line:sub(1, -2)
        end
        return line
    end

    local handle = {}

    function handle:read(arg)
        if arg == nil or arg == "*l" then
            return readLine()
        elseif arg == "*a" then
            local out = buf:sub(cursor)
            cursor = #buf + 1
            return out
        elseif type(arg) == "number" then
            local out = buf:sub(cursor, cursor + arg - 1)
            cursor = math.min(#buf + 1, cursor + arg)
            return out ~= "" and out or nil
        end
        return nil
    end

    function handle:lines()
        return function()
            return readLine()
        end
    end

    function handle:write(chunk)
        if not writable then return false end
        buf = buf .. tostring(chunk)
        return true
    end

    function handle:seek(whence, offset)
        whence = whence or "cur"
        offset = offset or 0
        if whence == "set" then
            cursor = math.max(1, offset + 1)
        elseif whence == "cur" then
            cursor = math.max(1, cursor + offset)
        elseif whence == "end" then
            cursor = math.max(1, #buf + 1 + offset)
        end
        return cursor - 1
    end

    function handle:close()
        if writable and path then
            vfs.files[path] = buf
        end
        return true
    end

    return handle
end

io._vfs = vfs
io._vfsNormalize = normalizePath

ensureDir(".")

io.open = function(path, mode)
    mode = mode or "r"
    local norm = normalizePath(path)
    local isWrite = mode:find("w") or mode:find("a") or mode:find("%+")

    if isWrite then
        ensureDir(dirname(norm))
        local initial = ""
        if mode:find("a") and vfs.files[norm] then
            initial = vfs.files[norm]
        end
        return vfsFileHandle(initial, true, norm)
    end

    if vfs.files[norm] then
        return vfsFileHandle(vfs.files[norm], false)
    end

    if realIoOpen then
        return realIoOpen(path, mode)
    end

    return nil
end

-- io.dirExists - check virtual directories only
io.dirExists = function(path)
    local norm = normalizePath(path)
    return vfs.dirs[norm] or false
end

-- io.scanDir - scan virtual directory for files matching pattern
io.scanDir = function(path, pattern)
    local normDir = normalizePath(path)
    if not vfs.dirs[normDir] then
        return nil
    end

    local files = {}
    local suffix = nil
    if pattern and pattern:match("^%*%.") then
        suffix = pattern:sub(2):lower()
    end

    local prefix = normDir ~= "" and (normDir .. "/") or ""
    for filePath, _ in pairs(vfs.files) do
        if filePath:sub(1, #prefix) == prefix then
            local filename = filePath:sub(#prefix + 1)
            if not filename:find("/") then
                if not suffix or filename:lower():sub(-#suffix) == suffix then
                    table.insert(files, filename)
                end
            end
        end
    end

    return #files > 0 and files or nil
end

-- io.createDir - create virtual directory if missing
io.createDir = function(path)
    local norm = normalizePath(path)
    if io.dirExists(norm) then
        return true
    end
    ensureDir(norm)
    return true
end

-- io.fileExists - check if file exists (virtual first)
io.fileExists = function(path)
    local norm = normalizePath(path)
    if vfs.files[norm] then
        return true
    end
    if realIoOpen then
        local f = realIoOpen(path, "rb")
        if f then
            f:close()
            return true
        end
    end
    return false
end

-- io.fileSize - get file size in bytes (virtual first)
io.fileSize = function(path)
    local norm = normalizePath(path)
    if vfs.files[norm] then
        return #vfs.files[norm]
    end
    if realIoOpen then
        local f = realIoOpen(path, "rb")
        if f then
            local size = f:seek("end")
            f:close()
            return size
        end
    end
    return -1
end

-- Mock CSP setTimeout
setTimeout = setTimeout or function(fn, delay)
    if type(fn) == "function" then
        fn()
    end
end

-- Mock minimal UI API for draw tests
ui.availableSpace = ui.availableSpace or function()
    return vec2(300, 120)
end

ui.drawRectFilled = ui.drawRectFilled or function() end
ui.drawRect = ui.drawRect or function() end
ui.pathClear = ui.pathClear or function() end
ui.pathLineTo = ui.pathLineTo or function() end
ui.pathFillConvex = ui.pathFillConvex or function() end
ui.pathStroke = ui.pathStroke or function() end

ui.Font = ui.Font or { Main = 1, Monospace = 2, Title = 3, Small = 4 }
ui.StyleColor = ui.StyleColor or { Text = 1 }

ui.pushFont = ui.pushFont or function() end
ui.popFont = ui.popFont or function() end
ui.pushStyleColor = ui.pushStyleColor or function() end
ui.popStyleColor = ui.popStyleColor or function() end
ui.setCursor = ui.setCursor or function() end
ui.measureText = ui.measureText or function(text)
    local len = text and #tostring(text) or 0
    return vec2(len * 8, 12)
end
ui.text = ui.text or function(text)
    ui._textLog = ui._textLog or {}
    table.insert(ui._textLog, tostring(text))
end

-- Override os.remove for virtual files only
os.remove = function(path)
    local norm = normalizePath(path)
    if vfs.files[norm] then
        vfs.files[norm] = nil
        return true
    end
    return false
end

function mock.resetVfs()
    vfs.files = {}
    vfs.dirs = {}
    ensureDir(".")
end

function mock.vfsAddDir(path)
    ensureDir(normalizePath(path))
end

function mock.vfsWrite(path, content)
    local norm = normalizePath(path)
    ensureDir(dirname(norm))
    vfs.files[norm] = content or ""
end

function mock.vfsRead(path)
    local norm = normalizePath(path)
    return vfs.files[norm]
end

function mock.vfsSeedMotec(trackName)
    local motecDir = "C:\\MoTeC\\Logged Data\\"
    local filename1 = "beche_daytona_sim.csv"
    local filename2 = "beche_daytona_sim_1_40_1.csv"
    local path1 = motecDir .. filename1
    local path2 = motecDir .. filename2
    local trackValue = trackName or "test_track"

    local lines = {
        '"Format","MoTeC CSV File"',
        '"Sample Rate","30","Hz"',
        "",
        '"Time","Track","Lap Progression","Ground Speed","Driver Throttle Pos","Brake Pressure F","Brake Pressure R","Clutch Pos","Steering Angle","Fuel Remaining","Gear","G Force Lat","G Force Long"',
        '"s","","","km/h","%","bar","bar","%","deg","l","","g","g"',
        "",
    }

    -- Generate a longer lap with enough samples for tests (>100)
    for i = 0, 199 do
        local timeS = i / 30
        local pos = i / 200
        local speed = 100 + (i % 60)
        local throttle = math.min(1, (i % 100) / 100)
        local brake = (i % 40) == 0 and 20 or 0
        local steer = (i % 10) - 5
        local fuel = 50 - (i * 0.01)
        local gear = 3 + (i % 3)
        local gLat = (i % 10) * 0.02
        local gLong = (i % 10) * 0.01

        table.insert(lines, string.format(
            '"%.3f","%s","%.4f","%d","%.2f","%d","%d","0","%d","%.2f","%d","%.2f","%.2f"',
            timeS, trackValue, pos, speed, throttle, brake, brake, steer, fuel, gear, gLat, gLong
        ))
    end

    local content = table.concat(lines, "\n")

    mock.resetVfs()
    mock.vfsAddDir(motecDir)
    mock.vfsWrite(path1, content)
    mock.vfsWrite(path2, content)

    return { path1, path2 }
end

return mock
