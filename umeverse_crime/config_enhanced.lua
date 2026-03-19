--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    Umeverse Crime System - Enhanced Configuration
    All enhancements: Specialization leveling, Dynamic mechanics, Advanced types
]]

CrimeConfig = {}

-- SPECIALIZATION SYSTEM (Enhanced with leveling)
CrimeConfig.Specializations = {
    ['lockpicking'] = {
        label = 'Master Lockpicker',
        maxLevel = 10,
        crimeBonus = { 'burglary', 'car_theft' },
        levelBonuses = {
            [1] = { timeReduction = 10, successBonus = 5, heatReduction = 5 },
            [5] = { timeReduction = 25, successBonus = 15, heatReduction = 10, unlock = 'silent_entry' },
            [10] = { timeReduction = 40, successBonus = 25, heatReduction = 20, unlock = 'bypass_alarms' },
        },
        unlockCost = 500, -- Black money to unlock specialization
        levelCost = 1000, -- Cost per level
    },
    ['hacking'] = {
        label = 'Expert Hacker',
        maxLevel = 10,
        crimeBonus = { 'atm_robbery', 'jewelry_heist', 'armored_car' },
        levelBonuses = {
            [1] = { timeReduction = 15, successBonus = 10, heatReduction = 10 },
            [5] = { timeReduction = 30, successBonus = 20, heatReduction = 15, unlock = 'remote_disable' },
            [10] = { timeReduction = 45, successBonus = 30, heatReduction = 25, unlock = 'security_access' },
        },
        unlockCost = 750,
        levelCost = 1500,
    },
    ['stealth'] = {
        label = 'Master Stealth',
        maxLevel = 10,
        crimeBonus = { 'pickpocket', 'burglary', 'jewelry_heist' },
        levelBonuses = {
            [1] = { detectionReduction = 20, heatReduction = 10 },
            [5] = { detectionReduction = 40, heatReduction = 20, unlock = 'ghost_mode' },
            [10] = { detectionReduction = 60, heatReduction = 30, unlock = 'invisibility_cloak' },
        },
        unlockCost = 600,
        levelCost = 1200,
    },
    ['brawler'] = {
        label = 'Street Brawler',
        maxLevel = 10,
        crimeBonus = { 'store_robbery', 'armored_car' },
        levelBonuses = {
            [1] = { rewardBonus = 5, damageReduction = 10 },
            [5] = { rewardBonus = 15, damageReduction = 20, unlock = 'intimidation' },
            [10] = { rewardBonus = 25, damageReduction = 30, unlock = 'knockout_punch' },
        },
        unlockCost = 400,
        levelCost = 800,
    },
}

-- DYNAMIC CRIME MECHANICS
CrimeConfig.DynamicMechanics = {
    complications = {
        enabled = true,
        baseChance = 0.15, -- 15% chance per crime
        types = {
            ['guard_encounter'] = { label = 'Unexpected Guard', timePenalty = 5, rewardReduction = 0.2 },
            ['alarm_triggered'] = { label = 'Alarm Triggered', heatIncrease = 30, rewardReduction = 0.3 },
            ['police_patrol'] = { label = 'Police Patrol Nearby', heatIncrease = 25, timePenalty = 10 },
            ['witness'] = { label = 'Civilian Witness', heatIncrease = 20, rewardReduction = 0.15 },
            ['escape_blocked'] = { label = 'Exit Blocked', timePenalty = 15, rewardReduction = 0.25 },
        },
    },
    witnesses = {
        enabled = true,
        witnessChance = 0.20, -- 20% someone sees crime
        identification = {
            chance = 0.40, -- 40% they identify you
            timeUntilReport = 300, -- 5 minutes
            reward = 500, -- Reward for turning in witness info
        },
    },
    timeBased = {
        enabled = true,
        earlyMorning = { hour = 4, hour_end = 7, successBonus = 15, heatReduction = 0.8 },
        daytime = { hour = 8, hour_end = 17, successPenalty = 10, heatMultiplier = 1.2 },
        evening = { hour = 18, hour_end = 23, neutral = true },
        night = { hour = 0, hour_end = 3, successBonus = 10, heatReduction = 0.9 },
    },
    weather = {
        enabled = true,
        rain = { detectionReduction = 0.20, heatReduction = 0.8, rewardBonus = 1.1 },
        fog = { detectionReduction = 0.25, heatReduction = 0.85 },
        snow = { detectionReduction = 0.15, successPenalty = 10, timeIncrease = 1.2 },
        sunny = { heatMultiplier = 1.15, detectionIncrease = 1.1 },
    },
    locationRotation = {
        enabled = true,
        rotationTime = 1800, -- 30 minutes before same location available again
        multipleCrimes = {
            sameLocation = 0.7, -- 70% penalty if repeating
            nearbyLocation = 0.85, -- 85% if nearby
        },
    },
}

