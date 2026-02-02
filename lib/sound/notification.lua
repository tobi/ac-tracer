-- notification.lua - Simple notification sounds for AC Tracer
-- Plays audio feedback for checkpoint save/load and brake beeps

local notification = {}

-- Sound file paths (relative to script directory)
local SOUNDS_DIR = __dirname .. "/lib/sound/"
local SAVE_SOUND_FILE = SOUNDS_DIR .. "save.wav"
local LOAD_SOUND_FILE = SOUNDS_DIR .. "load.wav"
local BEEP_SOUND_FILE = SOUNDS_DIR .. "beep.wav"

-- Countdown sound files (sound_1 through sound_4)
local COUNTDOWN_SOUND_FILES = {
    SOUNDS_DIR .. "sound_1.wav",
    SOUNDS_DIR .. "sound_2.wav",
    SOUNDS_DIR .. "sound_3.wav",
    SOUNDS_DIR .. "sound_4.wav",
}

-- Track if sounds are available
local saveSoundAvailable = false
local loadSoundAvailable = false
local beepSoundAvailable = false
local countdownSoundsAvailable = false

-- Preloaded audio events for instant playback
local countdownEvents = {}

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

-- Preload a sound file and return the audio event
local function preloadSound(path)
    if not io.fileExists(path) then
        return nil
    end

    local ok, event = pcall(function()
        return ac.AudioEvent.fromFile({
            filename = path,
            use3D = false,
        })
    end)

    if ok and event and event:isValid() then
        event.volume = 0.8
        event.cameraInteriorMultiplier = 1.0
        event.cameraExteriorMultiplier = 1.0
        event.cameraTrackMultiplier = 1.0
        return event
    end

    return nil
end

-- Initialize sounds (check if files exist and preload countdown sounds)
function notification.init()
    saveSoundAvailable = io.fileExists(SAVE_SOUND_FILE)
    loadSoundAvailable = io.fileExists(LOAD_SOUND_FILE)
    beepSoundAvailable = io.fileExists(BEEP_SOUND_FILE)

    -- Preload countdown sounds
    countdownSoundsAvailable = true
    for i, path in ipairs(COUNTDOWN_SOUND_FILES) do
        if io.fileExists(path) then
            local event = preloadSound(path)
            if event then
                countdownEvents[i] = event
            else
                countdownSoundsAvailable = false
                ac.log("AC Tracer: Failed to preload sound_" .. i .. ".wav")
            end
        else
            countdownSoundsAvailable = false
            ac.log("AC Tracer: Missing countdown sound: sound_" .. i .. ".wav")
        end
    end

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

    if countdownSoundsAvailable then
        ac.log("AC Tracer: Brake countdown sounds preloaded (sound_1 to sound_4)")
    elseif beepSoundAvailable then
        ac.log("AC Tracer: Brake beep sound available (fallback mode)")
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

-- Play a beep with pitch and volume shift
-- pitch: multiplier (1.0 = normal, 1.5 = higher, 0.7 = lower)
-- volume: multiplier (1.0 = default 0.8 base, 1.5 = louder)
function notification.playBeep(pitch, volume)
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
        event.volume = 0.8 * (volume or 1.0)
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
    return countdownSoundsAvailable or beepSoundAvailable
end

-- Check if countdown sounds are available
function notification.hasCountdownSounds()
    return countdownSoundsAvailable
end

-- Play a countdown sound (1-4, where 4 is the brake point)
-- Uses preloaded sounds for instant playback
-- Falls back to playBeep if countdown sounds not available
function notification.playCountdownSound(index, volume)
    if index < 1 or index > 4 then return false end

    -- Enforce cooldown to prevent overlapping sounds
    local now = os.clock()
    if (now - lastBeepTime) < BEEP_COOLDOWN then
        return false
    end
    lastBeepTime = now

    -- Use preloaded countdown sounds if available
    local event = countdownEvents[index]
    if event then
        -- Stop any currently playing instance before starting new one
        event:stop()
        event.volume = 0.8 * (volume or 1.0)
        event:start()
        
        -- Stop after 0.2 seconds (sound duration, prevents looping)
        setTimeout(function()
            if event then
                event:stop()
            end
        end, 0.2)
        
        return true
    end

    -- Fallback to pitched beeps (4 sounds with increasing pitch)
    local pitches = { 0.7, 0.9, 1.2, 2.0 }
    return notification.playBeep(pitches[index], volume)
end

return notification
