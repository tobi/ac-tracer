--[[
CSP Compatibility Layer for LÖVE2D
Maps CSP's ui.*, ac.*, render.* APIs to LÖVE equivalents

This allows ac-tracer code to run with minimal changes in the simulator.
Note: LÖVE uses a different paradigm than ImGui, so some approximations are made.
]]

--------------------------------------------------------------------------------
-- Global State
--------------------------------------------------------------------------------

_G._mockCarPosition = 0
_G._playbackLap = nil
_G._windowSize = { x = 400, y = 200 }
_G._cursorPos = { x = 0, y = 0 }
_G._pathPoints = {}
_G._fontStack = {}
_G._colorStack = {}

--------------------------------------------------------------------------------
-- Math Extensions
--------------------------------------------------------------------------------

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

os.preciseClock = os.preciseClock or function()
    if love and love.timer then
        return love.timer.getTime()
    end
    return os.clock()
end

--------------------------------------------------------------------------------
-- Bit Operations
--------------------------------------------------------------------------------

bit = bit or {}
if not bit.band then
    bit.band = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 and b > 0 do
            if a % 2 == 1 and b % 2 == 1 then result = result + bitval end
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
            if a % 2 == 1 or b % 2 == 1 then result = result + bitval end
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
            if (a % 2 == 1) ~= (b % 2 == 1) then result = result + bitval end
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

--------------------------------------------------------------------------------
-- Vector Types
--------------------------------------------------------------------------------

local function vec2(x, y)
    return { x = x or 0, y = y or 0 }
end

local function vec3(x, y, z)
    return { x = x or 0, y = y or 0, z = z or 0 }
end

local function vec4(x, y, z, w)
    return { x = x or 0, y = y or 0, z = z or 0, w = w or 0 }
end

local function rgb(r, g, b)
    return { r = r or 0, g = g or 0, b = b or 0 }
end

local function make_rgbm(r, g, b, m)
    return { r = r or 0, g = g or 0, b = b or 0, mult = m or 1 }
end

local rgbm = setmetatable({
    colors = {
        white = make_rgbm(1, 1, 1, 1),
        black = make_rgbm(0, 0, 0, 1),
        red = make_rgbm(1, 0, 0, 1),
        green = make_rgbm(0, 1, 0, 1),
        blue = make_rgbm(0, 0, 1, 1),
        yellow = make_rgbm(1, 1, 0, 1),
        transparent = make_rgbm(0, 0, 0, 0),
    }
}, {
    __call = function(_, r, g, b, m)
        return make_rgbm(r, g, b, m)
    end
})

_G.vec2 = vec2
_G.vec3 = vec3
_G.vec4 = vec4
_G.rgb = rgb
_G.rgbm = rgbm

--------------------------------------------------------------------------------
-- Color Helper
--------------------------------------------------------------------------------

local function setColor(color)
    if not love or not love.graphics then return end
    if not color then
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    local r = math.min(1, (color.r or 1) * (color.mult or 1))
    local g = math.min(1, (color.g or 1) * (color.mult or 1))
    local b = math.min(1, (color.b or 1) * (color.mult or 1))
    local a = math.min(1, color.mult or 1)
    love.graphics.setColor(r, g, b, a)
end

--------------------------------------------------------------------------------
-- ac.* API
--------------------------------------------------------------------------------

ac = {}

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
    if love and love.timer then
        mockSim.dt = love.timer.getDelta()
    end
    return mockSim
end

ac.getCar = function(index)
    local pos = _G._mockCarPosition or 0
    local lapData = _G._playbackLap

    if lapData then
        return {
            idValue = lapData.car or "sim_car",
            speedKmh = lapData:speedAt(pos),
            splinePosition = pos,
            lapCount = 1,
            lapTimeMs = (lapData:timeAt(pos) or 0) * 1000,
            bestLapTimeMs = lapData.time or 90000,
            gas = lapData:throttleAt(pos),
            brake = (lapData:brakeAt(pos) or 0) / 100,
            clutch = lapData.clutchAt and lapData:clutchAt(pos) or 0,
            steer = (0.5 - (lapData:steeringAt(pos) or 0.5)) * 2 * math.pi,
            gear = lapData:gearAt(pos),
            fuel = lapData.fuelAt and lapData:fuelAt(pos) or 50,
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
            id = function(self) return self.idValue end,
        }
    end

    -- Default when no lap loaded
    return {
        idValue = "sim_car",
        speedKmh = 0,
        splinePosition = pos,
        lapCount = 1,
        lapTimeMs = 0,
        bestLapTimeMs = 90000,
        gas = 0,
        brake = 0,
        clutch = 0,
        steer = 0,
        gear = 1,
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
        id = function(self) return self.idValue end,
    }
