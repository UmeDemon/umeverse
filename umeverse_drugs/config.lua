--[[
    Umeverse Framework - Drug System Configuration
    Drug types, progression chain, locations, pricing, and all settings
    
    ADDING A NEW DRUG:
    1. Add entry to DrugConfig.Drugs table below
    2. Add items to umeverse_core/shared/items.lua
    3. Add baggy to DrugConfig.DrugSellItems mapping
    4. Add baggy to desired SellCorners
    5. Add any new supply items to SupplyShops
    That's it — all client/server code is data-driven.
]]

DrugConfig = {}

-- ═══════════════════════════════════════════════════════════════
-- General Settings
-- ═══════════════════════════════════════════════════════════════

DrugConfig.MarkerDrawDistance = 15.0
DrugConfig.InteractDistance   = 2.0
DrugConfig.BlipDisplay        = true

-- Police alert settings
DrugConfig.PoliceAlert = {
    enabled       = true,           -- Send alerts to on-duty LEOs
    alertChance   = 25,             -- % chance per sale to trigger alert
    alertRadius   = 150.0,          -- Radius of alert blip on police map
    alertDuration = 60,             -- Seconds the alert stays on police map
}

-- ═══════════════════════════════════════════════════════════════
-- Quality System
-- ═══════════════════════════════════════════════════════════════
-- Drug rep level determines product quality tier.
-- Quality affects yield multipliers and sell price multipliers.

