--[[
    Umeverse Framework - Jobs Configuration
    Locations, vehicles, routes, and settings for civilian jobs
    All coordinates use vanilla GTA V world locations
]]

JobsConfig = {}

-- ═══════════════════════════════════════
-- General Settings
-- ═══════════════════════════════════════

JobsConfig.MarkerDrawDistance = 15.0     -- Distance to start rendering markers
JobsConfig.InteractDistance   = 2.0      -- Distance to interact with job points
JobsConfig.BlipDisplay        = true     -- Show job blips on map

-- ═══════════════════════════════════════
-- XP & Progression System
-- ═══════════════════════════════════════
-- Players earn XP for each job action. Accumulated XP unlocks grade promotions.
-- XP is persistent per-job across sessions (stored in database).

JobsConfig.Progression = {
    enabled = true,

    -- XP required per grade promotion (cumulative)
    -- Grade 0→1 needs xpPerGrade[1], grade 1→2 needs xpPerGrade[2], etc.
    xpPerGrade = { 500, 1500, 3500, 7000 },

    -- XP earned per action type (base values, modified by multipliers)
    xpRewards = {
        task_complete    = 15,   -- Complete one task unit (collect trash, deliver, mine, etc.)
        shift_complete   = 50,   -- Complete a full shift
        bonus_task       = 25,   -- Complete a bonus/random event
        perfect_shift    = 75,   -- Complete a shift with no vehicle damage / no fails
        speed_bonus      = 20,   -- Complete shift under time threshold
    },

    -- Auto-promote when XP threshold is met
    autoPromote = true,

    -- Show XP gain notifications
    showXPGain = true,
}

-- ═══════════════════════════════════════
-- Streak & Bonus Multiplier System
-- ═══════════════════════════════════════
-- Consecutive shifts in the same job build a streak.
-- Streaks multiply both pay and XP.

JobsConfig.Streaks = {
    enabled = true,

    -- Multiplier tiers: { minStreak, payMult, xpMult, label }
    tiers = {
        { minStreak = 2,  payMult = 1.10, xpMult = 1.15, label = '~y~Warm Up' },
        { minStreak = 4,  payMult = 1.25, xpMult = 1.30, label = '~o~On A Roll' },
        { minStreak = 7,  payMult = 1.40, xpMult = 1.50, label = '~r~On Fire!' },
        { minStreak = 10, payMult = 1.60, xpMult = 1.75, label = '~p~Legendary' },
    },

    -- Streak resets if the player doesn't do a shift within this many real minutes
    resetAfterMinutes = 120,
}

-- ═══════════════════════════════════════
-- Random Events System
-- ═══════════════════════════════════════
-- During shifts, random events can occur that add variety and bonus rewards.

JobsConfig.RandomEvents = {
    enabled = true,

    -- Chance per task completion to trigger a random event (percentage)
    triggerChance = 15,

    -- Event types (applied generically across jobs)
    events = {
        {
            id = 'tip',
            label = 'Generous Tip',
            description = 'A grateful citizen gives you an extra tip!',
            type = 'bonus_cash',      -- bonus_cash | bonus_xp | bonus_item | hazard
            cashMin = 25,
            cashMax = 100,
            weight = 40,
        },
        {
            id = 'rush_order',
            label = 'Rush Order',
            description = 'Complete the next task quickly for double pay!',
            type = 'timed_bonus',
            timeLimit = 60,           -- seconds to complete next task
            payMultiplier = 2.0,
            weight = 25,
        },
        {
            id = 'flat_tire',
            label = 'Flat Tire',
            description = 'Your vehicle got a flat tire! Repair it to continue.',
            type = 'hazard',
            repairDuration = 5000,    -- ms to repair
            weight = 15,
        },
        {
            id = 'employee_month',
            label = 'Employee of the Hour',
            description = 'Your boss noticed your hard work! Bonus XP awarded.',
            type = 'bonus_xp',
            xpAmount = 50,
            weight = 15,
        },
        {
            id = 'lost_item',
            label = 'Lost & Found',
            description = 'You found something valuable while working!',
            type = 'bonus_item',
            items = {
                { item = 'phone',    weight = 40, label = 'Phone' },
                { item = 'goldbar',  weight = 5,  label = 'Gold Bar' },
                { item = 'rolex',    weight = 10, label = 'Rolex Watch' },
                { item = 'lockpick', weight = 45, label = 'Lockpick' },
            },
            weight = 5,
        },
    },
}

-- ═══════════════════════════════════════
-- Vehicle Condition System
-- ═══════════════════════════════════════
-- Tracks vehicle health during shifts. Well-maintained vehicles earn bonuses.

JobsConfig.VehicleCondition = {
    enabled = true,

    -- Minimum vehicle body health percentage at end of shift for "perfect" bonus
    perfectThreshold = 90.0,

    -- Deductions for returning a damaged vehicle
    damageDeductions = {
        { minHealth = 70, maxHealth = 89, deductPercent = 0 },    -- Minor, no deduction
        { minHealth = 40, maxHealth = 69, deductPercent = 15 },   -- Moderate damage
        { minHealth = 0,  maxHealth = 39, deductPercent = 30 },   -- Severe damage
    },

    -- Bonus pay percentage for returning vehicle in perfect condition
    perfectBonusPercent = 15,
}

-- ═══════════════════════════════════════
-- Shift Timer & Speed Bonus
-- ═══════════════════════════════════════
-- Tracks shift duration. Fast completion earns bonus.

JobsConfig.ShiftTimer = {
    enabled = true,

    -- Time thresholds in seconds for speed bonus (per job, overridable)
    -- If not set per-job, uses default
    defaultSpeedThreshold = 300, -- 5 minutes

    -- Bonus percentage for completing under the threshold
    speedBonusPercent = 20,
}

-- ═══════════════════════════════════════
-- NPC Interaction System
-- ═══════════════════════════════════════
-- Spawns NPCs at job locations for immersion (boss, customers, etc.)

JobsConfig.NPCs = {
    enabled = true,

    -- Global NPC models for generic use
    bossModels = {
        'a_m_y_business_02', 'a_m_m_business_01', 'a_f_y_business_01',
        's_m_m_security_01', 's_m_y_construct_01',
    },
    customerModels = {
        'a_m_y_hipster_01', 'a_f_y_tourist_01', 'a_m_m_farmer_01',
        'a_f_y_hippie_01', 'a_m_y_business_01', 'a_f_m_fatwhite_01',
        'a_m_y_surfer_01', 'a_f_y_fitness_01',
    },

    -- Despawn distance for NPCs (from clock-in point)
    despawnDistance = 100.0,
}

-- ═══════════════════════════════════════
-- Shift Summary
-- ═══════════════════════════════════════
-- Display a summary screen at end of each shift.

JobsConfig.ShiftSummary = {
    enabled = true,
    displayDuration = 8000, -- ms to show the summary
}

-- ═══════════════════════════════════════
-- Weather & Time Bonuses
-- ═══════════════════════════════════════

JobsConfig.WeatherBonus = {
    enabled = true,

    -- Night shift bonus (between these hours)
    nightHours = { start = 21, finish = 5 },
    nightBonusPercent = 15,

    -- Rain bonus (check with GetRainLevel)
    rainBonusPercent = 10,
}

-- ═══════════════════════════════════════
-- Job Uniforms
-- ═══════════════════════════════════════
-- Auto-apply outfit on clock-in, revert on clock-out.
-- Components: {idx, drawable, texture}  (SetPedComponentVariation args)

