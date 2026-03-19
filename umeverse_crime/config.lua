--[[
    ██╗   ██╗███╗   ███╗███████╗██╗   ██╗███████╗██████╗ ███████╗███████╗
    Umeverse Crime System Configuration
]]

CrimeConfig = {}

-- Crime Types & Rewards
CrimeConfig.Crimes = {
    -- TIER 1: Beginner Crimes
    ['pickpocket'] = {
        label = 'Pickpocket',
        tier = 1,
        minSkill = 0,
        successChance = { min = 60, max = 80 },
        rewards = {
            money = { min = 50, max = 150 },
            black_money = { min = 100, max = 300 },
            items = {
                { name = 'phone', chance = 15 },
                { name = 'wallet', chance = 20 },
                { name = 'jewelry', chance = 5 },
            },
        },
        heat = 15,
        minTime = 3,
        maxTime = 8,
        animations = {
            dict = 'missheist_jewel',
            anim = 'mh_stealinv_grab',
            duration = 5000,
        },
    },
    ['store_robbery'] = {
        label = 'Store Robbery',
        tier = 2,
        minSkill = 50,
        successChance = { min = 70, max = 85 },
        rewards = {
            black_money = { min = 500, max = 1000 },
            items = {
                { name = 'cash_bundle', chance = 30 },
                { name = 'jewelry', chance = 25 },
                { name = 'electronics', chance = 15 },
            },
        },
        heat = 35,
        minTime = 10,
        maxTime = 15,
        animations = {
            dict = 'combat@damage@rb_writhe',
            anim = 'rb_writhe_loop',
            duration = 3000,
        },
        difficulty = 'medium',
    },
    ['car_theft'] = {
        label = 'Car Theft',
        tier = 1,
        minSkill = 30,
        successChance = { min = 75, max = 90 },
        rewards = {
            black_money = { min = 800, max = 2000 },
            items = {
                { name = 'car_parts', chance = 40 },
                { name = 'catalytic_converter', chance = 20 },
            },
        },
        heat = 40,
        minTime = 5,
        maxTime = 12,
        animations = {
            dict = 'vehshare@handsup',
            anim = 'handsup_base',
            duration = 2000,
        },
        difficulty = 'medium',
    },
    ['atm_robbery'] = {
        label = 'ATM Robbery',
        tier = 2,
        minSkill = 80,
        successChance = { min = 65, max = 80 },
        rewards = {
            black_money = { min = 1200, max = 3000 },
            items = {
                { name = 'cash_bundle', chance = 50 },
                { name = 'diamond_ring', chance = 15 },
            },
        },
        heat = 50,
        minTime = 8,
        maxTime = 15,
        animations = {
            dict = 'missheist_jewel',
            anim = 'mh_stealinv_grab',
            duration = 5000,
        },
        difficulty = 'hard',
        requiresHacking = true,
    },
    ['burglary'] = {
        label = 'Burglary',
        tier = 2,
        minSkill = 60,
        successChance = { min = 70, max = 85 },
        rewards = {
            black_money = { min = 1000, max = 2500 },
            items = {
                { name = 'jewelry', chance = 40 },
                { name = 'electronics', chance = 35 },
                { name = 'cash_bundle', chance = 30 },
                { name = 'painting', chance = 10 },
            },
        },
        heat = 60,
        minTime = 15,
        maxTime = 25,
        animations = {
            dict = 'missheist_jewel',
            anim = 'mh_stealinv_grab',
            duration = 5000,
        },
        difficulty = 'hard',
        requiresLockpicking = true,
    },
    ['jewelry_heist'] = {
        label = 'Jewelry Store Heist',
        tier = 3,
        minSkill = 150,
        successChance = { min = 60, max = 75 },
        rewards = {
            black_money = { min = 5000, max = 15000 },
            items = {
                { name = 'diamonds', chance = 60 },
                { name = 'gold_bars', chance = 40 },
                { name = 'rare_jewelry', chance = 30 },
            },
        },
        heat = 100,
        minTime = 20,
        maxTime = 35,
        difficulty = 'very_hard',
        requiresTeam = true,
        teamSize = 2,
        requiresHacking = true,
        requiresPlanning = true,
    },
    ['armored_car'] = {
        label = 'Armored Car Robbery',
        tier = 3,
        minSkill = 120,
        successChance = { min = 55, max = 70 },
        rewards = {
            black_money = { min = 3000, max = 8000 },
            items = {
                { name = 'cash_bundle', chance = 70 },
                { name = 'gold_bars', chance = 30 },
            },
        },
        heat = 80,
        minTime = 12,
        maxTime = 20,
        difficulty = 'hard',
        requiresTeam = true,
        teamSize = 2,
    },
}

-- Heat System
CrimeConfig.Heat = {
    maxHeat = 100,
    heatDecayRate = 5, -- Per minute when not committing crimes
    heatBlur = 0.1,
    heatMultiplier = {
        alone = 1.0,
        withTeam = 0.7,
        withGangMembers = 0.5,
    },
    policeResponse = {
        high = { minHeat = 70, maxResponseTime = 5, units = 3 },
        medium = { minHeat = 40, maxResponseTime = 10, units = 2 },
        low = { minHeat = 10, maxResponseTime = 15, units = 1 },
    },
}

-- Specializations
CrimeConfig.Specializations = {
    ['lockpicking'] = {
        label = 'Master Lockpicker',
        crimeBonus = { 'burglary', 'car_theft' },
        timeReduction = 25,
        successBonus = 15,
        heatReduction = 10,
    },
    ['hacking'] = {
        label = 'Expert Hacker',
        crimeBonus = { 'atm_robbery', 'jewelry_heist', 'armored_car' },
        timeReduction = 30,
        successBonus = 20,
        heatReduction = 15,
    },
    ['stealth'] = {
        label = 'Master Stealth',
        crimeBonus = { 'pickpocket', 'burglary', 'jewelry_heist' },
        detectionReduction = 40,
        heatReduction = 20,
    },
    ['brawler'] = {
        label = 'Street Brawler',
        crimeBonus = { 'store_robbery', 'armored_car' },
        rewardBonus = 15,
        damageReduction = 20,
    },
}

-- Blip Locations
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

-- Items for crimes
CrimeConfig.CrimeItems = {
    'phone', 'wallet', 'jewelry', 'cash_bundle',
    'electronics', 'car_parts', 'catalytic_converter',
    'diamond_ring', 'painting', 'diamonds', 'gold_bars',
    'rare_jewelry',
}

return CrimeConfig