DrugConfig.Quality = {
    enabled = true,

    -- Rep level ranges that map to each tier
    tiers = {
        { name = 'Poor',       color = '~r~',  minLevel = 1,  maxLevel = 2,  yieldMult = 0.8,  priceMult = 0.7  },
        { name = 'Standard',   color = '~w~',  minLevel = 3,  maxLevel = 4,  yieldMult = 1.0,  priceMult = 1.0  },
        { name = 'Good',       color = '~g~',  minLevel = 5,  maxLevel = 6,  yieldMult = 1.15, priceMult = 1.2  },
        { name = 'Premium',    color = '~b~',  minLevel = 7,  maxLevel = 8,  yieldMult = 1.3,  priceMult = 1.4  },
        { name = 'Masterwork', color = '~p~',  minLevel = 9,  maxLevel = 10, yieldMult = 1.5,  priceMult = 1.65 },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Batch Processing
-- ═══════════════════════════════════════════════════════════════
-- Players can choose to process/package multiple batches at once.
-- Higher rep unlocks larger batch sizes.

DrugConfig.Batching = {
    enabled = true,

    -- Each entry: { size = N, requiredLevel = L }
    sizes = {
        { size = 1, requiredLevel = 1  },
        { size = 2, requiredLevel = 3  },
        { size = 3, requiredLevel = 5  },
        { size = 5, requiredLevel = 8  },
    },

    timePerBatch = 0.75, -- Extra batches take 75% time each (diminishing returns)
}

-- ═══════════════════════════════════════════════════════════════
-- Failure / Waste System
-- ═══════════════════════════════════════════════════════════════
-- Processing can partially fail, wasting some input materials.
-- Higher rep reduces the failure chance.

DrugConfig.Failure = {
    enabled = true,

    -- Base chance of a batch failing (partial loss)
    baseChance       = 30,           -- % at level 1
    reductionPerLevel = 3,           -- Reduce by 3% per drug level
    minChance        = 2,            -- Floor: never below 2%

    -- When failure occurs, what fraction of inputs is lost (rest still produces output)
    wasteFraction    = 0.5,          -- Lose 50% of inputs on a fail
    -- If true, failures still produce some output (reduced). If false, total loss.
    partialOutput    = true,
    partialFraction  = 0.5,          -- Get 50% of expected output on a fail
}

-- ═══════════════════════════════════════════════════════════════
-- Field Depletion (Gathering)
-- ═══════════════════════════════════════════════════════════════
-- Gathering spots temporarily deplete after use.

DrugConfig.Depletion = {
    enabled      = true,
    maxUses      = 5,                -- Gathers before a spot is depleted
    cooldownTime = 180,              -- Seconds before spot regenerates
}

-- ═══════════════════════════════════════════════════════════════
-- Rep-Based Bonuses
-- ═══════════════════════════════════════════════════════════════
-- Higher drug rep = faster actions and bonus yield.

DrugConfig.RepBonuses = {
    speedEnabled  = true,
    speedPerLevel = 0.05,            -- 5% faster per level (up to 50% at level 10)
    maxSpeedBonus = 0.50,            -- Never more than 50% faster

    yieldEnabled  = true,
    yieldPerLevel = 0.04,            -- 4% bonus yield per level
    maxYieldBonus = 0.40,            -- Max 40% bonus yield at level 10
}

-- ═══════════════════════════════════════════════════════════════
-- Time-of-Day Modifiers
-- ═══════════════════════════════════════════════════════════════
-- Operations at night are more efficient but riskier.

DrugConfig.TimeOfDay = {
    enabled = true,

    nightStart = 22,                 -- 10 PM
    nightEnd   = 5,                  -- 5 AM

    nightBonuses = {
        yieldMult = 1.15,            -- 15% more yield at night
        speedMult = 0.90,            -- 10% faster at night
    },

    dayBonuses = {
        yieldMult = 1.0,
        speedMult = 1.0,
    },

    -- Increased police alert chance during daytime
    dayAlertMult   = 1.5,            -- 50% more police alert chance in daytime
    nightAlertMult = 0.8,            -- 20% less at night
}

-- ═══════════════════════════════════════════════════════════════
-- Random Encounters (during gathering/processing)
-- ═══════════════════════════════════════════════════════════════

DrugConfig.RandomEncounters = {
    enabled = true,

    -- Chance per action of triggering an encounter
    gatherChance  = 8,               -- 8% chance while gathering
    processChance = 12,              -- 12% chance while processing

    types = {
        {
            id       = 'rival_dealer',
            label    = 'Rival Dealer',
            weight   = 40,            -- Relative weight for random selection
            hostile  = true,
            pedModel = 'g_m_y_ballaorig_01',
            pedCount = { 1, 3 },       -- Spawn 1-3 hostiles
            radius   = 25.0,           -- Spawn within this radius
            despawnTime = 60,           -- Seconds before auto-despawn
        },
        {
            id       = 'police_patrol',
            label    = 'Police Patrol',
            weight   = 25,
            hostile  = true,
            pedModel = 's_m_y_cop_01',
            pedCount = { 2, 3 },
            radius   = 40.0,
            despawnTime = 90,
        },
        {
            id       = 'scavenger',
            label    = 'Scavenger',
            weight   = 20,
            hostile  = false,          -- Non-hostile, tries to steal product
            pedModel = 'a_m_m_tramp_01',
            pedCount = { 1, 1 },
            radius   = 15.0,
            despawnTime = 45,
        },
        {
            id       = 'bonus_stash',
            label    = 'Hidden Stash Found!',
            weight   = 15,             -- Lucky find — bonus materials
            hostile  = false,
            bonusItem = true,          -- Gives bonus of current drug's raw material
            bonusAmount = { 3, 8 },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Lab Props & Atmosphere
-- ═══════════════════════════════════════════════════════════════
-- Props spawned at processing/packaging locations for immersion.

DrugConfig.LabProps = {
    enabled = true,
    drawDistance = 30.0,

    -- Props to spawn at processing locations (by drug type, or default)
    processing = {
        default = {
            { model = 'prop_cs_pane_table', offset = vector3(0, 0, -1.0) },
        },
        weed = {
            { model = 'prop_weed_01',       offset = vector3(-1.0, 0, -0.5) },
            { model = 'prop_weed_01',       offset = vector3(1.0, 0.5, -0.5) },
            { model = 'prop_cs_pane_table', offset = vector3(0, 0, -1.0)  },
        },
        meth = {
            { model = 'prop_meth_bag_01',   offset = vector3(-0.5, 0, 0.0) },
            { model = 'prop_cs_beaker_01',  offset = vector3(0.5, 0, 0.0) },
            { model = 'bkr_prop_meth_table01a', offset = vector3(0, -1.0, -1.0) },
        },
        cocaine = {
            { model = 'prop_cs_pane_table', offset = vector3(0, 0, -1.0) },
            { model = 'prop_bag_01',        offset = vector3(-0.6, 0.3, 0.0) },
        },
        heroin = {
            { model = 'prop_cs_pane_table', offset = vector3(0, 0, -1.0) },
            { model = 'prop_cs_beaker_01',  offset = vector3(0.4, -0.3, 0.0) },
        },
    },

    -- Props to spawn at packaging locations
    packaging = {
        default = {
            { model = 'prop_cs_cardbox_01', offset = vector3(0, 0, -1.0) },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Progression System (Drug Rep)
-- ═══════════════════════════════════════════════════════════════
-- Players earn Drug Rep (XP) from all drug activities.
-- Higher rep unlocks new drugs, better prices, and warehouse access.

DrugConfig.Progression = {
    metadataKey = 'drugRep',        -- Stored in player metadata

    levels = {
        [1]  = { xp = 0,     label = 'Street Rat',        unlock = 'weed' },
        [2]  = { xp = 150,   label = 'Corner Boy',        unlock = 'ecstasy' },
        [3]  = { xp = 400,   label = 'Hustler',           unlock = 'lsd' },
        [4]  = { xp = 800,   label = 'Dealer',            unlock = 'meth' },
        [5]  = { xp = 1500,  label = 'Supplier',          unlock = 'crack' },
        [6]  = { xp = 2500,  label = 'Lieutenant',        unlock = 'cocaine' },
        [7]  = { xp = 4000,  label = 'Underboss',         unlock = 'heroin' },
        [8]  = { xp = 6000,  label = 'Kingpin',           unlock = 'warehouse' },
        [9]  = { xp = 9000,  label = 'Cartel Boss',       unlock = nil },
        [10] = { xp = 13000, label = 'Drug Lord',         unlock = nil },
    },

    -- XP earned per activity
    xpRewards = {
        gather     = 3,     -- Picking/harvesting raw materials
        process    = 5,     -- Processing raw into refined
        package    = 4,     -- Packaging for sale
        sell       = 8,     -- Selling to NPCs
        bulkSell   = 15,    -- Bulk warehouse sale
        launder    = 6,     -- Money laundering transaction
    },
}

-- ═══════════════════════════════════════════════════════════════
-- DRUG REGISTRY (Data-Driven)
-- ═══════════════════════════════════════════════════════════════
-- Every drug is defined here. Client/server code iterates this
-- table automatically — no code changes needed to add new drugs.
--
-- gatherType:
--   'field'  = Pick from radius zones (like weed, coca)
--   'npc'    = Buy from NPCs at fixed coords (like meth precursors)

DrugConfig.Drugs = {}

-- ───────────────────────────────
-- WEED (Entry Level - Rep Level 1)
-- ───────────────────────────────

DrugConfig.Drugs['weed'] = {
    label         = 'Weed',
    unlockKey     = 'weed',

    -- Gathering
    gatherType    = 'field',
    gatherLocations = {
        { coords = vector3(2208.78, 5578.23, 53.74), radius = 30.0 }, -- Grapeseed farmland
        { coords = vector3(2322.61, 5432.38, 46.28), radius = 25.0 }, -- North Grapeseed field
        { coords = vector3(1898.59, 4924.95, 48.87), radius = 20.0 }, -- East of Grapeseed
    },
    gatherItem    = 'weed_leaf',
    gatherAmount  = { 1, 3 },
    gatherTime    = 8000,
    gatherAnim    = { dict = 'amb@medic@standing@kneel@base', anim = 'base', flag = 1 },
    gatherLabel   = 'Pick weed leaves',
    gatherProgress = 'Picking leaves...',
    gatherMarker  = { r = 0, g = 180, b = 0, a = 80 },

    -- Processing
    processLocations = {
        vector4(2431.92, 4976.36, 46.94, 225.0),    -- Grapeseed farmhouse
        vector4(1391.38, 3606.68, 38.94, 190.0),    -- Sandy Shores shack
        vector4(2967.30, 4635.19, 48.72, 100.0),    -- Remote Grapeseed barn
    },
    processLabel   = 'Weed Drying Station',
    processHelp    = 'Dry weed leaves',
    processProgress = 'Drying weed...',
    processMarker  = { r = 0, g = 200, b = 0, a = 120 },
    processRecipe  = {
        input  = { { item = 'weed_leaf', amount = 6 } },
        output = { item = 'dried_weed', amount = 3 },
        time   = 12000,
        anim   = { dict = 'anim@gangops@morgue@table@', anim = 'body_search', flag = 1 },
    },

    -- Packaging
    packageLocations = {
        vector4(2431.92, 4976.36, 46.94, 225.0),
        vector4(1391.38, 3606.68, 38.94, 190.0),
        vector4(2967.30, 4635.19, 48.72, 100.0),
    },
    packageLabel   = 'Package Weed',
    packageHelp    = 'Package weed baggies',
    packageProgress = 'Packaging weed...',
    packageMarker  = { r = 0, g = 255, b = 100, a = 100 },
    packageRecipe  = {
        input  = { { item = 'dried_weed', amount = 2 }, { item = 'rolling_papers', amount = 1 } },
        output = { item = 'weed_baggy', amount = 4 },
        time   = 8000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 45, max = 75 },
}

-- ───────────────────────────────
-- ECSTASY / MDMA (Rep Level 2)
-- ───────────────────────────────

DrugConfig.Drugs['ecstasy'] = {
    label         = 'Ecstasy',
    unlockKey     = 'ecstasy',

    gatherType    = 'npc',
    gatherLocations = {
        { coords = vector4(268.56, -1353.41, 24.53, 270.0), npc = true, model = 'a_m_y_hipster_02', label = 'Club Chemist' },
        { coords = vector4(-1389.67, -586.06, 30.22, 210.0), npc = true, model = 'a_f_y_hipster_04', label = 'Underground Supplier' },
    },
    gatherItem    = 'sassafras_oil',
    gatherCost    = 120,
    gatherAmount  = { 2, 5 },
    gatherTime    = 3000,
    gatherAnim    = { dict = 'mp_common', anim = 'givetake1_a', flag = 49 },
    gatherLabel   = 'Buy sassafras oil',
    gatherProgress = 'Buying supplies...',
    gatherMarker  = { r = 255, g = 0, b = 200, a = 120 },

    processLocations = {
        vector4(1122.54, -3195.26, -40.40, 0.0),    -- Underground rave lab
        vector4(-1516.31, -431.35, 35.44, 140.0),   -- Del Perro basement
    },
    processLabel   = 'MDMA Synthesis Lab',
    processHelp    = 'Synthesize MDMA',
    processProgress = 'Synthesizing MDMA...',
    processMarker  = { r = 255, g = 0, b = 200, a = 120 },
    processRecipe  = {
        input  = {
            { item = 'sassafras_oil', amount = 4 },
            { item = 'acetone', amount = 1 },
        },
        output = { item = 'raw_mdma', amount = 3 },
        time   = 15000,
        anim   = { dict = 'anim@heists@narcotics@cooking@', anim = 'water_pipe_sequence', flag = 1 },
    },

    packageLocations = {
        vector4(1122.54, -3195.26, -40.40, 0.0),
        vector4(-1516.31, -431.35, 35.44, 140.0),
    },
    packageLabel   = 'Press Ecstasy Pills',
    packageHelp    = 'Press ecstasy pills',
    packageProgress = 'Pressing pills...',
    packageMarker  = { r = 255, g = 50, b = 220, a = 100 },
    packageRecipe  = {
        input  = { { item = 'raw_mdma', amount = 2 }, { item = 'pill_press_die', amount = 1 } },
        output = { item = 'ecstasy_baggy', amount = 6 },
        time   = 10000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 60, max = 110 },
}

-- ───────────────────────────────
-- LSD (Rep Level 3)
-- ───────────────────────────────

DrugConfig.Drugs['lsd'] = {
    label         = 'LSD',
    unlockKey     = 'lsd',

    gatherType    = 'field',
    gatherLocations = {
        { coords = vector3(2570.89, 4658.27, 34.08), radius = 20.0 }, -- Grapeseed fields (ergot grain)
        { coords = vector3(442.89, 6463.07, 29.35),  radius = 18.0 }, -- North Paleto farmland
    },
    gatherItem    = 'ergot_fungus',
    gatherAmount  = { 1, 2 },
    gatherTime    = 10000,
    gatherAnim    = { dict = 'amb@medic@standing@kneel@base', anim = 'base', flag = 1 },
    gatherLabel   = 'Harvest ergot fungus',
    gatherProgress = 'Harvesting fungus...',
    gatherMarker  = { r = 180, g = 0, b = 255, a = 80 },

    processLocations = {
        vector4(-1081.87, -1521.17, 4.40, 300.0),    -- Vespucci hidden lab
        vector4(2523.10, 3754.78, 43.48, 210.0),     -- Sandy Shores chemistry shed
    },
    processLabel   = 'LSD Synthesis Lab',
    processHelp    = 'Synthesize lysergic acid',
    processProgress = 'Synthesizing acid...',
    processMarker  = { r = 180, g = 0, b = 255, a = 120 },
    processRecipe  = {
        input  = {
            { item = 'ergot_fungus', amount = 5 },
            { item = 'diethylamine', amount = 2 },
        },
        output = { item = 'liquid_lsd', amount = 2 },
        time   = 20000,
        anim   = { dict = 'anim@gangops@morgue@table@', anim = 'body_search', flag = 1 },
    },

    packageLocations = {
        vector4(-1081.87, -1521.17, 4.40, 300.0),
        vector4(2523.10, 3754.78, 43.48, 210.0),
    },
    packageLabel   = 'Apply LSD to Blotters',
    packageHelp    = 'Apply acid to blotter paper',
    packageProgress = 'Preparing blotters...',
    packageMarker  = { r = 200, g = 50, b = 255, a = 100 },
    packageRecipe  = {
        input  = { { item = 'liquid_lsd', amount = 1 }, { item = 'blotter_paper', amount = 1 } },
        output = { item = 'lsd_tab', amount = 5 },
        time   = 8000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 80, max = 150 },
}

-- ───────────────────────────────
-- METH (Mid Level - Rep Level 4)
-- ───────────────────────────────

DrugConfig.Drugs['meth'] = {
    label         = 'Meth',
    unlockKey     = 'meth',

    gatherType    = 'npc',
    gatherLocations = {
        { coords = vector4(1009.63, -3200.83, -38.99, 180.0), npc = true, model = 's_m_y_dealer_01', label = 'Chemical Supplier' },
        { coords = vector4(-57.61, 6436.11, 31.43, 45.0),     npc = true, model = 'a_m_m_hillbilly_01', label = 'Precursor Dealer' },
    },
    gatherItem    = 'pseudoephedrine',
    gatherCost    = 200,
    gatherAmount  = { 2, 4 },
    gatherTime    = 3000,
    gatherAnim    = { dict = 'mp_common', anim = 'givetake1_a', flag = 49 },
    gatherLabel   = 'Buy precursors',
    gatherProgress = 'Buying supplies...',
    gatherMarker  = { r = 0, g = 100, b = 200, a = 120 },

    processLocations = {
        vector4(1009.63, -3200.83, -38.99, 180.0),    -- Underground meth lab
        vector4(2433.65, 4977.55, 46.94, 130.0),      -- Rural cook site
        vector4(1441.36, 6332.31, 23.98, 170.0),      -- Paleto cove lab
    },
    processLabel   = 'Meth Lab',
    processHelp    = 'Cook meth',
    processProgress = 'Cooking meth...',
    processMarker  = { r = 0, g = 150, b = 255, a = 120 },
    processRecipe  = {
        input  = {
            { item = 'pseudoephedrine', amount = 4 },
            { item = 'methylamine', amount = 2 },
            { item = 'acetone', amount = 1 },
        },
        output = { item = 'raw_meth', amount = 3 },
        time   = 20000,
        anim   = { dict = 'anim@heists@narcotics@cooking@', anim = 'water_pipe_sequence', flag = 1 },
    },

    packageLocations = {
        vector4(1009.63, -3200.83, -38.99, 180.0),
        vector4(2433.65, 4977.55, 46.94, 130.0),
        vector4(1441.36, 6332.31, 23.98, 170.0),
    },
    packageLabel   = 'Package Meth',
    packageHelp    = 'Package meth baggies',
    packageProgress = 'Packaging meth...',
    packageMarker  = { r = 0, g = 200, b = 255, a = 100 },
    packageRecipe  = {
        input  = { { item = 'raw_meth', amount = 2 }, { item = 'small_baggy', amount = 1 } },
        output = { item = 'meth_baggy', amount = 5 },
        time   = 10000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 120, max = 200 },
}

-- ───────────────────────────────
-- CRACK COCAINE (Rep Level 5)
-- ───────────────────────────────

DrugConfig.Drugs['crack'] = {
    label         = 'Crack',
    unlockKey     = 'crack',

    gatherType    = 'npc',
    gatherLocations = {
        { coords = vector4(-161.38, -1555.67, 35.07, 325.0), npc = true, model = 'g_m_y_ballaorig_01', label = 'Ballas Connect' },
        { coords = vector4(982.51, -102.43, 74.85, 210.0),   npc = true, model = 'g_m_y_lost_02', label = 'Biker Cook' },
    },
    gatherItem    = 'baking_soda',
    gatherCost    = 50,
    gatherAmount  = { 3, 6 },
    gatherTime    = 3000,
    gatherAnim    = { dict = 'mp_common', anim = 'givetake1_a', flag = 49 },
    gatherLabel   = 'Buy baking soda',
    gatherProgress = 'Buying supplies...',
    gatherMarker  = { r = 220, g = 200, b = 100, a = 120 },

    processLocations = {
        vector4(1395.22, 1141.33, 114.33, 90.0),      -- Grand Senora Desert trailer
        vector4(-210.47, 6218.62, 31.49, 45.0),       -- Paleto trap house
        vector4(84.18, -1960.29, 21.12, 320.0),       -- South LS crack house
    },
    processLabel   = 'Crack Cook House',
    processHelp    = 'Cook crack',
    processProgress = 'Cooking crack rocks...',
    processMarker  = { r = 220, g = 200, b = 100, a = 120 },
    processRecipe  = {
        input  = {
            { item = 'raw_cocaine', amount = 1 },
            { item = 'baking_soda', amount = 3 },
        },
        output = { item = 'crack_rocks', amount = 4 },
        time   = 15000,
        anim   = { dict = 'anim@heists@narcotics@cooking@', anim = 'water_pipe_sequence', flag = 1 },
    },

    packageLocations = {
        vector4(1395.22, 1141.33, 114.33, 90.0),
        vector4(-210.47, 6218.62, 31.49, 45.0),
        vector4(84.18, -1960.29, 21.12, 320.0),
    },
    packageLabel   = 'Package Crack Vials',
    packageHelp    = 'Package crack into vials',
    packageProgress = 'Packaging crack...',
    packageMarker  = { r = 240, g = 220, b = 120, a = 100 },
    packageRecipe  = {
        input  = { { item = 'crack_rocks', amount = 2 }, { item = 'glass_vial', amount = 1 } },
        output = { item = 'crack_baggy', amount = 5 },
        time   = 8000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 100, max = 180 },
}

-- ───────────────────────────────
-- COCAINE (High Level - Rep Level 6)
-- ───────────────────────────────

DrugConfig.Drugs['cocaine'] = {
    label         = 'Cocaine',
    unlockKey     = 'cocaine',

    gatherType    = 'field',
    gatherLocations = {
        { coords = vector3(-1169.85, 4926.67, 224.23), radius = 20.0 }, -- Mount Chiliad slopes
        { coords = vector3(-544.48, 5372.68, 74.29),   radius = 25.0 }, -- Paleto forest area
        { coords = vector3(-1625.50, 4715.56, 51.00),  radius = 22.0 }, -- West Chiliad foothills
    },
    gatherItem    = 'coca_leaf',
    gatherAmount  = { 1, 2 },
    gatherTime    = 10000,
    gatherAnim    = { dict = 'amb@medic@standing@kneel@base', anim = 'base', flag = 1 },
    gatherLabel   = 'Pick coca leaves',
    gatherProgress = 'Picking coca leaves...',
    gatherMarker  = { r = 255, g = 255, b = 255, a = 80 },

    processLocations = {
        vector4(-1054.76, -240.78, 44.02, 30.0),      -- West Vinewood basement
        vector4(479.77, -3291.42, 6.07, 270.0),       -- Port warehouse
        vector4(2340.18, 2571.72, 46.68, 270.0),      -- Desert compound
    },
    processLabel   = 'Cocaine Lab',
    processHelp    = 'Refine cocaine',
    processProgress = 'Refining cocaine...',
    processMarker  = { r = 255, g = 255, b = 255, a = 120 },
    processRecipe  = {
        input  = {
            { item = 'coca_leaf', amount = 8 },
            { item = 'acetone', amount = 2 },
        },
        output = { item = 'raw_cocaine', amount = 2 },
        time   = 25000,
        anim   = { dict = 'anim@gangops@morgue@table@', anim = 'body_search', flag = 1 },
    },

    packageLocations = {
        vector4(-1054.76, -240.78, 44.02, 30.0),
        vector4(479.77, -3291.42, 6.07, 270.0),
        vector4(2340.18, 2571.72, 46.68, 270.0),
    },
    packageLabel   = 'Package Cocaine',
    packageHelp    = 'Package cocaine baggies',
    packageProgress = 'Packaging cocaine...',
    packageMarker  = { r = 255, g = 255, b = 255, a = 100 },
    packageRecipe  = {
        input  = { { item = 'raw_cocaine', amount = 1 }, { item = 'small_baggy', amount = 1 } },
        output = { item = 'cocaine_baggy', amount = 3 },
        time   = 10000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 250, max = 400 },
}

-- ───────────────────────────────
-- HEROIN (Top Level - Rep Level 7)
-- ───────────────────────────────

DrugConfig.Drugs['heroin'] = {
    label         = 'Heroin',
    unlockKey     = 'heroin',

    gatherType    = 'field',
    gatherLocations = {
        { coords = vector3(-2175.34, 4288.26, 49.17), radius = 18.0 }, -- Remote Raton Canyon
        { coords = vector3(-878.26, 5413.44, 34.38),  radius = 20.0 }, -- Paleto highlands
    },
    gatherItem    = 'opium_poppy',
    gatherAmount  = { 1, 2 },
    gatherTime    = 12000,
    gatherAnim    = { dict = 'amb@medic@standing@kneel@base', anim = 'base', flag = 1 },
    gatherLabel   = 'Harvest opium poppies',
    gatherProgress = 'Harvesting poppies...',
    gatherMarker  = { r = 120, g = 40, b = 20, a = 80 },

    processLocations = {
        vector4(1088.42, -3099.53, -38.99, 270.0),    -- Underground bunker
        vector4(-223.23, 6161.06, 31.49, 315.0),      -- Paleto compound
        vector4(2705.42, 4325.27, 45.66, 180.0),      -- East desert hideout
    },
    processLabel   = 'Heroin Refinery',
    processHelp    = 'Refine opium into heroin',
    processProgress = 'Refining heroin...',
    processMarker  = { r = 120, g = 40, b = 20, a = 120 },
    processRecipe  = {
        input  = {
            { item = 'opium_poppy', amount = 6 },
            { item = 'acetic_anhydride', amount = 2 },
        },
        output = { item = 'raw_heroin', amount = 2 },
        time   = 30000,
        anim   = { dict = 'anim@gangops@morgue@table@', anim = 'body_search', flag = 1 },
    },

    packageLocations = {
        vector4(1088.42, -3099.53, -38.99, 270.0),
        vector4(-223.23, 6161.06, 31.49, 315.0),
        vector4(2705.42, 4325.27, 45.66, 180.0),
    },
    packageLabel   = 'Package Heroin',
    packageHelp    = 'Package heroin into bags',
    packageProgress = 'Cutting and packaging...',
    packageMarker  = { r = 140, g = 60, b = 30, a = 100 },
    packageRecipe  = {
        input  = { { item = 'raw_heroin', amount = 1 }, { item = 'small_baggy', amount = 1 } },
        output = { item = 'heroin_baggy', amount = 3 },
        time   = 12000,
        anim   = { dict = 'mp_arresting', anim = 'a_uncuff', flag = 49 },
    },

    sellPrice = { min = 350, max = 550 },
}

-- ═══════════════════════════════════════════════════════════════
-- LEGACY ALIASES (for backward compatibility)
-- ═══════════════════════════════════════════════════════════════

DrugConfig.Weed    = DrugConfig.Drugs['weed']
DrugConfig.Meth    = DrugConfig.Drugs['meth']
DrugConfig.Cocaine = DrugConfig.Drugs['cocaine']

-- ═══════════════════════════════════════════════════════════════
-- SELLING CORNERS / ZONES
-- ═══════════════════════════════════════════════════════════════
-- Players approach NPCs on corners to sell. Police alert chance applies.

DrugConfig.SellCorners = {
    {
        coords    = vector4(126.07, -1797.15, 29.30, 320.0),
        npcModel  = 'a_m_y_stbla_01',
        label     = 'Davis Corner',
        drugs     = { 'weed_baggy', 'meth_baggy', 'cocaine_baggy', 'crack_baggy', 'heroin_baggy' },
    },
    {
        coords    = vector4(-47.38, -1757.95, 29.42, 40.0),
        npcModel  = 'a_f_y_genhot_01',
        label     = 'Strawberry Alley',
        drugs     = { 'weed_baggy', 'ecstasy_baggy', 'lsd_tab', 'cocaine_baggy' },
    },
    {
        coords    = vector4(320.12, -2041.10, 20.99, 50.0),
        npcModel  = 'a_m_m_stlat_02',
        label     = 'Rancho Street',
        drugs     = { 'weed_baggy', 'meth_baggy', 'crack_baggy', 'heroin_baggy' },
    },
    {
        coords    = vector4(-1176.60, -1572.03, 4.36, 120.0),
        npcModel  = 'a_m_y_beach_01',
        label     = 'Vespucci',
        drugs     = { 'weed_baggy', 'ecstasy_baggy', 'lsd_tab', 'cocaine_baggy' },
    },
    {
        coords    = vector4(1161.94, -1657.89, 36.37, 210.0),
        npcModel  = 'a_m_y_mexthug_01',
        label     = 'El Burro',
        drugs     = { 'weed_baggy', 'meth_baggy', 'crack_baggy' },
    },
    {
        coords    = vector4(971.52, -1813.72, 31.39, 2.0),
        npcModel  = 'g_m_y_lost_01',
        label     = 'East LS',
        drugs     = { 'weed_baggy', 'meth_baggy', 'cocaine_baggy', 'crack_baggy', 'heroin_baggy' },
    },
    {
        coords    = vector4(-259.80, -1532.82, 31.15, 310.0),
        npcModel  = 'a_m_m_afriamer_01',
        label     = 'South Central',
        drugs     = { 'weed_baggy', 'meth_baggy', 'cocaine_baggy', 'crack_baggy', 'ecstasy_baggy' },
    },
    {
        coords    = vector4(1382.21, 3606.84, 34.98, 180.0),
        npcModel  = 'a_m_m_hillbilly_02',
        label     = 'Sandy Shores',
        drugs     = { 'weed_baggy', 'meth_baggy', 'lsd_tab' },
    },
    {
        coords    = vector4(-1282.37, -1203.67, 4.87, 100.0),
        npcModel  = 'a_m_y_stwhi_01',
        label     = 'Del Perro Boardwalk',
        drugs     = { 'ecstasy_baggy', 'lsd_tab', 'cocaine_baggy' },
    },
    {
        coords    = vector4(148.82, -1039.16, 29.37, 335.0),
        npcModel  = 'a_m_y_downtown_01',
        label     = 'Pillbox Hill',
        drugs     = { 'cocaine_baggy', 'heroin_baggy', 'ecstasy_baggy' },
    },
}

-- Sale cooldown per player per corner (seconds)
DrugConfig.SellCooldown = 45

-- Amount of each drug sold per transaction
DrugConfig.SellAmount = 1

-- ═══════════════════════════════════════════════════════════════
-- WAREHOUSES
-- ═══════════════════════════════════════════════════════════════
-- Rentable storage locations for bulk drug storage.
-- Player needs Rep Level 8 to access.

DrugConfig.Warehouses = {
    requiredLevel = 8,

    locations = {
        {
            id       = 'warehouse_port',
            label    = 'Port Warehouse',
            coords   = vector4(1088.42, -3099.53, -38.99, 270.0),
            blip     = vector3(1088.42, -3099.53, -38.99),
            rentCost = 15000,
            maxSlots = 100,
            maxWeight = 500000,
        },
        {
            id       = 'warehouse_grapeseed',
            label    = 'Grapeseed Barn',
            coords   = vector4(1700.77, 4789.23, 41.79, 95.0),
            blip     = vector3(1700.77, 4789.23, 41.79),
            rentCost = 8000,
            maxSlots = 60,
            maxWeight = 300000,
        },
        {
            id       = 'warehouse_sandy',
            label    = 'Sandy Shores Depot',
            coords   = vector4(1538.99, 3787.85, 34.28, 30.0),
            blip     = vector3(1538.99, 3787.85, 34.28),
            rentCost = 10000,
            maxSlots = 80,
            maxWeight = 400000,
        },
        {
            id       = 'warehouse_paleto',
            label    = 'Paleto Bay Storage',
            coords   = vector4(-155.15, 6320.66, 31.58, 315.0),
            blip     = vector3(-155.15, 6320.66, 31.58),
            rentCost = 12000,
            maxSlots = 70,
            maxWeight = 350000,
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- STASH HOUSES
-- ═══════════════════════════════════════════════════════════════

DrugConfig.StashHouses = {
    locations = {
        {
            id     = 'stash_grove',
            label  = 'Grove Street Stash',
            coords = vector4(-18.07, -1442.08, 31.10, 0.0),
            maxSlots  = 25,
            maxWeight = 80000,
        },
        {
            id     = 'stash_mirror',
            label  = 'Mirror Park Stash',
            coords = vector4(1034.52, -530.17, 61.65, 130.0),
            maxSlots  = 25,
            maxWeight = 80000,
        },
        {
            id     = 'stash_sandy',
            label  = 'Sandy Shores Stash',
            coords = vector4(1656.04, 3671.19, 34.88, 310.0),
            maxSlots  = 25,
            maxWeight = 80000,
        },
        {
            id     = 'stash_paleto',
            label  = 'Paleto Bay Stash',
            coords = vector4(-233.26, 6345.72, 31.48, 225.0),
            maxSlots  = 20,
            maxWeight = 60000,
        },
        {
            id     = 'stash_vinewood',
            label  = 'Vinewood Hills Stash',
            coords = vector4(-174.74, 502.91, 137.42, 230.0),
            maxSlots  = 30,
            maxWeight = 100000,
        },
        {
            id     = 'stash_elburro',
            label  = 'El Burro Stash',
            coords = vector4(1237.53, -1615.53, 52.53, 30.0),
            maxSlots  = 25,
            maxWeight = 80000,
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- MONEY LAUNDERING
-- ═══════════════════════════════════════════════════════════════

DrugConfig.Laundering = {
    locations = {
        {
            id       = 'launder_laundromat',
            label    = 'Coin Laundromat',
            coords   = vector4(1135.00, -982.72, 46.42, 280.0),
            npcModel = 'a_f_o_genstreet_01',
            blip     = { sprite = 362, color = 69, label = 'Laundromat' },
        },
        {
            id       = 'launder_carwash',
            label    = 'LS Car Wash',
            coords   = vector4(55.69, -1391.29, 29.37, 0.0),
            npcModel = 'a_m_y_business_02',
            blip     = { sprite = 100, color = 69, label = 'Car Wash' },
        },
        {
            id       = 'launder_arcade',
            label    = 'Pixel Pete\'s Arcade',
            coords   = vector4(-1654.00, -1068.84, 13.15, 315.0),
            npcModel = 'a_m_y_hipster_01',
            blip     = { sprite = 489, color = 69, label = 'Arcade' },
        },
        {
            id       = 'launder_nightclub',
            label    = 'Bahama Mamas',
            coords   = vector4(-1387.00, -588.41, 30.22, 30.0),
            npcModel = 'a_f_y_clubcust_01',
            blip     = { sprite = 614, color = 69, label = 'Nightclub' },
        },
    },

    rates = {
        [1]  = 0.55,
        [2]  = 0.58,
        [3]  = 0.62,
        [4]  = 0.65,
        [5]  = 0.68,
        [6]  = 0.72,
        [7]  = 0.75,
        [8]  = 0.78,
        [9]  = 0.82,
        [10] = 0.85,
    },

    minAmount    = 500,
    maxAmount    = 50000,
    cooldown     = 120,
    animTime     = 8000,
}

-- ═══════════════════════════════════════════════════════════════
-- SUPPLY SHOPS (Buy materials needed for processing)
-- ═══════════════════════════════════════════════════════════════

DrugConfig.SupplyShops = {
    {
        coords   = vector4(1393.67, 3604.68, 34.98, 200.0),
        npcModel = 'csb_anita',
        label    = 'Shady Supplier',
        items    = {
            { item = 'rolling_papers', price = 25,   label = 'Rolling Papers' },
            { item = 'small_baggy',    price = 30,   label = 'Small Baggies' },
            { item = 'acetone',        price = 150,  label = 'Acetone' },
            { item = 'methylamine',    price = 350,  label = 'Methylamine' },
            { item = 'pill_press_die', price = 200,  label = 'Pill Press Die' },
            { item = 'glass_vial',     price = 40,   label = 'Glass Vials' },
            { item = 'creatine_powder', price = 80,  label = 'Creatine Powder' },
            { item = 'oregano',        price = 15,   label = 'Oregano' },
        },
    },
    {
        coords   = vector4(-57.61, 6436.11, 31.43, 45.0),
        npcModel = 'a_m_m_hillbilly_01',
        label    = 'Back-Road Dealer',
        items    = {
            { item = 'rolling_papers', price = 20,   label = 'Rolling Papers' },
            { item = 'small_baggy',    price = 25,   label = 'Small Baggies' },
            { item = 'acetone',        price = 175,  label = 'Acetone' },
            { item = 'methylamine',    price = 400,  label = 'Methylamine' },
            { item = 'diethylamine',   price = 300,  label = 'Diethylamine' },
            { item = 'blotter_paper',  price = 80,   label = 'Blotter Paper' },
            { item = 'lactose_powder', price = 60,   label = 'Lactose Powder' },
            { item = 'oregano',        price = 12,   label = 'Oregano' },
        },
    },
    {
        coords   = vector4(-1389.67, -586.06, 30.22, 210.0),
        npcModel = 'a_m_y_clubcust_04',
        label    = 'Underground Chemist',
        items    = {
            { item = 'pill_press_die',    price = 180,  label = 'Pill Press Die' },
            { item = 'diethylamine',      price = 280,  label = 'Diethylamine' },
            { item = 'blotter_paper',     price = 70,   label = 'Blotter Paper' },
            { item = 'acetic_anhydride',  price = 500,  label = 'Acetic Anhydride' },
            { item = 'glass_vial',        price = 35,   label = 'Glass Vials' },
            { item = 'small_baggy',       price = 28,   label = 'Small Baggies' },
            { item = 'caffeine_pills',    price = 50,   label = 'Caffeine Pills' },
            { item = 'creatine_powder',   price = 90,   label = 'Creatine Powder' },
            { item = 'burner_phone',      price = 2500, label = 'Burner Phone' },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- BLIP CONFIG
-- ═══════════════════════════════════════════════════════════════

DrugConfig.Blips = {
    sellCorner  = { sprite = 140, color = 1,  label = 'Sell Corner',   scale = 0.6 },
    warehouse   = { sprite = 473, color = 5,  label = 'Warehouse',     scale = 0.7 },
    stash       = { sprite = 351, color = 40, label = 'Stash House',   scale = 0.6 },
    laundromat  = { sprite = 362, color = 69, label = 'Laundromat',    scale = 0.7 },
    supplier    = { sprite = 478, color = 2,  label = 'Supplier',      scale = 0.6 },
    gathering   = { sprite = 469, color = 25, label = 'Gathering Spot', scale = 0.6 },
    processing  = { sprite = 365, color = 44, label = 'Processing Lab', scale = 0.65 },
}

-- ═══════════════════════════════════════════════════════════════
-- DRUG ITEM → DRUG TYPE MAPPING (for sell system)
-- ═══════════════════════════════════════════════════════════════

DrugConfig.DrugSellItems = {
    ['weed_baggy']    = { drug = 'Weed',    config = 'weed' },
    ['meth_baggy']    = { drug = 'Meth',    config = 'meth' },
    ['cocaine_baggy'] = { drug = 'Cocaine', config = 'cocaine' },
    ['ecstasy_baggy'] = { drug = 'Ecstasy', config = 'ecstasy' },
    ['lsd_tab']       = { drug = 'LSD',     config = 'lsd' },
    ['crack_baggy']   = { drug = 'Crack',   config = 'crack' },
    ['heroin_baggy']  = { drug = 'Heroin',  config = 'heroin' },
}

-- ═══════════════════════════════════════════════════════════════
-- 1) DRUG PURITY / QUALITY METADATA ON ITEMS
-- ═══════════════════════════════════════════════════════════════
-- Purity is embedded as metadata on crafted/packaged items.
-- Higher purity = higher sell value, better buyer rep gains.

DrugConfig.Purity = {
    enabled = true,

    -- Base purity range by quality tier (percentage 0-100)
    basePurityByTier = {
        ['Poor']       = { min = 20, max = 45 },
        ['Standard']   = { min = 40, max = 65 },
        ['Good']       = { min = 55, max = 80 },
        ['Premium']    = { min = 70, max = 90 },
        ['Masterwork'] = { min = 85, max = 100 },
    },

    -- Sell price multiplier curve based on purity
    -- Purity 50 = 1.0x, above = bonus, below = penalty
    pricePerPurityPoint = 0.008,  -- +0.8% per point above 50, -0.8% per point below 50
    basePurityRef       = 50,     -- Reference point for 1.0x multiplier

    -- Display purity labels in sell menu
    labels = {
        { min = 0,  max = 30, label = 'Trash',    color = '~r~' },
        { min = 31, max = 50, label = 'Low',      color = '~o~' },
        { min = 51, max = 70, label = 'Standard',  color = '~w~' },
        { min = 71, max = 85, label = 'High',     color = '~g~' },
        { min = 86, max = 95, label = 'Pure',     color = '~b~' },
        { min = 96, max = 100, label = 'Crystal',  color = '~p~' },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- 2) CRAFTING SKILL TREES / SPECIALIZATION
-- ═══════════════════════════════════════════════════════════════
-- Players can specialize in a specific drug type for bonuses.
-- Specialization XP is earned per-drug alongside global drug rep.

DrugConfig.Specialization = {
    enabled = true,

    -- Specialization XP rewards (per-drug, separate from global rep)
    xpRewards = {
        gather  = 2,
        process = 4,
        package = 3,
        sell    = 5,
    },

    -- Levels and their bonuses
    levels = {
        [1]  = { xp = 0,     label = 'Novice',      yieldBonus = 0.00, speedBonus = 0.00, failReduction = 0,  purityBonus = 0 },
        [2]  = { xp = 50,    label = 'Apprentice',   yieldBonus = 0.03, speedBonus = 0.03, failReduction = 1,  purityBonus = 2 },
        [3]  = { xp = 150,   label = 'Journeyman',   yieldBonus = 0.06, speedBonus = 0.06, failReduction = 2,  purityBonus = 4 },
        [4]  = { xp = 350,   label = 'Adept',        yieldBonus = 0.10, speedBonus = 0.10, failReduction = 3,  purityBonus = 6 },
        [5]  = { xp = 700,   label = 'Expert',       yieldBonus = 0.15, speedBonus = 0.12, failReduction = 5,  purityBonus = 8 },
        [6]  = { xp = 1200,  label = 'Master',       yieldBonus = 0.20, speedBonus = 0.15, failReduction = 7,  purityBonus = 10 },
        [7]  = { xp = 2000,  label = 'Grandmaster',  yieldBonus = 0.25, speedBonus = 0.18, failReduction = 9,  purityBonus = 12 },
        [8]  = { xp = 3500,  label = 'Legendary',    yieldBonus = 0.30, speedBonus = 0.20, failReduction = 12, purityBonus = 15 },
    },

    -- Max number of drugs a player can specialize in simultaneously
    maxSpecializations = 3,
}

-- ═══════════════════════════════════════════════════════════════
-- 3) DRUG DEMAND / DYNAMIC PRICING
-- ═══════════════════════════════════════════════════════════════
-- Each sell corner has fluctuating demand per drug type.
-- High demand = better prices. Selling floods supply and lowers demand.

DrugConfig.DynamicPricing = {
    enabled = true,

    -- Base demand per drug at each corner (0-100 scale)
    baseDemand = 60,

    -- How much demand decreases per sale at a corner
    demandDropPerSale = 8,

    -- How much demand recovers per cycle (every recoveryInterval seconds)
    demandRecoveryRate = 3,
    recoveryInterval   = 300,    -- 5 minutes

    -- Demand bounds
    minDemand = 10,
    maxDemand = 100,

    -- Price multiplier based on demand (interpolated)
    -- At minDemand: lowMult, at maxDemand: highMult
    lowMult  = 0.5,    -- 50% price at rock-bottom demand
    highMult = 1.6,    -- 160% price at peak demand

    -- Random demand events (periodic spikes/crashes)
    events = {
        enabled  = true,
        interval = 600,    -- Check every 10 minutes
        chance   = 25,     -- 25% chance per check

        types = {
            { id = 'surge',  label = 'Demand Surge',  demandChange = 30,  duration = 300 }, -- +30 demand for 5 min
            { id = 'crash',  label = 'Market Crash',  demandChange = -25, duration = 300 }, -- -25 demand for 5 min
            { id = 'drought', label = 'Supply Drought', demandChange = 40,  duration = 180 }, -- +40 demand for 3 min
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- 4) TURF / TERRITORY CONTROL
-- ═══════════════════════════════════════════════════════════════
-- Players can claim sell corners as their turf.
-- Controlling turf grants passive income and sell bonuses.

DrugConfig.Turf = {
    enabled = true,

    -- Time to capture a turf (seconds of standing in zone)
    captureTime = 60,

    -- Minimum drug rep level to claim turf
    requiredLevel = 5,

    -- Max turfs a single player can hold
    maxTurfsPerPlayer = 3,

    -- Passive income from owned turf ($per cycle)
    passiveIncome     = 150,         -- Per turf per cycle
    passiveInterval   = 600,         -- 10 minute cycle
    passiveMoneyType  = 'black',     -- Paid as dirty money

    -- Sell bonus when selling on your own turf
    turfSellBonus = 0.20,            -- +20% sell price on your turf

    -- Police heat increase when capturing turf
    captureHeatGain = 15,

    -- Turf expires after this many seconds of player being offline
    offlineExpiry = 7200,            -- 2 hours

    -- Turf capture zones (linked to sell corner indexes)
    -- Each sell corner can become a turf zone
    captureRadius = 15.0,

    -- Blip for owned turf
    ownedBlip = { sprite = 543, color = 2, label = 'Your Turf', scale = 0.8 },
    enemyBlip = { sprite = 543, color = 1, label = 'Enemy Turf', scale = 0.7 },
}

-- ═══════════════════════════════════════════════════════════════
-- 5) HEAT / WANTED SYSTEM
-- ═══════════════════════════════════════════════════════════════
-- Drug activities generate "heat" — invisible wanted level.
-- High heat increases police encounters, raid risk, and sell interference.

DrugConfig.Heat = {
    enabled = true,

    -- Heat gained per activity
    gains = {
        gather    = 1,
        process   = 2,
        package   = 1,
        sell      = 3,
        bulkSell  = 5,
        launder   = 1,
        turfCap   = 15,
        supplyRun = 4,
    },

    -- Heat decays over time
    decayRate     = 1,               -- Heat lost per cycle
    decayInterval = 120,             -- 2 minutes per cycle

    -- Heat thresholds and consequences
    maxHeat = 100,
    thresholds = {
        { heat = 20,  label = 'Warm',     policeAlertMult = 1.2,  encounterMult = 1.1 },
        { heat = 40,  label = 'Hot',      policeAlertMult = 1.5,  encounterMult = 1.3 },
        { heat = 60,  label = 'Burning',  policeAlertMult = 2.0,  encounterMult = 1.6 },
        { heat = 80,  label = 'Inferno',  policeAlertMult = 3.0,  encounterMult = 2.0 },
        { heat = 95,  label = 'Nuclear',  policeAlertMult = 5.0,  encounterMult = 3.0 },
    },

    -- At these heat levels, police patrols can spawn near player
    patrolSpawnThreshold = 50,
    patrolCheckInterval  = 60,       -- Check every 60 seconds
    patrolChance         = 15,       -- 15% base chance (multiplied by encounterMult)

    -- How fast heat drops when player lies low (no drug activity)
    cooldownBonus = 2,               -- Extra decay per cycle if no activity in last 5 min
    cooldownWindow = 300,            -- 5 minutes of inactivity
}

-- ═══════════════════════════════════════════════════════════════
-- 6) SUPPLY CHAIN RUNS / TRANSPORT MISSIONS
-- ═══════════════════════════════════════════════════════════════
-- Risky delivery missions that transport bulk drugs between locations.

DrugConfig.SupplyRuns = {
    enabled = true,

    -- Minimum drug rep level to access supply runs
    requiredLevel = 4,

    -- Cooldown between supply runs (seconds)
    cooldown = 900,                  -- 15 minutes

    -- Routes
    routes = {
        {
            id          = 'grapeseed_city',
            label       = 'Grapeseed → LS',
            pickupCoords  = vector4(1700.77, 4789.23, 41.79, 95.0),
            deliveryCoords = vector4(126.07, -1797.15, 29.30, 320.0),
            vehicleModel = 'rumpo',
            reward       = { cash = 0, black = 3500, rep = 25 },
            timeLimit    = 600,      -- 10 minutes
            requiredLevel = 4,
        },
        {
            id          = 'paleto_sandy',
            label       = 'Paleto → Sandy Shores',
            pickupCoords  = vector4(-155.15, 6320.66, 31.58, 315.0),
            deliveryCoords = vector4(1538.99, 3787.85, 34.28, 30.0),
            vehicleModel = 'youga',
            reward       = { cash = 0, black = 2500, rep = 18 },
            timeLimit    = 480,      -- 8 minutes
            requiredLevel = 4,
        },
        {
            id          = 'port_vinewood',
            label       = 'Port → Vinewood',
            pickupCoords  = vector4(479.77, -3291.42, 6.07, 270.0),
            deliveryCoords = vector4(-174.74, 502.91, 137.42, 230.0),
            vehicleModel = 'speedo',
            reward       = { cash = 0, black = 4500, rep = 30 },
            timeLimit    = 720,      -- 12 minutes
            requiredLevel = 6,
        },
        {
            id          = 'desert_southls',
            label       = 'Desert → South LS',
            pickupCoords  = vector4(2340.18, 2571.72, 46.68, 270.0),
            deliveryCoords = vector4(84.18, -1960.29, 21.12, 320.0),
            vehicleModel = 'burrito3',
            reward       = { cash = 0, black = 5500, rep = 35 },
            timeLimit    = 600,      -- 10 minutes
            requiredLevel = 7,
        },
    },

    -- Ambush chance during delivery (hostile NPCs attack en route)
    ambush = {
        enabled = true,
        checkInterval = 30,          -- Check every 30 seconds during run
        chance  = 12,                -- 12% chance per check
        pedModel = 'g_m_y_lost_03',
        pedCount = { 2, 4 },
        vehicleModel = 'baller2',
    },

    -- Heat gained from supply runs
    heatGain = 4,
}

-- ═══════════════════════════════════════════════════════════════
-- 7) NPC BUYER REPUTATION
-- ═══════════════════════════════════════════════════════════════
-- Each sell corner NPC has trust/reputation with the player.
-- Higher buyer rep = better prices, bulk deals, special requests.

DrugConfig.BuyerRep = {
    enabled = true,

    -- Rep gained per successful sale at a corner
    repPerSale = 3,

    -- Rep lost for bad deals (low purity, skipping a corner for too long)
    repDecayRate     = 1,            -- Per cycle
    repDecayInterval = 1800,         -- 30 minutes

    -- Trust levels and bonuses
    levels = {
        [1] = { xp = 0,    label = 'Stranger',   priceBonus = 0.00, bulkAmount = 1 },
        [2] = { xp = 15,   label = 'Known Face',  priceBonus = 0.05, bulkAmount = 2 },
        [3] = { xp = 40,   label = 'Regular',     priceBonus = 0.10, bulkAmount = 3 },
        [4] = { xp = 80,   label = 'Trusted',     priceBonus = 0.18, bulkAmount = 5 },
        [5] = { xp = 150,  label = 'VIP',         priceBonus = 0.25, bulkAmount = 8 },
        [6] = { xp = 250,  label = 'Inner Circle', priceBonus = 0.35, bulkAmount = 10 },
    },

    -- Purity affects buyer rep gain
    -- High purity = more rep gained per sale
    purityRepMult = {
        { min = 0,  max = 30,  mult = 0.5 },  -- Low purity = half rep
        { min = 31, max = 60,  mult = 1.0 },
        { min = 61, max = 85,  mult = 1.3 },
        { min = 86, max = 100, mult = 1.8 },  -- High purity = extra rep
    },
}

-- ═══════════════════════════════════════════════════════════════
-- 8) CUTTING / MIXING SYSTEM
-- ═══════════════════════════════════════════════════════════════
-- Post-packaging step: cut drugs with fillers to increase quantity
-- at the cost of purity. High-risk/high-reward mechanic.

DrugConfig.Cutting = {
    enabled = true,

    -- Requires a cutting station (at stash houses)
    useStashLocations = true,

    -- Cutting agents and their effects
    agents = {
        {
            item         = 'baking_soda',
            label        = 'Baking Soda',
            quantityMult = 1.5,       -- +50% quantity
            purityLoss   = 15,        -- -15 purity points
            compatibleDrugs = { 'cocaine_baggy', 'crack_baggy' },
        },
        {
            item         = 'creatine_powder',
            label        = 'Creatine Powder',
            quantityMult = 1.3,       -- +30% quantity
            purityLoss   = 10,        -- -10 purity points
            compatibleDrugs = { 'cocaine_baggy', 'meth_baggy', 'heroin_baggy' },
        },
        {
            item         = 'lactose_powder',
            label        = 'Lactose Powder',
            quantityMult = 1.8,       -- +80% quantity
            purityLoss   = 25,        -- -25 purity points
            compatibleDrugs = { 'heroin_baggy', 'cocaine_baggy' },
        },
        {
            item         = 'caffeine_pills',
            label        = 'Caffeine Pills',
            quantityMult = 1.4,       -- +40% quantity
            purityLoss   = 12,        -- -12 purity points
            compatibleDrugs = { 'ecstasy_baggy', 'meth_baggy' },
        },
        {
            item         = 'oregano',
            label        = 'Oregano',
            quantityMult = 2.0,       -- +100% quantity
            purityLoss   = 30,        -- -30 purity points
            compatibleDrugs = { 'weed_baggy' },
        },
    },

    -- Animation and timing
    cutTime = 10000,
    cutAnim = { dict = 'anim@gangops@morgue@table@', anim = 'body_search', flag = 1 },

    -- Minimum purity after cutting (can't go below this)
    minPurity = 5,
}

-- ═══════════════════════════════════════════════════════════════
-- 9) BURNER PHONE SYSTEM
-- ═══════════════════════════════════════════════════════════════
-- Players can use a burner phone item to receive drug deal requests.
-- Deals are higher-risk but higher-reward than street corner sales.

DrugConfig.BurnerPhone = {
    enabled = true,

    -- Item required to use the burner phone
    phoneItem = 'burner_phone',

    -- How often new deals come in (seconds)
    dealInterval = 180,              -- 3 minutes

    -- Max active deals at once
    maxActiveDeals = 3,

    -- Deal types
    dealTypes = {
        {
            id     = 'quick_flip',
            label  = 'Quick Flip',
            weight = 40,
            priceMult     = { min = 1.2, max = 1.5 },   -- 20-50% above street price
            quantity       = { min = 1, max = 3 },
            timeLimit      = 300,                         -- 5 min to complete
            heatGain       = 2,
            repGain        = 5,
            policeChance   = 10,                          -- 10% police chance
        },
        {
            id     = 'bulk_order',
            label  = 'Bulk Order',
            weight = 25,
            priceMult     = { min = 1.4, max = 1.8 },   -- 40-80% above street
            quantity       = { min = 5, max = 15 },
            timeLimit      = 600,                         -- 10 min
            heatGain       = 5,
            repGain        = 12,
            policeChance   = 20,
            requiredLevel  = 4,
        },
        {
            id     = 'premium_client',
            label  = 'Premium Client',
            weight = 20,
            priceMult     = { min = 1.8, max = 2.5 },   -- 80-150% above street
            quantity       = { min = 2, max = 5 },
            timeLimit      = 420,                         -- 7 min
            heatGain       = 4,
            repGain        = 15,
            policeChance   = 15,
            requiredLevel  = 6,
            minPurity      = 70,                          -- Requires high purity
        },
        {
            id     = 'cartel_deal',
            label  = 'Cartel Deal',
            weight = 15,
            priceMult     = { min = 2.0, max = 3.0 },   -- 100-200% above street
            quantity       = { min = 10, max = 25 },
            timeLimit      = 900,                         -- 15 min
            heatGain       = 10,
            repGain        = 25,
            policeChance   = 30,
            requiredLevel  = 8,
            minPurity      = 80,
        },
    },

    -- Meet locations (random from this pool)
    meetLocations = {
        vector4(126.07, -1797.15, 29.30, 320.0),
        vector4(-47.38, -1757.95, 29.42, 40.0),
        vector4(971.52, -1813.72, 31.39, 2.0),
        vector4(1382.21, 3606.84, 34.98, 180.0),
        vector4(-1282.37, -1203.67, 4.87, 100.0),
        vector4(148.82, -1039.16, 29.37, 335.0),
        vector4(-259.80, -1532.82, 31.15, 310.0),
        vector4(320.12, -2041.10, 20.99, 50.0),
    },

    -- NPC buyer models
    buyerModels = {
        'a_m_y_business_01',
        'a_m_m_bevhills_02',
        'a_f_y_bevhills_01',
        'a_m_y_stwhi_02',
        'ig_clay',
        'csb_chin_goon',
    },
}

-- ═══════════════════════════════════════════════════════════════
-- 10) RAID EVENTS
-- ═══════════════════════════════════════════════════════════════
-- High heat + lots of activity can trigger police raids on labs/stashes.
-- Players get a warning and limited time to evacuate or defend.

DrugConfig.Raids = {
    enabled = true,

    -- Heat threshold to enable raid checks
    heatThreshold = 60,

    -- Check interval (seconds)
    checkInterval = 300,             -- 5 minutes

    -- Base chance per check (scaled by heat)
    baseChance = 10,                 -- 10% at threshold, scales up

    -- Warning time before raid starts (seconds)
    warningTime = 45,

    -- Raid duration (seconds) — how long police presence lasts
    raidDuration = 120,

    -- Possible raid targets
    targets = {
        'processLocations',          -- Raid a processing lab
        'stashHouse',                -- Raid a stash house
        'warehouse',                 -- Raid a warehouse
    },

    -- Police raid party
    officerModel = 's_m_y_swat_01',
    officerCount = { 3, 6 },
    officerWeapons = { 'WEAPON_CARBINERIFLE', 'WEAPON_PUMPSHOTGUN' },

    -- Consequences if player is caught at raid location
    heatOnCaught     = 30,           -- Additional heat if caught
    repLossOnCaught  = 50,           -- Drug rep lost if caught

    -- Reward for successfully evading
    evadeRepBonus = 10,

    -- Stash/warehouse seizure
    seizureEnabled = true,           -- Police can seize items from raided location
    seizureChance  = 40,             -- 40% chance of items being seized

    -- Blip during active raid
    raidBlip = { sprite = 161, color = 1, label = 'POLICE RAID', scale = 1.2 },
}