-- CRIME RECORDS & CRIMINAL PROFILE
CrimeConfig.CriminalRecords = {
    enabled = true,
    tracking = {
        wantedStatus = true, -- Tracks if actively wanted
        prisonTime = true, -- Tracks accumulated arrests
        bounties = true, -- Tracks active bounties on player
        crimeHistory = true, -- Full crime log
    },
    consequences = {
        arrest = { prisonTime = 300, fineMultiplier = 2.0 }, -- 5 minutes prison time, 2x fine
        bountyPercentage = 0.10, -- Bounty = 10% of crime reward
        recordDecayTime = 2592000, -- 30 days before record expires
    },
}

-- ADVANCED CRIME TYPES
CrimeConfig.AdvancedCrimes = {
    ['organized_heist'] = {
        label = 'Organized Heist',
        tier = 3,
        minSkill = 200,
        successChance = { min = 50, max = 70 },
        rewards = {
            black_money = { min = 20000, max = 50000 },
            items = { { name = 'diamonds', chance = 70 }, { name = 'gold_bars', chance = 50 } },
        },
        heat = 120,
        minTime = 30,
        maxTime = 60,
        difficulty = 'extreme',
        requiresTeam = true,
        teamSize = 3,
        requiresPlanning = true,
        stages = 4, -- Multi-stage mission
    },
    ['counterfeiting'] = {
        label = 'Counterfeiting Ring',
        tier = 2,
        minSkill = 100,
        successChance = { min = 65, max = 80 },
        rewards = {
            black_money = { min = 2000, max = 5000 },
        },
        heat = 50,
        minTime = 20,
        maxTime = 40,
        difficulty = 'hard',
        recurring = true, -- Can repeat for passive income
    },
    ['detective_case'] = {
        label = 'Detective Case',
        tier = 2,
        minSkill = 75,
        successChance = { min = 70, max = 85 },
        rewards = {
            black_money = { min = 3000, max = 8000 },
            reputation = 100,
        },
        heat = 30,
        minTime = 15,
        maxTime = 25,
        difficulty = 'medium',
        canTargetPlayers = true, -- Can hire detective work against other players
    },
    ['police_corruption'] = {
        label = 'Police Corruption',
        tier = 3,
        minSkill = 150,
        successChance = { min = 60, max = 80 },
        rewards = {
            black_money = { min = 5000, max = 15000 },
        },
        heat = 80,
        minTime = 10,
        maxTime = 20,
        difficulty = 'hard',
        requiresContact = true, -- Need a corrupt cop contact
    },
}

-- BOUNTY & HEAT SYSTEM (Enhanced)
CrimeConfig.BountySystem = {
    enabled = true,
    minBounty = 5000,
    maxBounty = 50000,
    bountyDuration = 604800, -- 7 days
    bountyHunters = {
        enabled = true,
        hunterReward = 0.75, -- Hunters get 75% of bounty
        hunterLevel = 5, -- Must have 5+ crime rep to be bounty hunter
    },
}