JobsConfig.Uniforms = {
    enabled = true,

    outfits = {
        garbage = {
            label = 'Sanitation Uniform',
            male = {
                { idx = 3, drawable = 17, texture = 0 },  -- Torso: orange hi-vis
                { idx = 4, drawable = 36, texture = 0 },  -- Legs: work pants
                { idx = 6, drawable = 25, texture = 0 },  -- Shoes: boots
                { idx = 8, drawable = 59, texture = 0 },  -- Undershirt
                { idx = 11, drawable = 55, texture = 0 }, -- Jacket: reflective vest
            },
            female = {
                { idx = 3, drawable = 7, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 35, texture = 0 },
                { idx = 11, drawable = 48, texture = 0 },
            },
        },
        bus = {
            label = 'Bus Driver Uniform',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 24, texture = 0 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 31, texture = 0 },
                { idx = 11, drawable = 29, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 25, texture = 0 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 24, texture = 0 },
            },
        },
        trucker = {
            label = 'Trucker Outfit',
            male = {
                { idx = 3, drawable = 1, texture = 0 },
                { idx = 4, drawable = 0, texture = 5 },
                { idx = 6, drawable = 1, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 7, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 1, texture = 0 },
                { idx = 4, drawable = 1, texture = 5 },
                { idx = 6, drawable = 1, texture = 0 },
                { idx = 8, drawable = 3, texture = 0 },
                { idx = 11, drawable = 3, texture = 0 },
            },
        },
        fisherman = {
            label = 'Fishing Gear',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 5, texture = 0 },
                { idx = 6, drawable = 6, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 41, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 5, texture = 0 },
                { idx = 6, drawable = 6, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 36, texture = 0 },
            },
        },
        lumberjack = {
            label = 'Lumberjack Flannel',
            male = {
                { idx = 3, drawable = 1, texture = 0 },
                { idx = 4, drawable = 5, texture = 2 },
                { idx = 6, drawable = 5, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 10, texture = 1 },
            },
            female = {
                { idx = 3, drawable = 1, texture = 0 },
                { idx = 4, drawable = 5, texture = 2 },
                { idx = 6, drawable = 5, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 6, texture = 1 },
            },
        },
        miner = {
            label = 'Mining Gear',
            male = {
                { idx = 0, drawable = 44, texture = 0 },  -- Hat: hard hat
                { idx = 3, drawable = 17, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 59, texture = 0 },
                { idx = 11, drawable = 55, texture = 0 },
            },
            female = {
                { idx = 0, drawable = 44, texture = 0 },
                { idx = 3, drawable = 7, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 35, texture = 0 },
                { idx = 11, drawable = 48, texture = 0 },
            },
        },
        tow = {
            label = 'Tow Truck Mechanic',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 59, texture = 2 },
                { idx = 11, drawable = 56, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 35, texture = 2 },
                { idx = 11, drawable = 49, texture = 0 },
            },
        },
        pizza = {
            label = 'Pizza Delivery Outfit',
            male = {
                { idx = 3, drawable = 5, texture = 0 },
                { idx = 4, drawable = 4, texture = 0 },
                { idx = 6, drawable = 12, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 42, texture = 3 },
            },
            female = {
                { idx = 3, drawable = 3, texture = 0 },
                { idx = 4, drawable = 4, texture = 0 },
                { idx = 6, drawable = 12, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 37, texture = 3 },
            },
        },
        reporter = {
            label = 'Reporter Blazer',
            male = {
                { idx = 3, drawable = 4, texture = 0 },
                { idx = 4, drawable = 10, texture = 0 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 31, texture = 0 },
                { idx = 11, drawable = 4, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 2, texture = 0 },
                { idx = 4, drawable = 10, texture = 0 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 3, texture = 0 },
                { idx = 11, drawable = 1, texture = 0 },
            },
        },
        taxi = {
            label = 'Taxi Driver Shirt',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 24, texture = 3 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 26, texture = 0 },
                { idx = 11, drawable = 27, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 25, texture = 3 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 22, texture = 0 },
            },
        },
        helitour = {
            label = 'Pilot Uniform',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 24, texture = 0 },
                { idx = 6, drawable = 24, texture = 0 },
                { idx = 8, drawable = 31, texture = 0 },
                { idx = 11, drawable = 28, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 25, texture = 0 },
                { idx = 6, drawable = 24, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 24, texture = 0 },
            },
        },
        postal = {
            label = 'Postal Uniform',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 24, texture = 2 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 26, texture = 2 },
                { idx = 11, drawable = 27, texture = 2 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 25, texture = 2 },
                { idx = 6, drawable = 10, texture = 0 },
                { idx = 8, drawable = 2, texture = 2 },
                { idx = 11, drawable = 22, texture = 2 },
            },
        },
        dockworker = {
            label = 'Dock Worker Gear',
            male = {
                { idx = 0, drawable = 11, texture = 0 },
                { idx = 3, drawable = 17, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 59, texture = 1 },
                { idx = 11, drawable = 55, texture = 1 },
            },
            female = {
                { idx = 0, drawable = 11, texture = 0 },
                { idx = 3, drawable = 7, texture = 0 },
                { idx = 4, drawable = 36, texture = 0 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 35, texture = 1 },
                { idx = 11, drawable = 48, texture = 1 },
            },
        },
        train = {
            label = 'Train Engineer Overalls',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 36, texture = 2 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 59, texture = 0 },
                { idx = 11, drawable = 55, texture = 2 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 36, texture = 2 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 35, texture = 0 },
                { idx = 11, drawable = 48, texture = 2 },
            },
        },
        hunter = {
            label = 'Hunting Camo',
            male = {
                { idx = 3, drawable = 1, texture = 0 },
                { idx = 4, drawable = 5, texture = 5 },
                { idx = 6, drawable = 5, texture = 3 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 103, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 1, texture = 0 },
                { idx = 4, drawable = 5, texture = 5 },
                { idx = 6, drawable = 5, texture = 3 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 97, texture = 0 },
            },
        },
        farmer = {
            label = 'Farm Overalls',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 5, texture = 3 },
                { idx = 6, drawable = 5, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 41, texture = 2 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 5, texture = 3 },
                { idx = 6, drawable = 5, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 36, texture = 2 },
            },
        },
        diver = {
            label = 'Diving Suit',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 94, texture = 0 },
                { idx = 6, drawable = 67, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 243, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 97, texture = 0 },
                { idx = 6, drawable = 70, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 251, texture = 0 },
            },
        },
        vineyard = {
            label = 'Vineyard Attire',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 5, texture = 0 },
                { idx = 6, drawable = 6, texture = 0 },
                { idx = 8, drawable = 15, texture = 0 },
                { idx = 11, drawable = 10, texture = 3 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 5, texture = 0 },
                { idx = 6, drawable = 6, texture = 0 },
                { idx = 8, drawable = 2, texture = 0 },
                { idx = 11, drawable = 6, texture = 3 },
            },
        },
        electrician = {
            label = 'Electrician Overalls',
            male = {
                { idx = 0, drawable = 11, texture = 2 },
                { idx = 3, drawable = 17, texture = 0 },
                { idx = 4, drawable = 36, texture = 1 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 59, texture = 0 },
                { idx = 11, drawable = 55, texture = 3 },
            },
            female = {
                { idx = 0, drawable = 11, texture = 2 },
                { idx = 3, drawable = 7, texture = 0 },
                { idx = 4, drawable = 36, texture = 1 },
                { idx = 6, drawable = 25, texture = 0 },
                { idx = 8, drawable = 35, texture = 0 },
                { idx = 11, drawable = 48, texture = 3 },
            },
        },
        security = {
            label = 'Security Guard Uniform',
            male = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 24, texture = 0 },
                { idx = 6, drawable = 24, texture = 0 },
                { idx = 8, drawable = 31, texture = 2 },
                { idx = 11, drawable = 31, texture = 0 },
            },
            female = {
                { idx = 3, drawable = 0, texture = 0 },
                { idx = 4, drawable = 25, texture = 0 },
                { idx = 6, drawable = 24, texture = 0 },
                { idx = 8, drawable = 2, texture = 2 },
                { idx = 11, drawable = 27, texture = 0 },
            },
        },
    },
}

-- ═══════════════════════════════════════
-- Boss NPCs at Clock-In Points
-- ═══════════════════════════════════════
-- Immersive NPC bosses standing at each clock-in location

