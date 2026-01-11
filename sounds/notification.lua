-- notification.lua - Simple notification sounds for AC Tracer
-- Plays audio feedback for checkpoint save/load

local notification = {}

-- Sound file paths (relative to script directory)
local SOUNDS_DIR = __dirname .. "/sounds/"
local SAVE_SOUND_FILE = SOUNDS_DIR .. "save.wav"
local LOAD_SOUND_FILE = SOUNDS_DIR .. "load.wav"

-- Track if sounds are available
local saveSoundAvailable = false
local loadSoundAvailable = false

-- Active audio events that need cleanup
local activeEvents = {}

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
    
    if saveSoundAvailable or loadSoundAvailable then
        ac.log("AC Tracer: Notification sounds available")
    else
        ac.log("AC Tracer: No notification sounds found (optional)")
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

return notification