CrimeConfig.HeatAmnestySystem = {
    enabled = true,
    gangsOnly = true,
    amnestyCost = 5000, -- Black money from gang bank
    amnestyDuration = 300, -- 5 minute protection
    amnestyPercentage = 0.50, -- 50% heat reduction if using amnesty
}

CrimeConfig.SafeHouses = {
    enabled = true,
    rentCost = 1000, -- Per hour
    maxDuration = 3600, -- 1 hour max per rental
    locations = {
        { name = 'Grove Street Safehouse', gang = 'families', x = -100, y = -1600, z = 35 },
        { name = 'Ballas Crib', gang = 'ballas', x = -150, y = -1500, z = 33 },
        { name = 'Vagos Compound', gang = 'vagos', x = 300, y = -1000, z = 29 },
    },
    benefits = {
        heatReduction = 0.90, -- 10% heat reduction per minute
        healPlayer = true,
        fullArmor = true,
    },
}

-- HEAT SYSTEM (Enhanced)
CrimeConfig.Heat = {
    maxHeat = 100,
    heatDecayRate = 5, -- Per minute when not committing crimes
    heatBlur = 0.1,
    heatMultiplier = {
        alone = 1.0,
        withTeam = 0.7,
        withGangMembers = 0.5,
    },
    heatTransfer = {
        enabled = true,
        distanceThreshold = 5000, -- 5km away resets heat faster
        transferMultiplier = 0.5, -- Half decay rate outside area
    },
    policeResponse = {
        high = { minHeat = 70, maxResponseTime = 5, units = 4, swat = true },
        medium = { minHeat = 40, maxResponseTime = 10, units = 3, swat = false },
        low = { minHeat = 10, maxResponseTime = 15, units = 1, swat = false },
    },
}

-- BLIP LOCATIONS
CrimeConfig.CrimeBlips = {
    -- Pickpocket hotspots
    { x = 425.5, y = -982.3, z = 29.4, type = 'pickpocket', label = 'Pickpocket - Legion Square' },
    { x = -548.2, y = -914.5, z = 29.3, type = 'pickpocket', label = 'Pickpocket - MRPD' },
    { x = -59.2, y = 6271.5, z = 31.5, type = 'pickpocket', label = 'Pickpocket - Sandy Shores' },
    
    -- Store robbery
    { x = -47.7, y = -1097.3, z = 26.4, type = 'store_robbery', label = 'Rob Store - Pillbox' },
    { x = 374.5, y = 326.1, z = 103.6, type = 'store_robbery', label = 'Rob Store - Downtown' },
    { x = -2968.2, y = 390.1, z = 15.0, type = 'store_robbery', label = 'Rob Store - Del Perro' },
    
    -- ATM robberies
    { x = -537.15, y = -287.5, z = 35.51, type = 'atm_robbery', label = 'Rob ATM - Maze' },
    { x = 149.27, y = -1044.45, z = 29.37, type = 'atm_robbery', label = 'Rob ATM - Pillbox' },
    
    -- Burglary Houses
    { x = -456.5, y = 6226.1, z = 31.5, type = 'burglary', label = 'Burgle House - Sandy' },
    { x = 1190.5, y = -783.3, z = 57.6, type = 'burglary', label = 'Burgle House - Vinewood' },
    
    -- Jewelry Store
    { x = -630.2, y = -234.5, z = 38.0, type = 'jewelry_heist', label = 'Jewelry Heist - Downtown' },
}

-- TIER REQUIREMENTS
CrimeConfig.TierRequirements = {
    [1] = { minSuccessRate = 0, minCrimesCompleted = 0, },
    [2] = { minSuccessRate = 60, minCrimesCompleted = 10 },
    [3] = { minSuccessRate = 80, minCrimesCompleted = 50 },
}

-- ITEMS
CrimeConfig.CrimeItems = {
    'phone', 'wallet', 'jewelry', 'cash_bundle',
    'electronics', 'car_parts', 'catalytic_converter',
    'diamond_ring', 'painting', 'diamonds', 'gold_bars',
    'rare_jewelry', 'counterfeit_money',
}

return CrimeConfig
