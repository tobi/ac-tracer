-- Corner scoring module
-- Calculates execution score based on comparison to reference lap

local scoring = {}

-- Weight configuration (must sum to 1.0)
local weights = {
    time = 0.40,      -- Time through corner vs reference (primary measure)
    exit = 0.25,      -- Exit speed vs reference (critical for lap time)
    apex = 0.15,      -- Apex speed vs reference (commitment indicator)
    brake = 0.10,     -- Brake point technique (conditional bonus)
    liftOff = 0.10    -- Lift-off point technique (conditional bonus)
}

-- Get track length for meter calculations
local function getTrackLength()
    local sim = ac.getSim()
    return sim and sim.trackLengthM or 5000
end

-- Convert position delta to meters
-- Positive = later/deeper into corner
function scoring.positionDeltaToMeters(currentPos, refPos)
    if not currentPos or not refPos then return nil end

    local trackLength = getTrackLength()
    local delta = currentPos - refPos

    -- Handle wrap-around (start/finish line)
    if delta > 0.5 then delta = delta - 1 end
    if delta < -0.5 then delta = delta + 1 end

    return delta * trackLength
end

-- Calculate score for time delta
-- Positive delta = slower (bad), negative = faster (good)
local function scoreTime(timeDelta)
    if not timeDelta then return 80 end

    -- Each 0.1s slower = -15 points, each 0.1s faster = +5 points
    local score
    if timeDelta > 0 then
        -- Slower: penalize heavily
        score = 100 - (timeDelta * 150)
    else
        -- Faster: reward moderately (cap at 110)
        score = 100 - (timeDelta * 50)
    end

    return math.clamp(score, 0, 110)
end

-- Calculate score for exit speed delta
-- Positive delta = faster (good) - critical for lap time
local function scoreExit(exitDelta)
    if not exitDelta then return 80 end

    -- Each km/h faster = +3 points, each km/h slower = -5 points
    local score
    if exitDelta >= 0 then
        score = 100 + (exitDelta * 3)
    else
        score = 100 + (exitDelta * 5)
    end

    return math.clamp(score, 0, 115)
end

-- Calculate score for apex speed delta
-- Positive delta = faster (good) - indicates commitment
local function scoreApex(apexDelta)
    if not apexDelta then return 80 end

    -- Each km/h faster = +2 points, each km/h slower = -3 points
    local score
    if apexDelta >= 0 then
        score = 100 + (apexDelta * 2)
    else
        score = 100 + (apexDelta * 3)
    end

    return math.clamp(score, 0, 110)
end

-- Calculate score for brake point
-- Later braking (positive meters) = good, BUT only if corner was executed well
local function scoreBrake(brakeMeters, timeDelta)
    if not brakeMeters then return 80 end

    local score = 100

    if brakeMeters > 0 then
        -- Braked later than reference
        if not timeDelta or timeDelta <= 0.15 then
            -- Corner was still good - reward late braking
            -- +3 points per meter later, capped
            score = 100 + math.min(brakeMeters * 3, 20)
        else
            -- Corner was compromised - no bonus for late braking
            score = 90
        end
    elseif brakeMeters < 0 then
        -- Braked earlier - small penalty (being cautious)
        -- -1 point per meter earlier
        score = 100 + math.max(brakeMeters * 1, -20)
    end

    return math.clamp(score, 60, 120)
end

-- Calculate score for lift-off point
-- Later lift-off (positive meters) = carrying more speed
local function scoreLiftOff(liftOffMeters, timeDelta)
    if not liftOffMeters then return 80 end

    local score = 100

    if liftOffMeters > 0 then
        -- Lifted later - carried more speed
        if not timeDelta or timeDelta <= 0.15 then
            -- Corner was still good - reward
            score = 100 + math.min(liftOffMeters * 2, 15)
        else
            score = 90
        end
    elseif liftOffMeters < 0 then
        -- Lifted earlier - small penalty
        score = 100 + math.max(liftOffMeters * 0.5, -15)
    end

    return math.clamp(score, 60, 115)
end

-- Calculate overall corner score
function scoring.calculate(cornerData)
    if not cornerData then return 0 end

    local timeDelta = cornerData.timeDelta or 0

    -- Calculate meter deltas
    local brakeMeters = scoring.positionDeltaToMeters(
        cornerData.currentBrakePos,
        cornerData.refBrakePos
    )
    local liftOffMeters = scoring.positionDeltaToMeters(
        cornerData.currentLiftOffPos,
        cornerData.refLiftOffPos
    )

    -- Calculate component scores
    local timeScore = scoreTime(timeDelta)
    local exitScore = scoreExit(cornerData.exitSpeedDelta)
    local apexScore = scoreApex(cornerData.apexSpeedDelta)
    local brakeScore = scoreBrake(brakeMeters, timeDelta)
    local liftOffScore = scoreLiftOff(liftOffMeters, timeDelta)

    -- Weighted average
    local score = timeScore * weights.time
                + exitScore * weights.exit
                + apexScore * weights.apex
                + brakeScore * weights.brake
                + liftOffScore * weights.liftOff

    return math.floor(math.clamp(score, 0, 100))
end

-- Get detailed breakdown for display
function scoring.getBreakdown(cornerData)
    if not cornerData then return nil end

    local timeDelta = cornerData.timeDelta or 0

    local brakeMeters = scoring.positionDeltaToMeters(
        cornerData.currentBrakePos,
        cornerData.refBrakePos
    )
    local liftOffMeters = scoring.positionDeltaToMeters(
        cornerData.currentLiftOffPos,
        cornerData.refLiftOffPos
    )

    return {
        time = scoreTime(timeDelta),
        exit = scoreExit(cornerData.exitSpeedDelta),
        apex = scoreApex(cornerData.apexSpeedDelta),
        brake = scoreBrake(brakeMeters, timeDelta),
        liftOff = scoreLiftOff(liftOffMeters, timeDelta),
        -- Raw deltas for display
        brakeMeters = brakeMeters,
        liftOffMeters = liftOffMeters,
        weights = weights
    }
end

-- Get meter deltas for UI display
function scoring.getMeterDeltas(cornerData)
    if not cornerData then return nil, nil end

    local brakeMeters = scoring.positionDeltaToMeters(
        cornerData.currentBrakePos,
        cornerData.refBrakePos
    )
    local liftOffMeters = scoring.positionDeltaToMeters(
        cornerData.currentLiftOffPos,
        cornerData.refLiftOffPos
    )

    return brakeMeters, liftOffMeters
end

-- Configure weights
function scoring.configure(settings)
    if settings.time_weight then weights.time = settings.time_weight end
    if settings.exit_weight then weights.exit = settings.exit_weight end
    if settings.apex_weight then weights.apex = settings.apex_weight end
    if settings.brake_weight then weights.brake = settings.brake_weight end
    if settings.liftOff_weight then weights.liftOff = settings.liftOff_weight end
end

return scoring