JobsConfig.BossNPCs = {
    enabled = true,

    -- Per-job boss: { model, offset from clockIn pos (x,y,z,heading), scenario }
    bosses = {
        garbage     = { model = 's_m_y_construct_01',  offset = vector4(1.5, 0.0, 0.0, 180.0), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        bus         = { model = 's_m_m_cntrybar_01',   offset = vector4(1.0, 1.0, 0.0, 220.0), scenario = 'WORLD_HUMAN_SMOKING' },
        trucker     = { model = 'a_m_m_farmer_01',     offset = vector4(-1.5, 0.5, 0.0, 150.0), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        fisherman   = { model = 'a_m_m_tramp_01',      offset = vector4(2.0, -1.0, 0.0, 90.0),  scenario = 'WORLD_HUMAN_STAND_FISHING' },
        lumberjack  = { model = 'a_m_m_hillbilly_02',  offset = vector4(1.0, -1.0, 0.0, 200.0), scenario = 'WORLD_HUMAN_SMOKING' },
        miner       = { model = 's_m_y_construct_02',  offset = vector4(-1.0, 1.0, 0.0, 160.0), scenario = 'WORLD_HUMAN_CONST_DRILL' },
        tow         = { model = 's_m_m_autoshop_02',   offset = vector4(2.0, 0.0, 0.0, 270.0),  scenario = 'WORLD_HUMAN_WELDING' },
        pizza       = { model = 's_m_m_strvend_01',    offset = vector4(-1.0, 0.0, 0.0, 180.0), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        reporter    = { model = 'a_f_y_business_01',   offset = vector4(1.5, 0.5, 0.0, 200.0),  scenario = 'WORLD_HUMAN_CLIPBOARD' },
        taxi        = { model = 'a_m_y_business_02',   offset = vector4(-1.5, 0.0, 0.0, 180.0), scenario = 'WORLD_HUMAN_SMOKING' },
        helitour    = { model = 's_m_y_pilot_01',      offset = vector4(2.0, 1.0, 0.0, 210.0),  scenario = 'WORLD_HUMAN_CLIPBOARD' },
        postal      = { model = 's_m_m_postal_02',     offset = vector4(1.0, -0.5, 0.0, 180.0), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        dockworker  = { model = 's_m_m_dockwork_01',   offset = vector4(-2.0, 0.0, 0.0, 150.0), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        train       = { model = 'a_m_m_business_01',   offset = vector4(1.0, 1.0, 0.0, 180.0),  scenario = 'WORLD_HUMAN_CLIPBOARD' },
        hunter      = { model = 'a_m_m_hillbilly_01',  offset = vector4(-1.5, 0.5, 0.0, 170.0), scenario = 'WORLD_HUMAN_SMOKING' },
        farmer      = { model = 'a_m_m_farmer_01',     offset = vector4(1.5, -0.5, 0.0, 200.0), scenario = 'WORLD_HUMAN_GARDENER_PLANT' },
        diver       = { model = 'a_m_y_surfer_01',     offset = vector4(2.0, 0.0, 0.0, 260.0),  scenario = 'WORLD_HUMAN_SUNBATHE_BACK' },
        vineyard    = { model = 'a_m_m_farmer_01',     offset = vector4(-1.0, 1.0, 0.0, 180.0), scenario = 'WORLD_HUMAN_GARDENER_PLANT' },
        electrician = { model = 's_m_y_construct_01',  offset = vector4(1.0, 0.5, 0.0, 190.0),  scenario = 'WORLD_HUMAN_CONST_DRILL' },
        security    = { model = 's_m_m_security_01',   offset = vector4(-1.0, 0.0, 0.0, 180.0), scenario = 'WORLD_HUMAN_GUARD_STAND' },
    },
}

-- ═══════════════════════════════════════
-- Daily Challenges
-- ═══════════════════════════════════════
-- Rotating daily objectives per-job with bonus rewards.
-- Server picks 1-2 challenges per job each real day.

JobsConfig.DailyChallenges = {
    enabled = true,
    challengesPerDay = 2,

    -- Bonus multipliers for completing challenges
    cashBonus  = 500,   -- Flat cash bonus per challenge
    xpBonus    = 100,   -- Flat XP bonus per challenge

    -- Challenge templates: { id, label, description, type, target }
    -- type: 'tasks' (complete N tasks), 'shifts' (complete N shifts), 'earnings' (earn $N), 'speed' (N speed bonuses), 'perfect' (N perfect vehicle shifts)
    templates = {
        { id = 'tasks_10',      label = 'Hard Worker',       description = 'Complete 10 tasks',              type = 'tasks',    target = 10 },
        { id = 'tasks_20',      label = 'Overachiever',      description = 'Complete 20 tasks',              type = 'tasks',    target = 20 },
        { id = 'tasks_5',       label = 'Getting Started',   description = 'Complete 5 tasks',               type = 'tasks',    target = 5 },
        { id = 'shifts_2',      label = 'Double Shift',      description = 'Complete 2 shifts',              type = 'shifts',   target = 2 },
        { id = 'shifts_3',      label = 'Triple Threat',     description = 'Complete 3 shifts',              type = 'shifts',   target = 3 },
        { id = 'earnings_500',  label = 'Money Maker',       description = 'Earn $500 in a single shift',    type = 'earnings', target = 500 },
        { id = 'earnings_1000', label = 'Big Earner',        description = 'Earn $1000 in a single shift',   type = 'earnings', target = 1000 },
        { id = 'speed_2',       label = 'Speed Demon',       description = 'Get 2 speed bonuses',            type = 'speed',    target = 2 },
        { id = 'perfect_1',     label = 'Careful Driver',    description = 'Complete a shift with no damage', type = 'perfect',  target = 1 },
        { id = 'perfect_3',     label = 'Flawless Record',   description = 'Complete 3 perfect shifts',      type = 'perfect',  target = 3 },
    },
}

-- ═══════════════════════════════════════
-- Skill Trees / Perks
-- ═══════════════════════════════════════
-- Each job has 3-4 perks that unlock at cumulative XP milestones.
-- Perks provide passive benefits during shifts.

JobsConfig.Perks = {
    enabled = true,

    -- perkId → { label, description, xpRequired, effect type, value }
    -- Effects: 'pay_bonus' (%), 'xp_bonus' (%), 'speed' (% faster anim), 'yield' (extra items %), 'rare_chance' (+% to rare drops)
    trees = {
        garbage = {
            { id = 'fast_pickup',   label = 'Quick Hands',       description = 'Pick up trash 25% faster',          xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'bonus_pay',     label = 'Union Rep',         description = '+10% pay per bag',                   xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'double_bags',   label = 'Bag Stacker',       description = '15% chance for double bag credit',   xpRequired = 2500,  effect = 'yield',       value = 15 },
            { id = 'xp_master',     label = 'Sanitation Expert', description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        bus = {
            { id = 'smooth_stops',  label = 'Smooth Operator',   description = 'Faster stop animations',            xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'more_fares',    label = 'Popular Driver',    description = '+10% pay per stop',                  xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'express',       label = 'Express Service',   description = 'Lower speed bonus threshold',        xpRequired = 2500,  effect = 'speed_threshold', value = -60 },
            { id = 'xp_master',     label = 'Transit Veteran',   description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        trucker = {
            { id = 'fast_load',     label = 'Quick Loader',      description = 'Load/unload 20% faster',            xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_pay',     label = 'Long Hauler',       description = '+12% pay per delivery',              xpRequired = 1000,  effect = 'pay_bonus',   value = 12 },
            { id = 'fuel_saver',    label = 'Fuel Efficient',    description = 'Vehicle takes less damage',          xpRequired = 2500,  effect = 'vehicle_armor', value = 25 },
            { id = 'xp_master',     label = 'Road King',         description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        fisherman = {
            { id = 'fast_reel',     label = 'Quick Reel',        description = 'Fish 25% faster',                   xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'rare_catch',    label = 'Lucky Angler',      description = '+15% chance for rare fish',          xpRequired = 1000,  effect = 'rare_chance', value = 15 },
            { id = 'double_catch',  label = 'Net Master',        description = '20% chance to catch 2 fish',         xpRequired = 2500,  effect = 'yield',       value = 20 },
            { id = 'xp_master',     label = 'Sea Legend',        description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        lumberjack = {
            { id = 'fast_chop',     label = 'Sharp Axe',         description = 'Chop trees 20% faster',             xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_logs',    label = 'Efficient Cuts',    description = '15% chance for extra logs',          xpRequired = 1000,  effect = 'yield',       value = 15 },
            { id = 'bonus_pay',     label = 'Master Carpenter',  description = '+10% sell price',                    xpRequired = 2500,  effect = 'pay_bonus',   value = 10 },
            { id = 'xp_master',     label = 'Forest King',       description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        miner = {
            { id = 'fast_mine',     label = 'Power Drill',       description = 'Mine 20% faster',                   xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'rare_ore',      label = 'Vein Finder',       description = '+15% chance for rare ores',          xpRequired = 1000,  effect = 'rare_chance', value = 15 },
            { id = 'multi_ore',     label = 'Rich Strike',       description = '20% chance for double ore',          xpRequired = 2500,  effect = 'yield',       value = 20 },
            { id = 'xp_master',     label = 'Deep Earth Expert', description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        tow = {
            { id = 'fast_hook',     label = 'Quick Hook',        description = 'Hook vehicles 25% faster',          xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'bonus_pay',     label = 'Premium Service',   description = '+10% pay per tow',                   xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'armor',         label = 'Reinforced Tow',    description = 'Tow truck takes less damage',        xpRequired = 2500,  effect = 'vehicle_armor', value = 30 },
            { id = 'xp_master',     label = 'Road Rescue Pro',   description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        pizza = {
            { id = 'fast_deliver',  label = 'Speed Runner',      description = 'Delivery animations 20% faster',    xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_tips',    label = 'Friendly Face',     description = '+12% pay per delivery',              xpRequired = 1000,  effect = 'pay_bonus',   value = 12 },
            { id = 'express',       label = 'Express Delivery',  description = 'Lower speed bonus threshold',        xpRequired = 2500,  effect = 'speed_threshold', value = -60 },
            { id = 'xp_master',     label = 'Pizza Legend',      description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        reporter = {
            { id = 'fast_record',   label = 'Quick Reporter',    description = 'Record stories 20% faster',         xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_pay',     label = 'Award Winner',      description = '+15% pay per story',                 xpRequired = 1000,  effect = 'pay_bonus',   value = 15 },
            { id = 'scoop',         label = 'Nose for News',     description = '10% chance for double pay scoop',    xpRequired = 2500,  effect = 'yield',       value = 10 },
            { id = 'xp_master',     label = 'Star Journalist',   description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        taxi = {
            { id = 'smooth_ride',   label = 'Smooth Ride',       description = 'Passenger patience increased',       xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_tips',    label = 'Five Star Driver',  description = '+10% pay per fare',                  xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'vip_fares',     label = 'VIP Access',        description = '15% chance for VIP double-pay fare', xpRequired = 2500,  effect = 'yield',       value = 15 },
            { id = 'xp_master',     label = 'City Navigator',    description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        helitour = {
            { id = 'smooth_flight', label = 'Steady Hands',      description = 'Waypoint detection range +25%',     xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'bonus_pay',     label = 'Tour Expert',       description = '+12% pay per waypoint',              xpRequired = 1000,  effect = 'pay_bonus',   value = 12 },
            { id = 'fuel_saver',    label = 'Fuel Efficient',    description = 'Helicopter takes less damage',       xpRequired = 2500,  effect = 'vehicle_armor', value = 25 },
            { id = 'xp_master',     label = 'Sky Captain',       description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        postal = {
            { id = 'fast_deliver',  label = 'Quick Dropper',     description = 'Deliver packages 20% faster',       xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_pay',     label = 'Express Rate',      description = '+10% pay per package',               xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'express',       label = 'Priority Mail',     description = 'Lower speed bonus threshold',        xpRequired = 2500,  effect = 'speed_threshold', value = -60 },
            { id = 'xp_master',     label = 'Postal Legend',     description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        dockworker = {
            { id = 'fast_carry',    label = 'Strong Back',       description = 'Carry crates 25% faster',           xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'bonus_pay',     label = 'Foreman',           description = '+10% pay per crate',                 xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'double_crates', label = 'Heavy Lifter',      description = '15% chance for double crate credit', xpRequired = 2500,  effect = 'yield',       value = 15 },
            { id = 'xp_master',     label = 'Dock Master',       description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        train = {
            { id = 'fast_stop',     label = 'Quick Conductor',   description = 'Station waits 20% shorter',         xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_pay',     label = 'Senior Engineer',   description = '+10% pay per station',               xpRequired = 1000,  effect = 'pay_bonus',   value = 10 },
            { id = 'express',       label = 'Express Line',      description = 'Lower speed bonus threshold',        xpRequired = 2500,  effect = 'speed_threshold', value = -60 },
            { id = 'xp_master',     label = 'Rail Legend',       description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        hunter = {
            { id = 'fast_skin',     label = 'Quick Skinner',     description = 'Skin animals 25% faster',           xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'rare_animal',   label = 'Tracker',           description = '+15% chance for rare animals',       xpRequired = 1000,  effect = 'rare_chance', value = 15 },
            { id = 'double_loot',   label = 'Master Hunter',     description = '20% chance for double pelts',        xpRequired = 2500,  effect = 'yield',       value = 20 },
            { id = 'xp_master',     label = 'Wilderness Legend',  description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        farmer = {
            { id = 'fast_harvest',  label = 'Quick Picker',      description = 'Harvest 20% faster',                xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_yield',   label = 'Green Thumb',       description = '+1 crop per harvest',                xpRequired = 1000,  effect = 'yield',       value = 25 },
            { id = 'bonus_pay',     label = 'Organic Premium',   description = '+10% sell price',                    xpRequired = 2500,  effect = 'pay_bonus',   value = 10 },
            { id = 'xp_master',     label = 'Master Farmer',     description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        diver = {
            { id = 'fast_dive',     label = 'Quick Lungs',       description = 'Dive 20% faster',                   xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'rare_salvage',  label = 'Treasure Eye',      description = '+15% chance for rare salvage',       xpRequired = 1000,  effect = 'rare_chance', value = 15 },
            { id = 'double_salvage',label = 'Salvage Pro',       description = '20% chance for double items',        xpRequired = 2500,  effect = 'yield',       value = 20 },
            { id = 'xp_master',     label = 'Deep Sea Legend',   description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        vineyard = {
            { id = 'fast_pick',     label = 'Quick Picker',      description = 'Pick grapes 20% faster',            xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_yield',   label = 'Fertile Hills',     description = '+1 grape per pick',                  xpRequired = 1000,  effect = 'yield',       value = 25 },
            { id = 'bonus_pay',     label = 'Fine Wine',         description = '+12% sell price',                    xpRequired = 2500,  effect = 'pay_bonus',   value = 12 },
            { id = 'xp_master',     label = 'Vintner Master',    description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        electrician = {
            { id = 'fast_repair',   label = 'Quick Fixer',       description = 'Repair 25% faster',                 xpRequired = 300,   effect = 'speed',       value = 25 },
            { id = 'bonus_pay',     label = 'Licensed Pro',      description = '+12% pay per repair',                xpRequired = 1000,  effect = 'pay_bonus',   value = 12 },
            { id = 'safety_gear',   label = 'Safety First',      description = 'No hazard events',                   xpRequired = 2500,  effect = 'hazard_immune', value = 1 },
            { id = 'xp_master',     label = 'Master Electrician',description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
        security = {
            { id = 'fast_check',    label = 'Sharp Eyes',        description = 'Check-in 20% faster',               xpRequired = 300,   effect = 'speed',       value = 20 },
            { id = 'bonus_pay',     label = 'Chief of Security', description = '+15% pay per checkpoint',            xpRequired = 1000,  effect = 'pay_bonus',   value = 15 },
            { id = 'night_vision',  label = 'Night Owl',         description = 'Double night bonus',                 xpRequired = 2500,  effect = 'night_bonus', value = 100 },
            { id = 'xp_master',     label = 'Guardian Legend',   description = '+20% XP from all tasks',             xpRequired = 5000,  effect = 'xp_bonus',    value = 20 },
        },
    },
}

-- ═══════════════════════════════════════
-- Dynamic Pay Market
-- ═══════════════════════════════════════
-- Supply/demand: more players in a job = lower pay multiplier for that job.
-- Encourages spreading across different jobs.

JobsConfig.DynamicPay = {
    enabled = true,
    updateIntervalMs = 60000, -- How often server recalculates (1 minute)

    -- Multiplier tiers based on active player count in same job
    tiers = {
        { maxPlayers = 1,  payMult = 1.15, label = '~g~High Demand'   },  -- Solo = bonus
        { maxPlayers = 3,  payMult = 1.00, label = ''                  },  -- Normal
        { maxPlayers = 5,  payMult = 0.90, label = '~y~Competitive'   },  -- Slight reduction
        { maxPlayers = 10, payMult = 0.80, label = '~r~Oversaturated'  },  -- Noticeable reduction
    },
}

-- ═══════════════════════════════════════
-- Co-op Job Shifts
-- ═══════════════════════════════════════
-- Players working the same job nearby get a co-op bonus.

JobsConfig.CoOp = {
    enabled = true,

    -- Nearby distance to qualify as co-op partners
    nearbyDistance = 100.0,

    -- Bonus per nearby co-worker (stacks, capped by maxPartners)
    bonusPerPartner = 10,    -- +10% per nearby partner
    maxPartners     = 3,     -- Max 3 partners = +30% bonus

    -- XP bonus for co-op
    xpBonusPerPartner = 5,   -- +5% XP per partner
}

-- ═══════════════════════════════════════
-- Milestones / Achievements
-- ═══════════════════════════════════════
-- One-time achievements tracked per-player, per-job and global.

JobsConfig.Milestones = {
    enabled = true,

    -- Cash and XP rewards for achievements
    cashReward = 200,
    xpReward   = 150,

    -- Achievement definitions: { id, label, description, type, target, scope }
    -- type: 'total_tasks', 'total_shifts', 'total_earned', 'streak', 'night_shifts', 'speed_bonuses', 'perfect_shifts'
    -- scope: 'per_job' (tracked per job) or 'global' (across all jobs)
    achievements = {
        -- Per-job milestones
        { id = 'first_shift',      label = 'First Day',          description = 'Complete your first shift',         type = 'total_shifts',   target = 1,    scope = 'per_job' },
        { id = 'shifts_10',        label = 'Dedicated Worker',   description = 'Complete 10 shifts',                type = 'total_shifts',   target = 10,   scope = 'per_job' },
        { id = 'shifts_50',        label = 'Company Veteran',    description = 'Complete 50 shifts',                type = 'total_shifts',   target = 50,   scope = 'per_job' },
        { id = 'shifts_100',       label = 'Employee for Life',  description = 'Complete 100 shifts',               type = 'total_shifts',   target = 100,  scope = 'per_job' },
        { id = 'tasks_100',        label = 'Centurion',          description = 'Complete 100 tasks',                type = 'total_tasks',    target = 100,  scope = 'per_job' },
        { id = 'tasks_500',        label = 'Task Machine',       description = 'Complete 500 tasks',                type = 'total_tasks',    target = 500,  scope = 'per_job' },
        { id = 'tasks_1000',       label = 'Legendary Worker',   description = 'Complete 1000 tasks',               type = 'total_tasks',    target = 1000, scope = 'per_job' },
        { id = 'earned_5000',      label = 'Five Grand',         description = 'Earn $5,000 total',                 type = 'total_earned',   target = 5000, scope = 'per_job' },
        { id = 'earned_25000',     label = 'Quarter Rich',       description = 'Earn $25,000 total',                type = 'total_earned',   target = 25000,scope = 'per_job' },
        { id = 'earned_100000',    label = 'Job Tycoon',         description = 'Earn $100,000 total',               type = 'total_earned',   target = 100000,scope = 'per_job' },
        { id = 'streak_5',         label = 'On A Roll',          description = 'Reach a 5-shift streak',            type = 'streak',         target = 5,    scope = 'per_job' },
        { id = 'streak_10',        label = 'Unstoppable',        description = 'Reach a 10-shift streak',           type = 'streak',         target = 10,   scope = 'per_job' },

        -- Global milestones
        { id = 'night_owl_10',     label = 'Night Owl',          description = 'Complete 10 night shifts (any job)', type = 'night_shifts',   target = 10,   scope = 'global' },
        { id = 'night_owl_50',     label = 'Vampire',            description = 'Complete 50 night shifts',           type = 'night_shifts',   target = 50,   scope = 'global' },
        { id = 'speed_demon_10',   label = 'Speed Demon',        description = 'Get 10 speed bonuses (any job)',     type = 'speed_bonuses',  target = 10,   scope = 'global' },
        { id = 'perfect_10',       label = 'Perfectionist',      description = 'Complete 10 perfect vehicle shifts', type = 'perfect_shifts', target = 10,   scope = 'global' },
        { id = 'jack_of_trades',   label = 'Jack of All Trades', description = 'Complete a shift in 10 different jobs', type = 'unique_jobs', target = 10,  scope = 'global' },
        { id = 'master_of_all',    label = 'Master of All',      description = 'Complete a shift in all 20 jobs',   type = 'unique_jobs',    target = 20,   scope = 'global' },
    },
}

-- ═══════════════════════════════════════
-- Prestige System
-- ═══════════════════════════════════════
-- After hitting max grade, players can "prestige" to reset grade and earn a permanent pay/XP bonus.

JobsConfig.Prestige = {
    enabled = true,

    maxPrestige = 3,            -- Maximum prestige levels
    payBonusPerLevel  = 5,      -- +5% permanent pay per prestige level
    xpBonusPerLevel   = 10,     -- +10% permanent XP per prestige level

    -- Prestige labels/badges
    levels = {
        [1] = { label = '~y~★',   name = 'Gold Star' },
        [2] = { label = '~o~★★',  name = 'Double Star' },
        [3] = { label = '~r~★★★', name = 'Triple Star' },
    },

    -- Cash cost to prestige (optional gate)
    cashCost = { 5000, 15000, 30000 },
}

-- ═══════════════════════════════════════
-- Expanded Random Events (Job-Specific)
-- ═══════════════════════════════════════
-- Additional random events tailored to specific jobs.
-- These are added to the global events pool when the player is in the matching job.

JobsConfig.JobSpecificEvents = {
    enabled = true,

    events = {
        garbage = {
            { id = 'recycling_score', label = 'Recycling Jackpot',  description = 'Found valuable recyclables!',    type = 'bonus_cash', cashMin = 50, cashMax = 200, weight = 30 },
            { id = 'stinky_load',     label = 'Toxic Waste',        description = 'Extra hazardous load! Bonus pay!', type = 'bonus_cash', cashMin = 75, cashMax = 150, weight = 20 },
        },
        trucker = {
            { id = 'traffic_jam',     label = 'Traffic Jam',        description = 'Heavy traffic ahead — patience pays!', type = 'bonus_xp', xpAmount = 40, weight = 25 },
            { id = 'oversize_load',   label = 'Oversize Load',      description = 'Difficult cargo — extra pay!',        type = 'bonus_cash', cashMin = 100, cashMax = 250, weight = 20 },
        },
        fisherman = {
            { id = 'big_catch',       label = 'Monster Catch!',     description = 'You hooked a huge one!',             type = 'bonus_cash', cashMin = 100, cashMax = 300, weight = 15 },
            { id = 'tangled_line',    label = 'Tangled Line',       description = 'Your line got tangled. Wait it out.', type = 'bonus_xp',   xpAmount = 30, weight = 20 },
        },
        taxi = {
            { id = 'vip_passenger',   label = 'VIP Passenger',      description = 'A VIP got in! Double fare!',         type = 'bonus_cash', cashMin = 150, cashMax = 400, weight = 15 },
            { id = 'wrong_address',   label = 'Wrong Address',      description = 'Passenger gave wrong address. Extra patience pays.', type = 'bonus_xp', xpAmount = 35, weight = 25 },
        },
        diver = {
            { id = 'shark_sighting',  label = 'Shark Spotted!',     description = 'Danger bonus for brave diving!',     type = 'bonus_cash', cashMin = 100, cashMax = 250, weight = 15 },
            { id = 'treasure_chest',  label = 'Treasure Chest!',    description = 'You found a hidden treasure!',       type = 'bonus_cash', cashMin = 200, cashMax = 500, weight = 5 },
        },
        electrician = {
            { id = 'live_wire',       label = 'Live Wire!',         description = 'Dangerous repair! Extra pay!',       type = 'bonus_cash', cashMin = 75, cashMax = 200, weight = 20 },
            { id = 'power_surge',     label = 'Power Surge',        description = 'Surge while repairing! Bonus XP.',   type = 'bonus_xp',   xpAmount = 45, weight = 20 },
        },
        hunter = {
            { id = 'rare_tracks',     label = 'Rare Tracks',        description = 'You found tracks of a rare animal!', type = 'bonus_xp',   xpAmount = 50, weight = 15 },
            { id = 'trophy_animal',   label = 'Trophy Animal!',     description = 'That was a prize specimen!',         type = 'bonus_cash', cashMin = 150, cashMax = 350, weight = 10 },
        },
        security = {
            { id = 'suspicious_person', label = 'Suspicious Person', description = 'You spotted a trespasser! Bonus!', type = 'bonus_cash', cashMin = 50, cashMax = 150, weight = 25 },
            { id = 'false_alarm',     label = 'False Alarm',        description = 'Nothing here but you checked anyway.', type = 'bonus_xp', xpAmount = 25, weight = 30 },
        },
        pizza = {
            { id = 'big_order',       label = 'Big Order!',         description = 'Extra large order — bonus tip!',     type = 'bonus_cash', cashMin = 50, cashMax = 175, weight = 20 },
            { id = 'wrong_order',     label = 'Wrong Order',        description = 'Had to go back. Patience pays.',     type = 'bonus_xp',   xpAmount = 30, weight = 20 },
        },
        miner = {
            { id = 'gem_vein',        label = 'Gem Vein!',          description = 'You struck a gem vein!',             type = 'bonus_cash', cashMin = 125, cashMax = 300, weight = 10 },
            { id = 'cave_in',         label = 'Partial Cave-In',    description = 'Close call! Adrenaline bonus XP.',   type = 'bonus_xp',   xpAmount = 40, weight = 15 },
        },
    },
}

-- ═══════════════════════════════════════
-- Job Contracts
-- ═══════════════════════════════════════
-- Accept a long-haul contract for bonus pay, with a time limit and penalty for quitting early.

JobsConfig.Contracts = {
    enabled = true,

    -- Contracts available per job
    contracts = {
        { id = 'short_contract',  label = 'Quick Job',     tasks = 5,  timeLimitMins = 15, payBonus = 20, xpBonus = 10, description = 'Complete 5 tasks within 15 minutes' },
        { id = 'medium_contract', label = 'Standard Haul',  tasks = 10, timeLimitMins = 30, payBonus = 40, xpBonus = 25, description = 'Complete 10 tasks within 30 minutes' },
        { id = 'long_contract',   label = 'Marathon Shift', tasks = 20, timeLimitMins = 60, payBonus = 75, xpBonus = 50, description = 'Complete 20 tasks within 60 minutes' },
    },

    -- Penalty for quitting a contract early (% of basePay deducted)
    earlyQuitPenaltyPercent = 25,
}

-- ═══════════════════════════════════════
-- Server Leaderboard
-- ═══════════════════════════════════════
-- View top earners and most dedicated workers per job and globally.

JobsConfig.Leaderboard = {
    enabled = true,

    -- How many entries to show per board
    topN = 10,

    -- Categories
    categories = {
        { id = 'total_earned',   label = 'Top Earners' },
        { id = 'total_shifts',   label = 'Most Dedicated' },
        { id = 'total_tasks',    label = 'Most Productive' },
        { id = 'highest_streak', label = 'Longest Streaks' },
    },
}

-- ═══════════════════════════════════════
-- Mentorship System
-- ═══════════════════════════════════════
-- High-grade players can mentor newcomers for mutual bonus.

JobsConfig.Mentorship = {
    enabled = true,

    -- Mentor minimum grade to qualify
    mentorMinGrade = 3,

    -- Bonus when mentor and mentee work same job nearby
    mentorXPBonus   = 25,    -- +25% XP for both
    mentorPayBonus  = 15,    -- +15% pay for both (mentor and mentee)
    nearbyDistance   = 150.0, -- Distance to qualify

    -- Max mentees per mentor
    maxMentees = 2,
}

JobsConfig.Garbage = {
    clockIn = vector4(-322.20, -1545.91, 27.74, 320.0), -- Davis (LS Sanitation)

    vehicle = {
        model = 'trash',
        spawn = vector4(-327.36, -1558.04, 27.74, 320.0),
    },

    payPerBag = { 50, 75, 100, 125 },  -- Per grade (0–3)

    routes = {
        {   -- Route 1: South LS
            vector3(-210.47, -1639.56, 34.25),
            vector3(-163.31, -1641.43, 33.39),
            vector3(-162.07, -1571.16, 35.04),
            vector3(-264.37, -1530.82, 31.15),
            vector3(-345.63, -1469.10, 30.48),
            vector3(-404.12, -1414.33, 30.46),
            vector3(-430.94, -1340.73, 30.49),
        },
        {   -- Route 2: Strawberry / Davis
            vector3(257.38, -2027.78, 18.75),
            vector3(171.53, -2019.42, 18.27),
            vector3(51.37, -1933.85, 21.87),
            vector3(-44.52, -1838.78, 26.26),
            vector3(-58.53, -1772.67, 26.53),
            vector3(-76.41, -1651.23, 29.35),
        },
        {   -- Route 3: Vinewood area
            vector3(310.91, 178.43, 103.59),
            vector3(260.96, 199.83, 105.29),
            vector3(169.47, 189.33, 105.49),
            vector3(122.78, 196.80, 105.23),
            vector3(-15.95, 212.45, 107.65),
            vector3(-72.45, 263.82, 107.62),
        },
    },
}

-- ═══════════════════════════════════════
-- Bus Driver
-- ═══════════════════════════════════════

JobsConfig.Bus = {
    clockIn = vector4(-816.89, -2400.14, 14.47, 315.0), -- LS Airport bus depot area

    vehicle = {
        model = 'bus',
        spawn = vector4(-823.55, -2406.10, 14.47, 315.0),
    },

    payPerStop = { 30, 45, 60, 75 }, -- Per grade (0–3)

    routes = {
        {   -- Route 1: Airport → Downtown → Vinewood
            label = 'Airport Express',
            stops = {
                { coords = vector3(-1037.05, -2735.85, 13.76), name = 'Airport Terminal' },
                { coords = vector3(-537.52, -677.92, 33.68),   name = 'Little Seoul' },
                { coords = vector3(-258.82, -332.54, 30.20),   name = 'Downtown' },
                { coords = vector3(122.78, 196.80, 105.23),    name = 'Vinewood Blvd' },
                { coords = vector3(301.70, 178.56, 104.28),    name = 'Vinewood Hills' },
            },
        },
        {   -- Route 2: Del Perro → Vespucci → Airport
            label = 'Coastal Route',
            stops = {
                { coords = vector3(-1496.32, -866.50, 10.17),  name = 'Del Perro Pier' },
                { coords = vector3(-1191.76, -1389.83, 4.95),  name = 'Vespucci Beach' },
                { coords = vector3(-1009.48, -2417.38, 13.95), name = 'Airport North' },
                { coords = vector3(-1037.05, -2735.85, 13.76), name = 'Airport Terminal' },
            },
        },
        {   -- Route 3: East LS Loop
            label = 'East LS Circuit',
            stops = {
                { coords = vector3(297.45, -760.00, 29.32),    name = 'Pillbox Hill' },
                { coords = vector3(447.77, -1019.28, 28.73),   name = 'Mission Row' },
                { coords = vector3(301.31, -1517.50, 29.29),   name = 'Strawberry' },
                { coords = vector3(96.79, -1958.89, 20.75),    name = 'Davis' },
                { coords = vector3(823.48, -2157.90, 29.62),   name = 'Rancho' },
            },
        },
    },
}

-- ═══════════════════════════════════════
-- Trucker
-- ═══════════════════════════════════════

JobsConfig.Trucker = {
    clockIn = vector4(151.00, -3210.00, 5.91, 270.0), -- Port of LS

    vehicle = {
        model = 'hauler',
        spawn = vector4(138.69, -3203.64, 5.85, 270.0),
    },

    trailer = 'trailers',

    payPerDelivery = { 200, 325, 450, 575 }, -- Per grade (0–3)

    pickups = {
        vector4(151.00, -3210.00, 5.91, 270.0),     -- Port of LS
        vector4(1230.98, -3223.42, 5.94, 180.0),    -- Terminal area
    },

    deliveries = {
        { coords = vector4(826.88, -1890.03, 29.10, 0.0),      name = 'Rancho Warehouse' },
        { coords = vector4(49.40, 6337.23, 31.38, 315.0),      name = 'Paleto Bay Store' },
        { coords = vector4(1701.05, 4920.73, 42.06, 55.0),     name = 'Grapeseed Depot' },
        { coords = vector4(2683.43, 3275.06, 55.24, 150.0),    name = 'Sandy Shores Depot' },
        { coords = vector4(-3172.82, 1087.64, 20.84, 340.0),   name = 'Chumash Market' },
        { coords = vector4(-1822.30, 4987.02, 60.13, 125.0),   name = 'Gordo Lighthouse Depot' },
    },
}

-- ═══════════════════════════════════════
-- Fisherman
-- ═══════════════════════════════════════

JobsConfig.Fisherman = {
    clockIn = vector4(-1846.88, -1249.85, 8.62, 320.0), -- Del Perro Pier area

    fishingSpots = {
        vector3(-1849.06, -1235.79, 8.62),
        vector3(-1854.67, -1246.89, 8.62),
        vector3(-1832.92, -1267.41, 8.62),
        vector3(-2079.32, -1018.87, 5.90),
        vector3(-3426.15, 967.13, 8.35),
        vector3(1297.51, 4216.69, 33.91),    -- Alamo Sea
        vector3(-268.15, 6637.58, 7.08),     -- Paleto Bay pier
    },

    animDuration = 12000, -- ms to wait while "fishing"

    -- Catch table: { item, chance weight }
    catches = {
        { item = 'fish_common',   weight = 60 },
        { item = 'fish_uncommon', weight = 30 },
        { item = 'fish_rare',     weight = 10 },
    },

    sellPoint = vector4(-1831.26, -1199.66, 14.30, 230.0),

    sellPrices = {
        ['fish_common']   = 25,
        ['fish_uncommon'] = 60,
        ['fish_rare']     = 150,
    },
}

-- ═══════════════════════════════════════
-- Lumberjack
-- ═══════════════════════════════════════

JobsConfig.Lumberjack = {
    clockIn = vector4(-538.71, 5402.24, 37.00, 185.0), -- Paleto forest area

    -- Tree chop locations (near existing trees in Paleto Forest)
    trees = {
        vector3(-555.34, 5378.46, 37.34),
        vector3(-570.73, 5365.08, 38.21),
        vector3(-541.87, 5361.47, 38.58),
        vector3(-528.85, 5345.68, 39.41),
        vector3(-566.27, 5341.91, 39.56),
        vector3(-587.23, 5360.15, 37.45),
        vector3(-508.52, 5340.22, 41.20),
        vector3(-543.95, 5330.78, 41.62),
    },

    animDuration = 8000,  -- ms per chop cycle

    logsPerChop = { 1, 1, 2, 2 },  -- Per grade (0–3)

    -- Processing: turn logs into planks
    processPoint = vector4(-549.62, 5400.53, 37.00, 180.0),
    planksPerLog = 2,
    processDuration = 5000,

    sellPoint = vector4(-523.70, 5405.19, 37.22, 90.0),

    sellPrices = {
        ['wood_log']   = 15,
        ['wood_plank'] = 30,
    },
}

-- ═══════════════════════════════════════
-- Miner
-- ═══════════════════════════════════════

JobsConfig.Miner = {
    clockIn = vector4(2959.25, 2774.22, 39.31, 235.0), -- Quarry area (Grand Senora Desert)

    -- Rock mining spots in quarry area
    rocks = {
        vector3(2952.62, 2790.20, 39.68),
        vector3(2968.79, 2787.71, 42.10),
        vector3(2933.90, 2796.73, 40.56),
        vector3(2944.31, 2812.93, 41.23),
        vector3(2979.96, 2805.59, 43.89),
        vector3(2916.53, 2786.22, 39.08),
        vector3(2965.07, 2824.28, 44.31),
    },

    animDuration = 10000, -- ms per mining cycle

    -- Ore table: { item, chance weight }
    ores = {
        { item = 'stone',    weight = 55 },
        { item = 'iron_ore', weight = 35 },
        { item = 'gold_ore', weight = 10 },
    },

    sellPoint = vector4(2963.75, 2758.35, 39.31, 180.0),

    sellPrices = {
        ['stone']    = 10,
        ['iron_ore'] = 40,
        ['gold_ore'] = 120,
    },
}

-- ═══════════════════════════════════════
-- Tow Truck Driver
-- ═══════════════════════════════════════

JobsConfig.Tow = {
    clockIn = vector4(409.98, -1637.87, 29.29, 228.0), -- Tow yard near MRPD

    vehicle = {
        model = 'flatbed',
        spawn = vector4(405.32, -1645.38, 29.29, 228.0),
    },

    payPerTow = { 100, 175, 250, 325 }, -- Per grade (0–3)

    -- Possible breakdown spawn locations (roadside in the city)
    breakdownLocations = {
        vector4(-71.10, -1585.47, 29.57, 145.0),
        vector4(173.60, -1589.49, 29.29, 50.0),
        vector4(-547.72, -879.34, 25.24, 90.0),
        vector4(239.67, -878.24, 29.29, 340.0),
        vector4(-334.53, -718.85, 29.29, 90.0),
        vector4(-814.22, -1083.12, 11.15, 30.0),
        vector4(539.43, -183.62, 54.47, 275.0),
        vector4(-1057.03, -237.79, 44.02, 200.0),
    },

    -- Breakdown vehicle models (common GTA cars)
    breakdownVehicles = {
        'emperor', 'tornado', 'ruiner', 'buccaneer', 'voodoo',
        'manana', 'primo', 'stanier', 'stratum', 'ingot',
    },

    impound = vector4(409.98, -1637.87, 29.29, 228.0), -- Deliver back to tow yard
}

-- ═══════════════════════════════════════
-- Pizza Delivery
-- ═══════════════════════════════════════

JobsConfig.Pizza = {
    clockIn = vector4(286.10, -963.00, 29.43, 356.0), -- Near Pillbox area (pizza shop)

    vehicle = {
        model = 'faggio',
        spawn = vector4(284.67, -959.24, 29.43, 356.0),
    },

    payPerDelivery = { 40, 65, 90, 115 }, -- Per grade (0–3)

    deliveriesPerRound = 4, -- Number of deliveries per shift round

    -- Possible delivery destinations (houses/apartments around LS)
    deliveryLocations = {
        { coords = vector3(-1221.31, -1468.41, 4.32), name = 'Vespucci Apt' },
        { coords = vector3(-1153.48, -1518.24, 4.39), name = 'Beach House' },
        { coords = vector3(91.47, -1942.63, 20.75),   name = 'Davis Residence' },
        { coords = vector3(-24.69, -1444.38, 31.07),  name = 'South Blvd House' },
        { coords = vector3(310.68, -590.54, 43.29),   name = 'Pillbox Towers' },
        { coords = vector3(-263.56, -733.25, 33.44),  name = 'Downtown Loft' },
        { coords = vector3(976.39, -1714.80, 30.17),  name = 'East LS Home' },
        { coords = vector3(-1538.67, 123.39, 56.64),  name = 'Del Perro Condo' },
        { coords = vector3(131.36, -227.23, 54.56),   name = 'Hawick Apt' },
        { coords = vector3(-1041.89, -1550.94, 5.62), name = 'Vespucci Canal House' },
    },
}

-- ═══════════════════════════════════════
-- News Reporter
-- ═══════════════════════════════════════

JobsConfig.Reporter = {
    clockIn = vector4(-598.97, -929.98, 23.86, 0.0), -- Weazel News area

    vehicle = {
        model = 'rumpo',    -- Weazel News van
        spawn = vector4(-585.01, -924.66, 23.86, 90.0),
    },

    payPerStory = { 75, 125, 175, 225 }, -- Per grade (0–3)

    -- Story/scene types and locations
    scenes = {
        { coords = vector3(297.45, -760.00, 29.32),   label = 'City Hall Press Conference' },
        { coords = vector3(440.91, -981.47, 30.69),    label = 'Mission Row PD Report' },
        { coords = vector3(297.69, -584.22, 43.26),    label = 'Pillbox Hospital Story' },
        { coords = vector3(-1102.78, -842.07, 19.22),  label = 'Del Perro Weather Report' },
        { coords = vector3(-74.42, -818.63, 326.17),   label = 'Maze Bank Tower Report' },
        { coords = vector3(-1037.05, -2735.85, 13.76), label = 'Airport Security Alert' },
        { coords = vector3(2683.43, 3275.06, 55.24),   label = 'Sandy Shores Incident' },
        { coords = vector3(49.40, 6337.23, 31.38),     label = 'Paleto Bay Local Story' },
    },

    recordDuration = 10000, -- ms to "record" at scene
}

-- ═══════════════════════════════════════
-- Taxi (NPC Passenger Service)
-- ═══════════════════════════════════════

JobsConfig.Taxi = {
    clockIn = vector4(903.32, -170.90, 74.08, 240.0), -- Downtown Cab Co.

    vehicle = {
        model = 'taxi',
        spawn = vector4(909.51, -176.06, 74.08, 240.0),
    },

    payPerFare = { 60, 90, 120, 150, 180 }, -- Per grade (0–4, taxi has 5 grades)

    ridesPerShift = 4,

    -- Pickup/destination pairs
    fares = {
        { pickup = vector3(215.78, -806.24, 30.72),    dropoff = vector3(-1037.05, -2735.85, 13.76), name = 'To Airport' },
        { pickup = vector3(-1496.32, -866.50, 10.17),   dropoff = vector3(297.45, -760.00, 29.32),    name = 'Pier to Pillbox' },
        { pickup = vector3(-258.82, -332.54, 30.20),    dropoff = vector3(-1191.76, -1389.83, 4.95),  name = 'Downtown to Vespucci' },
        { pickup = vector3(447.77, -1019.28, 28.73),    dropoff = vector3(-537.52, -677.92, 33.68),   name = 'MRPD to Little Seoul' },
        { pickup = vector3(-1102.78, -842.07, 19.22),   dropoff = vector3(301.70, 178.56, 104.28),    name = 'Del Perro to Vinewood' },
        { pickup = vector3(-74.42, -818.63, 326.17),    dropoff = vector3(96.79, -1958.89, 20.75),    name = 'Maze Bank to Davis' },
        { pickup = vector3(823.48, -2157.90, 29.62),    dropoff = vector3(-258.82, -332.54, 30.20),   name = 'Rancho to Downtown' },
        { pickup = vector3(-1538.67, 123.39, 56.64),    dropoff = vector3(903.32, -170.90, 74.08),    name = 'Del Perro Condo to Cab Co' },
    },
}

-- ═══════════════════════════════════════
-- Helicopter Tour
-- ═══════════════════════════════════════

JobsConfig.HeliTour = {
    clockIn = vector4(-1233.41, -3393.38, 13.94, 330.0), -- Vespucci Helipad

    vehicle = {
        model = 'maverick',
        spawn = vector4(-1233.41, -3393.38, 13.94, 330.0),
    },

    payPerTour = { 200, 350, 500, 650 }, -- Per grade (0–3)

    routes = {
        {
            label = 'City Skyline Tour',
            waypoints = {
                { coords = vector3(-74.42, -818.63, 350.0),    name = 'Maze Bank Tower' },
                { coords = vector3(310.91, 178.43, 250.0),     name = 'Vinewood Sign' },
                { coords = vector3(-1496.32, -866.50, 150.0),  name = 'Del Perro Pier' },
            },
        },
        {
            label = 'Coastal Tour',
            waypoints = {
                { coords = vector3(-1191.76, -1389.83, 150.0), name = 'Vespucci Beach' },
                { coords = vector3(-3426.15, 967.13, 150.0),   name = 'Chumash Coast' },
                { coords = vector3(49.40, 6337.23, 150.0),     name = 'Paleto Bay' },
            },
        },
        {
            label = 'Mountain Tour',
            waypoints = {
                { coords = vector3(501.03, 5604.87, 900.0),    name = 'Mount Chiliad Peak' },
                { coords = vector3(2683.43, 3275.06, 200.0),   name = 'Sandy Shores' },
                { coords = vector3(1297.51, 4216.69, 150.0),   name = 'Alamo Sea' },
            },
        },
    },

    waypointRadius = 80.0, -- How close to fly to the waypoint
}

-- ═══════════════════════════════════════
-- Postal / Courier
-- ═══════════════════════════════════════

JobsConfig.Postal = {
    clockIn = vector4(105.22, -1568.18, 29.60, 320.0), -- Near postal depot

    vehicle = {
        model = 'boxville',
        spawn = vector4(110.45, -1575.44, 29.60, 320.0),
    },

    payPerPackage = { 35, 55, 75, 95 }, -- Per grade (0–3)

    packagesPerRound = 5,

    deliveryLocations = {
        { coords = vector3(-1221.31, -1468.41, 4.32),  name = 'Vespucci Apt' },
        { coords = vector3(310.68, -590.54, 43.29),    name = 'Pillbox Towers' },
        { coords = vector3(-263.56, -733.25, 33.44),   name = 'Downtown Loft' },
        { coords = vector3(-1538.67, 123.39, 56.64),   name = 'Del Perro Condo' },
        { coords = vector3(131.36, -227.23, 54.56),    name = 'Hawick Apt' },
        { coords = vector3(976.39, -1714.80, 30.17),   name = 'East LS Home' },
        { coords = vector3(-24.69, -1444.38, 31.07),   name = 'South Blvd House' },
        { coords = vector3(-1041.89, -1550.94, 5.62),  name = 'Vespucci Canal' },
        { coords = vector3(91.47, -1942.63, 20.75),    name = 'Davis Residence' },
        { coords = vector3(-1153.48, -1518.24, 4.39),  name = 'Beach House' },
        { coords = vector3(-815.56, 178.78, 72.16),    name = 'Richards Majestic' },
        { coords = vector3(1143.19, -468.83, 66.73),   name = 'Mirror Park' },
    },
}

-- ═══════════════════════════════════════
-- Dock Worker
-- ═══════════════════════════════════════

JobsConfig.DockWorker = {
    clockIn = vector4(178.24, -3279.82, 5.92, 90.0), -- Port of LS docks

    vehicle = {
        model = 'forklift',
        spawn = vector4(172.41, -3283.67, 5.92, 90.0),
    },

    payPerCrate = { 45, 70, 95, 120 }, -- Per grade (0–3)

    cratesPerShift = 6,

    -- Pickup points (cargo on the docks)
    pickupPoints = {
        vector3(126.09, -3295.12, 5.90),
        vector3(152.38, -3312.56, 5.90),
        vector3(183.56, -3330.87, 5.90),
        vector3(209.41, -3292.18, 5.90),
    },

    -- Drop-off warehouse/container area
    dropoffPoints = {
        vector3(218.73, -3236.48, 5.92),
        vector3(240.21, -3249.12, 5.92),
        vector3(198.36, -3244.67, 5.92),
    },
}

-- ═══════════════════════════════════════
-- Train Engineer
-- ═══════════════════════════════════════

JobsConfig.Train = {
    clockIn = vector4(459.62, -601.11, 28.49, 180.0), -- Pillbox South train station

    payPerStation = { 60, 100, 140, 180 }, -- Per grade (0–3)

    -- Train station stops players must walk to (simulating train ride)
    routes = {
        {
            label = 'LS Metro Line',
            stations = {
                { coords = vector3(459.62, -601.11, 28.49),    name = 'Pillbox South' },
                { coords = vector3(297.45, -760.00, 29.32),    name = 'Pillbox Hill' },
                { coords = vector3(447.77, -1019.28, 28.73),   name = 'Mission Row' },
                { coords = vector3(-537.52, -677.92, 33.68),   name = 'Little Seoul' },
                { coords = vector3(-816.89, -2400.14, 14.47),  name = 'Airport' },
            },
        },
        {
            label = 'Freight Line',
            stations = {
                { coords = vector3(459.62, -601.11, 28.49),    name = 'LS Central' },
                { coords = vector3(2683.43, 3275.06, 55.24),   name = 'Sandy Shores' },
                { coords = vector3(1701.05, 4920.73, 42.06),   name = 'Grapeseed' },
                { coords = vector3(49.40, 6337.23, 31.38),     name = 'Paleto Bay' },
            },
        },
    },

    waitDuration = 5000, -- ms to wait at each station
}

-- ═══════════════════════════════════════
-- Hunter
-- ═══════════════════════════════════════

JobsConfig.Hunter = {
    clockIn = vector4(-671.46, 5834.33, 17.33, 270.0), -- Paleto area, near forest

    -- Hunting zones in Blaine County
    huntingZones = {
        {
            center = vector3(-720.18, 5825.47, 17.21),
            radius = 60.0,
        },
        {
            center = vector3(-756.23, 5863.89, 17.44),
            radius = 50.0,
        },
    },

    minAnimals = 2,
    maxAnimals = 4,

    -- Animal models and their loot
    animalModels = {
        { model = 'a_c_deer', type = 'deer', pelt = 'deer_pelt', meat = 'raw_venison' },
        { model = 'a_c_boar', type = 'boar', pelt = 'boar_pelt', meat = 'raw_pork' },
    },

    skinDuration = 5000, -- ms for skinning animation

    sellLocation = { pos = vector3(-665.83, 5843.12, 17.33) },

    sellPrices = {
        ['deer_pelt']   = 50,
        ['boar_pelt']   = 65,
        ['raw_venison'] = 30,
        ['raw_pork']    = 35,
    },
}

-- ═══════════════════════════════════════
-- Farmer
-- ═══════════════════════════════════════

JobsConfig.Farmer = {
    clockIn = vector4(2444.23, 4974.72, 46.81, 315.0), -- Grapeseed farm area

    -- Field areas with harvest points
    fields = {
        {
            center = vector3(2435.00, 4970.00, 46.30),
            radius = 40.0,
            harvestPoints = {
                vector3(2427.16, 4984.03, 46.18),
                vector3(2410.29, 4971.37, 46.02),
                vector3(2455.67, 4963.88, 46.41),
                vector3(2472.18, 4975.22, 46.53),
                vector3(2438.73, 4951.09, 46.12),
                vector3(2417.89, 4943.56, 45.98),
                vector3(2460.41, 4989.33, 46.67),
                vector3(2480.55, 4992.17, 46.78),
            },
        },
    },

    harvestDuration = 6000, -- ms per harvest
    harvestsPerShift = { 8, 10, 12, 15 }, -- Per grade (0–3)
    yieldPerGrade = { 1, 2, 2, 3 }, -- Crops per harvest per grade

    cropTypes = {
        { item = 'wheat',   label = 'Wheat' },
        { item = 'corn',    label = 'Corn' },
        { item = 'tomato',  label = 'Tomato' },
        { item = 'lettuce', label = 'Lettuce' },
    },

    sellLocation = { pos = vector3(2444.23, 5014.36, 46.81) },

    sellPrices = {
        ['wheat']   = 15,
        ['corn']    = 20,
        ['tomato']  = 25,
        ['lettuce'] = 18,
    },
}

-- ═══════════════════════════════════════
-- Diver / Salvager
-- ═══════════════════════════════════════

JobsConfig.Diver = {
    clockIn = vector4(-1596.56, 5264.68, 4.05, 160.0), -- Procopio Beach (north coast)

    -- Dive sites with surface entry and underwater salvage points
    diveSites = {
        {
            surface = vector3(-1623.44, 5262.31, 2.0),
            salvagePoints = {
                vector3(-1623.44, 5262.31, -5.0),
                vector3(-1651.78, 5238.19, -10.0),
                vector3(-1680.33, 5290.56, -8.0),
            },
        },
        {
            surface = vector3(-1609.21, 5305.89, 2.0),
            salvagePoints = {
                vector3(-1609.21, 5305.89, -6.0),
                vector3(-1575.67, 5285.44, -12.0),
                vector3(-1644.89, 5315.23, -7.0),
            },
        },
    },

    salvageDuration = 8000, -- ms per salvage
    divesPerShift = { 5, 7, 9, 12 }, -- Per grade (0–3)

    -- Salvage table: { item, label, chance weight }
    salvageItems = {
        { item = 'scrap_metal',  label = 'Scrap Metal',  weight = 55 },
        { item = 'sea_pearl',    label = 'Sea Pearl',    weight = 30 },
        { item = 'ancient_coin', label = 'Ancient Coin', weight = 15 },
    },

    sellLocation = { pos = vector3(-1590.12, 5258.33, 4.05) },

    sellPrices = {
        ['scrap_metal']  = 20,
        ['sea_pearl']    = 100,
        ['ancient_coin'] = 200,
    },
}

-- ═══════════════════════════════════════
-- Vineyard Worker
-- ═══════════════════════════════════════

JobsConfig.Vineyard = {
    clockIn = vector4(-1905.42, 2054.37, 140.74, 250.0), -- Marlowe Vineyards area

    vineyardCenter = vector3(-1925.00, 2055.00, 140.50),

    -- Grape picking spots
    grapePoints = {
        vector3(-1920.34, 2040.56, 140.18),
        vector3(-1935.78, 2055.23, 140.42),
        vector3(-1910.67, 2068.87, 140.64),
        vector3(-1950.12, 2042.41, 140.33),
        vector3(-1940.89, 2070.19, 140.55),
        vector3(-1898.44, 2052.76, 140.21),
        vector3(-1925.56, 2078.93, 140.71),
    },

    pickDuration = 5000, -- ms per pick
    picksPerShift = { 8, 10, 12, 15 }, -- Per grade (0–3)
    yieldPerGrade = { 1, 2, 2, 3 }, -- Grapes per pick per grade

    -- Processing: grapes into wine
    processLocation = { pos = vector3(-1910.55, 2050.12, 140.74) },
    grapesPerBottle = 5,

    sellLocation = { pos = vector3(-1895.33, 2060.67, 140.74) },

    sellPrices = {
        ['grapes']      = 10,
        ['wine_bottle'] = 75,
    },
}

-- ═══════════════════════════════════════
-- Electrician
-- ═══════════════════════════════════════

JobsConfig.Electrician = {
    clockIn = vector4(724.95, -1082.59, 22.17, 0.0), -- Power station / utility area

    payPerFix = { 75, 125, 175, 225 }, -- Per grade (0–3)

    fixesPerShift = 5,
    repairDuration = 8000, -- ms per repair

    -- Electrical box locations around the city
    repairLocations = {
        { pos = vector3(-167.44, -1553.82, 35.06),  label = 'South LS Junction' },
        { pos = vector3(-547.72, -879.34, 25.24),   label = 'Little Seoul Box' },
        { pos = vector3(310.68, -590.54, 43.29),    label = 'Pillbox Utility' },
        { pos = vector3(-1102.78, -842.07, 19.22),  label = 'Del Perro Panel' },
        { pos = vector3(447.77, -1019.28, 28.73),   label = 'Mission Row Box' },
        { pos = vector3(-1538.67, 123.39, 56.64),   label = 'Del Perro North' },
        { pos = vector3(131.36, -227.23, 54.56),    label = 'Hawick Panel' },
        { pos = vector3(1143.19, -468.83, 66.73),   label = 'Mirror Park Box' },
        { pos = vector3(-815.56, 178.78, 72.16),    label = 'Richards Majestic' },
        { pos = vector3(976.39, -1714.80, 30.17),   label = 'East LS Breaker' },
    },
}

-- ═══════════════════════════════════════
-- Security Guard
-- ═══════════════════════════════════════

JobsConfig.Security = {
    clockIn = vector4(-1044.62, -236.39, 44.02, 30.0), -- Rockford Hills security office

    payPerCheckpoint = { 40, 65, 90, 115 }, -- Per grade (0–3)

    checkpointsPerShift = 6,
    checkDuration = 5000, -- ms per checkpoint check-in

    -- Night shift only (optional, set to false to allow all hours)
    nightOnly = true,

    -- Patrol checkpoint locations
    checkpoints = {
        { pos = vector3(-74.42, -818.63, 326.17),   label = 'Maze Bank Lobby' },
        { pos = vector3(-258.82, -332.54, 30.20),   label = 'City Hall Entrance' },
        { pos = vector3(-1496.32, -866.50, 10.17),  label = 'Del Perro Pier Gate' },
        { pos = vector3(297.69, -584.22, 43.26),    label = 'Pillbox Hospital' },
        { pos = vector3(-537.52, -677.92, 33.68),   label = 'Little Seoul Market' },
        { pos = vector3(447.77, -1019.28, 28.73),   label = 'Mission Row PD' },
        { pos = vector3(215.78, -806.24, 30.72),    label = 'Legion Square' },
        { pos = vector3(-1102.78, -842.07, 19.22),  label = 'Del Perro Plaza' },
        { pos = vector3(-1221.31, -1468.41, 4.32),  label = 'Vespucci Canals' },
        { pos = vector3(1143.19, -468.83, 66.73),   label = 'Mirror Park' },
    },
}

-- ═══════════════════════════════════════
-- Blip Configuration (per job)
-- ═══════════════════════════════════════

JobsConfig.Blips = {
    garbage    = { sprite = 318, color = 25, label = 'Garbage Depot' },
    bus        = { sprite = 513, color = 5,  label = 'Bus Depot' },
    trucker    = { sprite = 477, color = 47, label = 'Trucking Depot' },
    fisherman  = { sprite = 68,  color = 3,  label = 'Fishing Spot' },
    lumberjack = { sprite = 77,  color = 21, label = 'Lumber Yard' },
    miner      = { sprite = 618, color = 44, label = 'Mining Quarry' },
    tow        = { sprite = 68,  color = 46, label = 'Tow Yard' },
    pizza      = { sprite = 93,  color = 1,  label = 'Pizza Shop' },
    reporter   = { sprite = 459, color = 4,  label = 'Weazel News' },
    taxi       = { sprite = 198, color = 5,  label = 'Taxi Depot' },
    helitour   = { sprite = 43,  color = 4,  label = 'Heli Tours' },
    postal     = { sprite = 478, color = 47, label = 'Postal Depot' },
    dockworker = { sprite = 427, color = 44, label = 'Port Docks' },
    train      = { sprite = 513, color = 15, label = 'Train Station' },
    hunter     = { sprite = 141, color = 21, label = 'Hunting Lodge' },
    farmer     = { sprite = 77,  color = 25, label = 'Farm' },
    diver      = { sprite = 410, color = 3,  label = 'Dive Shop' },
    vineyard   = { sprite = 93,  color = 27, label = 'Vineyard' },
    electrician= { sprite = 354, color = 5,  label = 'Power Station' },
    security   = { sprite = 526, color = 0,  label = 'Security Office' },
}
