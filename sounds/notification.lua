-- notification.lua - Simple notification sounds for AC Tracer
-- Plays audio feedback for checkpoint save/load and brake beeps

local notification = {}

-- Sound file paths (relative to script directory)
local SOUNDS_DIR = __dirname .. "/sounds/"
local SAVE_SOUND_FILE = SOUNDS_DIR .. "save.wav"
local LOAD_SOUND_FILE = SOUNDS_DIR .. "load.wav"
local BEEP_SOUND_FILE = SOUNDS_DIR .. "beep.wav"

-- Track if sounds are available
local saveSoundAvailable = false
local loadSoundAvailable = false
local beepSoundAvailable = false

-- Active audio events that need cleanup
local activeEvents = {}

-- Beep cooldown to prevent overlapping beeps
local lastBeepTime = 0
local BEEP_COOLDOWN = 0.08  -- 80ms minimum between beeps

-- Play a one-shot sound from file (plays for 0.2s then stops)
local function playOneShot(path)
    if not io.fileExists(path) then
        return false
    end
    
    local ok, event = pcall(function()
        return ac.AudioEvent.fromFile({
            filename = path,
            use3D = false,
        })
    end)
    
    if ok and event and event:isValid() then
        event.volume = 0.7
        event.cameraInteriorMultiplier = 1.0
        event.cameraExteriorMultiplier = 1.0
        event.cameraTrackMultiplier = 1.0
        event:start()
        
        -- Stop and dispose after 0.1 seconds (setTimeout uses seconds, not ms)
        setTimeout(function()
            if event then
                event:stop()
                event:dispose()
            end
        end, 0.1)
        
        return true
    end
    
    return false
end

-- Initialize sounds (check if files exist)
function notification.init()
    saveSoundAvailable = io.fileExists(SAVE_SOUND_FILE)
    loadSoundAvailable = io.fileExists(LOAD_SOUND_FILE)
    beepSoundAvailable = io.fileExists(BEEP_SOUND_FILE)
    
    -- Fall back to save.wav for beep if beep.wav doesn't exist
    if not beepSoundAvailable and saveSoundAvailable then
        beepSoundAvailable = true
        BEEP_SOUND_FILE = SAVE_SOUND_FILE
        ac.log("AC Tracer: Using save.wav as beep sound (beep.wav not found)")
    end
    
    if saveSoundAvailable or loadSoundAvailable or beepSoundAvailable then
        ac.log("AC Tracer: Notification sounds available")
    else
        ac.log("AC Tracer: No notification sounds found (optional)")
    end
    
    if beepSoundAvailable then
        ac.log("AC Tracer: Brake beep sound available")
    end
end

-- Play save checkpoint sound
function notification.playSave()
    if saveSoundAvailable then
        playOneShot(SAVE_SOUND_FILE)
    end
end

-- Play load checkpoint sound (uses save sound)
function notification.playLoad()
    if saveSoundAvailable then
        playOneShot(SAVE_SOUND_FILE)
    end
end

-- Play a beep with pitch shift
-- pitch: multiplier (1.0 = normal, 1.5 = higher, 0.7 = lower)
function notification.playBeep(pitch)
    if not beepSoundAvailable then return false end
    
    -- Enforce cooldown to prevent overlapping beeps
    local now = os.clock()
    if (now - lastBeepTime) < BEEP_COOLDOWN then
        return false
    end
    lastBeepTime = now
    
    local ok, event = pcall(function()
        return ac.AudioEvent.fromFile({
            filename = BEEP_SOUND_FILE,
            use3D = false,
        })
    end)
    
    if ok and event and event:isValid() then
        event.volume = 0.8
        event.pitch = pitch or 1.0
        event.cameraInteriorMultiplier = 1.0
        event.cameraExteriorMultiplier = 1.0
        event.cameraTrackMultiplier = 1.0
        event:start()
        
        -- Stop and dispose after 0.15 seconds
        setTimeout(function()
            if event then
                event:stop()
                event:dispose()
            end
        end, 0.15)
        
        return true
    end
    
    return false
end

-- Check if beep sound is available
function notification.hasBeepSound()
    return beepSoundAvailable
end

return notification
