-- notification.lua - Simple notification sounds for AC Tracer
-- 
-- Uses ac.AudioEvent.fromFile with loop=false for one-shot sounds.
-- CSP internally caches the audio file data, so creating new events is efficient.

local notification = {}

local SOUNDS_DIR = __dirname .. "/lib/sound/"
local COUNTDOWN_FILES = {
    [1] = "sound_1.wav",
    [2] = "sound_2.wav",
    [3] = "sound_3.wav",
    [4] = "sound_4.wav",
}
local highestCountdownPath = nil

-- Track which files exist (checked once on first use)
local fileExists = {}

-- Beep cooldown to prevent overlapping
local lastBeepTime = 0
local BEEP_COOLDOWN = 0.08

--- Check if a sound file exists (cached)
---@param path string
---@return boolean
local function soundExists(path)
    if fileExists[path] == nil then
        fileExists[path] = io.fileExists(path)
    end
    return fileExists[path]
end

--- Find the highest available countdown sound (sound_N.wav) in sound dir.
---@return string|nil
local function getHighestCountdownPath()
    if highestCountdownPath ~= nil then
        return highestCountdownPath ~= "" and highestCountdownPath or nil
    end
    local highestIndex = -1
    local highestPath = nil
    local files = io.scanDir(SOUNDS_DIR) or {}
    for _, filename in ipairs(files) do
        local idx = tonumber(tostring(filename):match("^sound_(%d+)%.wav$"))
        if idx and idx > highestIndex then
            local path = SOUNDS_DIR .. filename
            if soundExists(path) then
                highestIndex = idx
                highestPath = path
            end
        end
    end
    highestCountdownPath = highestPath or ""
    return highestPath
end

--- Play a one-shot sound from file
--- Creates a new event with loop=false - CSP caches the file data internally
---@param path string File path
---@param volume number|nil Volume (default 0.7)
---@param pitch number|nil Pitch (default 1.0)
---@return boolean success
local function playSound(path, volume, pitch)
    if not soundExists(path) then
        return false
    end
    
    local ok, event = pcall(function()
        return ac.AudioEvent.fromFile({
            filename = path,
            use3D = false,
            loop = false,  -- One-shot, stops automatically after playing
        }, false)
    end)
    
    if ok and event and event:isValid() then
        event.volume = volume or 0.7
        event.pitch = pitch or 1.0
        event.cameraInteriorMultiplier = 1.0
        event.cameraExteriorMultiplier = 1.0
        event.cameraTrackMultiplier = 1.0
        event:start()
        return true
    end
    
    return false
end

--- Play save sound
function notification.playSave()
    return playSound(SOUNDS_DIR .. "save.wav")
end

--- Play load sound (same as save)
function notification.playLoad()
    local loadPath = SOUNDS_DIR .. "load.wav"
    if soundExists(loadPath) then
        return playSound(loadPath)
    end
    return playSound(SOUNDS_DIR .. "save.wav")
end

--- Play beep with pitch/volume adjustment
---@param pitch number|nil Pitch multiplier (default 1.0)
---@param volume number|nil Volume multiplier (default 1.0)
function notification.playBeep(pitch, volume)
    -- Cooldown check
    local now = os.clock()
    if (now - lastBeepTime) < BEEP_COOLDOWN then
        return false
    end
    lastBeepTime = now
    
    -- Try beep.wav first, fall back to save.wav
    local path = SOUNDS_DIR .. "beep.wav"
    if not soundExists(path) then
        path = SOUNDS_DIR .. "save.wav"
    end
    
    return playSound(path, 0.7 * (volume or 1.0), pitch)
end

--- Play countdown sound (1-4, where 4 is brake point)
---@param index number Sound index 1-4
---@param volume number|nil Volume multiplier
function notification.playCountdownSound(index, volume)
    if index < 1 or index > 4 then return false end

    -- Try dedicated countdown sounds first (preferred "fancier" cue pack)
    local path = SOUNDS_DIR .. COUNTDOWN_FILES[index]
    if index == 4 then
        path = getHighestCountdownPath() or path
    end
    if soundExists(path) then
        return playSound(path, 1.0 * (volume or 1.0))
    end
    
    -- Fall back to beep with pitch
    local pitches = { 0.7, 0.9, 1.2, 2.0 }
    return notification.playBeep(pitches[index], volume)
end

--- Check if beep sounds are available
function notification.hasBeepSound()
    return soundExists(SOUNDS_DIR .. "beep.wav") or soundExists(SOUNDS_DIR .. "save.wav")
end

--- Check if countdown sounds are available
function notification.hasCountdownSounds()
    for i = 1, 4 do
        if not soundExists(SOUNDS_DIR .. "sound_" .. i .. ".wav") then
            return false
        end
    end
    return true
end

--- Initialize (no-op, sounds are checked on first use)
function notification.init()
    local countdownReady = notification.hasCountdownSounds()
    ac.log(string.format(
        "AC Tracer: Notification sounds ready (countdown pack: %s, one-shot mode, loop=false)",
        countdownReady and "enabled" or "fallback"
    ))
end

return notification
