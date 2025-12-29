-- theme.lua - Centralized color and style definitions
-- All UI modules should use these semantic colors

local theme = {}

--------------------------------------------------------------------------------
-- Base Palette (internal - use semantic names below)
--------------------------------------------------------------------------------

local palette = {
    -- Grays
    black = rgbm(0, 0, 0, 1),
    gray10 = rgbm(0.05, 0.05, 0.05, 1),
    gray15 = rgbm(0.08, 0.08, 0.08, 1),
    gray20 = rgbm(0.12, 0.12, 0.12, 1),
    gray30 = rgbm(0.2, 0.2, 0.2, 1),
    gray40 = rgbm(0.3, 0.3, 0.3, 1),
    gray50 = rgbm(0.5, 0.5, 0.5, 1),
    gray60 = rgbm(0.6, 0.6, 0.6, 1),
    gray70 = rgbm(0.7, 0.7, 0.7, 1),
    white = rgbm(1, 1, 1, 1),

    -- Primary colors
    green = rgbm(0, 1, 0, 1),
    red = rgbm(1, 0, 0, 1),
    blue = rgbm(0.3, 0.6, 1, 1),
    yellow = rgbm(1, 1, 0, 1),
    orange = rgbm(1, 0.6, 0, 1),
    purple = rgbm(0.55, 0.2, 0.7, 1),
}

--------------------------------------------------------------------------------
-- Semantic Colors
--------------------------------------------------------------------------------

-- Backgrounds
theme.bg = {
    window = rgbm(0.12, 0.12, 0.12, 1),
    panel = rgbm(0.08, 0.08, 0.10, 0.98),
    graph = rgbm(0.05, 0.05, 0.05, 0.95),
    overlay = rgbm(0.1, 0.1, 0.12, 0.98),
    header = rgbm(0.1, 0.1, 0.1, 0.9),
    collapsed = rgbm(0.08, 0.08, 0.1, 0.9),
    input = rgbm(0.15, 0.15, 0.15, 1),
    button = rgbm(0.2, 0.2, 0.25, 0.9),
    buttonHover = rgbm(0.3, 0.35, 0.4, 0.95),
    buttonActive = rgbm(0.15, 0.15, 0.18, 0.95),
}

-- Text
theme.text = {
    primary = rgbm(1, 1, 1, 1),
    secondary = rgbm(0.7, 0.7, 0.7, 1),
    muted = rgbm(0.5, 0.5, 0.5, 1),
    disabled = rgbm(0.4, 0.4, 0.4, 1),
    highlight = rgbm(0.5, 0.8, 1, 1),
    reference = rgbm(0.6, 0.6, 1, 1),   -- Reference lap text
    accent = rgbm(0.4, 0.5, 0.7, 1),    -- Accent/header text
}

-- Telemetry traces (current lap)
theme.trace = {
    throttle = rgbm(0, 1, 0, 0.85),
    brake = rgbm(1, 0, 0, 0.85),
    clutch = rgbm(0, 0.4, 1, 0.85),
    steering = rgbm(0.7, 0.7, 0.7, 0.85),
    speed = rgbm(0.7, 0.7, 1, 0.85),
    delta = rgbm(1, 1, 0, 1),
    fuel = rgbm(1, 0.8, 0.3, 1),
}

-- Ghost/reference traces (fainter)
theme.ghost = {
    throttle = rgbm(0, 1, 0, 0.25),
    brake = rgbm(1, 0, 0, 0.25),
    clutch = rgbm(0, 0.4, 1, 0.25),
    steering = rgbm(0.7, 0.7, 0.7, 0.25),
    speed = rgbm(0.5, 0.5, 0.7, 0.4),
}

-- Delta/comparison (positive = good/green, negative = bad/red)
theme.delta = {
    positive = rgbm(0.3, 1, 0.3, 1),      -- Faster/ahead
    negative = rgbm(1, 0.3, 0.3, 1),      -- Slower/behind
    neutral = rgbm(1, 1, 1, 1),           -- Even
    positiveFaint = rgbm(0.3, 1, 0.3, 0.7),
    negativeFaint = rgbm(1, 0.3, 0.3, 0.7),
}

