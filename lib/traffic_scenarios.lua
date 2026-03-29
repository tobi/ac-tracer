-- Traffic Scenarios - DSL-like definitions for traffic simulation
--
-- Each scenario describes a traffic situation to practice.
-- Cars are placed relative to the next corner's start/end positions.
--
-- Fields:
--   name     - Short display name
--   desc     - What this scenario trains
--   minCars  - Minimum AI opponents needed
--   place    - Array of car placements, each with:
--     where    - "entry", "mid", "exit", or "brake" (30m before entry)
--     speed    - Fraction of player speed (0.6 = 60%)
--     offset   - Lateral offset: -1 (left) to +1 (right), 0 = racing line

return {
    ----------------------------------------------------------------------
    -- Single car scenarios: basic reactions
    ----------------------------------------------------------------------

    {
        name = "Braking Zone",
        desc = "Car blocking the braking zone — forces earlier/later braking decision",
        minCars = 1,
        place = {
            { where = "entry", speed = 0.9, offset = 0 },
        },
    },

    {
        name = "Mid-Corner",
        desc = "Slow car at the apex — practice adjusting line mid-corner",
        minCars = 1,
        place = {
            { where = "mid", speed = 0.7, offset = 0 },
        },
    },

    {
        name = "Exit Block",
        desc = "Slow car on corner exit — patience and late acceleration",
        minCars = 1,
        place = {
            { where = "exit", speed = 0.6, offset = 0 },
        },
    },

    {
        name = "Offline Blocker",
        desc = "Car offline in the braking zone — practice threading the gap",
        minCars = 1,
        place = {
            { where = "brake", speed = 0.85, offset = 0.5 },
        },
    },

    ----------------------------------------------------------------------
    -- Two car scenarios: reading situations
    ----------------------------------------------------------------------

    {
        name = "Fighting",
        desc = "Two cars side-by-side into corner — find the gap or wait",
        minCars = 2,
        place = {
            { where = "entry", speed = 0.9, offset = -0.4 },
            { where = "entry", speed = 0.9, offset = 0.4 },
        },
    },

    {
        name = "Draft & Pass",
        desc = "Staggered cars on approach — slipstream then commit to a side",
        minCars = 2,
        place = {
            { where = "brake", speed = 0.95, offset = 0 },
            { where = "entry", speed = 0.85, offset = 0.3 },
        },
    },

    ----------------------------------------------------------------------
    -- Three car scenarios: pack racing
    ----------------------------------------------------------------------

    {
        name = "Pack",
        desc = "Cars spread through the corner — navigate a dense field",
        minCars = 3,
        place = {
            { where = "brake", speed = 0.9, offset = 0 },
            { where = "mid",   speed = 0.7, offset = 0 },
            { where = "exit",  speed = 0.8, offset = 0 },
        },
    },

    {
        name = "Three Wide",
        desc = "Three cars entering abreast — no clean line available",
        minCars = 3,
        place = {
            { where = "entry", speed = 0.88, offset = -0.5 },
            { where = "entry", speed = 0.88, offset = 0 },
            { where = "entry", speed = 0.88, offset = 0.5 },
        },
    },
}