end

ac.getTrackID = function()
    local lapData = _G._playbackLap
    return lapData and lapData.track or "sim_track"
end

ac.getCarID = function(index)
    local lapData = _G._playbackLap
    return lapData and lapData.car or "sim_car"
end

ac.getCarName = function(index, withYear)
    return "Simulator Car"
end

ac.log = function(msg) print("[AC LOG] " .. tostring(msg)) end
ac.warn = function(msg) print("[AC WARN] " .. tostring(msg)) end
ac.error = function(msg) print("[AC ERROR] " .. tostring(msg)) end
ac.setMessage = function(title, message) print(string.format("[AC MSG] %s: %s", title, message)) end

ac.setClipboardText = function(text)
    if love and love.system then
        love.system.setClipboardText(text)
    end
end

ac.isCarResetAllowed = function() return true end
ac.saveCarStateAsync = function(callback) if callback then callback(nil, { mock = "state" }) end end
ac.loadCarState = function() end

ac.onCarJumped = function(index, callback) end

ac.trackCoordinateToWorld = function(vec)
    return vec3(vec.x * 10, vec.y, vec.z * mockSim.trackLengthM)
end

ac.getTrackSectorName = function(pos) return "Sector" end

ac.readMemoryMappedFile = function() return nil end

ac.ControlButton = function(name, defaults)
    return {
        pressed = function() return false end,
        down = function() return false end,
        control = function(self, size) end,
    }
end

ac.accessAppWindow = function(name)
    return {
        valid = function() return true end,
        visible = function() return true end,
    }
end

ac.AudioEvent = {
    fromFile = function(opts)
        return {
            isValid = function() return false end,
            start = function() end,
            stop = function() end,
            dispose = function() end,
            volume = 1.0,
            pitch = 1.0,
        }
    end
}

