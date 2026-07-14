-- focus.lua - Track focus notes window
-- Reads C:/Users/ASR/Dropbox/Sim Racing/ac-tracer/focus/{track}.txt and shows
-- it alongside any images named {track}*.png from the same folder.

local state = require('lib.core.state')

local focus = {}

local FOCUS_DIR = 'C:/Users/ASR/Dropbox/Sim Racing/ac-tracer/focus/'
local REFRESH_INTERVAL = 2.0  -- re-scan disk every 2s so edits show up live

local cache = {
    trackId = nil,
    text = nil,
    images = {},
    lastRefreshTime = -1,
}

local function loadForTrack(trackId)
    cache.trackId = trackId
    cache.text = nil
    cache.images = {}

    if not trackId or trackId == '' then return end
    if not io.dirExists(FOCUS_DIR) then return end

    local txtPath = FOCUS_DIR .. trackId .. '.txt'
    if io.exists(txtPath) then
        local raw = io.load(txtPath)
        if raw and raw ~= '' then
            cache.text = raw
        end
    end

    local files = io.scanDir(FOCUS_DIR, trackId .. '*.png') or {}
    for _, fname in ipairs(files) do
        table.insert(cache.images, FOCUS_DIR .. fname)
    end
end

local function refreshCache()
    local trackId = state.track
    if not trackId or trackId == '' then trackId = ac.getTrackID() end
    local now = os.clock()

    if cache.trackId ~= trackId or now - cache.lastRefreshTime > REFRESH_INTERVAL then
        loadForTrack(trackId)
        cache.lastRefreshTime = now
    end
end

--- True iff there is any content (text or images) for the current track.
function focus.hasContent()
    refreshCache()
    return (cache.text ~= nil) or (#cache.images > 0)
end

function focus.draw(dt)
    refreshCache()

    if not focus.hasContent() then
        -- Window will be force-hidden by ac-tracer.lua, but render a
        -- placeholder in case the user opens it manually.
        ui.pushFont(ui.Font.Main)
        ui.textColored('No focus notes for ' .. (cache.trackId or 'unknown'),
            rgbm(1, 1, 1, 0.5))
        ui.text('Add ' .. (cache.trackId or 'track') .. '.txt to:')
        ui.text(FOCUS_DIR)
        ui.popFont()
        return
    end

    if cache.text then
        ui.pushFont(ui.Font.Title)
        ui.textWrapped(cache.text)
        ui.popFont()
    end

    if #cache.images > 0 then
        if cache.text then ui.dummy(vec2(0, 10)) end
        local availW = ui.availableSpaceX()
        for _, imgPath in ipairs(cache.images) do
            local size = ui.imageSize(imgPath)
            if size.x > 0 and size.y > 0 then
                local scale = math.min(1, availW / size.x)
                ui.image(imgPath, vec2(size.x * scale, size.y * scale))
            else
                ui.image(imgPath, vec2(availW, 200))
            end
            ui.dummy(vec2(0, 6))
        end
    end
end

return focus
