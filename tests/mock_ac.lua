-- mock_ac.lua - Mock CSP/AC environment for testing
-- Provides stub implementations of ac.*, ui.*, etc.

-- Create global namespaces that CSP provides
ac = ac or {}
ui = ui or {}
render = render or {}
physics = physics or {}
bit = bit or {}

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

-- Mock storage (in-memory)
local storageData = {}

ac.storage = setmetatable({}, {
    __index = function(t, k)
        return storageData[k]
    end,
    __newindex = function(t, k, v)
        storageData[k] = v
    end,
    __call = function(t, defaults)
        -- Return a table that auto-persists (simplified mock)
        local data = {}
        for k, v in pairs(defaults) do
            data[k] = storageData[k] or v
        end
        return setmetatable(data, {
            __newindex = function(self, k, v)
                rawset(self, k, v)
                storageData[k] = v
            end
        })
    end
})

-- Mock stringify (JSON-like serialization)
stringify = stringify or {}

stringify.binary = function(data)
    -- Simple JSON-like serialization for testing
    return "MOCK_BINARY:" .. tostring(data)
end

stringify.parse = function(str)
    -- For testing, just return nil (real impl would parse)
    if str:match("^MOCK_BINARY:") then
        return nil
    end
    -- Try to evaluate as Lua table literal (unsafe but ok for tests)
    local fn, err = load("return " .. str)
    if fn then
        return fn()
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
        -- Return a Lua table literal string for testing
        return serpent and serpent.dump(data) or tostring(data)
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

-- Mock extended-brake module (stub that returns car.brake)
package.loaded['extended-brake'] = {
    isAvailable = function() return false end,
    getBrakePressure = function(car) return car and car.brake or 0, false end,
    getNormalizedBrake = function(car) return car and car.brake or 0 end,
    getBrakeData = function(car) return { value = car and car.brake * 100 or 0, isPressure = false, unit = "%" } end,
    getFrontRearPressure = function(car) local b = car and car.brake or 0; return b, b, false end,
    getNormalizedFrontRear = function(car) local b = car and car.brake or 0; return b, b end,
    getStatus = function() return { available = false, source = "car.brake", status = "fallback mode" } end,
}

-- Mock app_settings module
package.loaded['app_settings'] = {
    brakeThreshold = 0.1,
    throttleThreshold = 0.98,
    useKMH = true,
}

-- Mock theme module (minimal stub for corner_analysis)
package.loaded['theme'] = {
    bg = { window = rgbm(0.1, 0.1, 0.1, 1), graph = rgbm(0.15, 0.15, 0.15, 1), panel = rgbm(0.12, 0.12, 0.12, 1) },
    text = { primary = rgbm(1, 1, 1, 1), muted = rgbm(0.6, 0.6, 0.6, 1) },
    delta = { positive = rgbm(0, 1, 0, 1), negative = rgbm(1, 0, 0, 1) },
    corner = { faster = rgbm(0, 0.8, 0, 0.6), slower = rgbm(0.8, 0, 0, 0.6), onSpeed = rgbm(0.5, 0.5, 0.5, 0.4), focusedBorder = rgbm(0.3, 0.5, 1, 1) },
    marker = { brake = rgbm(1, 0, 0, 1), brakeRef = rgbm(1, 0.3, 0.3, 0.6), apex = rgbm(1, 1, 0, 1), apexRef = rgbm(1, 1, 0.3, 0.6), lift = rgbm(0, 1, 0, 1), liftRef = rgbm(0.3, 1, 0.3, 0.6) },
    score = { bg = rgbm(0.3, 0.3, 0.3, 1), fill = rgbm(0, 0.8, 0.4, 1) },
    trace = { throttle = rgbm(0, 1, 0, 1), brake = rgbm(1, 0, 0, 1), fuel = rgbm(1, 0.6, 0, 1) },
    ghost = { throttle = rgbm(0, 0.5, 0, 0.5), brake = rgbm(0.5, 0, 0, 0.5) },
    grid = { major = rgbm(0.4, 0.4, 0.4, 1), line = rgbm(0.3, 0.3, 0.3, 0.5) },
    withAlpha = function(color, alpha) return rgbm(color.r, color.g, color.b, alpha) end,
}

-- Mock ui_utils module
package.loaded['ui_utils'] = {
    textFont = function() end,
    drawDashedLine = function() end,
}

return mock