-- Storage (in-memory)
local storageData = {}
ac.storage = setmetatable({}, {
    __index = function(t, k) return storageData[k] end,
    __newindex = function(t, k, v) storageData[k] = v end,
    __call = function(t, defaults, prefix)
        local data = {}
        for k, v in pairs(defaults) do
            local storageKey = prefix and (prefix .. k) or k
            data[k] = storageData[storageKey]
            if data[k] == nil then data[k] = v end
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

--------------------------------------------------------------------------------
-- ui.* API (LÖVE graphics)
--------------------------------------------------------------------------------

ui = {}

-- Enums
ui.Font = { Main = 1, Monospace = 2, Title = 3, Small = 4 }
ui.StyleColor = { Text = 1, Button = 2, ButtonHovered = 3, FrameBg = 4 }
ui.StyleVar = { FramePadding = 1, ItemSpacing = 2 }
ui.InputTextFlags = { None = 0 }
ui.MouseButton = { Left = 1, Right = 2, Middle = 3 }

ui.DWriteFont = function(name)
    return { weight = function(self, w) return self end }
end

-- Layout
ui.availableSpace = function()
    return _G._windowSize
end

ui.availableSpaceX = function()
    return _G._windowSize.x
end

ui.setCursor = function(pos)
    _G._cursorPos = { x = pos.x or 0, y = pos.y or 0 }
end

ui.getCursor = function()
    return _G._cursorPos
end

ui.offsetCursorY = function(amount)
    _G._cursorPos.y = _G._cursorPos.y + amount
end

ui.sameLine = function(x) end

ui.setNextItemWidth = function(width) end

ui.windowPos = function()
    return vec2(0, 0)
end

ui.measureText = function(text)
    if love and love.graphics then
        local font = love.graphics.getFont()
        if font then
            return vec2(font:getWidth(tostring(text)), font:getHeight())
        end
    end
    return vec2(#tostring(text) * 8, 14)
end

-- Font/Style stack
ui.pushFont = function(font) table.insert(_G._fontStack, font) end
ui.popFont = function() table.remove(_G._fontStack) end
ui.pushStyleColor = function(style, color) table.insert(_G._colorStack, color) end
ui.popStyleColor = function(count) for i = 1, (count or 1) do table.remove(_G._colorStack) end end
ui.pushStyleVar = function(var, value) end
ui.popStyleVar = function(count) end
ui.pushItemWidth = function(width) end
ui.popItemWidth = function() end

-- Text
ui.text = function(text)
    if not love or not love.graphics then return end
    setColor(rgbm.colors.white)
    love.graphics.print(tostring(text), _G._cursorPos.x, _G._cursorPos.y)
    local font = love.graphics.getFont()
    if font then
        _G._cursorPos.y = _G._cursorPos.y + font:getHeight() + 2
    end
end

ui.textColored = function(text, color)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.print(tostring(text), _G._cursorPos.x, _G._cursorPos.y)
    local font = love.graphics.getFont()
    if font then
        _G._cursorPos.y = _G._cursorPos.y + font:getHeight() + 2
    end
end

ui.textAligned = function(text, align, size)
    if not love or not love.graphics then return end
    setColor(rgbm.colors.white)
    local alignStr = "left"
    if align and align.x then
        if align.x > 0.6 then alignStr = "right"
        elseif align.x > 0.3 then alignStr = "center"
        end
    end
    local w = size and size.x or _G._windowSize.x
    love.graphics.printf(tostring(text), _G._cursorPos.x, _G._cursorPos.y, w, alignStr)
end

ui.dwriteDrawTextClipped = function(text, fontSize, topLeft, bottomRight, alignX, alignY, rtl, color)
    if not love or not love.graphics then return end
    setColor(color)
    local alignStr = "left"
    if alignX then
        if alignX > 0.6 then alignStr = "right"
        elseif alignX > 0.3 then alignStr = "center"
        end
    end
    local w = bottomRight.x - topLeft.x
    love.graphics.printf(tostring(text), topLeft.x, topLeft.y, w, alignStr)
end

-- Drawing primitives
ui.drawLine = function(p1, p2, color, thickness)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.setLineWidth(thickness or 1)
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

ui.drawRect = function(p1, p2, color, cornerRadius, thickness)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.setLineWidth(thickness or 1)
    love.graphics.rectangle("line", p1.x, p1.y, p2.x - p1.x, p2.y - p1.y, cornerRadius or 0)
end

ui.drawRectFilled = function(p1, p2, color, cornerRadius)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.rectangle("fill", p1.x, p1.y, p2.x - p1.x, p2.y - p1.y, cornerRadius or 0)
end

ui.drawCircle = function(center, radius, color, segments)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.circle("line", center.x, center.y, radius, segments or 32)
end

ui.drawCircleFilled = function(center, radius, color, segments)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.circle("fill", center.x, center.y, radius, segments or 32)
end

ui.drawTriangleFilled = function(p1, p2, p3, color)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.polygon("fill", p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)
end

ui.drawQuadFilled = function(p1, p2, p3, p4, color)
    if not love or not love.graphics then return end
    setColor(color)
    love.graphics.polygon("fill", p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)
end

-- Path drawing
ui.pathClear = function()
    _G._pathPoints = {}
end

ui.pathLineTo = function(point)
    table.insert(_G._pathPoints, point.x)
    table.insert(_G._pathPoints, point.y)
end

ui.pathArcTo = function(center, radius, angleStart, angleEnd, segments)
    segments = segments or 16
    local step = (angleEnd - angleStart) / segments
    for i = 0, segments do
        local angle = angleStart + step * i
        table.insert(_G._pathPoints, center.x + math.cos(angle) * radius)
        table.insert(_G._pathPoints, center.y + math.sin(angle) * radius)
    end
end

ui.pathStroke = function(color, closed, thickness)
    if not love or not love.graphics then _G._pathPoints = {} return end
    if #_G._pathPoints >= 4 then
        setColor(color)
        love.graphics.setLineWidth(thickness or 1)
        if closed then
            love.graphics.polygon("line", _G._pathPoints)
        else
            love.graphics.line(_G._pathPoints)
        end
    end
    _G._pathPoints = {}
end

ui.pathFillConvex = function(color)
    if not love or not love.graphics then _G._pathPoints = {} return end
    if #_G._pathPoints >= 6 then
        setColor(color)
        love.graphics.polygon("fill", _G._pathPoints)
    end
    _G._pathPoints = {}
end

-- Controls (stubs)
ui.button = function(label, size) return false end
ui.checkbox = function(label, isChecked) return isChecked end
ui.radioButton = function(label, isSelected) return isSelected end
ui.slider = function(id, value, min, max, format) return value end
ui.inputText = function(id, text, flags) return text, false end
ui.header = function(label) return true end
ui.childWindow = function(id, size, fn) if fn then fn() end end
ui.dummy = function(size) end
ui.invisibleButton = function(id, size) return false end
ui.setTooltip = function(text) end

-- Mouse input
ui.mouseClicked = function(button)
    if love and love.mouse then
        return love.mouse.isDown(button or 1)
    end
    return false
end

ui.mouseDown = function(button)
    if love and love.mouse then
        return love.mouse.isDown(button or 1)
    end
    return false
end

ui.mousePos = function()
    if love and love.mouse then
        local x, y = love.mouse.getPosition()
        return vec2(x, y)
    end
    return vec2(0, 0)
end

ui.mouseWheel = function()
    return 0
end

ui.rectHovered = function(p1, p2)
    if love and love.mouse then
        local x, y = love.mouse.getPosition()
        return x >= p1.x and x <= p2.x and y >= p1.y and y <= p2.y
    end
    return false
end

ui.itemHovered = function()
    return false
end

--------------------------------------------------------------------------------
-- render.* API
--------------------------------------------------------------------------------

render = {}
render.debugLine = function(p1, p2, color1, color2) end

--------------------------------------------------------------------------------
-- physics.* API
--------------------------------------------------------------------------------

physics = {}

--------------------------------------------------------------------------------
-- stringify
--------------------------------------------------------------------------------

local function serializeValue(v, seen)
    local t = type(v)
    if t == "nil" then return "nil"
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "number" then return tostring(v)
    elseif t == "string" then return string.format("%q", v)
    elseif t == "table" then
        if seen[v] then return "nil" end
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
            for i = 1, #v do
                table.insert(parts, serializeValue(v[i], seen))
            end
        else
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
        return "nil"
    end
end

stringify = setmetatable({
    binary = function(data) return serializeValue(data, {}) end,
    parse = function(str)
        if not str or str == "" then return nil end
        local fn = load("return " .. str)
        if fn then
            local ok, result = pcall(fn)
            if ok then return result end
        end
        return nil
    end,
    tryParse = function(str, default)
        return stringify.parse(str) or default
    end
}, {
    __call = function(t, data)
        return serializeValue(data, {})
    end
})

--------------------------------------------------------------------------------
-- setTimeout
--------------------------------------------------------------------------------

setTimeout = function(fn, delay)
    if type(fn) == "function" then fn() end
end

--------------------------------------------------------------------------------
-- __dirname
--------------------------------------------------------------------------------

__dirname = "."
if love and love.filesystem then
    __dirname = love.filesystem.getSource() .. "/.."
end

--------------------------------------------------------------------------------
-- io extensions
--------------------------------------------------------------------------------

io.createDir = function(path)
    if love and love.filesystem then
        return love.filesystem.createDirectory(path)
    end
    return false
end

io.dirExists = function(path)
    if love and love.filesystem then
        local info = love.filesystem.getInfo(path)
        return info and info.type == "directory"
    end
    return false
end

io.fileExists = function(path)
    -- Try LÖVE filesystem first
    if love and love.filesystem then
        local info = love.filesystem.getInfo(path)
        if info then return true end
    end
    -- Fall back to native io
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

io.scanDir = function(path, pattern)
    if not love or not love.filesystem then return nil end
    local items = love.filesystem.getDirectoryItems(path)
    if pattern then
        local suffix = pattern:match("^%*(.+)$")
        if suffix then
            local filtered = {}
            for _, item in ipairs(items or {}) do
                if item:sub(-#suffix) == suffix then
                    table.insert(filtered, item)
                end
            end
            return #filtered > 0 and filtered or nil
        end
    end
    return items and #items > 0 and items or nil
end

io.fileSize = function(path)
    if love and love.filesystem then
        local info = love.filesystem.getInfo(path)
        return info and info.size or -1
    end
    return -1
end

--------------------------------------------------------------------------------
-- extended-brake module mock
--------------------------------------------------------------------------------

package.loaded['extended-brake'] = {
    isAvailable = function() return false end,
    getBrakePressureBar = function(car) return (car and car.brake or 0) * 100, false end,
    getFrontRearBar = function(car) local bar = (car and car.brake or 0) * 100; return bar, bar, false end,
    getBrakeData = function(car) return { value = (car and car.brake or 0) * 100, isFromDLL = false, unit = "bar" } end,
    getBrakePressure = function(car) return (car and car.brake or 0) * 100, false end,
    getFrontRearPressure = function(car) local bar = (car and car.brake or 0) * 100; return bar, bar, false end,
    getNormalizedBrake = function(car) return car and car.brake or 0 end,
    getNormalizedFrontRear = function(car) local b = car and car.brake or 0; return b, b end,
    getStatus = function() return { available = false, source = "sim", status = "simulation mode" } end,
}

print("CSP Compatibility Layer (LÖVE2D) loaded")