-- Corner analysis specific
theme.corner = {
    faster = rgbm(0.55, 0.20, 0.70, 0.85),   -- Purple: faster than ref
    onSpeed = rgbm(0.20, 0.70, 0.20, 0.85),  -- Green: matching ref
    slower = rgbm(0.70, 0.20, 0.20, 0.85),   -- Red: slower than ref
    -- Zone backgrounds (alternating)
    even = rgbm(0.25, 0.25, 0.35, 0.12),
    odd = rgbm(0.2, 0.3, 0.25, 0.12),
    evenEdit = rgbm(0.2, 0.2, 0.35, 0.15),
    oddEdit = rgbm(0.2, 0.35, 0.2, 0.15),
    -- Special states
    focused = rgbm(0.3, 0.4, 0.6, 0.2),
    focusedBorder = rgbm(0.4, 0.7, 1, 0.8),
    selected = rgbm(0.4, 0.6, 1, 0.5),
    -- Drag handles
    handle = rgbm(1, 1, 1, 0.9),
    handleHover = rgbm(1, 0.8, 0.2, 1),
}

-- Marker lines
theme.marker = {
    apex = rgbm(1, 1, 0, 1),                 -- Current apex
    apexRef = rgbm(0.7, 0.7, 0.5, 0.6),      -- Reference apex
    brake = rgbm(1, 0.2, 0.2, 1),            -- Current brake point
    brakeRef = rgbm(1, 0.4, 0.4, 0.6),       -- Reference brake
    lift = rgbm(0.2, 1, 0.2, 1),             -- Current lift point
    liftRef = rgbm(0.4, 1, 0.4, 0.6),        -- Reference lift
    cursor = rgbm(1, 1, 1, 0.9),             -- Telemetry cursor
    startFinish = rgbm(1, 1, 1, 0.9),        -- Checkered flag colors
    tc = rgbm(1, 0.5, 0, 1),                 -- Traction control active
}

-- Grid and separators
theme.grid = {
    line = rgbm(0.3, 0.3, 0.3, 0.4),
    major = rgbm(0.5, 0.5, 0.5, 0.6),
    separator = rgbm(0.2, 0.2, 0.25, 1),
}

-- Status colors
theme.status = {
    success = rgbm(0.4, 1, 0.4, 1),
    warning = rgbm(1, 0.7, 0.3, 1),
    error = rgbm(1, 0.3, 0.3, 1),
    info = rgbm(0.5, 0.7, 1, 1),
    recording = rgbm(1, 0.2, 0.2, 1),
}

-- Buttons (colored variants)
theme.button = {
    primary = rgbm(0.2, 0.35, 0.5, 1),
    primaryHover = rgbm(0.3, 0.45, 0.6, 1),
    success = rgbm(0.2, 0.4, 0.2, 1),
    successHover = rgbm(0.3, 0.5, 0.3, 1),
    danger = rgbm(0.5, 0.2, 0.2, 1),
    dangerHover = rgbm(0.6, 0.3, 0.3, 1),
    reference = rgbm(0.2, 0.2, 0.4, 1),
    referenceHover = rgbm(0.3, 0.3, 0.5, 1),
}

-- Wheel/steering indicator
theme.wheel = {
    bg = rgbm(0, 0, 0, 0.6),
    indicator = rgbm(1, 1, 0, 1),
    centerLine = rgbm(1, 0.2, 0.2, 1),
    notch = rgbm(0.5, 0.5, 0.5, 0.6),
    ghost = rgbm(0.6, 0.6, 0.6, 0.7),
}

-- Score gauge
theme.score = {
    fill = rgbm(1, 0.85, 0, 1),
    bg = rgbm(0.25, 0.25, 0.25, 1),
}


--------------------------------------------------------------------------------
-- Style Constants
--------------------------------------------------------------------------------

theme.style = {
    cornerRadius = 4,
    padding = 10,
    lineHeight = 18,
    traceThickness = 1.5,
}

--------------------------------------------------------------------------------
-- Helper: Create alpha variant
--------------------------------------------------------------------------------

function theme.withAlpha(color, alpha)
    return rgbm(color.r, color.g, color.b, alpha)
end

return theme
